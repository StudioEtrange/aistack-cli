llmfit_init() {

    export AISTACK_LLMFIT_LAUNCHER_HOME="${AISTACK_LAUNCHER_HOME}/llmfit"
    mkdir -p "${AISTACK_LLMFIT_LAUNCHER_HOME}"


    export LLMFIT_FEAT_INSTALL_ROOT="$AISTACK_ISOLATED_ROOT/llmfit"
    mkdir -p "${LLMFIT_FEAT_INSTALL_ROOT}"

	export AISTACK_LLMFIT_RUNTIME_REQUIRED=""
    
}

# return 0 : is installed
# return 1 : tool is not installed
# return 2 : missing runtime
llmfit_is_installed() {
	local r
	export AISTACK_LLMFIT_TOOL_AVAILABLE="false"
	for r in ${AISTACK_LLMFIT_RUNTIME_REQUIRED}; do aistack_runtime_is_detected "${r}" || return 2; done
	[ -x "${LLMFIT_FEAT_INSTALL_ROOT}/llmfit" ] || return 1
	export AISTACK_LLMFIT_TOOL_AVAILABLE="true"
	export AISTACK_LLMFIT_TOOL_PATH="${LLMFIT_FEAT_INSTALL_ROOT}/llmfit"
	return 0
}



llmfit_install() {
	local r
  
	for r in ${AISTACK_LLMFIT_RUNTIME_REQUIRED}; do 
		echo "Require needed ${r} managed runtime"
		aistack_runtime_require "${r}"
	done

	echo "Installing llmfit"
	stella_feature_install "llmfit" "NOT_LOADED_IN_PATH"
	llmfit_is_installed
}
 
llmfit_uninstall() {
	if llmfit_is_installed; then
		echo "Uninstalling LLMFIT from ${LLMFIT_FEAT_INSTALL_ROOT}..."
		rm -Rf "${LLMFIT_FEAT_INSTALL_ROOT}"
		echo "LLMFIT uninstalled successfully."

		llmfit_is_installed
	else
		echo "WARN : not installed or missing a required managed runtime $AISTACK_LLMFIT_RUNTIME_REQUIRED"
	fi
}


llmfit_path_register_for_shell() {
    local shell_name="$1"
	if llmfit_is_installed; then
    	path_register_for_shell "llmfit" "${AISTACK_LLMFIT_LAUNCHER_HOME}" "$shell_name"
	fi
}
llmfit_path_unregister_for_shell() {
    local shell_name="${1:-all}"
    path_unregister_for_shell "llmfit" "$shell_name"
}
llmfit_path_register_for_vs_terminal() {
	if llmfit_is_installed; then
    	vscode_path_register_for_vs_terminal "llmfit" "${AISTACK_LLMFIT_LAUNCHER_HOME}"
	fi
}
llmfit_path_unregister_for_vs_terminal() {
    vscode_path_unregister_for_vs_terminal "llmfit" "${AISTACK_LLMFIT_LAUNCHER_HOME}"
}

llmfit_launch_export_variables="LLMFIT_FEAT_INSTALL_ROOT"
llmfit_launch() {


    if [ "$#" -gt 0 ]; then
        "$LLMFIT_FEAT_INSTALL_ROOT/llmfit" "$@"
    else
        "$LLMFIT_FEAT_INSTALL_ROOT/llmfit"
    fi
}

llmfit_launcher_manage() {
    local action="${1:-create}"

    case ${action} in
        create)
			if llmfit_is_installed; then
				# create a compatible POSIX shell script to be called from bash, zsn, fish and wo on
				# and executed by the default /bin/sh on the current system
				{
					echo '#!/bin/sh'
					for v in $llmfit_launch_export_variables; do
						printf 'export %s=%s\n' "$v" "$(shell_quote_posix "${!v}")"
					done

					declare -f llmfit_launch

					echo llmfit_launch \"\$@\"
				} > "${AISTACK_LLMFIT_LAUNCHER_HOME}/llmfit"

				chmod +x "${AISTACK_LLMFIT_LAUNCHER_HOME}/llmfit"
			fi
            ;;

        delete)
            rm -Rf "${AISTACK_LLMFIT_LAUNCHER_HOME}"
			mkdir -p "${AISTACK_LLMFIT_LAUNCHER_HOME}"
            ;;

		refresh_if_exists)
			[ -f "${AISTACK_LLMFIT_LAUNCHER_HOME}/llmfit" ] && ( llmfit_launcher_manage "delete"; llmfit_launcher_manage "create" )
			;;
    esac
}


llmfit_info() {
	echo "LLMFIT available : $AISTACK_LLMFIT_TOOL_AVAILABLE"
	echo "LLMFIT path : $AISTACK_LLMFIT_TOOL_PATH"
	echo "LLMFIT needed managed runtime : $AISTACK_LLMFIT_RUNTIME_REQUIRED"
	echo
}
