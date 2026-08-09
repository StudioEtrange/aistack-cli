asm_init() {
	# asm specific variables
	export AISTACK_ASM_CONFIG_HOME="${HOME}/.config/agent-skill-manager"
	mkdir -p "${AISTACK_ASM_CONFIG_HOME}"
	export AISTACK_ASM_CONFIG_FILE="${AISTACK_ASM_CONFIG_HOME}/settings.json"

	# asm launcher
	export AISTACK_ASM_LAUNCHER_HOME="${AISTACK_LAUNCHER_HOME}/asm"
	mkdir -p "${AISTACK_ASM_LAUNCHER_HOME}"
	export AISTACK_ASM_LAUNCHER_FILE="${AISTACK_ASM_LAUNCHER_HOME}/asm"

	# asm context
	export AISTACK_ASM_CONTEXT_HOME="${AISTACK_CONTEXT_HOME}/asm"
	mkdir -p "${AISTACK_ASM_CONTEXT_HOME}"
	export AISTACK_ASM_CONTEXT_FILE="${AISTACK_ASM_CONTEXT_HOME}/asm_context.sh"
	# any variables needed to run this component or used by _launch function
	# NOTE: do not need to declare those variables:
	#		AISTACK_*_CONTEXT_FILE and AISTACK_GENERIC_CONTEXT_FILE are already exported
	#		every *_SEARCH_PATH variable related to a REQUIRED_RUNTIME or REQUIRED_MODULE are already exported
	export AISTACK_ASM_CONTEXT_EXPORT_VARIABLES=""

	# asm requirement - those will be installed and presence checked to run the current component
	# NOTE:	those search path will be injected in context file
	#export AISTACK_ASM_RUNTIME_REQUIRED="bun"
	export AISTACK_ASM_RUNTIME_REQUIRED="nodejs"
	export AISTACK_ASM_MODULE_REQUIRED=""
	# remove from context any runtime or module any item already in generic aistack context
	export AISTACK_ASM_RUNTIME_REQUIRED_IN_CONTEXT="$($STELLA_API filter_list_with_list "${AISTACK_ASM_RUNTIME_REQUIRED}" "${AISTACK_GENERIC_CONTEXT_ADD_RUNTIME}")"
	export AISTACK_ASM_MODULE_REQUIRED_IN_CONTEXT="$($STELLA_API filter_list_with_list "${AISTACK_ASM_MODULE_REQUIRED}" "${AISTACK_GENERIC_CONTEXT_ADD_MODULE}")"

}

# test if asm is installed
# return 0 : is installed
# return 1 : tool is not installed
# return 2 : missing runtime
asm_is_installed() {
	local r m
	export AISTACK_ASM_TOOL_AVAILABLE="false"
	export AISTACK_ASM_TOOL_PATH=""
	for r in ${AISTACK_ASM_RUNTIME_REQUIRED}; do aistack_runtime_is_detected "${r}" || return 2; done
	for m in ${AISTACK_ASM_MODULE_REQUIRED}; do aistack_module_is_detected "${m}" || return 2; done
	[ -x "$AISTACK_RUNTIME_NODEJS_SEARCH_PATH/asm" ] || return 1
	export AISTACK_ASM_TOOL_PATH="$AISTACK_RUNTIME_NODEJS_SEARCH_PATH/asm"
	export AISTACK_ASM_TOOL_AVAILABLE="true"
	return 0
}

asm_install() {
	local r m
	local version="$1"
	[ -z "${version}" ] && version="@latest"

	for r in ${AISTACK_ASM_RUNTIME_REQUIRED}; do 
		echo "INFO: asm require ${r} managed runtime"
		aistack_runtime_require "${r}"
	done

	for m in ${AISTACK_ASM_MODULE_REQUIRED}; do 
		echo "INFO: asm require ${m} managed module"
		aistack_module_require "${m}"
	done

	echo "Installing Agent Skill Manager ${version}"
	node_package_install "agent-skill-manager${version}" || return $?
	#PATH="${AISTACK_RUNTIME_NODEJS_SEARCH_PATH}:${STELLA_ORIGINAL_SYSTEM_PATH}" npm install --verbose -g agent-skill-manager${version}
	# using bun package manager
	# PATH="${AISTACK_RUNTIME_BUN_SEARCH_PATH}:${STELLA_ORIGINAL_SYSTEM_PATH}" bun add --verbose -g agent-skill-manager${version}
	asm_is_installed
	return $?
}

asm_uninstall() {
	if asm_is_installed; then
		node_package_uninstall "agent-skill-manager" || return $?
		#PATH="${AISTACK_RUNTIME_NODEJS_SEARCH_PATH}:${STELLA_ORIGINAL_SYSTEM_PATH}" npm uninstall -g agent-skill-manager
		# using bun package manager
		# PATH="${AISTACK_RUNTIME_BUN_SEARCH_PATH}:${STELLA_ORIGINAL_SYSTEM_PATH}" bun remove -g agent-skill-manager
		asm_is_installed && return 1
		return 0
	else
		echo "WARN : not installed or missing a required managed runtime $AISTACK_ASM_RUNTIME_REQUIRED"
	fi
}

asm_path_register_for_shell() {
	local shell_name="$1"
	if asm_is_installed; then
		path_register_for_shell "asm" "${AISTACK_ASM_LAUNCHER_HOME}" "$shell_name"
	fi
}
asm_path_unregister_for_shell() {
    local shell_name="${1:-all}"
	path_unregister_for_shell "asm" "$shell_name"
}
asm_path_register_for_vs_terminal() {
	if asm_is_installed; then
		vscode_path_register_for_vs_terminal "asm" "${AISTACK_ASM_LAUNCHER_HOME}"
	fi
}
asm_path_unregister_for_vs_terminal() {
	vscode_path_unregister_for_vs_terminal "asm" "${AISTACK_ASM_LAUNCHER_HOME}"
}


asm_launch() {
	(
		[ -f "${AISTACK_GENERIC_CONTEXT_FILE}" ] && . "${AISTACK_GENERIC_CONTEXT_FILE}"
		[ -f "${AISTACK_ASM_CONTEXT_FILE}" ] && . "${AISTACK_ASM_CONTEXT_FILE}"

		if [ "$#" -gt 0 ]; then
			"$AISTACK_RUNTIME_NODEJS_SEARCH_PATH/asm" "$@"
		else
			"$AISTACK_RUNTIME_NODEJS_SEARCH_PATH/asm"
		fi
	)
}

asm_launcher_and_context_files_manage() {
	local action="${1:-create}"

	case $action in
		create)
			if asm_is_installed; then
				# GENERATE CONTEXT FILE ----
				asm_context_file_generate

				# GENERATE LAUNCHER FILE ----
				{
					echo '#!/bin/sh'

					printf 'export %s=%s\n' "AISTACK_GENERIC_CONTEXT_FILE" "$(shell_quote_posix "${AISTACK_GENERIC_CONTEXT_FILE}")"
					printf 'export %s=%s\n' "AISTACK_ASM_CONTEXT_FILE" "$(shell_quote_posix "${AISTACK_ASM_CONTEXT_FILE}")"

					declare -f asm_launch

					echo asm_launch \"\$@\"
				} > "${AISTACK_ASM_LAUNCHER_FILE}"

				chmod +x "${AISTACK_ASM_LAUNCHER_FILE}"
			fi
			;;

		delete)
			rm -Rf "${AISTACK_ASM_LAUNCHER_HOME}"
			mkdir -p "${AISTACK_ASM_LAUNCHER_HOME}"
			asm_context_file_generate_remove
			;;

		refresh_if_exists)
			[ -f "${AISTACK_ASM_LAUNCHER_FILE}" ] && ( asm_launcher_and_context_files_manage "delete"; asm_launcher_and_context_files_manage "create" )
			;;
	esac
}

asm_context_file_generate() {
	# GENERATE CONTEXT FILE ----
	echo '#!/bin/sh' > "${AISTACK_ASM_CONTEXT_FILE}"
	chmod +x "${AISTACK_ASM_CONTEXT_FILE}"

	# VARIABLES
	aistack_context_file_export_variables "${AISTACK_ASM_CONTEXT_FILE}" "${AISTACK_ASM_CONTEXT_EXPORT_VARIABLES}"
	
	# PATH
	local m r list_path
	for r in ${AISTACK_ASM_RUNTIME_REQUIRED_IN_CONTEXT}; do list_path="$(aistack_context_path_add_component "runtime" "${r}" "VARIABLE_LIST") ${list_path}"; done
	for m in ${AISTACK_ASM_MODULE_REQUIRED_IN_CONTEXT}; do list_path="$(aistack_context_path_add_component "module" "${m}" "VARIABLE_LIST") ${list_path}"; done
	aistack_context_file_export_path "${AISTACK_ASM_CONTEXT_FILE}" "${list_path}" "VARIABLE_LIST"
}

asm_context_file_generate_remove() {
	rm -f "${AISTACK_ASM_CONTEXT_FILE}"
}


asm_info() {
	echo "Configuration file : $AISTACK_ASM_CONFIG_FILE"
	echo
	echo "Agent Skill Manager available : $AISTACK_ASM_TOOL_AVAILABLE"
	echo "Agent Skill Manager path : $AISTACK_ASM_TOOL_PATH"
	echo "Agent Skill Manager needed managed runtime : $AISTACK_ASM_RUNTIME_REQUIRED"
	echo "Agent Skill Manager needed managed module : $AISTACK_ASM_MODULE_REQUIRED"
	echo "Agent Skill Manager launcher : $AISTACK_ASM_LAUNCHER_FILE"
	echo "Agent Skill Manager context file : $AISTACK_ASM_CONTEXT_FILE"
}

# generic config management -----------------
asm_show_config() {
	if [ -f "$AISTACK_ASM_CONFIG_FILE" ]; then
		cat "$AISTACK_ASM_CONFIG_FILE"
	else
		echo "No asm configuration file found. ($AISTACK_ASM_CONFIG_FILE)"
	fi
}


asm_settings_configure() {
	:
}

asm_settings_remove() {
	rm -Rf "$AISTACK_ASM_CONFIG_HOME"
}
