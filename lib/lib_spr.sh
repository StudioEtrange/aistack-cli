spr_init() {

    export AISTACK_SPR_LAUNCHER_HOME="${AISTACK_LAUNCHER_HOME}/spr"
    mkdir -p "${AISTACK_SPR_LAUNCHER_HOME}"


    export SPR_FEAT_INSTALL_ROOT="$AISTACK_ISOLATED_ROOT/spr"
    mkdir -p "${SPR_FEAT_INSTALL_ROOT}"

	export AISTACK_SPR_RUNTIME_REQUIRED="python"
    
}

# return 0 : is installed
# return 1 : tool is not installed
# return 2 : missing runtime
spr_is_installed() {
	local r
	export AISTACK_SPR_TOOL_AVAILABLE="false"
	for r in ${AISTACK_SPR_RUNTIME_REQUIRED}; do aistack_runtime_is_detected "${r}" || return 2; done
	[ -x "${SPR_FEAT_INSTALL_ROOT}/spr" ] || return 1
	export AISTACK_SPR_TOOL_AVAILABLE="true"
	export AISTACK_SPR_TOOL_PATH="${SPR_FEAT_INSTALL_ROOT}/spr"
	return 0
}



spr_install() {
	local r
  
	for r in ${AISTACK_SPR_RUNTIME_REQUIRED}; do 
		echo "Require needed ${r} managed runtime"
		aistack_runtime_require "${r}"
	done

	echo "Installing spr"

	local repo_url="https://github.com/nvidia/skillspector.git"
	
	echo "Cloning skillspector from ${repo_url} to ${SPR_FEAT_INSTALL_ROOT}..."
	git clone "${repo_url}" "${SPR_FEAT_INSTALL_ROOT}/skillspector"
	echo "skillspector cloned successfully."
	
    echo "Installing skillspector requirements..."
    PATH="${AISTACK_RUNTIME_PYTHON_SEARCH_PATH}:${STELLA_ORIGINAL_SYSTEM_PATH}" uv pip install --system -e "${SPR_FEAT_INSTALL_ROOT}/skillspector"
	
	cat << EOF > "${SPR_FEAT_INSTALL_ROOT}/spr"
#!/bin/sh
PYTHONPATH="${SPR_FEAT_INSTALL_ROOT}/skillspector/src" "\$AISTACK_RUNTIME_PYTHON_PATH" -m skillspector.cli "\$@"
EOF
	chmod +x "${SPR_FEAT_INSTALL_ROOT}/spr"

	if spr_is_installed; then
		if [ -n "${AISTACK_INIT_FORCE_SPR_GBC}" ]; then
			glibc_binary_compat "spr" "${SPR_FEAT_INSTALL_ROOT}" "${AISTACK_INIT_FORCE_SPR_GBC}"
		fi
	fi
}
 
spr_uninstall() {
	if spr_is_installed; then
		echo "Uninstalling SPR from ${SPR_FEAT_INSTALL_ROOT}..."
		rm -Rf "${SPR_FEAT_INSTALL_ROOT}"
		echo "SPR uninstalled successfully."

		spr_is_installed
	else
		echo "WARN : not installed or missing a required managed runtime $AISTACK_SPR_RUNTIME_REQUIRED"
	fi
}


spr_path_register_for_shell() {
    local shell_name="$1"
	if spr_is_installed; then
    	path_register_for_shell "spr" "${AISTACK_SPR_LAUNCHER_HOME}" "$shell_name"
	fi
}
spr_path_unregister_for_shell() {
    local shell_name="${1:-all}"
    path_unregister_for_shell "spr" "$shell_name"
}
spr_path_register_for_vs_terminal() {
	if spr_is_installed; then
    	vscode_path_register_for_vs_terminal "spr" "${AISTACK_SPR_LAUNCHER_HOME}"
	fi
}
spr_path_unregister_for_vs_terminal() {
    vscode_path_unregister_for_vs_terminal "spr" "${AISTACK_SPR_LAUNCHER_HOME}"
}

spr_launch_export_variables="SPR_FEAT_INSTALL_ROOT"
spr_launch() {


    if [ "$#" -gt 0 ]; then
        "$SPR_FEAT_INSTALL_ROOT/spr" "$@"
    else
        "$SPR_FEAT_INSTALL_ROOT/spr"
    fi
}

spr_launcher_manage() {
    local action="${1:-create}"

    case ${action} in
        create)
			if spr_is_installed; then
				# create a compatible POSIX shell script to be called from bash, zsn, fish and wo on
				# and executed by the default /bin/sh on the current system
				{
					echo '#!/bin/sh'
					for v in $spr_launch_export_variables; do
						printf 'export %s=%s\n' "$v" "$(shell_quote_posix "${!v}")"
					done

					declare -f spr_launch

					echo spr_launch \"\$@\"
				} > "${AISTACK_SPR_LAUNCHER_HOME}/spr"

				chmod +x "${AISTACK_SPR_LAUNCHER_HOME}/spr"
			fi
            ;;

        delete)
            rm -Rf "${AISTACK_SPR_LAUNCHER_HOME}"
			mkdir -p "${AISTACK_SPR_LAUNCHER_HOME}"
            ;;

		refresh_if_exists)
			[ -f "${AISTACK_SPR_LAUNCHER_HOME}/spr" ] && ( spr_launcher_manage "delete"; spr_launcher_manage "create" )
			;;
    esac
}


spr_info() {
	echo "SPR available : $AISTACK_SPR_TOOL_AVAILABLE"
	echo "SPR path : $AISTACK_SPR_TOOL_PATH"
	echo "SPR needed managed runtime : $AISTACK_SPR_RUNTIME_REQUIRED"
	echo
}

