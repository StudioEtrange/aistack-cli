
opencode_path() {
    # oc specific paths
    export AISTACK_OPENCODE_LOCAL_SHARE_HOME="$HOME/.local/share/opencode"
    export AISTACK_OPENCODE_CONFIG_HOME="$HOME/.config/opencode"
    #You can also specify a custom config file path using the OPENCODE_CONFIG environment variable. This takes precedence over the global and project configs.
    [ "$OPENCODE_CONFIG" = "" ] && export AISTACK_OPENCODE_CONFIG_FILE="$AISTACK_OPENCODE_CONFIG_HOME/opencode.json" || export AISTACK_OPENCODE_CONFIG_FILE="$OPENCODE_CONFIG"

    # aistack path for oc
    export AISTACK_OPENCODE_LAUNCHER_HOME="${AISTACK_LAUNCHER_HOME}/opencode"
    mkdir -p "${AISTACK_OPENCODE_LAUNCHER_HOME}"


}

# add opencode launcher in path for shell
opencode_path_register_for_shell() {
    local shell_name="$1"
    path_register_for_shell "opencode" "$shell_name" "${AISTACK_OPENCODE_LAUNCHER_HOME}"
}
opencode_path_unregister_for_shell() {
    local shell_name="$1"
    path_unregister_for_shell "opencode" "$shell_name"
}
opencode_path_register_for_vs_terminal() {
    vscode_path_register_for_vs_terminal "opencode" "${AISTACK_OPENCODE_LAUNCHER_HOME}"
}
opencode_path_unregister_for_vs_terminal() {
    vscode_path_unregister_for_vs_terminal "opencode" "${AISTACK_OPENCODE_LAUNCHER_HOME}"
}

opencode_install() {
    local version="$1"
    [ -z "${version}" ] && version="@latest"

    echo "Installing Opencode CLI"
    PATH="${AISTACK_NODEJS_BIN_PATH}:${STELLA_ORIGINAL_SYSTEM_PATH}" npm install --verbose -g opencode-ai${version}

}

opencode_uninstall() {
    PATH="${AISTACK_NODEJS_BIN_PATH}:${STELLA_ORIGINAL_SYSTEM_PATH}" npm uninstall -g opencode-ai
}

opencode_launch_variables="AISTACK_RUNTIME_PATH_FILE AISTACK_NODEJS_BIN_PATH"
opencode_launch() {
    set -- "$@"

    (
        . "${AISTACK_RUNTIME_PATH_FILE}"

        if [ "$#" -gt 0 ]; then
            "$AISTACK_NODEJS_BIN_PATH/opencode" "$@"
        else
            "$AISTACK_NODEJS_BIN_PATH/opencode"
        fi
    )
}

opencode_launcher_manage() {
    local action="${1:-create}"

    case $action in
        create)
            if [ -f "${AISTACK_NODEJS_BIN_PATH}opencode" ]; then
                
                # runtime_path_file_generate

                # echo '#!/bin/sh' > "${AISTACK_OPENCODE_LAUNCHER_HOME}/opencode"
                # echo ". ${AISTACK_RUNTIME_PATH_FILE}" >> "${AISTACK_OPENCODE_LAUNCHER_HOME}/opencode"
                # echo "opencode \$@" >> "${AISTACK_OPENCODE_LAUNCHER_HOME}/opencode"
                # chmod +x "${AISTACK_OPENCODE_LAUNCHER_HOME}/opencode"

                # launcher based on a symbolic link - test link does not exist OR is not valid
                # if [ ! -L "${AISTACK_OPENCODE_LAUNCHER_HOME}/opencode" ] || [ ! -e "${AISTACK_OPENCODE_LAUNCHER_HOME}/opencode" ]; then
                #     echo "Create an opencode launcher"
                #     ln -fsv "${AISTACK_NODEJS_BIN_PATH}opencode" "${AISTACK_OPENCODE_LAUNCHER_HOME}/opencode"
                # fi

                {
                    echo '#!/bin/sh'
                    for v in $opencode_launch_variables; do
                        printf '%s=%s\n' "$v" "$(shell_quote_posix "${!v}")"
                    done

                    declare -f opencode_launch

                    echo opencode_launch \"\$@\"
                } > "${AISTACK_OPENCODE_LAUNCHER_HOME}/opencode"
            fi
            ;;

        delete)
            rm -f "${AISTACK_OPENCODE_LAUNCHER_HOME}/opencode"
            ;;
    esac
}

opencode_settings_configure() {
    merge_json_file "${AISTACK_POOL}/settings/opencode/opencode.json" "$AISTACK_OPENCODE_CONFIG_FILE"
}

opencode_settings_remove() {
    rm -Rf "$AISTACK_OPENCODE_LOCAL_SHARE_HOME"
    rm -Rf "$AISTACK_OPENCODE_CONFIG_HOME"
}

opencode_merge_config() {
    local file_to_merge="$1"
    merge_json_file "$file_to_merge" "$AISTACK_OPENCODE_CONFIG_FILE"
}

opencode_remove_config() {
    local key_path="$1"
    json_del_key_from_file "$AISTACK_OPENCODE_CONFIG_FILE" "$key_path" 
}

