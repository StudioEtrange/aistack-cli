adk_path() {

    export AISTACK_ADK_LAUNCHER_HOME="${AISTACK_LAUNCHER_HOME}/adk"
    mkdir -p "${AISTACK_ADK_LAUNCHER_HOME}"
    
}


adk_install() {

    echo "Installing adk for python"
    PATH="${AISTACK_PYTHON_BIN_PATH}:${STELLA_ORIGINAL_SYSTEM_PATH}" uv pip install --system --verbose google-adk
}

adk_uninstall() {
    PATH="${AISTACK_PYTHON_BIN_PATH}:${STELLA_ORIGINAL_SYSTEM_PATH}" uv pip uninstall --system --verbose google-adk
}
 

adk_path_register_for_shell() {
    local shell_name="$1"
    path_register_for_shell "adk" "${AISTACK_BMAD_LAUNCHER_HOME}" "$shell_name"
}
adk_path_unregister_for_shell() {
    local shell_name="${1:-all}"
    path_unregister_for_shell "adk" "$shell_name"
}
adk_path_register_for_vs_terminal() {
    vscode_path_register_for_vs_terminal "adk" "${AISTACK_BMAD_LAUNCHER_HOME}"
}
adk_path_unregister_for_vs_terminal() {
    vscode_path_unregister_for_vs_terminal "adk" "${AISTACK_BMAD_LAUNCHER_HOME}"
}



adk_launch_export_variables="AISTACK_RUNTIME_PATH_FILE AISTACK_PYTHON_BIN_PATH"
adk_launch() {

    (
        . "${AISTACK_RUNTIME_PATH_FILE}"

        if [ "$#" -gt 0 ]; then
            "${AISTACK_PYTHON_BIN_PATH}/adk" "$@"
        else
            "${AISTACK_PYTHON_BIN_PATH}/adk"
        fi
    )
}



adk_launcher_manage() {
    local action="${1:-create}"

    case $action in

        create)
			# create a compatible POSIX shell script to be called from bash, zsn, fish and wo on
            # and executed by the default /bin/sh on the current system
            {
                echo '#!/bin/sh'
                for v in $adk_launch_export_variables; do
                    printf 'export %s=%s\n' "$v" "$(shell_quote_posix "${!v}")"
                done

                declare -f adk_launch

                echo adk_launch \"\$@\"
            } > "${AISTACK_ADK_LAUNCHER_HOME}/adk"
            chmod +x "${AISTACK_ADK_LAUNCHER_HOME}/adk"
            ;;

        delete)
            rm -f "${AISTACK_ADK_LAUNCHER_HOME}/adk"
            ;;
    esac
    
}


adk_settings_configure() {
    :
}

adk_settings_remove() {
    :
}