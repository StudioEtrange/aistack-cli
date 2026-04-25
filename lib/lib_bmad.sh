bmad_path() {

    export AISTACK_BMAD_LAUNCHER_HOME="${AISTACK_LAUNCHER_HOME}/bmad"
    mkdir -p "${AISTACK_BMAD_LAUNCHER_HOME}"
    
}


bmad_install() {
    local version="$1"
    [ -z "${version}" ] && version="@latest"

    echo "Installing bmad-method ${version}"
    # available versions : https://www.npmjs.com/package/bmad-method
    PATH="${AISTACK_NODEJS_BIN_PATH}:${STELLA_ORIGINAL_SYSTEM_PATH}" npm install --verbose -g bmad-method${version}
}

bmad_uninstall() {
    PATH="${AISTACK_NODEJS_BIN_PATH}:${STELLA_ORIGINAL_SYSTEM_PATH}" npm uninstall -g bmad-method
}
 

bmad_path_register_for_shell() {
    local shell_name="$1"
    path_register_for_shell "bmad" "${AISTACK_BMAD_LAUNCHER_HOME}" "$shell_name"
}
bmad_path_unregister_for_shell() {
    local shell_name="${1:-all}"
    path_unregister_for_shell "bmad" "$shell_name"
}
bmad_path_register_for_vs_terminal() {
    vscode_path_register_for_vs_terminal "bmad" "${AISTACK_BMAD_LAUNCHER_HOME}"
}
bmad_path_unregister_for_vs_terminal() {
    vscode_path_unregister_for_vs_terminal "bmad" "${AISTACK_BMAD_LAUNCHER_HOME}"
}



bmad_launch_export_variables="AISTACK_RUNTIME_PATH_FILE AISTACK_NODEJS_BIN_PATH"
bmad_launch() {

    (
        . "${AISTACK_RUNTIME_PATH_FILE}"

        # NOTE : we could call "${AISTACK_NODEJS_BIN_PATH}/bmad" instead of bmad-method. Both are link to the same binary
        if [ "$#" -gt 0 ]; then
            "${AISTACK_NODEJS_BIN_PATH}/bmad-method" "$@"
        else
            "${AISTACK_NODEJS_BIN_PATH}/bmad-method"
        fi
    )
}



bmad_launcher_manage() {
    local action="${1:-create}"

    case $action in

        create)
			# create a compatible POSIX shell script to be called from bash, zsn, fish and wo on
            # and executed by the default /bin/sh on the current system
            {
                echo '#!/bin/sh'
                for v in $bmad_launch_export_variables; do
                    printf 'export %s=%s\n' "$v" "$(shell_quote_posix "${!v}")"
                done

                declare -f bmad_launch

                echo bmad_launch \"\$@\"
            } | tee "${AISTACK_BMAD_LAUNCHER_HOME}/bmad" "${AISTACK_BMAD_LAUNCHER_HOME}/bmad-method" > /dev/null

            chmod +x "${AISTACK_BMAD_LAUNCHER_HOME}/bmad"
            chmod +x "${AISTACK_BMAD_LAUNCHER_HOME}/bmad-method"
            ;;

        delete)
            rm -f "${AISTACK_BMAD_LAUNCHER_HOME}/bmad"
            rm -f "${AISTACK_BMAD_LAUNCHER_HOME}/bmad-method"
            ;;
    esac
    
}


bmad_settings_configure() {
    :
}

bmad_settings_remove() {
    :
}