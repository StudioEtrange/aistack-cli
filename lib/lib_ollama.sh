ollama_init() {
	export OLLAMA_FEAT_INSTALL_ROOT="${AISTACK_ISOLATED_ROOT}/ollama"
	export AISTACK_OLLAMA_DATA_HOME="${STELLA_APP_WORK_ROOT}/ollama"
	export AISTACK_OLLAMA_MODELS_HOME="${AISTACK_OLLAMA_DATA_HOME}/models"
	export AISTACK_OLLAMA_LAUNCHER_HOME="${AISTACK_LAUNCHER_HOME}/ollama"
	export AISTACK_OLLAMA_LAUNCHER_FILE="${AISTACK_OLLAMA_LAUNCHER_HOME}/ollama"
	export AISTACK_OLLAMA_CONTEXT_HOME="${AISTACK_CONTEXT_HOME}/ollama"
	export AISTACK_OLLAMA_CONTEXT_FILE="${AISTACK_OLLAMA_CONTEXT_HOME}/ollama_context.sh"
	export AISTACK_OLLAMA_CONTEXT_EXPORT_VARIABLES="OLLAMA_FEAT_INSTALL_ROOT AISTACK_OLLAMA_DATA_HOME AISTACK_OLLAMA_MODELS_HOME"
	export AISTACK_OLLAMA_RUNTIME_REQUIRED=""
	export AISTACK_OLLAMA_MODULE_REQUIRED=""
	mkdir -p "${AISTACK_OLLAMA_DATA_HOME}" "${AISTACK_OLLAMA_MODELS_HOME}" "${AISTACK_OLLAMA_LAUNCHER_HOME}" "${AISTACK_OLLAMA_CONTEXT_HOME}"
}

ollama_is_installed() {
	export AISTACK_OLLAMA_TOOL_AVAILABLE="false"
	export AISTACK_OLLAMA_TOOL_PATH=""
	[ -x "${OLLAMA_FEAT_INSTALL_ROOT}/bin/ollama" ] || return 1
	export AISTACK_OLLAMA_TOOL_AVAILABLE="true"
	export AISTACK_OLLAMA_TOOL_PATH="${OLLAMA_FEAT_INSTALL_ROOT}/bin/ollama"
	return 0
}

# Extract official CLI archives into a staging directory before replacing binaries.
# Model data is deliberately stored outside the installation directory.
ollama_install() {
	local version="${1:-latest}"
	local asset arch staging archive status
	case "${STELLA_CURRENT_CPU_FAMILY}" in
		intel) arch="amd64" ;;
		arm) arch="arm64" ;;
		*) echo "ERROR: Unsupported CPU family: ${STELLA_CURRENT_CPU_FAMILY}"; return 1 ;;
	esac
	case "${STELLA_CURRENT_PLATFORM}" in
		darwin) asset="ollama-darwin.tgz" ;;
		linux)
			asset="ollama-linux-${arch}.tar.zst"
			command -v zstd >/dev/null 2>&1 || { echo "ERROR: zstd is required to extract Ollama Linux archives"; return 1; }
			;;
		*) echo "ERROR: Unsupported platform: ${STELLA_CURRENT_PLATFORM}"; return 1 ;;
	esac
	command -v curl >/dev/null 2>&1 || { echo "ERROR: curl is required to download Ollama"; return 1; }
	command -v tar >/dev/null 2>&1 || { echo "ERROR: tar is required to extract Ollama"; return 1; }
	if [ "${version}" = "latest" ]; then
		version="$(github_get_latest_release "ollama/ollama")" || return $?
	fi
	case "${version}" in
		v[0-9]*) ;;
		[0-9]*) version="v${version}" ;;
		*) echo "ERROR: Invalid Ollama version: ${version}"; return 1 ;;
	esac
	case "${version}" in
		*[!a-zA-Z0-9.+-]*) echo "ERROR: Invalid Ollama version: ${version}"; return 1 ;;
	esac
	mkdir -p "${AISTACK_ISOLATED_ROOT}" || return $?
	staging="$(mktemp -d "${AISTACK_ISOLATED_ROOT}/ollama.install.XXXXXX")" || return $?
	archive="${staging}/${asset}"
	mkdir -p "${staging}/unpacked" || { rmdir "${staging}"; return 1; }
	echo "INFO: Installing Ollama ${version} (${asset})"
	curl -fL --retry 3 -o "${archive}" "https://github.com/ollama/ollama/releases/download/${version}/${asset}"
	status=$?
	if [ "${status}" -eq 0 ]; then
		if [ "${STELLA_CURRENT_PLATFORM}" = "linux" ]; then
			# Avoid a pipeline: a decompression failure must not be hidden by tar.
			zstd -d -q "${archive}" -o "${staging}/ollama.tar" && tar -xf "${staging}/ollama.tar" -C "${staging}/unpacked"
			status=$?
		else
			tar -xzf "${archive}" -C "${staging}/unpacked"
			status=$?
			if [ "${status}" -eq 0 ]; then
				# The macOS CLI archive contains ollama and its companion libraries.
				mkdir -p "${staging}/unpacked/bin" && ln -s ../ollama "${staging}/unpacked/bin/ollama"
				status=$?
			fi
		fi
	fi
	if [ "${status}" -eq 0 ] && [ -x "${staging}/unpacked/bin/ollama" ]; then
		# Keep the macOS executable and its companion libraries together.
		if [ "${status}" -eq 0 ]; then
			rm -rf "${OLLAMA_FEAT_INSTALL_ROOT}" && mv "${staging}/unpacked" "${OLLAMA_FEAT_INSTALL_ROOT}"
			status=$?
		fi
	else
		echo "ERROR: Failed to download or extract the Ollama executable"
		[ "${status}" -ne 0 ] || status=1
	fi
	rm -rf "${staging}"
	[ "${status}" -eq 0 ] || return "${status}"
	ollama_is_installed
}

ollama_uninstall() {
	rm -rf "${OLLAMA_FEAT_INSTALL_ROOT}"
}

ollama_launch() {
	(
		[ -f "${AISTACK_GENERIC_CONTEXT_FILE}" ] && . "${AISTACK_GENERIC_CONTEXT_FILE}"
		[ -f "${AISTACK_OLLAMA_CONTEXT_FILE}" ] && . "${AISTACK_OLLAMA_CONTEXT_FILE}"
		if [ ! -x "${OLLAMA_FEAT_INSTALL_ROOT}/bin/ollama" ]; then
			echo "ERROR: Ollama is not installed; use aistack ollama install" >&2
			return 1
		fi
		# HOME isolates Ollama's keys/history, OLLAMA_MODELS isolates large downloads.
		export HOME="${AISTACK_OLLAMA_DATA_HOME}"
		export OLLAMA_MODELS="${AISTACK_OLLAMA_MODELS_HOME}"
		export OLLAMA_HOST="${OLLAMA_HOST:-127.0.0.1:11434}"
		"${OLLAMA_FEAT_INSTALL_ROOT}/bin/ollama" "$@"
	)
}

ollama_context_file_generate() {
	printf '%s\n' '#!/bin/sh' > "${AISTACK_OLLAMA_CONTEXT_FILE}" || return $?
	aistack_context_file_export_variables "${AISTACK_OLLAMA_CONTEXT_FILE}" "${AISTACK_OLLAMA_CONTEXT_EXPORT_VARIABLES}"
}

ollama_context_file_generate_remove() {
	rm -f "${AISTACK_OLLAMA_CONTEXT_FILE}"
}

ollama_launcher_and_context_files_manage() {
	local action="${1:-create}"
	case "${action}" in
		create)
			ollama_is_installed || return 1
			ollama_context_file_generate || return $?
			{
				echo '#!/bin/sh'
				printf 'export %s=%s\n' "AISTACK_GENERIC_CONTEXT_FILE" "$(shell_quote_posix "${AISTACK_GENERIC_CONTEXT_FILE}")"
				printf 'export %s=%s\n' "AISTACK_OLLAMA_CONTEXT_FILE" "$(shell_quote_posix "${AISTACK_OLLAMA_CONTEXT_FILE}")"
				declare -f ollama_launch
				echo 'ollama_launch "$@"'
			} > "${AISTACK_OLLAMA_LAUNCHER_FILE}" || return $?
			chmod +x "${AISTACK_OLLAMA_LAUNCHER_FILE}"
			;;
		delete)
			rm -f "${AISTACK_OLLAMA_LAUNCHER_FILE}"
			ollama_context_file_generate_remove
			;;
		refresh_if_exists)
			[ ! -f "${AISTACK_OLLAMA_LAUNCHER_FILE}" ] || ollama_launcher_and_context_files_manage create
			;;
		*) echo "ERROR: Unknown Ollama launcher action: ${action}"; return 1 ;;
	esac
}

ollama_path_register_for_shell() {
	ollama_is_installed || { echo "ERROR: Ollama is not installed"; return 1; }
	register_path_named_bloc_for_shell "ollama" "${AISTACK_OLLAMA_LAUNCHER_HOME}" "${1:-current}"
}

ollama_path_unregister_for_shell() {
	unregister_path_named_bloc_for_shell "ollama" "${1:-all}"
}

ollama_path_register_for_vs_terminal() {
	ollama_is_installed || { echo "ERROR: Ollama is not installed"; return 1; }
	vscode_path_register_for_vs_terminal "ollama" "${AISTACK_OLLAMA_LAUNCHER_HOME}"
}

ollama_path_unregister_for_vs_terminal() {
	vscode_path_unregister_for_vs_terminal "ollama" "${AISTACK_OLLAMA_LAUNCHER_HOME}"
}

ollama_info() {
	ollama_is_installed
	echo "Ollama available: ${AISTACK_OLLAMA_TOOL_AVAILABLE}"
	echo "Ollama path: ${AISTACK_OLLAMA_TOOL_PATH}"
	echo "Ollama launcher: ${AISTACK_OLLAMA_LAUNCHER_FILE}"
	echo "Ollama data: ${AISTACK_OLLAMA_DATA_HOME}"
	echo "Ollama models: ${AISTACK_OLLAMA_MODELS_HOME}"
	echo "Ollama endpoint: ${OLLAMA_HOST:-127.0.0.1:11434}"
}
