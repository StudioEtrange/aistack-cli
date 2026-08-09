playwright_init() {
	# playwright cli launcher
	export AISTACK_PLAYWRIGHT_LAUNCHER_HOME="${AISTACK_LAUNCHER_HOME}/playwright-cli"
	mkdir -p "${AISTACK_PLAYWRIGHT_LAUNCHER_HOME}"
	export AISTACK_PLAYWRIGHT_LAUNCHER_FILE="${AISTACK_PLAYWRIGHT_LAUNCHER_HOME}/playwright-cli"

	# playwright cli context
	export AISTACK_PLAYWRIGHT_CONTEXT_HOME="${AISTACK_CONTEXT_HOME}/playwright-cli"
	mkdir -p "${AISTACK_PLAYWRIGHT_CONTEXT_HOME}"
	export AISTACK_PLAYWRIGHT_CONTEXT_FILE="${AISTACK_PLAYWRIGHT_CONTEXT_HOME}/playwright_context.sh"
	# any variables needed to run this component or used by _launch function
	# NOTE: do not need to declare those variables:
	#		AISTACK_*_CONTEXT_FILE and AISTACK_GENERIC_CONTEXT_FILE are already exported
	#		every *_SEARCH_PATH variable related to a REQUIRED_RUNTIME or REQUIRED_MODULE are already exported
	export AISTACK_PLAYWRIGHT_CONTEXT_EXPORT_VARIABLES=""

	# playwright cli requirement - those will be installed and presence checked to run the current component
	# NOTE:	those search path will be injected in context file
	export AISTACK_PLAYWRIGHT_RUNTIME_REQUIRED="nodejs"
	export AISTACK_PLAYWRIGHT_MODULE_REQUIRED=""
	# remove from context any runtime or module any item already in generic aistack context
	export AISTACK_PLAYWRIGHT_RUNTIME_REQUIRED_IN_CONTEXT="$($STELLA_API filter_list_with_list "${AISTACK_PLAYWRIGHT_RUNTIME_REQUIRED}" "${AISTACK_GENERIC_CONTEXT_ADD_RUNTIME}")"
	export AISTACK_PLAYWRIGHT_MODULE_REQUIRED_IN_CONTEXT="$($STELLA_API filter_list_with_list "${AISTACK_PLAYWRIGHT_MODULE_REQUIRED}" "${AISTACK_GENERIC_CONTEXT_ADD_MODULE}")"
}

# test if playwright cli is installed
# return 0 : is installed
# return 1 : tool is not installed
# return 2 : missing runtime
playwright_is_installed() {
	local r m
	export AISTACK_PLAYWRIGHT_TOOL_AVAILABLE="false"
	export AISTACK_PLAYWRIGHT_TOOL_PATH=""
	for r in ${AISTACK_PLAYWRIGHT_RUNTIME_REQUIRED}; do aistack_runtime_is_detected "${r}" || return 2; done
	for m in ${AISTACK_PLAYWRIGHT_MODULE_REQUIRED}; do aistack_module_is_detected "${m}" || return 2; done

	[ -x "${AISTACK_RUNTIME_NODEJS_SEARCH_PATH}/playwright-cli" ] || return 1
	export AISTACK_PLAYWRIGHT_TOOL_PATH="${AISTACK_RUNTIME_NODEJS_SEARCH_PATH}/playwright-cli"
	export AISTACK_PLAYWRIGHT_TOOL_AVAILABLE="true"
	return 0
}

playwright_install() {
	local r m
	local version="$1"
	[ -z "${version}" ] && version="@latest"

	for r in ${AISTACK_PLAYWRIGHT_RUNTIME_REQUIRED}; do
		echo "INFO: playwright-cli require ${r} managed runtime"
		aistack_runtime_require "${r}"
	done

	for m in ${AISTACK_PLAYWRIGHT_MODULE_REQUIRED}; do
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
		node_package_uninstall "@playwright/cli" || return $?
		playwright_is_installed && return 1
		return 0
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

playwright_launch() {
	(
		[ -f "${AISTACK_GENERIC_CONTEXT_FILE}" ] && . "${AISTACK_GENERIC_CONTEXT_FILE}"
		[ -f "${AISTACK_PLAYWRIGHT_CONTEXT_FILE}" ] && . "${AISTACK_PLAYWRIGHT_CONTEXT_FILE}"
		
		if [ "$#" -gt 0 ]; then
			"${AISTACK_RUNTIME_NODEJS_SEARCH_PATH}/playwright-cli" "$@"
		else
			"${AISTACK_RUNTIME_NODEJS_SEARCH_PATH}/playwright-cli"
		fi
	)
}

playwright_launcher_manage() {
	local action="${1:-create}"

	case "${action}" in
		create)
			if playwright_is_installed; then
				# GENERATE CONTEXT FILE ----
				playwright_context_file_generate

				# GENERATE LAUNCHER FILE ----
				{
					echo '#!/bin/sh'

					printf 'export %s=%s\n' "AISTACK_GENERIC_CONTEXT_FILE" "$(shell_quote_posix "${AISTACK_GENERIC_CONTEXT_FILE}")"
					printf 'export %s=%s\n' "AISTACK_PLAYWRIGHT_CONTEXT_FILE" "$(shell_quote_posix "${AISTACK_PLAYWRIGHT_CONTEXT_FILE}")"

					declare -f playwright_launch

					echo playwright_launch \"\$@\"
				} > "${AISTACK_PLAYWRIGHT_LAUNCHER_FILE}"

				chmod +x "${AISTACK_PLAYWRIGHT_LAUNCHER_FILE}"
			fi
			;;
		delete)
			rm -Rf "${AISTACK_PLAYWRIGHT_LAUNCHER_HOME}"
			mkdir -p "${AISTACK_PLAYWRIGHT_LAUNCHER_HOME}"
			playwright_context_file_generate_remove
			;;
		refresh_if_exists)
			if [ -f "${AISTACK_PLAYWRIGHT_LAUNCHER_FILE}" ]; then
				playwright_launcher_manage "delete"
				playwright_launcher_manage "create"
			fi
			;;
	esac
}

playwright_context_file_generate() {
	# GENERATE CONTEXT FILE ----
	echo '#!/bin/sh' > "${AISTACK_PLAYWRIGHT_CONTEXT_FILE}"
	chmod +x "${AISTACK_PLAYWRIGHT_CONTEXT_FILE}"

	# VARIABLES
	aistack_context_file_export_variables "${AISTACK_PLAYWRIGHT_CONTEXT_FILE}" "${AISTACK_PLAYWRIGHT_CONTEXT_EXPORT_VARIABLES}"

	# PATH
	local m r list_path
	for r in ${AISTACK_PLAYWRIGHT_RUNTIME_REQUIRED_IN_CONTEXT}; do list_path="$(aistack_context_path_add_component "runtime" "${r}" "VARIABLE_LIST") ${list_path}"; done
	for m in ${AISTACK_PLAYWRIGHT_MODULE_REQUIRED_IN_CONTEXT}; do list_path="$(aistack_context_path_add_component "module" "${m}" "VARIABLE_LIST") ${list_path}"; done
	aistack_context_file_export_path "${AISTACK_PLAYWRIGHT_CONTEXT_FILE}" "${list_path}" "VARIABLE_LIST"
}

playwright_context_file_generate_remove() {
	rm -f "${AISTACK_PLAYWRIGHT_CONTEXT_FILE}"
}

playwright_info() {
	echo "PLAYWRIGHT CLI available : ${AISTACK_PLAYWRIGHT_TOOL_AVAILABLE}"
	echo "PLAYWRIGHT CLI path : ${AISTACK_PLAYWRIGHT_TOOL_PATH}"
	echo "PLAYWRIGHT CLI needed managed runtime : ${AISTACK_PLAYWRIGHT_RUNTIME_REQUIRED}"
	echo "PLAYWRIGHT CLI needed managed module : ${AISTACK_PLAYWRIGHT_MODULE_REQUIRED}"
	echo "PLAYWRIGHT CLI launcher : ${AISTACK_PLAYWRIGHT_LAUNCHER_FILE}"
	echo "PLAYWRIGHT CLI context file : ${AISTACK_PLAYWRIGHT_CONTEXT_FILE}"
}

