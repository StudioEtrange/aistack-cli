
gemini_init() {
    # gc specific paths
    export AISTACK_GEMINI_CONFIG_HOME="${HOME}/.gemini"
    export AISTACK_GEMINI_CONFIG_CMD_HOME="${AISTACK_GEMINI_CONFIG_HOME}/commands"
    export AISTACK_GEMINI_CONFIG_FILE="${AISTACK_GEMINI_CONFIG_HOME}/settings.json"

    # aistack path for gc
    export AISTACK_GEMINI_LAUNCHER_HOME="${AISTACK_LAUNCHER_HOME}/gemini-cli"
    mkdir -p "${AISTACK_GEMINI_LAUNCHER_HOME}"

}


gemini_is_installed() {
	export AISTACK_GEMINI_TOOL_AVAILABLE="false"
	[ "$AISTACK_INTERNAL_NODEJS_RUNTIME_AVAILABLE" = "true" ] || return 1
	[ -x "$AISTACK_NODEJS_BIN_PATH/gemini" ] || return 1
	export AISTACK_GEMINI_TOOL_PATH="$AISTACK_NODEJS_BIN_PATH/gemini"
	export AISTACK_GEMINI_TOOL_AVAILABLE="true"
	return 0
}

gemini_install() {
    local version="$1"
    [ -z "${version}" ] && version="@latest"

    echo "Installing Gemini CLI ${version}"
    # available versions : https://www.npmjs.com/package/@google/gemini-cli-core
    # latest is stable version
    PATH="${AISTACK_NODEJS_BIN_PATH}:${STELLA_ORIGINAL_SYSTEM_PATH}" npm install --verbose -g @google/gemini-cli${version}
	
	gemini_is_installed
}

gemini_uninstall() {
    PATH="${AISTACK_NODEJS_BIN_PATH}:${STELLA_ORIGINAL_SYSTEM_PATH}" npm uninstall -g @google/gemini-cli
	gemini_is_installed
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

gemini_launch_export_variables="AISTACK_RUNTIME_BOOTSTRAP_FILE AISTACK_NODEJS_BIN_PATH"
gemini_launch() {
    (
        . "${AISTACK_RUNTIME_BOOTSTRAP_FILE}"

        if [ "$#" -gt 0 ]; then
            "$AISTACK_NODEJS_BIN_PATH/gemini" "$@"
        else
            "$AISTACK_NODEJS_BIN_PATH/gemini"
        fi
    )
}

gemini_launcher_manage() {
    local action="${1:-create}"

    case $action in
        create)
            # echo '#!/bin/sh' > "${AISTACK_GEMINI_LAUNCHER_HOME}/gemini"
            # echo ". ${AISTACK_RUNTIME_BOOTSTRAP_FILE}" >> "${AISTACK_GEMINI_LAUNCHER_HOME}/gemini"
            # echo "gemini \$@" >> "${AISTACK_GEMINI_LAUNCHER_HOME}/gemini"
            # chmod +x "${AISTACK_GEMINI_LAUNCHER_HOME}/gemini"

            # launcher based on a wrapper
            # echo '#!/bin/sh' > "${AISTACK_GEMINI_LAUNCHER_HOME}/gemini"
            # echo "${AISTACK_NODEJS_BIN_PATH}node ${AISTACK_NODEJS_BIN_PATH}/gemini \$@" >> "${AISTACK_GEMINI_LAUNCHER_HOME}/gemini"
            # chmod +x "${AISTACK_GEMINI_LAUNCHER_HOME}/gemini"

            # launcher based on a symbolic link - test link does not exist OR is not valid
            # if [ ! -L "${AISTACK_GEMINI_LAUNCHER_HOME}/gemini" ] || [ ! -e "${AISTACK_GEMINI_LAUNCHER_HOME}/gemini" ]; then
            #     echo "Create a gemini launcher"
            #     ln -fsv "${AISTACK_NODEJS_BIN_PATH}/gemini" "${AISTACK_GEMINI_LAUNCHER_HOME}/gemini"
            # fi

			if gemini_is_installed; then
				# create a compatible POSIX shell script to be called from bash, zsn, fish and wo on
				# and executed by the default /bin/sh on the current system
				{
					echo '#!/bin/sh'
					for v in $gemini_launch_export_variables; do
						printf 'export %s=%s\n' "$v" "$(shell_quote_posix "${!v}")"
					done

					declare -f gemini_launch

					echo gemini_launch \"\$@\"
				} > "${AISTACK_GEMINI_LAUNCHER_HOME}/gemini"

				chmod +x "${AISTACK_GEMINI_LAUNCHER_HOME}/gemini"
			fi
            ;;

        delete)
            rm -f "${AISTACK_GEMINI_LAUNCHER_HOME}/gemini"
            ;;
		
		refresh_if_exists)
			[ -f "${AISTACK_GEMINI_LAUNCHER_HOME}/gemini" ] && ( gemini_launcher_manage "delete"; gemini_launcher_manage "create" )
			;;
    esac
}


gemini_info() {
    echo "Configuration file : $AISTACK_GEMINI_CONFIG_FILE"
	echo
	echo "GEMINI CLI available : $AISTACK_GEMINI_TOOL_AVAILABLE"
	echo "GEMINI CLI path : $AISTACK_GEMINI_TOOL_PATH"
	echo
}

gemini_show_config() {
    if [ -f "$AISTACK_GEMINI_CONFIG_FILE" ]; then
        echo "Current configuration file : $AISTACK_GEMINI_CONFIG_FILE"
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
