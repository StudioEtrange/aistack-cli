llmfit_init() {
	# llmfit specific variables
	export LLMFIT_FEAT_INSTALL_ROOT="${AISTACK_ISOLATED_ROOT}/llmfit"
	mkdir -p "${LLMFIT_FEAT_INSTALL_ROOT}"

	# llmfit launcher
	export AISTACK_LLMFIT_LAUNCHER_HOME="${AISTACK_LAUNCHER_HOME}/llmfit"
	mkdir -p "${AISTACK_LLMFIT_LAUNCHER_HOME}"
	export AISTACK_LLMFIT_LAUNCHER_FILE="${AISTACK_LLMFIT_LAUNCHER_HOME}/llmfit"

	# llmfit context
	export AISTACK_LLMFIT_CONTEXT_HOME="${AISTACK_CONTEXT_HOME}/llmfit"
	mkdir -p "${AISTACK_LLMFIT_CONTEXT_HOME}"
	export AISTACK_LLMFIT_CONTEXT_FILE="${AISTACK_LLMFIT_CONTEXT_HOME}/llmfit_context.sh"
	# any variables needed to run this component or used by _launch function
	# NOTE: do not need to declare those variables:
	#		AISTACK_*_CONTEXT_FILE and AISTACK_GENERIC_CONTEXT_FILE are already exported
	#		every *_SEARCH_PATH variable related to a REQUIRED_RUNTIME or REQUIRED_MODULE are already exported
	export AISTACK_LLMFIT_CONTEXT_EXPORT_VARIABLES="LLMFIT_FEAT_INSTALL_ROOT"

	# llmfit requirement - those will be installed and presence checked to run the current component
	# NOTE:	those search path will be injected in context file
	export AISTACK_LLMFIT_RUNTIME_REQUIRED=""
	export AISTACK_LLMFIT_MODULE_REQUIRED=""
	# remove from context any runtime or module any item already in generic aistack context
	export AISTACK_LLMFIT_RUNTIME_REQUIRED_IN_CONTEXT="$($STELLA_API filter_list_with_list "${AISTACK_LLMFIT_RUNTIME_REQUIRED}" "${AISTACK_GENERIC_CONTEXT_ADD_RUNTIME}")"
	export AISTACK_LLMFIT_MODULE_REQUIRED_IN_CONTEXT="$($STELLA_API filter_list_with_list "${AISTACK_LLMFIT_MODULE_REQUIRED}" "${AISTACK_GENERIC_CONTEXT_ADD_MODULE}")"

}

# test if llmfit is installed
# return 0 : is installed
# return 1 : tool is not installed
# return 2 : missing runtime
llmfit_is_installed() {
	local r m
	export AISTACK_LLMFIT_TOOL_AVAILABLE="false"
	export AISTACK_LLMFIT_TOOL_PATH=""
	for r in ${AISTACK_LLMFIT_RUNTIME_REQUIRED}; do aistack_runtime_is_detected "${r}" || return 2; done
	for m in ${AISTACK_LLMFIT_MODULE_REQUIRED}; do aistack_module_is_detected "${m}" || return 2; done
	[ -x "${LLMFIT_FEAT_INSTALL_ROOT}/llmfit" ] || return 1
	export AISTACK_LLMFIT_TOOL_AVAILABLE="true"
	export AISTACK_LLMFIT_TOOL_PATH="${LLMFIT_FEAT_INSTALL_ROOT}/llmfit"
	return 0
}



llmfit_install() {
	local r m
  
	for r in ${AISTACK_LLMFIT_RUNTIME_REQUIRED}; do
		echo "INFO: llmfit require ${r} managed runtime"
		aistack_runtime_require "${r}"
	done

	for m in ${AISTACK_LLMFIT_MODULE_REQUIRED}; do
		echo "INFO: llmfit require ${m} managed module"
		aistack_module_require "${m}"
	done

	echo "Installing llmfit"
	stella_feature_install "llmfit" "NOT_LOADED_IN_PATH" || return $?

	if llmfit_is_installed; then
		if [ -n "${AISTACK_INIT_FORCE_LLMFIT_GBC}" ]; then
			glibc_binary_compat "llmfit" "${LLMFIT_FEAT_INSTALL_ROOT}" "${AISTACK_INIT_FORCE_LLMFIT_GBC}" || return $?
		fi
		return 0
	else
		return 1
	fi

}
 
llmfit_uninstall() {
	if llmfit_is_installed; then
		echo "Uninstalling LLMFIT from ${LLMFIT_FEAT_INSTALL_ROOT}..."
		rm -Rf "${LLMFIT_FEAT_INSTALL_ROOT}" || return $?
		echo "LLMFIT uninstalled successfully."

		llmfit_is_installed && return 1
		return 0
	else
		echo "WARN : not installed or missing a required managed runtime $AISTACK_LLMFIT_RUNTIME_REQUIRED"
	fi
}


llmfit_path_register_for_shell() {
    local shell_name="$1"
	if llmfit_is_installed; then
    	path_register_for_shell "llmfit" "${AISTACK_LLMFIT_LAUNCHER_HOME}" "$shell_name"
	fi
}
llmfit_path_unregister_for_shell() {
    local shell_name="${1:-all}"
    path_unregister_for_shell "llmfit" "$shell_name"
}
llmfit_path_register_for_vs_terminal() {
	if llmfit_is_installed; then
    	vscode_path_register_for_vs_terminal "llmfit" "${AISTACK_LLMFIT_LAUNCHER_HOME}"
	fi
}
llmfit_path_unregister_for_vs_terminal() {
    vscode_path_unregister_for_vs_terminal "llmfit" "${AISTACK_LLMFIT_LAUNCHER_HOME}"
}

llmfit_launch() {
	(
		[ -f "${AISTACK_GENERIC_CONTEXT_FILE}" ] && . "${AISTACK_GENERIC_CONTEXT_FILE}"
		[ -f "${AISTACK_LLMFIT_CONTEXT_FILE}" ] && . "${AISTACK_LLMFIT_CONTEXT_FILE}"

		if [ "$#" -gt 0 ]; then
			"${LLMFIT_FEAT_INSTALL_ROOT}/llmfit" "$@"
		else
			"${LLMFIT_FEAT_INSTALL_ROOT}/llmfit"
		fi
	)
}

llmfit_launcher_manage() {
    local action="${1:-create}"

    case ${action} in
        create)
			if llmfit_is_installed; then
				# GENERATE CONTEXT FILE ----
				llmfit_context_file_generate

				# GENERATE LAUNCHER FILE ----
				{
					echo '#!/bin/sh'

					printf 'export %s=%s\n' "AISTACK_GENERIC_CONTEXT_FILE" "$(shell_quote_posix "${AISTACK_GENERIC_CONTEXT_FILE}")"
					printf 'export %s=%s\n' "AISTACK_LLMFIT_CONTEXT_FILE" "$(shell_quote_posix "${AISTACK_LLMFIT_CONTEXT_FILE}")"

					declare -f llmfit_launch

					echo llmfit_launch \"\$@\"
				} > "${AISTACK_LLMFIT_LAUNCHER_FILE}"

				chmod +x "${AISTACK_LLMFIT_LAUNCHER_FILE}"
			fi
            ;;

        delete)
			rm -f "${AISTACK_LLMFIT_LAUNCHER_FILE}"
			llmfit_context_file_generate_remove
            ;;

		refresh_if_exists)
			[ -f "${AISTACK_LLMFIT_LAUNCHER_FILE}" ] && ( llmfit_launcher_manage "delete"; llmfit_launcher_manage "create" )
			;;
    esac
}

llmfit_context_file_generate() {
	# GENERATE CONTEXT FILE ----
	echo '#!/bin/sh' > "${AISTACK_LLMFIT_CONTEXT_FILE}"
	chmod +x "${AISTACK_LLMFIT_CONTEXT_FILE}"

	# VARIABLES
	aistack_context_file_export_variables "${AISTACK_LLMFIT_CONTEXT_FILE}" "${AISTACK_LLMFIT_CONTEXT_EXPORT_VARIABLES}"

	# PATH
	local m r list_path
	for r in ${AISTACK_LLMFIT_RUNTIME_REQUIRED_IN_CONTEXT}; do list_path="$(aistack_context_path_add_component "runtime" "${r}" "VARIABLE_LIST") ${list_path}"; done
	for m in ${AISTACK_LLMFIT_MODULE_REQUIRED_IN_CONTEXT}; do list_path="$(aistack_context_path_add_component "module" "${m}" "VARIABLE_LIST") ${list_path}"; done
	aistack_context_file_export_path "${AISTACK_LLMFIT_CONTEXT_FILE}" "${list_path}" "VARIABLE_LIST"
}

llmfit_context_file_generate_remove() {
	rm -f "${AISTACK_LLMFIT_CONTEXT_FILE}"
}


llmfit_info() {
	echo "LLMFIT available : $AISTACK_LLMFIT_TOOL_AVAILABLE"
	echo "LLMFIT path : $AISTACK_LLMFIT_TOOL_PATH"
	echo "LLMFIT needed managed runtime : $AISTACK_LLMFIT_RUNTIME_REQUIRED"
	echo "LLMFIT needed managed module : $AISTACK_LLMFIT_MODULE_REQUIRED"
	echo "LLMFIT install root : $LLMFIT_FEAT_INSTALL_ROOT"
	echo "LLMFIT launcher : $AISTACK_LLMFIT_LAUNCHER_FILE"
	echo "LLMFIT context file : $AISTACK_LLMFIT_CONTEXT_FILE"
	echo
}
