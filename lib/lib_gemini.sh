gemini_init() {
	# gemini cli specific variables
	export AISTACK_GEMINI_CONFIG_HOME="${HOME}/.gemini"
	export AISTACK_GEMINI_CONFIG_CMD_HOME="${AISTACK_GEMINI_CONFIG_HOME}/commands"
	export AISTACK_GEMINI_CONFIG_FILE="${AISTACK_GEMINI_CONFIG_HOME}/settings.json"

	# gemini cli launcher
	export AISTACK_GEMINI_LAUNCHER_HOME="${AISTACK_LAUNCHER_HOME}/gemini-cli"
	mkdir -p "${AISTACK_GEMINI_LAUNCHER_HOME}"
	export AISTACK_GEMINI_LAUNCHER_FILE="${AISTACK_GEMINI_LAUNCHER_HOME}/gemini"

	# gemini cli context
	export AISTACK_GEMINI_CONTEXT_HOME="${AISTACK_CONTEXT_HOME}/gemini-cli"
	mkdir -p "${AISTACK_GEMINI_CONTEXT_HOME}"
	export AISTACK_GEMINI_CONTEXT_FILE="${AISTACK_GEMINI_CONTEXT_HOME}/gemini_context.sh"
	# any variables needed to run this component or used by _launch function
	# NOTE: do not need to declare those variables:
	#		AISTACK_*_CONTEXT_FILE and AISTACK_GENERIC_CONTEXT_FILE are already exported
	#		every *_SEARCH_PATH variable related to a REQUIRED_RUNTIME or REQUIRED_MODULE are already exported
	export AISTACK_GEMINI_CONTEXT_EXPORT_VARIABLES=""

	# gemini cli requirement - those will be installed and presence checked to run the current component
	# NOTE:	those search path will be injected in context file
	export AISTACK_GEMINI_RUNTIME_REQUIRED="nodejs"
	export AISTACK_GEMINI_MODULE_REQUIRED=""
	# remove from context any runtime or module any item already in generic aistack context
	export AISTACK_GEMINI_RUNTIME_REQUIRED_IN_CONTEXT="$($STELLA_API filter_list_with_list "${AISTACK_GEMINI_RUNTIME_REQUIRED}" "${AISTACK_GENERIC_CONTEXT_ADD_RUNTIME}")"
	export AISTACK_GEMINI_MODULE_REQUIRED_IN_CONTEXT="$($STELLA_API filter_list_with_list "${AISTACK_GEMINI_MODULE_REQUIRED}" "${AISTACK_GENERIC_CONTEXT_ADD_MODULE}")"

}

# test if gemini cli is installed
# return 0 : is installed
# return 1 : tool is not installed
# return 2 : missing runtime
gemini_is_installed() {
	local r m
	export AISTACK_GEMINI_TOOL_AVAILABLE="false"
	export AISTACK_GEMINI_TOOL_PATH=""
	for r in ${AISTACK_GEMINI_RUNTIME_REQUIRED}; do aistack_runtime_is_detected "${r}" || return 2; done
	for m in ${AISTACK_GEMINI_MODULE_REQUIRED}; do aistack_module_is_detected "${m}" || return 2; done
	[ -x "${AISTACK_RUNTIME_NODEJS_SEARCH_PATH}/gemini" ] || return 1
	export AISTACK_GEMINI_TOOL_PATH="${AISTACK_RUNTIME_NODEJS_SEARCH_PATH}/gemini"
	export AISTACK_GEMINI_TOOL_AVAILABLE="true"
	return 0
}

gemini_install() {
	local r m
	# latest is stable version
	local version="$1"
	[ -z "${version}" ] && version="@latest"

	for r in ${AISTACK_GEMINI_RUNTIME_REQUIRED}; do
		echo "INFO: Gemini CLI require ${r} managed runtime"
		aistack_runtime_require "${r}"
	done

	for m in ${AISTACK_GEMINI_MODULE_REQUIRED}; do
		echo "INFO: Gemini CLI require ${m} managed module"
		aistack_module_require "${m}"
	done

	echo "Installing Gemini CLI ${version}"
	# available versions : https://www.npmjs.com/package/@google/gemini-cli-core
	node_package_install "@google/gemini-cli${version}" || return $?
	#PATH="${AISTACK_RUNTIME_NODEJS_SEARCH_PATH}:${STELLA_ORIGINAL_SYSTEM_PATH}" npm install --verbose -g @google/gemini-cli${version}

	gemini_is_installed
	return $?
}

gemini_uninstall() {
	if gemini_is_installed; then
		node_package_uninstall "@google/gemini-cli" || return $?
		#PATH="${AISTACK_RUNTIME_NODEJS_SEARCH_PATH}:${STELLA_ORIGINAL_SYSTEM_PATH}" npm uninstall -g @google/gemini-cli
		gemini_is_installed && return 1
		return 0
	else
		echo "WARN : not installed or missing a required managed runtime $AISTACK_GEMINI_RUNTIME_REQUIRED"
	fi
}


gemini_path_register_for_shell() {
    local shell_name="$1"
	if gemini_is_installed; then
    	path_register_for_shell "gemini" "${AISTACK_GEMINI_LAUNCHER_HOME}" "$shell_name"
	fi
}
gemini_path_unregister_for_shell() {
    local shell_name="${1:-all}"
    path_unregister_for_shell "gemini" "$shell_name"
}
gemini_path_register_for_vs_terminal() {
	if gemini_is_installed; then
    	vscode_path_register_for_vs_terminal "gemini" "${AISTACK_GEMINI_LAUNCHER_HOME}"
	fi
}
gemini_path_unregister_for_vs_terminal() {
    vscode_path_unregister_for_vs_terminal "gemini" "${AISTACK_GEMINI_LAUNCHER_HOME}"
}

gemini_launch() {
	(
		[ -f "${AISTACK_GENERIC_CONTEXT_FILE}" ] && . "${AISTACK_GENERIC_CONTEXT_FILE}"
		[ -f "${AISTACK_GEMINI_CONTEXT_FILE}" ] && . "${AISTACK_GEMINI_CONTEXT_FILE}"

		if [ "$#" -gt 0 ]; then
			"${AISTACK_RUNTIME_NODEJS_SEARCH_PATH}/gemini" "$@"
		else
			"${AISTACK_RUNTIME_NODEJS_SEARCH_PATH}/gemini"
		fi
	)
}

gemini_launcher_and_context_files_manage() {
	local action="${1:-create}"

	case $action in
		create)
			if gemini_is_installed; then
				# GENERATE CONTEXT FILE ----
				gemini_context_file_generate

				# GENERATE LAUNCHER FILE ----
				{
					echo '#!/bin/sh'

					printf 'export %s=%s\n' "AISTACK_GENERIC_CONTEXT_FILE" "$(shell_quote_posix "${AISTACK_GENERIC_CONTEXT_FILE}")"
					printf 'export %s=%s\n' "AISTACK_GEMINI_CONTEXT_FILE" "$(shell_quote_posix "${AISTACK_GEMINI_CONTEXT_FILE}")"

					declare -f gemini_launch

					echo gemini_launch \"\$@\"
				} > "${AISTACK_GEMINI_LAUNCHER_FILE}"

				chmod +x "${AISTACK_GEMINI_LAUNCHER_FILE}"
			fi
			;;

		delete)
			rm -Rf "${AISTACK_GEMINI_LAUNCHER_HOME}"
            mkdir -p "${AISTACK_GEMINI_LAUNCHER_HOME}"
			gemini_context_file_generate_remove
			;;
		
		refresh_if_exists)
			[ -f "${AISTACK_GEMINI_LAUNCHER_FILE}" ] && ( gemini_launcher_and_context_files_manage "delete"; gemini_launcher_and_context_files_manage "create" )
			;;
	esac
}

gemini_context_file_generate() {
	# GENERATE CONTEXT FILE ----
	echo '#!/bin/sh' > "${AISTACK_GEMINI_CONTEXT_FILE}"
	chmod +x "${AISTACK_GEMINI_CONTEXT_FILE}"

	# VARIABLES
	aistack_context_file_export_variables "${AISTACK_GEMINI_CONTEXT_FILE}" "${AISTACK_GEMINI_CONTEXT_EXPORT_VARIABLES}"

	# PATH
	local m r list_path
	for r in ${AISTACK_GEMINI_RUNTIME_REQUIRED_IN_CONTEXT}; do list_path="$(aistack_context_path_add_component "runtime" "${r}" "VARIABLE_LIST") ${list_path}"; done
	for m in ${AISTACK_GEMINI_MODULE_REQUIRED_IN_CONTEXT}; do list_path="$(aistack_context_path_add_component "module" "${m}" "VARIABLE_LIST") ${list_path}"; done
	aistack_context_file_export_path "${AISTACK_GEMINI_CONTEXT_FILE}" "${list_path}" "VARIABLE_LIST"
}

gemini_context_file_generate_remove() {
	rm -f "${AISTACK_GEMINI_CONTEXT_FILE}"
}


gemini_info() {
    echo "Configuration file : $AISTACK_GEMINI_CONFIG_FILE"
	echo
	echo "GEMINI CLI available : $AISTACK_GEMINI_TOOL_AVAILABLE"
	echo "GEMINI CLI path : $AISTACK_GEMINI_TOOL_PATH"
	echo "GEMINI CLI needed managed runtime : $AISTACK_GEMINI_RUNTIME_REQUIRED"
	echo "GEMINI CLI needed managed module : $AISTACK_GEMINI_MODULE_REQUIRED"
	echo "GEMINI CLI launcher : $AISTACK_GEMINI_LAUNCHER_FILE"
	echo "GEMINI CLI context file : $AISTACK_GEMINI_CONTEXT_FILE"
	echo
}

gemini_show_config() {
    if [ -f "$AISTACK_GEMINI_CONFIG_FILE" ]; then
        cat "$AISTACK_GEMINI_CONFIG_FILE"
    else
        echo "No configuration file found. ($AISTACK_GEMINI_CONFIG_FILE)"
    fi
}


# generic config management -----------------
gemini_settings_configure() {
    echo "add some default settings :"
    echo " - disable statistics usage data send"
    echo " - support for autoloading AGENTS.md file"
    cat "${AISTACK_POOL}/settings/gemini-cli/settings.json"
    printf "\n"
    merge_json_file "${AISTACK_POOL}/settings/gemini-cli/settings.json" "$AISTACK_GEMINI_CONFIG_FILE"
}

gemini_settings_remove() {
    #rm -Rf "$AISTACK_GEMINI_CONFIG_HOME"
    remove_dir_with_exceptions "$AISTACK_GEMINI_CONFIG_HOME" "antigravity-cli"
}


gemini_merge_config() {
    local file_to_merge="$1"
    merge_json_file "$file_to_merge" "$AISTACK_GEMINI_CONFIG_FILE"
}

gemini_remove_config() {
    local key_path="$1"
    json_del_key_from_file "$AISTACK_GEMINI_CONFIG_FILE" "$key_path"
}

gemini_set_config() {
    local key_path="$1"
    local value="$2"
    json_set_key_into_file "$AISTACK_GEMINI_CONFIG_FILE" "$key_path" "$value"
}


# gemini command management ------------------------
gemini_add_command() {
    local command_file="$1"

     if [ ! -f "${command_file}" ]; then
        echo "ERROR : command file not found ${command_file}"
        exit 1
    fi

    mkdir -p "${AISTACK_GEMINI_CONFIG_CMD_HOME}"

    cp -f "${command_file}" "${AISTACK_GEMINI_CONFIG_CMD_HOME}/"
}

gemini_remove_command() {
    local command_file="$1"

    rm -f "${AISTACK_GEMINI_CONFIG_CMD_HOME}/${command_file}"
}
