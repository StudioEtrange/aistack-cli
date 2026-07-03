adk_init() {

    export AISTACK_ADK_LAUNCHER_HOME="${AISTACK_LAUNCHER_HOME}/adk"
    mkdir -p "${AISTACK_ADK_LAUNCHER_HOME}"

	export AISTACK_ADK_RUNTIME_REQUIRED="python"
    
}

# return 0 : is installed
# return 1 : tool is not installed
# return 2 : missing runtime
adk_is_installed() {
	local r
	export AISTACK_ADK_TOOL_AVAILABLE="false"
	for r in $AISTACK_ADK_RUNTIME_REQUIRED; do aistack_runtime_is_detected "${r}" || return 2; done
	[ -x "${AISTACK_RUNTIME_PYTHON_SEARCH_PATH}/adk" ] || return 1
	export AISTACK_ADK_TOOL_PATH="${AISTACK_RUNTIME_PYTHON_SEARCH_PATH}/adk"
	export AISTACK_ADK_TOOL_AVAILABLE="true"
	return 0
}

adk_install() {
	local r

	for r in $AISTACK_ADK_RUNTIME_REQUIRED; do 
		echo "Require needed ${r} rmanaged untime"
		aistack_runtime_require "${r}"
	done

    echo "Installing adk for python"
	python_uv_package_install "google-adk"
    #PATH="${AISTACK_RUNTIME_PYTHON_SEARCH_PATH}:${STELLA_ORIGINAL_SYSTEM_PATH}" uv pip install --system --reinstall --verbose google-adk
	adk_is_installed
}

adk_uninstall() {
	if adk_is_installed; then
		python_uv_package_uninstall "google-adk"
		#PATH="${AISTACK_RUNTIME_PYTHON_SEARCH_PATH}:${STELLA_ORIGINAL_SYSTEM_PATH}" uv pip uninstall --system --verbose google-adk
		adk_is_installed
	else
		echo "WARN : not installed or missing a required managed runtime $AISTACK_ADK_RUNTIME_REQUIRED"
	fi
}
 

adk_path_register_for_shell() {
    local shell_name="$1"
	if adk_is_installed; then
    	path_register_for_shell "adk" "${AISTACK_BMAD_LAUNCHER_HOME}" "$shell_name"
	fi
}
adk_path_unregister_for_shell() {
    local shell_name="${1:-all}"
    path_unregister_for_shell "adk" "$shell_name"
}
adk_path_register_for_vs_terminal() {
	if adk_is_installed; then
    	vscode_path_register_for_vs_terminal "adk" "${AISTACK_BMAD_LAUNCHER_HOME}"
	fi
}
adk_path_unregister_for_vs_terminal() {
    vscode_path_unregister_for_vs_terminal "adk" "${AISTACK_BMAD_LAUNCHER_HOME}"
}




adk_launch_export_variables="AISTACK_RUN_CONTEXT_FILE AISTACK_RUNTIME_PYTHON_SEARCH_PATH"
adk_launch() {
    (
        . "${AISTACK_RUN_CONTEXT_FILE}"

        if [ "$#" -gt 0 ]; then
            "${AISTACK_RUNTIME_PYTHON_SEARCH_PATH}/adk" "$@"
        else
            "${AISTACK_RUNTIME_PYTHON_SEARCH_PATH}/adk"
        fi
    )
}



adk_launcher_manage() {
    local action="${1:-create}"

    case $action in

        create)
			if adk_is_installed; then
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
			fi
            ;;

        delete)
            rm -Rf "${AISTACK_ADK_LAUNCHER_HOME}/adk"
			mkdir -p "${AISTACK_ADK_LAUNCHER_HOME}/adk"
            ;;
		
		refresh_if_exists)
			[ -f "${AISTACK_ADK_LAUNCHER_HOME}/adk" ] && ( adk_launcher_manage "delete"; adk_launcher_manage "create" )
			;;
    esac
    
}


adk_settings_configure() {
    :
}

adk_settings_remove() {
    :
}