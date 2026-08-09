adk_init() {
	# adk specific variables

	# adk launcher
	export AISTACK_ADK_LAUNCHER_HOME="${AISTACK_LAUNCHER_HOME}/adk"
	mkdir -p "${AISTACK_ADK_LAUNCHER_HOME}"
	export AISTACK_ADK_LAUNCHER_FILE="${AISTACK_ADK_LAUNCHER_HOME}/adk"

	# adk context
	export AISTACK_ADK_CONTEXT_HOME="${AISTACK_CONTEXT_HOME}/adk"
	mkdir -p "${AISTACK_ADK_CONTEXT_HOME}"
	export AISTACK_ADK_CONTEXT_FILE="${AISTACK_ADK_CONTEXT_HOME}/adk_context.sh"
	# any variables needed to run this component or used by _launch function
	# NOTE: do not need to declare those variables:
	#		AISTACK_*_CONTEXT_FILE and AISTACK_GENERIC_CONTEXT_FILE are already exported
	#		every *_SEARCH_PATH variable related to a REQUIRED_RUNTIME or REQUIRED_MODULE are already exported
	export AISTACK_ADK_CONTEXT_EXPORT_VARIABLES=""

	# adk requirement - those will be installed and presence checked to run the current component
	# NOTE:	those search path will be injected in context file
	export AISTACK_ADK_RUNTIME_REQUIRED="python"
	export AISTACK_ADK_MODULE_REQUIRED=""
	# remove from context any runtime or module any item already in generic aistack context
	export AISTACK_ADK_RUNTIME_REQUIRED_IN_CONTEXT="$($STELLA_API filter_list_with_list "${AISTACK_ADK_RUNTIME_REQUIRED}" "${AISTACK_GENERIC_CONTEXT_ADD_RUNTIME}")"
	export AISTACK_ADK_MODULE_REQUIRED_IN_CONTEXT="$($STELLA_API filter_list_with_list "${AISTACK_ADK_MODULE_REQUIRED}" "${AISTACK_GENERIC_CONTEXT_ADD_MODULE}")"

}

# test if adk is installed
# return 0 : is installed
# return 1 : tool is not installed
# return 2 : missing runtime
adk_is_installed() {
	local r m
	export AISTACK_ADK_TOOL_AVAILABLE="false"
	export AISTACK_ADK_TOOL_PATH=""
	for r in ${AISTACK_ADK_RUNTIME_REQUIRED}; do aistack_runtime_is_detected "${r}" || return 2; done
	for m in ${AISTACK_ADK_MODULE_REQUIRED}; do aistack_module_is_detected "${m}" || return 2; done
	[ -x "${AISTACK_RUNTIME_PYTHON_SEARCH_PATH}/adk" ] || return 1
	export AISTACK_ADK_TOOL_PATH="${AISTACK_RUNTIME_PYTHON_SEARCH_PATH}/adk"
	export AISTACK_ADK_TOOL_AVAILABLE="true"
	return 0
}

adk_install() {
	local r m

	for r in ${AISTACK_ADK_RUNTIME_REQUIRED}; do
		echo "INFO: adk require ${r} managed runtime"
		aistack_runtime_require "${r}"
	done

	for m in ${AISTACK_ADK_MODULE_REQUIRED}; do
		echo "INFO: adk require ${m} managed module"
		aistack_module_require "${m}"
	done

	echo "Installing adk for python"
	python_uv_package_install "google-adk" || return $?
	#PATH="${AISTACK_RUNTIME_PYTHON_SEARCH_PATH}:${STELLA_ORIGINAL_SYSTEM_PATH}" uv pip install --system --reinstall --verbose google-adk
	adk_is_installed
	return $?
}

adk_uninstall() {
	if adk_is_installed; then
		python_uv_package_uninstall "google-adk" || return $?
		#PATH="${AISTACK_RUNTIME_PYTHON_SEARCH_PATH}:${STELLA_ORIGINAL_SYSTEM_PATH}" uv pip uninstall --system --verbose google-adk
		adk_is_installed && return 1
		return 0
	else
		echo "WARN : not installed or missing a required managed runtime $AISTACK_ADK_RUNTIME_REQUIRED"
	fi
}

adk_path_register_for_shell() {
	local shell_name="$1"
	if adk_is_installed; then
		path_register_for_shell "adk" "${AISTACK_ADK_LAUNCHER_HOME}" "$shell_name"
	fi
}
adk_path_unregister_for_shell() {
	local shell_name="${1:-all}"
	path_unregister_for_shell "adk" "$shell_name"
}
adk_path_register_for_vs_terminal() {
	if adk_is_installed; then
		vscode_path_register_for_vs_terminal "adk" "${AISTACK_ADK_LAUNCHER_HOME}"
	fi
}
adk_path_unregister_for_vs_terminal() {
	vscode_path_unregister_for_vs_terminal "adk" "${AISTACK_ADK_LAUNCHER_HOME}"
}


adk_launch() {
	(
		[ -f "${AISTACK_GENERIC_CONTEXT_FILE}" ] && . "${AISTACK_GENERIC_CONTEXT_FILE}"
		[ -f "${AISTACK_ADK_CONTEXT_FILE}" ] && . "${AISTACK_ADK_CONTEXT_FILE}"

		if [ "$#" -gt 0 ]; then
			"${AISTACK_RUNTIME_PYTHON_SEARCH_PATH}/adk" "$@"
		else
			"${AISTACK_RUNTIME_PYTHON_SEARCH_PATH}/adk"
		fi
	)
}

adk_launcher_and_context_files_manage() {
	local action="${1:-create}"

	case $action in
		create)
			if adk_is_installed; then
				# GENERATE CONTEXT FILE ----
				adk_context_file_generate

				# GENERATE LAUNCHER FILE ----
				{
					echo '#!/bin/sh'

					printf 'export %s=%s\n' "AISTACK_GENERIC_CONTEXT_FILE" "$(shell_quote_posix "${AISTACK_GENERIC_CONTEXT_FILE}")"
					printf 'export %s=%s\n' "AISTACK_ADK_CONTEXT_FILE" "$(shell_quote_posix "${AISTACK_ADK_CONTEXT_FILE}")"

					declare -f adk_launch

					echo adk_launch \"\$@\"
				} > "${AISTACK_ADK_LAUNCHER_FILE}"

				chmod +x "${AISTACK_ADK_LAUNCHER_FILE}"
			fi
			;;

		delete)
			rm -Rf "${AISTACK_ADK_LAUNCHER_HOME}"
			mkdir -p "${AISTACK_ADK_LAUNCHER_HOME}"
			adk_context_file_generate_remove
			;;
		
		refresh_if_exists)
			[ -f "${AISTACK_ADK_LAUNCHER_FILE}" ] && ( adk_launcher_and_context_files_manage "delete"; adk_launcher_and_context_files_manage "create" )
			;;
	esac
}

adk_context_file_generate() {
	# GENERATE CONTEXT FILE ----
	echo '#!/bin/sh' > "${AISTACK_ADK_CONTEXT_FILE}"
	chmod +x "${AISTACK_ADK_CONTEXT_FILE}"

	# VARIABLES
	aistack_context_file_export_variables "${AISTACK_ADK_CONTEXT_FILE}" "${AISTACK_ADK_CONTEXT_EXPORT_VARIABLES}"

	# PATH
	local m r list_path
	for r in ${AISTACK_ADK_RUNTIME_REQUIRED_IN_CONTEXT}; do list_path="$(aistack_context_path_add_component "runtime" "${r}" "VARIABLE_LIST") ${list_path}"; done
	for m in ${AISTACK_ADK_MODULE_REQUIRED_IN_CONTEXT}; do list_path="$(aistack_context_path_add_component "module" "${m}" "VARIABLE_LIST") ${list_path}"; done
	aistack_context_file_export_path "${AISTACK_ADK_CONTEXT_FILE}" "${list_path}" "VARIABLE_LIST"
}

adk_context_file_generate_remove() {
	rm -f "${AISTACK_ADK_CONTEXT_FILE}"
}


adk_info() {
	echo "ADK available : $AISTACK_ADK_TOOL_AVAILABLE"
	echo "ADK path : $AISTACK_ADK_TOOL_PATH"
	echo "ADK needed managed runtime : $AISTACK_ADK_RUNTIME_REQUIRED"
	echo "ADK needed managed module : $AISTACK_ADK_MODULE_REQUIRED"
	echo "ADK launcher : $AISTACK_ADK_LAUNCHER_FILE"
	echo "ADK context file : $AISTACK_ADK_CONTEXT_FILE"
}

adk_settings_configure() {
	:
}

adk_settings_remove() {
	:
}
