gsd_path() {
    export AISTACK_GSD_LAUNCHER_HOME="${AISTACK_LAUNCHER_HOME}/gsd"
    mkdir -p "${AISTACK_GSD_LAUNCHER_HOME}"
}


gsd_install() {
    local version="$1"
    [ -z "${version}" ] && version="@latest"

    echo "Installing gsd ${version}"
    # available versions : https://www.npmjs.com/package/get-shit-done-cc
    PATH="${AISTACK_NODEJS_BIN_PATH}:${STELLA_ORIGINAL_SYSTEM_PATH}" npm install --verbose -g get-shit-done-cc${version}
}

gsd_uninstall() {
    PATH="${AISTACK_NODEJS_BIN_PATH}:${STELLA_ORIGINAL_SYSTEM_PATH}" npm uninstall -g get-shit-done-cc
}
 

gsd_path_register_for_shell() {
    local shell_name="$1"
    path_register_for_shell "gsd" "${AISTACK_GSD_LAUNCHER_HOME}" "$shell_name"
}
gsd_path_unregister_for_shell() {
    local shell_name="${1:-all}"
    path_unregister_for_shell "gsd" "$shell_name"
}
gsd_path_register_for_vs_terminal() {
    vscode_path_register_for_vs_terminal "gsd" "${AISTACK_GSD_LAUNCHER_HOME}"
}
gsd_path_unregister_for_vs_terminal() {
    vscode_path_unregister_for_vs_terminal "gsd" "${AISTACK_GSD_LAUNCHER_HOME}"
}



gsd_launch_export_variables="AISTACK_RUNTIME_PATH_FILE AISTACK_NODEJS_BIN_PATH"
gsd_launch() {
	set -- "$@"
    (
        . "${AISTACK_RUNTIME_PATH_FILE}"

        if [ "$#" -gt 0 ]; then
            "${AISTACK_NODEJS_BIN_PATH}/get-shit-done-cc" "$@"
        else
            "${AISTACK_NODEJS_BIN_PATH}/get-shit-done-cc"
        fi
    )
}



gsd_launcher_manage() {
    local action="${1:-create}"

    case $action in

        create)
			# create a compatible POSIX shell script to be called from bash, zsn, fish and wo on
            # and executed by the default /bin/sh on the current system
            {
                echo '#!/bin/sh'
                for v in $gsd_launch_export_variables; do
                    printf 'export %s=%s\n' "$v" "$(shell_quote_posix "${!v}")"
                done

                declare -f gsd_launch

                echo gsd_launch \"\$@\"
            } > "${AISTACK_GSD_LAUNCHER_HOME}/get-shit-done-cc"

            chmod +x "${AISTACK_GSD_LAUNCHER_HOME}/get-shit-done-cc"
            ;;

        delete)
            rm -f "${AISTACK_GSD_LAUNCHER_HOME}/get-shit-done-cc"
            ;;
    esac
    
}


gsd_settings_configure() {
    :
}

gsd_settings_remove() {
    :
}