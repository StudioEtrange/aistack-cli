
gemini_path() {
    # gc specific paths
    export AISTACK_GEMINI_CONFIG_HOME="${HOME}/.gemini"
    export AISTACK_GEMINI_CONFIG_CMD_HOME="${AISTACK_GEMINI_CONFIG_HOME}/commands"
    export AISTACK_GEMINI_CONFIG_FILE="${AISTACK_GEMINI_CONFIG_HOME}/settings.json"

    # aistack path for gc
    export AISTACK_GEMINI_LAUNCHER_HOME="${AISTACK_LAUNCHER_HOME}/gemini-cli"
    mkdir -p "${AISTACK_GEMINI_LAUNCHER_HOME}"

}

# add gemini launcher in path for shell
gemini_path_register_for_shell() {
    local shell_name="$1"
    path_register_for_shell "gemini" "$shell_name" "${AISTACK_GEMINI_LAUNCHER_HOME}"
}
gemini_path_unregister_for_shell() {
    local shell_name="$1"
    path_unregister_for_shell "gemini" "$shell_name"
}
gemini_path_register_for_vs_terminal() {
    vscode_path_register_for_vs_terminal "gemini" "${AISTACK_GEMINI_LAUNCHER_HOME}"
}
gemini_path_unregister_for_vs_terminal() {
    vscode_path_unregister_for_vs_terminal "gemini" "${AISTACK_GEMINI_LAUNCHER_HOME}"
}



gemini_launcher_manage() {
    local action="${1:-create}"

    case $action in
        create)
            if [ -f "${AISTACK_NODEJS_BIN_PATH}gemini" ]; then

                runtime_path_files_generate

                echo '#!/bin/sh' > "${AISTACK_GEMINI_LAUNCHER_HOME}/gemini"
                echo ". ${AISTACK_RUNTIME_PATH_FILE}" >> "${AISTACK_GEMINI_LAUNCHER_HOME}/gemini"
                echo "gemini \$@" >> "${AISTACK_GEMINI_LAUNCHER_HOME}/gemini"
                chmod +x "${AISTACK_GEMINI_LAUNCHER_HOME}/gemini"

                # launcher based on a wrapper
                # echo '#!/bin/sh' > "${AISTACK_GEMINI_LAUNCHER_HOME}/gemini"
                # echo "${AISTACK_NODEJS_BIN_PATH}node ${AISTACK_NODEJS_BIN_PATH}/gemini \$@" >> "${AISTACK_GEMINI_LAUNCHER_HOME}/gemini"
                # chmod +x "${AISTACK_GEMINI_LAUNCHER_HOME}/gemini"

                # launcher based on a symbolic link - test link does not exist OR is not valid
                # if [ ! -L "${AISTACK_GEMINI_LAUNCHER_HOME}/gemini" ] || [ ! -e "${AISTACK_GEMINI_LAUNCHER_HOME}/gemini" ]; then
                #     echo "Create a gemini launcher"
                #     ln -fsv "${AISTACK_NODEJS_BIN_PATH}/gemini" "${AISTACK_GEMINI_LAUNCHER_HOME}/gemini"
                # fi
            fi
            ;;
        delete)
            rm -f "${AISTACK_GEMINI_LAUNCHER_HOME}/gemini"
            ;;
    esac
}


gemini_settings_configure() {
    echo "add some default settings :"
    echo " - disable statistics usage data send"
    echo " - support for autoloading AGENTS.md file"
    cat "${AISTACK_POOL}/settings/gemini-cli/settings.json"
    printf "\n"
    merge_json_file "${AISTACK_POOL}/settings/gemini-cli/settings.json" "$AISTACK_GEMINI_CONFIG_FILE"
}

gemini_settings_remove() {
    rm -Rf "$AISTACK_GEMINI_CONFIG_HOME"
}


gemini_launch() {
    local list_args=()

    for arg in "$@"; do
        list_args+=("$arg")
    done

    if [ ${#list_args[@]} -gt 0 ]; then
        gemini "${list_args[@]}"
    else
        gemini
    fi
}


# generic config management -----------------
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
