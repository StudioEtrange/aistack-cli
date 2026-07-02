gsd_init() {
    export AISTACK_GSD_LAUNCHER_HOME="${AISTACK_LAUNCHER_HOME}/gsd"
    mkdir -p "${AISTACK_GSD_LAUNCHER_HOME}"

	export AISTACK_GSD_RUNTIME_REQUIRED="nodejs"
}

# return 0 : is installed
# return 1 : tool is not installed
# return 2 : missing runtime
gsd_is_installed() {
	local r
	export AISTACK_GSD_TOOL_AVAILABLE="false"
	for r in $AISTACK_GSD_RUNTIME_REQUIRED; do aistack_runtime_is_detected "${r}" || return 2; done
	[ -x "$AISTACK_RUNTIME_NODEJS_SEARCH_PATH/gsd-core" ] || return 1
	export AISTACK_GSD_TOOL_PATH=""
	export AISTACK_GSD_TOOL_AVAILABLE="true"
	return 0
}


gsd_install() {
	local r
    #local version="$1"
    [ -z "${version}" ] && version="@latest"

	for r in $AISTACK_GSD_RUNTIME_REQUIRED; do 
		echo "Require needed ${r} managed runtime"
		aistack_runtime_require "${r}"
	done

    echo "Installing gsd"
    # available versions : https://www.npmjs.com/package/@opengsd/gsd-core
    PATH="${AISTACK_RUNTIME_NODEJS_SEARCH_PATH}:${STELLA_ORIGINAL_SYSTEM_PATH}" npx @opengsd/gsd-core -y

	gsd_is_installed
}

gsd_uninstall() {
	if aistack_runtime_is_detected "nodejs"; then
		PATH="${AISTACK_RUNTIME_NODEJS_SEARCH_PATH}:${STELLA_ORIGINAL_SYSTEM_PATH}" npx @opengsd/gsd-core -y --uninstall --global
		gsd_is_installed
	else
		echo "WARN : not installed or missing a required managed runtime $AISTACK_GSD_RUNTIME_REQUIRED"
	fi
}

# gsd_path_register_for_shell() {
#     local shell_name="$1"
# 	if gsd_is_installed; then
#     	path_register_for_shell "gsd" "${AISTACK_GSD_LAUNCHER_HOME}" "$shell_name"
# 	fi
# }
# gsd_path_unregister_for_shell() {
#     local shell_name="${1:-all}"
#     path_unregister_for_shell "gsd" "$shell_name"
# }
# gsd_path_register_for_vs_terminal() {
# 	if gsd_is_installed; then
#     	vscode_path_register_for_vs_terminal "gsd" "${AISTACK_GSD_LAUNCHER_HOME}"
# 	fi
# }
# gsd_path_unregister_for_vs_terminal() {
#     vscode_path_unregister_for_vs_terminal "gsd" "${AISTACK_GSD_LAUNCHER_HOME}"
# }




gsd_launch_export_variables=""
gsd_launch() {
 	:
}

gsd_launcher_manage() {
    :
}


gsd_settings_configure() {
    :
}

gsd_settings_remove() {
    :
}