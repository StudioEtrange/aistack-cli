bmad_init() {
	# bmad launcher
	export AISTACK_BMAD_LAUNCHER_HOME="${AISTACK_LAUNCHER_HOME}/bmad"
	mkdir -p "${AISTACK_BMAD_LAUNCHER_HOME}"
	export AISTACK_BMAD_LAUNCHER_FILE="${AISTACK_BMAD_LAUNCHER_HOME}/bmad"
	export AISTACK_BMAD_METHOD_LAUNCHER_FILE="${AISTACK_BMAD_LAUNCHER_HOME}/bmad-method"

	# bmad context
	export AISTACK_BMAD_CONTEXT_HOME="${AISTACK_CONTEXT_HOME}/bmad"
	mkdir -p "${AISTACK_BMAD_CONTEXT_HOME}"
	export AISTACK_BMAD_CONTEXT_FILE="${AISTACK_BMAD_CONTEXT_HOME}/bmad_context.sh"
	# any variables needed to run this component or used by _launch function
	# NOTE: do not need to declare those variables:
	#		AISTACK_*_CONTEXT_FILE and AISTACK_GENERIC_CONTEXT_FILE are already exported
	#		every *_SEARCH_PATH variable related to a REQUIRED_RUNTIME or REQUIRED_MODULE are already exported
	export AISTACK_BMAD_CONTEXT_EXPORT_VARIABLES=""

	# bmad requirement - those will be installed and presence checked to run the current component
	# NOTE:	those search path will be injected in context file
	export AISTACK_BMAD_RUNTIME_REQUIRED="nodejs"
	export AISTACK_BMAD_MODULE_REQUIRED=""
	# remove from context any runtime or module any item already in generic aistack context
	export AISTACK_BMAD_RUNTIME_REQUIRED_IN_CONTEXT="$($STELLA_API filter_list_with_list "${AISTACK_BMAD_RUNTIME_REQUIRED}" "${AISTACK_GENERIC_CONTEXT_ADD_RUNTIME}")"
	export AISTACK_BMAD_MODULE_REQUIRED_IN_CONTEXT="$($STELLA_API filter_list_with_list "${AISTACK_BMAD_MODULE_REQUIRED}" "${AISTACK_GENERIC_CONTEXT_ADD_MODULE}")"

}

# test if bmad is installed
# return 0 : is installed
# return 1 : tool is not installed
# return 2 : missing runtime
bmad_is_installed() {
	local r m
	export AISTACK_BMAD_TOOL_AVAILABLE="false"
	export AISTACK_BMAD_TOOL_PATH=""
	for r in ${AISTACK_BMAD_RUNTIME_REQUIRED}; do aistack_runtime_is_detected "${r}" || return 2; done
	for m in ${AISTACK_BMAD_MODULE_REQUIRED}; do aistack_module_is_detected "${m}" || return 2; done
	[ -x "${AISTACK_RUNTIME_NODEJS_SEARCH_PATH}/bmad-method" ] || return 1
	export AISTACK_BMAD_TOOL_PATH="${AISTACK_RUNTIME_NODEJS_SEARCH_PATH}/bmad-method"
	export AISTACK_BMAD_TOOL_AVAILABLE="true"
	return 0
}

bmad_install() {
	local r m
	# available versions : https://www.npmjs.com/package/bmad-method
	local version="$1"
	[ -z "${version}" ] && version="@latest"

	for r in ${AISTACK_BMAD_RUNTIME_REQUIRED}; do
		echo "INFO: bmad require ${r} managed runtime"
		aistack_runtime_require "${r}"
	done

	for m in ${AISTACK_BMAD_MODULE_REQUIRED}; do
		echo "INFO: bmad require ${m} managed module"
		aistack_module_require "${m}"
	done

	echo "Installing bmad-method ${version}"
	node_package_install "bmad-method${version}" || return $?
	#PATH="${AISTACK_RUNTIME_NODEJS_SEARCH_PATH}:${STELLA_ORIGINAL_SYSTEM_PATH}" npm install --verbose -g bmad-method${version}
	bmad_is_installed
	return $?
}

bmad_uninstall() {
	if bmad_is_installed; then
		node_package_uninstall "bmad-method" || return $?
		#PATH="${AISTACK_RUNTIME_NODEJS_SEARCH_PATH}:${STELLA_ORIGINAL_SYSTEM_PATH}" npm uninstall -g bmad-method
		bmad_is_installed && return 1
		return 0
	else
		echo "WARN : not installed or missing a required managed runtime $AISTACK_BMAD_RUNTIME_REQUIRED"
	fi
}


bmad_path_register_for_shell() {
    local shell_name="$1"
	if bmad_is_installed; then
    	path_register_for_shell "bmad" "${AISTACK_BMAD_LAUNCHER_HOME}" "$shell_name"
	fi
}
bmad_path_unregister_for_shell() {
    local shell_name="${1:-all}"
    path_unregister_for_shell "bmad" "$shell_name"
}
bmad_path_register_for_vs_terminal() {
	if bmad_is_installed; then
    	vscode_path_register_for_vs_terminal "bmad" "${AISTACK_BMAD_LAUNCHER_HOME}"
	fi
}
bmad_path_unregister_for_vs_terminal() {
    vscode_path_unregister_for_vs_terminal "bmad" "${AISTACK_BMAD_LAUNCHER_HOME}"
}


bmad_launch() {
	(
		[ -f "${AISTACK_GENERIC_CONTEXT_FILE}" ] && . "${AISTACK_GENERIC_CONTEXT_FILE}"
		[ -f "${AISTACK_BMAD_CONTEXT_FILE}" ] && . "${AISTACK_BMAD_CONTEXT_FILE}"

		# NOTE: both bmad and bmad-method are links to the same binary
		if [ "$#" -gt 0 ]; then
			"${AISTACK_RUNTIME_NODEJS_SEARCH_PATH}/bmad-method" "$@"
        else
            "${AISTACK_RUNTIME_NODEJS_SEARCH_PATH}/bmad-method"
        fi
	)
}

bmad_launcher_and_context_files_manage() {
	local action="${1:-create}"

	case $action in
		create)
			if bmad_is_installed; then
				# GENERATE CONTEXT FILE ----
				bmad_context_file_generate

				# GENERATE LAUNCHER FILES ----
				{
					echo '#!/bin/sh'

					printf 'export %s=%s\n' "AISTACK_GENERIC_CONTEXT_FILE" "$(shell_quote_posix "${AISTACK_GENERIC_CONTEXT_FILE}")"
					printf 'export %s=%s\n' "AISTACK_BMAD_CONTEXT_FILE" "$(shell_quote_posix "${AISTACK_BMAD_CONTEXT_FILE}")"

					declare -f bmad_launch

					echo bmad_launch \"\$@\"
				} > "${AISTACK_BMAD_METHOD_LAUNCHER_FILE}"

				cp -f "${AISTACK_BMAD_METHOD_LAUNCHER_FILE}" "${AISTACK_BMAD_LAUNCHER_FILE}"

				chmod +x "${AISTACK_BMAD_LAUNCHER_FILE}"
				chmod +x "${AISTACK_BMAD_METHOD_LAUNCHER_FILE}"
			fi
			;;

		delete)
			rm -Rf "${AISTACK_BMAD_LAUNCHER_HOME}"
			mkdir -p "${AISTACK_BMAD_LAUNCHER_HOME}"
			bmad_context_file_generate_remove
			;;

		refresh_if_exists)
			[ -f "${AISTACK_BMAD_METHOD_LAUNCHER_FILE}" ] && ( bmad_launcher_and_context_files_manage "delete"; bmad_launcher_and_context_files_manage "create" )
			;;
	esac
}

bmad_context_file_generate() {
	# GENERATE CONTEXT FILE ----
	echo '#!/bin/sh' > "${AISTACK_BMAD_CONTEXT_FILE}"
	chmod +x "${AISTACK_BMAD_CONTEXT_FILE}"

	# VARIABLES
	aistack_context_file_export_variables "${AISTACK_BMAD_CONTEXT_FILE}" "${AISTACK_BMAD_CONTEXT_EXPORT_VARIABLES}"

	# PATH
	local m r list_path
	for r in ${AISTACK_BMAD_RUNTIME_REQUIRED_IN_CONTEXT}; do list_path="$(aistack_context_path_add_component "runtime" "${r}" "VARIABLE_LIST") ${list_path}"; done
	for m in ${AISTACK_BMAD_MODULE_REQUIRED_IN_CONTEXT}; do list_path="$(aistack_context_path_add_component "module" "${m}" "VARIABLE_LIST") ${list_path}"; done
	aistack_context_file_export_path "${AISTACK_BMAD_CONTEXT_FILE}" "${list_path}" "VARIABLE_LIST"
}

bmad_context_file_generate_remove() {
	rm -f "${AISTACK_BMAD_CONTEXT_FILE}"
}


bmad_info() {
	echo "BMAD available : $AISTACK_BMAD_TOOL_AVAILABLE"
	echo "BMAD path : $AISTACK_BMAD_TOOL_PATH"
	echo "BMAD needed managed runtime : $AISTACK_BMAD_RUNTIME_REQUIRED"
	echo "BMAD needed managed module : $AISTACK_BMAD_MODULE_REQUIRED"
	echo "BMAD launcher : $AISTACK_BMAD_LAUNCHER_FILE"
	echo "BMAD method launcher : $AISTACK_BMAD_METHOD_LAUNCHER_FILE"
	echo "BMAD context file : $AISTACK_BMAD_CONTEXT_FILE"
}

bmad_settings_configure() {
    :
}

bmad_settings_remove() {
    :
}
