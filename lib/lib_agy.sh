agy_init() {

	# Antigravity CLI specific paths
	export AISTACK_ANTIGRAVITY_CONFIG_HOME="${HOME}/.gemini/antigravity-cli"
    export AISTACK_ANTIGRAVITY_CONFIG_FILE="${AISTACK_ANTIGRAVITY_CONFIG_HOME}/settings.json"


	# aistack path for Antigravity CLI
	export AISTACK_ANTIGRAVITY_LAUNCHER_HOME="${AISTACK_LAUNCHER_HOME}/antigravity"
	mkdir -p "${AISTACK_ANTIGRAVITY_LAUNCHER_HOME}"

	export AGY_FEAT_INSTALL_ROOT="$AISTACK_ISOLATED_ROOT/antigravity"
	mkdir -p "${AGY_FEAT_INSTALL_ROOT}"

	export AISTACK_ANTIGRAVITY_RUNTIME_REQUIRED=""
}

# return 0 : is installed
# return 1 : tool is not installed
# return 2 : missing runtime
agy_is_installed() {
	local r
	export AISTACK_ANTIGRAVITY_TOOL_AVAILABLE="false"
	for r in $AISTACK_ANTIGRAVITY_RUNTIME_REQUIRED; do aistack_runtime_is_detected "${r}" || return 2; done
	[ -x "$AGY_FEAT_INSTALL_ROOT/agy" ] || return 1
	export AISTACK_ANTIGRAVITY_TOOL_AVAILABLE="true"
	export AISTACK_ANTIGRAVITY_TOOL_PATH="$AGY_FEAT_INSTALL_ROOT/agy"
	return 0
}



# https://antigravity.google/download
agy_install() {
	local r

	for r in ${AISTACK_ANTIGRAVITY_RUNTIME_REQUIRED}; do 
		echo "Require needed ${r} managed runtime"
		aistack_runtime_require "${r}"
	done

	# use a temporary HOME to avoid rc file modification in HOME
	local tmp_home="$(mktemp -d)"
	curl -fsSL https://antigravity.google/cli/install.sh | HOME="${tmp_home}" bash -s -- --dir "${AGY_FEAT_INSTALL_ROOT}"
	rm -rf "${tmp_home}"

	[ -n "${AISTACK_INIT_FORCE_AGY_GBC}" ] && glibc_binary_compat "agy" "${AGY_FEAT_INSTALL_ROOT}" "${AISTACK_INIT_FORCE_AGY_GBC}"

	agy_is_installed
}



agy_uninstall() {
	if agy_is_installed; then
		echo "Uninstalling Antigravity CLI from ${AGY_FEAT_INSTALL_ROOT}..."
		rm -Rf "${AGY_FEAT_INSTALL_ROOT}"
		echo "Antigravity CLI uninstalled successfully."

		agy_is_installed
	else
		echo "WARN : not installed or missing a required managed runtime $AISTACK_ANTIGRAVITY_RUNTIME_REQUIRED"
	fi
}

agy_path_register_for_shell() {
	local shell_name="$1"
	if agy_is_installed; then
		path_register_for_shell "antigravity" "${AISTACK_ANTIGRAVITY_LAUNCHER_HOME}" "$shell_name"
	fi
}

agy_path_unregister_for_shell() {
	local shell_name="${1:-all}"
	path_unregister_for_shell "antigravity" "$shell_name"
}

agy_path_register_for_vs_terminal() {
	if agy_is_installed; then
		vscode_path_register_for_vs_terminal "antigravity" "${AISTACK_ANTIGRAVITY_LAUNCHER_HOME}"
	fi
}

agy_path_unregister_for_vs_terminal() {
	vscode_path_unregister_for_vs_terminal "antigravity" "${AISTACK_ANTIGRAVITY_LAUNCHER_HOME}"
}

agy_launch_export_variables="AISTACK_RUN_CONTEXT_FILE AGY_FEAT_INSTALL_ROOT"
agy_launch() {
	(
		# antigravity does not need any runtime to be run
		# but we give runtime to it can run some code
        . "${AISTACK_RUN_CONTEXT_FILE}"

		if [ "$#" -gt 0 ]; then
			"$AGY_FEAT_INSTALL_ROOT/agy" "$@"
		else
			"$AGY_FEAT_INSTALL_ROOT/agy"
		fi
	)
}

agy_launcher_manage() {
	local action="${1:-create}"

	case $action in
		create)
			if agy_is_installed; then
				# create a compatible POSIX shell script to be called from bash, zsh, fish and so on
				# and executed by the default /bin/sh on the current system
				{
					echo '#!/bin/sh'
					for v in $agy_launch_export_variables; do
						printf 'export %s=%s\n' "$v" "$(shell_quote_posix "${!v}")"
					done

					declare -f agy_launch

					echo agy_launch \"\$@\"
				} > "${AISTACK_ANTIGRAVITY_LAUNCHER_HOME}/agy"

				chmod +x "${AISTACK_ANTIGRAVITY_LAUNCHER_HOME}/agy"
			fi
			;;

		delete)
			rm -f "${AISTACK_ANTIGRAVITY_LAUNCHER_HOME}/agy"
			;;

		refresh_if_exists)
			[ -f "${AISTACK_ANTIGRAVITY_LAUNCHER_HOME}/agy" ] && ( agy_launcher_manage "delete"; agy_launcher_manage "create" )
			;;
	esac
}

agy_info() {
	echo "Configuration file : $AISTACK_ANTIGRAVITY_CONFIG_FILE"
	echo
	echo "Antigravity CLI available : $AISTACK_ANTIGRAVITY_TOOL_AVAILABLE"
	echo "Antigravity CLI path : $AISTACK_ANTIGRAVITY_TOOL_PATH"
	echo "Antigravity CLI needed managed runtime : $AISTACK_ANTIGRAVITY_RUNTIME_REQUIRED"
	echo "Antigravity CLI install root : $AGY_FEAT_INSTALL_ROOT"
	echo "Antigravity CLI launcher home : $AISTACK_ANTIGRAVITY_LAUNCHER_HOME"
}



agy_show_config() {
    if [ -f "$AISTACK_ANTIGRAVITY_CONFIG_FILE" ]; then
        echo "Current configuration file : $AISTACK_ANTIGRAVITY_CONFIG_FILE"
        cat "$AISTACK_ANTIGRAVITY_CONFIG_FILE"
    else
        echo "No configuration file found. ($AISTACK_ANTIGRAVITY_CONFIG_FILE)"
    fi
}

# generic config management -----------------
agy_settings_configure() {
	echo "add some default settings :"
    echo " - disable statistics usage data send"
    cat "${AISTACK_POOL}/settings/antigravity-cli/settings.json"
    printf "\n"
    merge_json_file "${AISTACK_POOL}/settings/antigravity-cli/settings.json" "${AISTACK_ANTIGRAVITY_CONFIG_FILE}"
}

agy_settings_remove() {
	rm -Rf "$AISTACK_ANTIGRAVITY_CONFIG_HOME"
}


agy_merge_config() {
    local file_to_merge="$1"
    merge_json_file "$file_to_merge" "$AISTACK_ANTIGRAVITY_CONFIG_FILE"
}

agy_remove_config() {
    local key_path="$1"
    json_del_key_from_file "$AISTACK_ANTIGRAVITY_CONFIG_FILE" "$key_path"
}

agy_set_config() {
    local key_path="$1"
    local value="$2"
    json_set_key_into_file "$AISTACK_ANTIGRAVITY_CONFIG_FILE" "$key_path" "$value"
}
