bmad_init() {
    export AISTACK_BMAD_LAUNCHER_HOME="${AISTACK_LAUNCHER_HOME}/bmad"
    mkdir -p "${AISTACK_BMAD_LAUNCHER_HOME}"

	export AISTACK_BMAD_RUNTIME_REQUIRED="nodejs"

}

# return 0 : is installed
# return 1 : tool is not installed
# return 2 : missing runtime
bmad_is_installed() {
	local r
	export AISTACK_BMAD_TOOL_AVAILABLE="false"
	for r in $AISTACK_BMAD_RUNTIME_REQUIRED; do aistack_runtime_is_detected "${r}" || return 2; done
	[ -x "$AISTACK_RUNTIME_NODEJS_SEARCH_PATH/bmad-method" ] || return 1
	export AISTACK_BMAD_TOOL_PATH="$AISTACK_RUNTIME_NODEJS_SEARCH_PATH/bmad-method"
	export AISTACK_BMAD_TOOL_AVAILABLE="true"
	return 0
}

bmad_install() {
	local r
    # available versions : https://www.npmjs.com/package/bmad-method
    local version="$1"
    [ -z "${version}" ] && version="@latest"

	for r in $AISTACK_BMAD_RUNTIME_REQUIRED; do 
		echo "Require needed ${r} managed runtime"
		aistack_runtime_require "${r}"
	done

    echo "Installing bmad-method ${version}"
	node_package_install "bmad-method${version}"
    #PATH="${AISTACK_RUNTIME_NODEJS_SEARCH_PATH}:${STELLA_ORIGINAL_SYSTEM_PATH}" npm install --verbose -g bmad-method${version}
    bmad_is_installed
}

bmad_uninstall() {
	if bmad_is_installed; then
		node_package_uninstall "bmad-method"
		#PATH="${AISTACK_RUNTIME_NODEJS_SEARCH_PATH}:${STELLA_ORIGINAL_SYSTEM_PATH}" npm uninstall -g bmad-method
		bmad_is_installed
	else
		echo "WARN : not installed or missing a required managed runtime $AISTACK_BMAD_RUNTIME_REQUIRED"
	fi
}


bmad_path_register_for_shell() {
    local shell_name="$1"
	if bmad_is_installed; then
    	path_register_for_shell "bmad" "${AISTACK_BMAD_LAUNCHER_HOME}" "$shell_name"
	fi
}
bmad_path_unregister_for_shell() {
    local shell_name="${1:-all}"
    path_unregister_for_shell "bmad" "$shell_name"
}
bmad_path_register_for_vs_terminal() {
	if bmad_is_installed; then
    	vscode_path_register_for_vs_terminal "bmad" "${AISTACK_BMAD_LAUNCHER_HOME}"
	fi
}
bmad_path_unregister_for_vs_terminal() {
    vscode_path_unregister_for_vs_terminal "bmad" "${AISTACK_BMAD_LAUNCHER_HOME}"
}


bmad_launch_export_variables="AISTACK_RUN_CONTEXT_FILE AISTACK_RUNTIME_NODEJS_SEARCH_PATH"
bmad_launch() {
    (
        . "${AISTACK_RUN_CONTEXT_FILE}"

        # NOTE : we could call "${AISTACK_RUNTIME_NODEJS_SEARCH_PATH}/bmad" instead of bmad-method. Both are link to the same binary
        if [ "$#" -gt 0 ]; then
            "${AISTACK_RUNTIME_NODEJS_SEARCH_PATH}/bmad-method" "$@"
        else
            "${AISTACK_RUNTIME_NODEJS_SEARCH_PATH}/bmad-method"
        fi
    )
}

bmad_launcher_manage() {
    local action="${1:-create}"

    case $action in

        create)
			if bmad_is_installed; then
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
            fi
            ;;

        delete)
            rm -Rf "${AISTACK_BMAD_LAUNCHER_HOME}"
			mkdir -p "${AISTACK_BMAD_LAUNCHER_HOME}"
            ;;

        refresh_if_exists)
			[ -f "${AISTACK_BMAD_LAUNCHER_HOME}/bmad-method" ] && ( bmad_launcher_manage "delete"; bmad_launcher_manage "create" )
            ;;
    esac
    
}


bmad_settings_configure() {
    :
}

bmad_settings_remove() {
    :
}