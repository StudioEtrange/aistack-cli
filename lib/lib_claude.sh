claude_init() {
	# claude specific variables
	export CLAUDE_CODE_FEAT_INSTALL_ROOT="${AISTACK_ISOLATED_ROOT}/claude-code"
	mkdir -p "${CLAUDE_CODE_FEAT_INSTALL_ROOT}"

	# claude launcher
	export AISTACK_CLAUDE_CODE_LAUNCHER_HOME="${AISTACK_LAUNCHER_HOME}/claude-code"
	mkdir -p "${AISTACK_CLAUDE_CODE_LAUNCHER_HOME}"
	export AISTACK_CLAUDE_CODE_LAUNCHER_FILE="${AISTACK_CLAUDE_CODE_LAUNCHER_HOME}/claude"

	# claude context
	export AISTACK_CLAUDE_CODE_CONTEXT_HOME="${AISTACK_CONTEXT_HOME}/claude-code"
	mkdir -p "${AISTACK_CLAUDE_CODE_CONTEXT_HOME}"
	export AISTACK_CLAUDE_CODE_CONTEXT_FILE="${AISTACK_CLAUDE_CODE_CONTEXT_HOME}/claude_context.sh"
	# any variables needed to run this component or used by _launch function
	# NOTE: do not need to declare those variables:
	#		AISTACK_*_CONTEXT_FILE and AISTACK_GENERIC_CONTEXT_FILE are already exported
	#		every *_SEARCH_PATH variable related to a REQUIRED_RUNTIME or REQUIRED_MODULE are already exported
	export AISTACK_CLAUDE_CODE_CONTEXT_EXPORT_VARIABLES="CLAUDE_CODE_FEAT_INSTALL_ROOT"

	# claude requirement - those will be installed and presence checked to run the current component
	# NOTE: those search path will be injected in context file
	export AISTACK_CLAUDE_CODE_RUNTIME_REQUIRED=""
	export AISTACK_CLAUDE_CODE_MODULE_REQUIRED=""
	# remove from context any runtime or module any item already in generic aistack context
	export AISTACK_CLAUDE_CODE_RUNTIME_REQUIRED_IN_CONTEXT="$("${STELLA_API}" filter_list_with_list "${AISTACK_CLAUDE_CODE_RUNTIME_REQUIRED}" "${AISTACK_GENERIC_CONTEXT_ADD_RUNTIME}")"
	export AISTACK_CLAUDE_CODE_MODULE_REQUIRED_IN_CONTEXT="$("${STELLA_API}" filter_list_with_list "${AISTACK_CLAUDE_CODE_MODULE_REQUIRED}" "${AISTACK_GENERIC_CONTEXT_ADD_MODULE}")"

}

# test if claude is installed
# return 0 : is installed
# return 1 : tool is not installed
# return 2 : missing runtime
claude_is_installed() {
	local r m
	export AISTACK_CLAUDE_CODE_TOOL_AVAILABLE="false"
	export AISTACK_CLAUDE_CODE_TOOL_SEARCH_PATH=""
	export AISTACK_CLAUDE_CODE_TOOL_PATH=""
	for r in ${AISTACK_CLAUDE_CODE_RUNTIME_REQUIRED}; do aistack_runtime_is_detected "${r}" || return 2; done
	for m in ${AISTACK_CLAUDE_CODE_MODULE_REQUIRED}; do aistack_module_is_detected "${m}" || return 2; done
	[ -x "${CLAUDE_CODE_FEAT_INSTALL_ROOT}/claude" ] || return 1
	export AISTACK_CLAUDE_CODE_TOOL_AVAILABLE="true"
	export AISTACK_CLAUDE_CODE_TOOL_SEARCH_PATH="${CLAUDE_CODE_FEAT_INSTALL_ROOT}"
	export AISTACK_CLAUDE_CODE_TOOL_PATH="${AISTACK_CLAUDE_CODE_TOOL_SEARCH_PATH}/claude"
	return 0
}


# Keep upstream platform detection and checksum verification, but stop before setup.
# Temporary adapter until https://github.com/anthropics/claude-code/issues/106145
# provides a download-only mode. Reject an unrecognized layout before execution.
claude_bootstrap_prepare() {
	local source_file="${1}"
	local output_file="${2}"
	[ -f "${source_file}" ] && [ -n "${output_file}" ] || return 1
	if ! awk '
		$0 == "DOWNLOAD_DIR=\"$HOME/.claude/downloads\"" { directory++; directory_line=NR }
		$0 == "chmod +x \"$binary_path\"" { boundary++; boundary_line=NR }
		$0 == "# Run claude install to set up launcher and shell integration" { setup++; setup_line=NR }
		$0 == "\"$binary_path\" install ${TARGET:+\"$TARGET\"} || install_code=$?" { install++; install_line=NR }
		$0 == "rm -f \"$binary_path\"" && setup { cleanup++; cleanup_line=NR }
		END {
			exit !(directory == 1 && boundary == 1 && setup == 1 && install == 1 && cleanup == 1 &&
				directory_line < boundary_line && boundary_line < setup_line &&
				setup_line < install_line && install_line < cleanup_line)
		}
	' "${source_file}"; then
		echo "ERROR: Unsupported Claude Code bootstrap layout; download-only adapter needs updating." >&2
		return 1
	fi

	awk '
		$0 == "DOWNLOAD_DIR=\"$HOME/.claude/downloads\"" {
			print "DOWNLOAD_DIR=\"${AISTACK_CLAUDE_CODE_DOWNLOAD_DIR:?}\""
			next
		}
		{ print }
		$0 == "chmod +x \"$binary_path\"" { exit }
	' "${source_file}" > "${output_file}" || return $?
	cat >> "${output_file}" <<'EOF'

printf '%s\n' "${binary_path}" > "${AISTACK_CLAUDE_CODE_DOWNLOAD_RESULT:?}"
exit 0
EOF
	bash -n "${output_file}"
}

claude_bootstrap_download() {
	local output_file="${1}"
	if command -v curl >/dev/null 2>&1; then
		curl -fsSL -o "${output_file}" "https://claude.ai/install.sh"
	elif command -v wget >/dev/null 2>&1; then
		wget -q -O "${output_file}" "https://claude.ai/install.sh"
	else
		echo "ERROR: curl or wget is required to download Claude Code." >&2
		return 1
	fi
}

# Stage on the destination filesystem so replacing an existing binary is atomic.
claude_install_download() (
	local staging binary_path
	mkdir -p "${CLAUDE_CODE_FEAT_INSTALL_ROOT}" || return $?
	staging="$(mktemp -d "${CLAUDE_CODE_FEAT_INSTALL_ROOT}/.download.XXXXXX")" || return $?
	trap 'rm -rf "${staging}"' EXIT
	trap 'exit 130' INT
	trap 'exit 143' TERM
	claude_bootstrap_download "${staging}/bootstrap.sh" || return $?
	claude_bootstrap_prepare "${staging}/bootstrap.sh" "${staging}/download-only.sh" || return $?
	AISTACK_CLAUDE_CODE_DOWNLOAD_DIR="${staging}/downloads" \
		AISTACK_CLAUDE_CODE_DOWNLOAD_RESULT="${staging}/result" \
		bash "${staging}/download-only.sh" || return $?
	[ -f "${staging}/result" ] || { echo "ERROR: Claude Code bootstrap did not report a binary." >&2; return 1; }
	IFS= read -r binary_path < "${staging}/result" || return $?
	case "${binary_path}" in
		"${staging}/downloads/claude-"*) ;;
		*) echo "ERROR: Unexpected Claude Code download path." >&2; return 1 ;;
	esac
	[ "$(dirname "${binary_path}")" = "${staging}/downloads" ] &&
		[ -f "${binary_path}" ] && [ -x "${binary_path}" ] && [ ! -L "${binary_path}" ] || {
		echo "ERROR: Claude Code bootstrap did not produce an executable file." >&2
		return 1
	}
	[ ! -d "${CLAUDE_CODE_FEAT_INSTALL_ROOT}/claude" ] || return 1
	mv -f "${binary_path}" "${CLAUDE_CODE_FEAT_INSTALL_ROOT}/claude" || return $?
)

claude_install() {
	local r m
	if [ "$#" -ne 0 ]; then
		echo "ERROR: cc install accepts no arguments; the official bootstrap downloads latest." >&2
		return 1
	fi

	for r in ${AISTACK_CLAUDE_CODE_RUNTIME_REQUIRED}; do
		echo "INFO: Claude Code requires ${r} managed runtime"
		aistack_runtime_require "${r}" || return $?
	done
	for m in ${AISTACK_CLAUDE_CODE_MODULE_REQUIRED}; do
		echo "INFO: Claude Code requires ${m} managed module"
		aistack_module_require "${m}" || return $?
	done

	echo "INFO: Downloading latest Claude Code using the official bootstrap (download-only)."
	claude_install_download || return $?
	claude_is_installed
	return $?
}

claude_uninstall() {
	if claude_is_installed; then
		echo "INFO: Uninstalling Claude Code from ${CLAUDE_CODE_FEAT_INSTALL_ROOT}"
		rm -Rf "${CLAUDE_CODE_FEAT_INSTALL_ROOT}" || return $?
		claude_is_installed && return 1
		return 0
	else
		echo "WARN: Claude Code is not installed or requirements are missing."
	fi
}



claude_path_register_for_shell() {
	local shell_name="${1:-current}"
	if claude_is_installed; then
		register_path_named_bloc_for_shell "claude" "${AISTACK_CLAUDE_CODE_LAUNCHER_HOME}" "${shell_name}"
	fi
}
claude_path_unregister_for_shell() {
	local shell_name="${1:-all}"
	unregister_path_named_bloc_for_shell "claude" "${shell_name}"
}
claude_path_register_for_vs_terminal() {
	if claude_is_installed; then
		vscode_path_register_for_vs_terminal "claude" "${AISTACK_CLAUDE_CODE_LAUNCHER_HOME}"
	fi
}
claude_path_unregister_for_vs_terminal() {
	vscode_path_unregister_for_vs_terminal "claude" "${AISTACK_CLAUDE_CODE_LAUNCHER_HOME}"
}


claude_launch() {
	(
		[ -f "${AISTACK_GENERIC_CONTEXT_FILE}" ] && . "${AISTACK_GENERIC_CONTEXT_FILE}"
		[ -f "${AISTACK_CLAUDE_CODE_CONTEXT_FILE}" ] && . "${AISTACK_CLAUDE_CODE_CONTEXT_FILE}"

		if [ "$#" -gt 0 ]; then
			"${CLAUDE_CODE_FEAT_INSTALL_ROOT}/claude" "$@"
		else
			"${CLAUDE_CODE_FEAT_INSTALL_ROOT}/claude"
		fi
	)
}

claude_launcher_and_context_files_manage() {
	local action="${1:-create}"

	case "${action}" in
		create)
			if claude_is_installed; then
				# GENERATE CONTEXT FILE ----
				claude_context_file_generate || return $?

				# GENERATE LAUNCHER FILE ----
				{
					echo '#!/bin/sh'

					printf 'export %s=%s\n' "AISTACK_GENERIC_CONTEXT_FILE" "$(shell_quote_posix "${AISTACK_GENERIC_CONTEXT_FILE}")"
					printf 'export %s=%s\n' "AISTACK_CLAUDE_CODE_CONTEXT_FILE" "$(shell_quote_posix "${AISTACK_CLAUDE_CODE_CONTEXT_FILE}")"

					declare -f claude_launch

					echo claude_launch \"\$@\"
				} > "${AISTACK_CLAUDE_CODE_LAUNCHER_FILE}" || return $?

				chmod +x "${AISTACK_CLAUDE_CODE_LAUNCHER_FILE}"
			fi
			;;

		delete)
			rm -Rf "${AISTACK_CLAUDE_CODE_LAUNCHER_HOME}"
			mkdir -p "${AISTACK_CLAUDE_CODE_LAUNCHER_HOME}"
			claude_context_file_generate_remove
			;;

		refresh_if_exists)
			[ -f "${AISTACK_CLAUDE_CODE_LAUNCHER_FILE}" ] && ( claude_launcher_and_context_files_manage "delete"; claude_launcher_and_context_files_manage "create" )
			;;
	esac
}

claude_context_file_generate() {
	# GENERATE CONTEXT FILE ----
	echo '#!/bin/sh' > "${AISTACK_CLAUDE_CODE_CONTEXT_FILE}" || return $?
	chmod +x "${AISTACK_CLAUDE_CODE_CONTEXT_FILE}" || return $?

	# VARIABLES
	aistack_context_file_export_variables "${AISTACK_CLAUDE_CODE_CONTEXT_FILE}" "${AISTACK_CLAUDE_CODE_CONTEXT_EXPORT_VARIABLES}" || return $?

	# PATH
	local m r list_path
	for r in ${AISTACK_CLAUDE_CODE_RUNTIME_REQUIRED_IN_CONTEXT}; do list_path="$(aistack_component_get_search_path "runtime" "${r}" "VARIABLE_LIST") ${list_path}"; done
	for m in ${AISTACK_CLAUDE_CODE_MODULE_REQUIRED_IN_CONTEXT}; do list_path="$(aistack_component_get_search_path "module" "${m}" "VARIABLE_LIST") ${list_path}"; done
	aistack_context_file_export_path "${AISTACK_CLAUDE_CODE_CONTEXT_FILE}" "${list_path}" "VARIABLE_LIST"
}

claude_context_file_generate_remove() {
	rm -f "${AISTACK_CLAUDE_CODE_CONTEXT_FILE}"
}



claude_info() {
	echo "Claude Code available : ${AISTACK_CLAUDE_CODE_TOOL_AVAILABLE}"
	echo "Claude Code path : ${AISTACK_CLAUDE_CODE_TOOL_PATH}"
	echo "Claude Code needed managed runtime : ${AISTACK_CLAUDE_CODE_RUNTIME_REQUIRED}"
	echo "Claude Code needed managed module : ${AISTACK_CLAUDE_CODE_MODULE_REQUIRED}"
	echo "Claude Code install root : ${CLAUDE_CODE_FEAT_INSTALL_ROOT}"
	echo "Claude Code launcher : ${AISTACK_CLAUDE_CODE_LAUNCHER_FILE}"
	echo "Claude Code context file : ${AISTACK_CLAUDE_CODE_CONTEXT_FILE}"
	echo "Claude Code installation : latest, official bootstrap adapted for download-only"

	echo
}
