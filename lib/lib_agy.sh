agy_init() {
	# antigravity cli specific variables
	export AISTACK_ANTIGRAVITY_CONFIG_HOME="${HOME}/.gemini/antigravity-cli"
	export AISTACK_ANTIGRAVITY_CONFIG_FILE="${AISTACK_ANTIGRAVITY_CONFIG_HOME}/settings.json"
	export AGY_FEAT_INSTALL_ROOT="${AISTACK_ISOLATED_ROOT}/antigravity"
	mkdir -p "${AGY_FEAT_INSTALL_ROOT}"

	# antigravity cli launcher
	export AISTACK_ANTIGRAVITY_LAUNCHER_HOME="${AISTACK_LAUNCHER_HOME}/antigravity"
	mkdir -p "${AISTACK_ANTIGRAVITY_LAUNCHER_HOME}"
	export AISTACK_ANTIGRAVITY_LAUNCHER_FILE="${AISTACK_ANTIGRAVITY_LAUNCHER_HOME}/agy"

	# antigravity cli context
	export AISTACK_ANTIGRAVITY_CONTEXT_HOME="${AISTACK_CONTEXT_HOME}/antigravity"
	mkdir -p "${AISTACK_ANTIGRAVITY_CONTEXT_HOME}"
	export AISTACK_ANTIGRAVITY_CONTEXT_FILE="${AISTACK_ANTIGRAVITY_CONTEXT_HOME}/antigravity_context.sh"
	# any variables needed to run this component or used by _launch function
	# NOTE: do not need to declare those variables:
	#		AISTACK_*_CONTEXT_FILE and AISTACK_GENERIC_CONTEXT_FILE are already exported
	#		every *_SEARCH_PATH variable related to a REQUIRED_RUNTIME or REQUIRED_MODULE are already exported
	export AISTACK_ANTIGRAVITY_CONTEXT_EXPORT_VARIABLES="AGY_FEAT_INSTALL_ROOT"

	# antigravity cli requirement - those will be installed and presence checked to run the current component
	# NOTE:	those search path will be injected in context file
	export AISTACK_ANTIGRAVITY_RUNTIME_REQUIRED=""
	export AISTACK_ANTIGRAVITY_MODULE_REQUIRED=""
	# remove from context any runtime or module any item already in generic aistack context
	export AISTACK_ANTIGRAVITY_RUNTIME_REQUIRED_IN_CONTEXT="$($STELLA_API filter_list_with_list "${AISTACK_ANTIGRAVITY_RUNTIME_REQUIRED}" "${AISTACK_GENERIC_CONTEXT_ADD_RUNTIME}")"
	export AISTACK_ANTIGRAVITY_MODULE_REQUIRED_IN_CONTEXT="$($STELLA_API filter_list_with_list "${AISTACK_ANTIGRAVITY_MODULE_REQUIRED}" "${AISTACK_GENERIC_CONTEXT_ADD_MODULE}")"

}

# test if antigravity cli is installed
# return 0 : is installed
# return 1 : tool is not installed
# return 2 : missing runtime
agy_is_installed() {
	local r m
	export AISTACK_ANTIGRAVITY_TOOL_AVAILABLE="false"
	export AISTACK_ANTIGRAVITY_TOOL_PATH=""
	for r in ${AISTACK_ANTIGRAVITY_RUNTIME_REQUIRED}; do aistack_runtime_is_detected "${r}" || return 2; done
	for m in ${AISTACK_ANTIGRAVITY_MODULE_REQUIRED}; do aistack_module_is_detected "${m}" || return 2; done
	[ -x "${AGY_FEAT_INSTALL_ROOT}/agy" ] || return 1
	export AISTACK_ANTIGRAVITY_TOOL_AVAILABLE="true"
	export AISTACK_ANTIGRAVITY_TOOL_PATH="${AGY_FEAT_INSTALL_ROOT}/agy"
	return 0
}



# https://antigravity.google/download
agy_install() {
	local r m

	for r in ${AISTACK_ANTIGRAVITY_RUNTIME_REQUIRED}; do
		echo "INFO: Antigravity CLI require ${r} managed runtime"
		aistack_runtime_require "${r}"
	done

	for m in ${AISTACK_ANTIGRAVITY_MODULE_REQUIRED}; do
		echo "INFO: Antigravity CLI require ${m} managed module"
		aistack_module_require "${m}"
	done

	if [ -n "${AISTACK_INIT_FORCE_AGY_GBC}" ]; then
		echo "WARN: at install you may have an error about GLIBC, ignore it. antigravity will be patched after installation"
	fi

	rm -Rf "${AGY_FEAT_INSTALL_ROOT}" || return $?
	mkdir -p "${AGY_FEAT_INSTALL_ROOT}" || return $?

	# use a temporary HOME to avoid rc file modification in HOME
	local tmp_home="$(mktemp -d)"
	local install_script="${tmp_home}/install.sh"
	curl -fsSL https://antigravity.google/cli/install.sh -o "${install_script}" || {
		rm -rf "${tmp_home}"
		return 1
	}
	HOME="${tmp_home}" bash "${install_script}" --dir "${AGY_FEAT_INSTALL_ROOT}" || {
		rm -rf "${tmp_home}"
		return 1
	}
	rm -rf "${tmp_home}"

	if [ -f "${AGY_FEAT_INSTALL_ROOT}/agy" ]; then
		if [ -n "${AISTACK_INIT_FORCE_AGY_GBC}" ]; then
			glibc_binary_compat "agy" "${AGY_FEAT_INSTALL_ROOT}" "${AISTACK_INIT_FORCE_AGY_GBC}" || return $?
			"${AGY_FEAT_INSTALL_ROOT}/agy" install --dir "${AGY_FEAT_INSTALL_ROOT}" || return $?
		fi
	fi

	agy_is_installed
	return $?
}



agy_uninstall() {
	if agy_is_installed; then
		echo "Uninstalling Antigravity CLI from ${AGY_FEAT_INSTALL_ROOT}..."
		rm -Rf "${AGY_FEAT_INSTALL_ROOT}" || return $?
		echo "Antigravity CLI uninstalled successfully."

		agy_is_installed && return 1
		return 0
	else
		echo "WARN : not installed or missing a required managed runtime $AISTACK_ANTIGRAVITY_RUNTIME_REQUIRED"
	fi
}

agy_path_register_for_shell() {
	local shell_name="$1"
	if agy_is_installed; then
		path_register_for_shell "antigravity" "${AISTACK_ANTIGRAVITY_LAUNCHER_HOME}" "$shell_name"
	fi
}

agy_path_unregister_for_shell() {
	local shell_name="${1:-all}"
	path_unregister_for_shell "antigravity" "$shell_name"
}

agy_path_register_for_vs_terminal() {
	if agy_is_installed; then
		vscode_path_register_for_vs_terminal "antigravity" "${AISTACK_ANTIGRAVITY_LAUNCHER_HOME}"
	fi
}

agy_path_unregister_for_vs_terminal() {
	vscode_path_unregister_for_vs_terminal "antigravity" "${AISTACK_ANTIGRAVITY_LAUNCHER_HOME}"
}

agy_launch() {
	(
		[ -f "${AISTACK_GENERIC_CONTEXT_FILE}" ] && . "${AISTACK_GENERIC_CONTEXT_FILE}"
		[ -f "${AISTACK_ANTIGRAVITY_CONTEXT_FILE}" ] && . "${AISTACK_ANTIGRAVITY_CONTEXT_FILE}"

		if [ "$#" -gt 0 ]; then
			"${AGY_FEAT_INSTALL_ROOT}/agy" "$@"
		else
			"${AGY_FEAT_INSTALL_ROOT}/agy"
		fi
	)
}

agy_launcher_manage() {
	local action="${1:-create}"

	case $action in
		create)
			if agy_is_installed; then
				# GENERATE CONTEXT FILE ----
				agy_context_file_generate

				# GENERATE LAUNCHER FILE ----
				{
					echo '#!/bin/sh'

					printf 'export %s=%s\n' "AISTACK_GENERIC_CONTEXT_FILE" "$(shell_quote_posix "${AISTACK_GENERIC_CONTEXT_FILE}")"
					printf 'export %s=%s\n' "AISTACK_ANTIGRAVITY_CONTEXT_FILE" "$(shell_quote_posix "${AISTACK_ANTIGRAVITY_CONTEXT_FILE}")"

					declare -f agy_launch

					echo agy_launch \"\$@\"
				} > "${AISTACK_ANTIGRAVITY_LAUNCHER_FILE}"

				chmod +x "${AISTACK_ANTIGRAVITY_LAUNCHER_FILE}"
			fi
			;;

		delete)
			rm -Rf "${AISTACK_ANTIGRAVITY_LAUNCHER_HOME}"
			mkdir -p "${AISTACK_ANTIGRAVITY_LAUNCHER_HOME}"
			agy_context_file_generate_remove
			;;

		refresh_if_exists)
			[ -f "${AISTACK_ANTIGRAVITY_LAUNCHER_FILE}" ] && ( agy_launcher_manage "delete"; agy_launcher_manage "create" )
			;;
	esac
}

agy_context_file_generate() {
	# GENERATE CONTEXT FILE ----
	echo '#!/bin/sh' > "${AISTACK_ANTIGRAVITY_CONTEXT_FILE}"
	chmod +x "${AISTACK_ANTIGRAVITY_CONTEXT_FILE}"

	# VARIABLES
	aistack_context_file_export_variables "${AISTACK_ANTIGRAVITY_CONTEXT_FILE}" "${AISTACK_ANTIGRAVITY_CONTEXT_EXPORT_VARIABLES}"

	# PATH
	local m r list_path
	for r in ${AISTACK_ANTIGRAVITY_RUNTIME_REQUIRED_IN_CONTEXT}; do list_path="$(aistack_context_path_add_component "runtime" "${r}" "VARIABLE_LIST") ${list_path}"; done
	for m in ${AISTACK_ANTIGRAVITY_MODULE_REQUIRED_IN_CONTEXT}; do list_path="$(aistack_context_path_add_component "module" "${m}" "VARIABLE_LIST") ${list_path}"; done
	aistack_context_file_export_path "${AISTACK_ANTIGRAVITY_CONTEXT_FILE}" "${list_path}" "VARIABLE_LIST"
}

agy_context_file_generate_remove() {
	rm -f "${AISTACK_ANTIGRAVITY_CONTEXT_FILE}"
}

agy_info() {
	echo "Configuration file : $AISTACK_ANTIGRAVITY_CONFIG_FILE"
	echo
	echo "Antigravity CLI available : $AISTACK_ANTIGRAVITY_TOOL_AVAILABLE"
	echo "Antigravity CLI path : $AISTACK_ANTIGRAVITY_TOOL_PATH"
	echo "Antigravity CLI needed managed runtime : $AISTACK_ANTIGRAVITY_RUNTIME_REQUIRED"
	echo "Antigravity CLI needed managed module : $AISTACK_ANTIGRAVITY_MODULE_REQUIRED"
	echo "Antigravity CLI install root : $AGY_FEAT_INSTALL_ROOT"
	echo "Antigravity CLI launcher : $AISTACK_ANTIGRAVITY_LAUNCHER_FILE"
	echo "Antigravity CLI context file : $AISTACK_ANTIGRAVITY_CONTEXT_FILE"
}



agy_show_config() {
    if [ -f "$AISTACK_ANTIGRAVITY_CONFIG_FILE" ]; then
        cat "$AISTACK_ANTIGRAVITY_CONFIG_FILE"
    else
        echo "No configuration file found. ($AISTACK_ANTIGRAVITY_CONFIG_FILE)"
    fi
}

# generic config management -----------------
agy_settings_configure() {
	echo "add some default settings :"
    echo " - disable statistics usage data send"
    cat "${AISTACK_POOL}/settings/antigravity-cli/settings.json"
    printf "\n"
    merge_json_file "${AISTACK_POOL}/settings/antigravity-cli/settings.json" "${AISTACK_ANTIGRAVITY_CONFIG_FILE}"
}

agy_settings_remove() {
	rm -Rf "$AISTACK_ANTIGRAVITY_CONFIG_HOME"
}


agy_merge_config() {
    local file_to_merge="$1"
    merge_json_file "$file_to_merge" "$AISTACK_ANTIGRAVITY_CONFIG_FILE"
}

agy_remove_config() {
    local key_path="$1"
    json_del_key_from_file "$AISTACK_ANTIGRAVITY_CONFIG_FILE" "$key_path"
}

agy_set_config() {
    local key_path="$1"
    local value="$2"
    json_set_key_into_file "$AISTACK_ANTIGRAVITY_CONFIG_FILE" "$key_path" "$value"
}
