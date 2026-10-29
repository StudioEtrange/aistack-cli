geiger_init() {
	# geiger specific variables
	export GEIGER_FEAT_INSTALL_ROOT="${AISTACK_ISOLATED_ROOT}/geiger"
	mkdir -p "${GEIGER_FEAT_INSTALL_ROOT}"
	
	# geiger launcher
	export AISTACK_GEIGER_LAUNCHER_HOME="${AISTACK_LAUNCHER_HOME}/geiger"
	mkdir -p "${AISTACK_GEIGER_LAUNCHER_HOME}"
	export AISTACK_GEIGER_LAUNCHER_FILE="${AISTACK_GEIGER_LAUNCHER_HOME}/geiger"
	
	# geiger context
	export AISTACK_GEIGER_CONTEXT_HOME="${AISTACK_CONTEXT_HOME}/geiger"
	mkdir -p "${AISTACK_GEIGER_CONTEXT_HOME}"
	export AISTACK_GEIGER_CONTEXT_FILE="${AISTACK_GEIGER_CONTEXT_HOME}/geiger_context.sh"
	# any variables needed to run this component or used by _launch function
	# NOTE: do not need to declare those variables:
	#		AISTACK_*_CONTEXT_FILE and AISTACK_GENERIC_CONTEXT_FILE are already exported
	#		every *_SEARCH_PATH variable related to a REQUIRED_RUNTIME or REQUIRED_MODULE are already exported
	export AISTACK_GEIGER_CONTEXT_EXPORT_VARIABLES="GEIGER_FEAT_INSTALL_ROOT"
	
	# geiger requirements - those will be installed and presence checked to run the current component
	# NOTE:	those search path will be injected in context file
	export AISTACK_GEIGER_RUNTIME_REQUIRED="nodejs"
	export AISTACK_GEIGER_MODULE_REQUIRED=""
	# remove from context any runtime or module any item already in generic aistack context
	export AISTACK_GEIGER_RUNTIME_REQUIRED_IN_CONTEXT="$("${STELLA_API}" filter_list_with_list "${AISTACK_GEIGER_RUNTIME_REQUIRED}" "${AISTACK_GENERIC_CONTEXT_ADD_RUNTIME}")"
	export AISTACK_GEIGER_MODULE_REQUIRED_IN_CONTEXT=""
}

# test if geiger is installed
# return 0 : is installed
# return 1 : tool is not installed
# return 2 : missing runtime
geiger_is_installed() {
	local r
	export AISTACK_GEIGER_TOOL_AVAILABLE="false"
	export AISTACK_GEIGER_TOOL_SEARCH_PATH=""
	export AISTACK_GEIGER_TOOL_PATH=""
	for r in ${AISTACK_GEIGER_RUNTIME_REQUIRED}; do aistack_runtime_is_detected "${r}" || return 2; done
	for m in ${AISTACK_GEIGER_MODULE_REQUIRED}; do aistack_module_is_detected "${m}" || return 2; done
	[ -x "${GEIGER_FEAT_INSTALL_ROOT}/bin/geiger" ] || return 1
	export AISTACK_GEIGER_TOOL_AVAILABLE="true"
	export AISTACK_GEIGER_TOOL_SEARCH_PATH="${GEIGER_FEAT_INSTALL_ROOT}/bin"
	export AISTACK_GEIGER_TOOL_PATH="${AISTACK_GEIGER_TOOL_SEARCH_PATH}/geiger"
}

geiger_install() {
	local r m
	local version="$1"
	[ -z "${version}" ] && version="@latest"

	for r in ${AISTACK_GEIGER_RUNTIME_REQUIRED}; do
		echo "INFO: Geiger requires ${r} managed runtime"
		aistack_runtime_require "${r}" || return $?
	done

	for m in ${AISTACK_GEIGER_MODULE_REQUIRED}; do 
		echo "INFO: Geiger require ${m} managed module"
		aistack_module_require "${m}"
	done

	echo "INFO: Installing Geiger ${version}"
	node_isolated_package_install "${GEIGER_FEAT_INSTALL_ROOT}" --allow-scripts="geiger-scan" "geiger-scan${version}" || return $?
	geiger_is_installed
	return $?
}

geiger_uninstall() {
	if geiger_is_installed; then
		node_isolated_package_uninstall "${GEIGER_FEAT_INSTALL_ROOT}" --allow-scripts="geiger-scan" "geiger-scan" || return $?
		rm -Rf "${GEIGER_FEAT_INSTALL_ROOT}"
		geiger_is_installed && return 1
		return 0
	else
		echo "WARN : not installed or missing requirements."
	fi
}

geiger_path_register_for_shell() {
	local shell_name="${1:-current}"
	if geiger_is_installed; then
		register_path_named_bloc_for_shell "geiger" "${AISTACK_GEIGER_LAUNCHER_HOME}" "${shell_name}"
	fi
}

geiger_path_unregister_for_shell() {
	local shell_name="${1:-all}"
	unregister_path_named_bloc_for_shell "geiger" "${shell_name}"
}

geiger_path_register_for_vs_terminal() {
	if geiger_is_installed; then
		vscode_path_register_for_vs_terminal "geiger" "${AISTACK_GEIGER_LAUNCHER_HOME}"
	fi
}

geiger_path_unregister_for_vs_terminal() {
	vscode_path_unregister_for_vs_terminal "geiger" "${AISTACK_GEIGER_LAUNCHER_HOME}"
}

geiger_launch() {
	(
		[ -f "${AISTACK_GENERIC_CONTEXT_FILE}" ] && . "${AISTACK_GENERIC_CONTEXT_FILE}"
		[ -f "${AISTACK_GEIGER_CONTEXT_FILE}" ] && . "${AISTACK_ASM_CONTEXT_FILE}"

		if [ "$#" -gt 0 ]; then
			"${GEIGER_FEAT_INSTALL_ROOT}/bin/geiger" "$@"
		else
			"${GEIGER_FEAT_INSTALL_ROOT}/bin/geiger"
		fi
	)
}

geiger_launcher_and_context_files_manage() {
	local action="${1:-create}"

	case "${action}" in
		create)
			if geiger_is_installed; then
				# GENERATE CONTEXT FILE ----
				geiger_context_file_generate

				# GENERATE LAUNCHER FILE ----
				{
					echo '#!/bin/sh'

					printf 'export %s=%s\n' "AISTACK_GENERIC_CONTEXT_FILE" "$(shell_quote_posix "${AISTACK_GENERIC_CONTEXT_FILE}")"
					printf 'export %s=%s\n' "AISTACK_GEIGER_CONTEXT_FILE" "$(shell_quote_posix "${AISTACK_GEIGER_CONTEXT_FILE}")"

					declare -f geiger_launch

					echo asm_launch \"\$@\"
				} > "${AISTACK_GEIGER_LAUNCHER_FILE}"

				chmod +x "${AISTACK_GEIGER_LAUNCHER_FILE}"
			fi
			;;

		delete)
			rm -Rf "${AISTACK_GEIGER_LAUNCHER_HOME}" "${AISTACK_GEIGER_CONTEXT_FILE}"
			mkdir -p "${AISTACK_GEIGER_LAUNCHER_HOME}"
			geiger_context_file_generate_remove
			;;

		refresh_if_exists)
			[ -f "${AISTACK_GEIGER_LAUNCHER_FILE}" ]  && ( geiger_launcher_and_context_files_manage "delete"; geiger_launcher_and_context_files_manage "create" )
			;;
	esac
}

geiger_context_file_generate() {
	# GENERATE CONTEXT FILE ----
	echo '#!/bin/sh' > "${AISTACK_ASM_CONTEXT_FILE}"
	chmod +x "${AISTACK_ASM_CONTEXT_FILE}"

	# VARIABLES
	aistack_context_file_export_variables "${AISTACK_GEIGER_CONTEXT_FILE}" "${AISTACK_GEIGER_CONTEXT_EXPORT_VARIABLES}"
	
	# PATH
	local m r list_path
	for r in ${AISTACK_GEIGER_RUNTIME_REQUIRED_IN_CONTEXT}; do list_path="$(aistack_component_get_search_path "runtime" "${r}" "VARIABLE_LIST") ${list_path}"; done
	for m in ${AISTACK_GEIGER_MODULE_REQUIRED_IN_CONTEXT}; do list_path="$(aistack_component_get_search_path "module" "${m}" "VARIABLE_LIST") ${list_path}"; done
	aistack_context_file_export_path "${AISTACK_GEIGER_CONTEXT_FILE}" "${list_path}" "VARIABLE_LIST"
}

geiger_context_file_generate_remove() {
	rm -f "${AISTACK_GEIGER_CONTEXT_FILE}"
}

geiger_info() {
	echo "Geiger available : ${AISTACK_GEIGER_TOOL_AVAILABLE}"
	echo "Geiger path : ${AISTACK_GEIGER_TOOL_PATH}"
	echo "Geiger needed managed runtime : ${AISTACK_GEIGER_RUNTIME_REQUIRED} (Node.js >=18)"
	echo "Geiger needed managed module : $AISTACK_GEIGER_MODULE_REQUIRED"
	echo "Geiger install root : ${GEIGER_FEAT_INSTALL_ROOT}"
	echo "Geiger launcher : ${AISTACK_GEIGER_LAUNCHER_FILE}"
	echo "Geiger context file : ${AISTACK_GEIGER_CONTEXT_FILE}"
}
