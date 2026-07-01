asm_init() {
	export AISTACK_ASM_CONFIG_HOME="${HOME}/.config/agent-skill-manager"
	mkdir -p "${AISTACK_ASM_CONFIG_HOME}"
	export AISTACK_ASM_CONFIG_FILE="${AISTACK_ASM_CONFIG_HOME}/settings.json"

	# aistack path for asm
	export AISTACK_ASM_LAUNCHER_HOME="${AISTACK_LAUNCHER_HOME}/asm"
	mkdir -p "${AISTACK_ASM_LAUNCHER_HOME}"

	#export AISTACK_ASM_RUNTIME_REQUIRED="bun"
	export AISTACK_ASM_RUNTIME_REQUIRED="nodejs"

}

# return 0 : is installed
# return 1 : tool is not installed
# return 2 : missing runtime
asm_is_installed() {
	local r
	export AISTACK_ASM_TOOL_AVAILABLE="false"
	for r in $AISTACK_ASM_RUNTIME_REQUIRED; do aistack_runtime_is_detected "${r}" || return 2; done
	[ -x "$AISTACK_RUNTIME_NODEJS_SEARCH_PATH/asm" ] || return 1
	export AISTACK_ASM_TOOL_PATH="$AISTACK_RUNTIME_NODEJS_SEARCH_PATH/asm"
	export AISTACK_ASM_TOOL_AVAILABLE="true"
	return 0
}

asm_install() {
	local r
	local version="$1"
	[ -z "${version}" ] && version="@latest"

	for r in $AISTACK_ASM_RUNTIME_REQUIRED; do 
		echo "Require needed ${r} managed runtime"
		aistack_runtime_require "${r}"
	done

	echo "Installing Agent Skill Manager ${version}"
	PATH="${AISTACK_RUNTIME_NODEJS_SEARCH_PATH}:${STELLA_ORIGINAL_SYSTEM_PATH}" npm install --verbose -g agent-skill-manager${version}
	# using bun package manager
	# PATH="${AISTACK_RUNTIME_BUN_SEARCH_PATH}:${STELLA_ORIGINAL_SYSTEM_PATH}" bun add --verbose -g agent-skill-manager${version}
	asm_is_installed
}

asm_uninstall() {
	if asm_is_installed; then
		PATH="${AISTACK_RUNTIME_NODEJS_SEARCH_PATH}:${STELLA_ORIGINAL_SYSTEM_PATH}" npm uninstall -g agent-skill-manager
		# using bun package manager
		# PATH="${AISTACK_RUNTIME_BUN_SEARCH_PATH}:${STELLA_ORIGINAL_SYSTEM_PATH}" bun remove -g agent-skill-manager
		asm_is_installed
	else
		echo "WARN : not installed or missing a required managed runtime $AISTACK_ASM_RUNTIME_REQUIRED"
	fi
}

asm_path_register_for_shell() {
	local shell_name="$1"
	if asm_is_installed; then
		path_register_for_shell "asm" "${AISTACK_ASM_LAUNCHER_HOME}" "$shell_name"
	fi
}
asm_path_unregister_for_shell() {
    local shell_name="${1:-all}"
	path_unregister_for_shell "asm" "$shell_name"
}
asm_path_register_for_vs_terminal() {
	if asm_is_installed; then
		vscode_path_register_for_vs_terminal "asm" "${AISTACK_ASM_LAUNCHER_HOME}"
	fi
}
asm_path_unregister_for_vs_terminal() {
	vscode_path_unregister_for_vs_terminal "asm" "${AISTACK_ASM_LAUNCHER_HOME}"
}


asm_launch_export_variables="AISTACK_RUN_CONTEXT_FILE AISTACK_RUNTIME_NODEJS_SEARCH_PATH"
asm_launch() {
	(
		. "${AISTACK_RUN_CONTEXT_FILE}"

		if [ "$#" -gt 0 ]; then
			"$AISTACK_RUNTIME_NODEJS_SEARCH_PATH/asm" "$@"
		else
			"$AISTACK_RUNTIME_NODEJS_SEARCH_PATH/asm"
		fi
	)
}

asm_launcher_manage() {
	local action="${1:-create}"

	case $action in
		create)
			if asm_is_installed; then
				# create a compatible POSIX shell script to be called from bash, zsn, fish and wo on
				# and executed by the default /bin/sh on the current system
				{
					echo '#!/bin/sh'
					for v in $asm_launch_export_variables; do
						printf 'export %s=%s\n' "$v" "$(shell_quote_posix "${!v}")"
					done

					declare -f asm_launch

					echo asm_launch \"\$@\"
				} > "${AISTACK_ASM_LAUNCHER_HOME}/asm"

				chmod +x "${AISTACK_ASM_LAUNCHER_HOME}/asm"
			fi
			;;

		delete)
			rm -f "${AISTACK_ASM_LAUNCHER_HOME}/asm"
			;;

		refresh_if_exists)
			[ -f "${AISTACK_ASM_LAUNCHER_HOME}/asm" ] && ( asm_launcher_manage "delete"; asm_launcher_manage "create" )
			;;
	esac
}


asm_show_config() {
	if [ -f "$AISTACK_ASM_CONFIG_FILE" ]; then
		echo "Current asm configuration file : $AISTACK_ASM_CONFIG_FILE"
		cat "$AISTACK_ASM_CONFIG_FILE"
	else
		echo "No asm configuration file found."
	fi
}


asm_settings_configure() {
	:
}

asm_settings_remove() {
	rm -Rf "$AISTACK_ASM_CONFIG_HOME"
}
