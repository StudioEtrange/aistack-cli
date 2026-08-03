playwright_init() {
	export AISTACK_PLAYWRIGHT_LAUNCHER_HOME="${AISTACK_LAUNCHER_HOME}/playwright-cli"
	mkdir -p "${AISTACK_PLAYWRIGHT_LAUNCHER_HOME}"

	export AISTACK_PLAYWRIGHT_RUNTIME_REQUIRED="nodejs"
	export AISTACK_PLAYWRIGHT_MODULE_REQUIRED=""
}

# return 0 : is installed
# return 1 : tool is not installed
# return 2 : missing runtime
playwright_is_installed() {
	local r m
	export AISTACK_PLAYWRIGHT_TOOL_AVAILABLE="false"
	for r in ${AISTACK_PLAYWRIGHT_RUNTIME_REQUIRED}; do aistack_runtime_is_detected "${r}" || return 2; done
	for m in ${AISTACK_PLAYWRIGHT_MODULE_REQUIRED}; do aistack_module_is_detected "${m}" || return 2; done

	[ -x "${AISTACK_RUNTIME_NODEJS_SEARCH_PATH}/playwright-cli" ] || return 1
	export AISTACK_PLAYWRIGHT_TOOL_PATH="${AISTACK_RUNTIME_NODEJS_SEARCH_PATH}/playwright-cli"
	export AISTACK_PLAYWRIGHT_TOOL_AVAILABLE="true"
	return 0
}

playwright_install() {
	local r
	local version="$1"
	[ -z "${version}" ] && version="@latest"

	for r in ${AISTACK_PLAYWRIGHT_RUNTIME_REQUIRED}; do
		echo "INFO: playwright-cli require ${r} managed runtime"
		aistack_runtime_require "${r}"
	done

	for m in $AISTACK_PLAYWRIGHT_MODULE_REQUIRED; do 
		echo "INFO: playwright-cli require ${m} managed module"
		aistack_module_require "${m}"
	done

	echo "Installing Playwright CLI ${version}"
	node_package_install "@playwright/cli${version}" || return $?
	playwright_is_installed
	return $?
}

playwright_uninstall() {
	if playwright_is_installed; then
		node_package_uninstall "@playwright/cli"
	else
		echo "WARN: not installed or missing a required managed runtime ${AISTACK_PLAYWRIGHT_RUNTIME_REQUIRED}"
	fi
}

playwright_path_register_for_shell() {
	local shell_name="$1"
	if playwright_is_installed; then
		path_register_for_shell "playwright-cli" "${AISTACK_PLAYWRIGHT_LAUNCHER_HOME}" "${shell_name}"
	fi
}

playwright_path_unregister_for_shell() {
	local shell_name="${1:-all}"
	path_unregister_for_shell "playwright-cli" "${shell_name}"
}

playwright_path_register_for_vs_terminal() {
	if playwright_is_installed; then
		vscode_path_register_for_vs_terminal "playwright-cli" "${AISTACK_PLAYWRIGHT_LAUNCHER_HOME}"
	fi
}

playwright_path_unregister_for_vs_terminal() {
	vscode_path_unregister_for_vs_terminal "playwright-cli" "${AISTACK_PLAYWRIGHT_LAUNCHER_HOME}"
}

playwright_launch_export_variables="AISTACK_TOOL_CONTEXT_FILE AISTACK_RUNTIME_NODEJS_SEARCH_PATH"
playwright_launch() {
	(
		. "${AISTACK_TOOL_CONTEXT_FILE}"
		"${AISTACK_RUNTIME_NODEJS_SEARCH_PATH}/playwright-cli" "$@"
	)
}

playwright_launcher_manage() {
	local action="${1:-create}"

	case "${action}" in
		create)
			if playwright_is_installed; then
				{
					echo '#!/bin/sh'
					for v in ${playwright_launch_export_variables}; do
						printf '[ -n "$%s" ] && export %s="$%s" || export %s=%s\n' "${v}" "${v}" "${v}" "${v}" "$(shell_quote_posix "${!v}")"
					done

					declare -f playwright_launch

					echo playwright_launch \"\$@\"
				} > "${AISTACK_PLAYWRIGHT_LAUNCHER_HOME}/playwright-cli"

				chmod +x "${AISTACK_PLAYWRIGHT_LAUNCHER_HOME}/playwright-cli"
			fi
			;;
		delete)
			rm -f "${AISTACK_PLAYWRIGHT_LAUNCHER_HOME}/playwright-cli"
			;;
		refresh_if_exists)
			if [ -f "${AISTACK_PLAYWRIGHT_LAUNCHER_HOME}/playwright-cli" ]; then
				playwright_launcher_manage "delete"
				playwright_launcher_manage "create"
			fi
			;;
	esac
}

playwright_info() {
	echo "PLAYWRIGHT CLI available : ${AISTACK_PLAYWRIGHT_TOOL_AVAILABLE}"
	echo "PLAYWRIGHT CLI path : ${AISTACK_PLAYWRIGHT_TOOL_PATH}"
	echo "PLAYWRIGHT CLI needed managed runtime : ${AISTACK_PLAYWRIGHT_RUNTIME_REQUIRED}"
}


