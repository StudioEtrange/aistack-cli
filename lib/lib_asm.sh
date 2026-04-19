asm_path() {
	export AISTACK_ASM_CONFIG_HOME="${HOME}/.config/agent-skill-manager"
	mkdir -p "${AISTACK_ASM_CONFIG_HOME}"
	export AISTACK_ASM_CONFIG_FILE="${AISTACK_ASM_CONFIG_HOME}/settings.json"

	# aistack path for asm
	export AISTACK_ASM_LAUNCHER_HOME="${AISTACK_LAUNCHER_HOME}/asm"
	mkdir -p "${AISTACK_ASM_LAUNCHER_HOME}"
}

# add asm launcher in path for shell
asm_path_register_for_shell() {
	local shell_name="$1"
	path_register_for_shell "asm" "$shell_name" "${AISTACK_ASM_LAUNCHER_HOME}"
}
asm_path_unregister_for_shell() {
	local shell_name="$1"
	path_unregister_for_shell "asm" "$shell_name"
}
asm_path_register_for_vs_terminal() {
	vscode_path_register_for_vs_terminal "asm" "${AISTACK_ASM_LAUNCHER_HOME}"
}
asm_path_unregister_for_vs_terminal() {
	vscode_path_unregister_for_vs_terminal "asm" "${AISTACK_ASM_LAUNCHER_HOME}"
}

asm_install() {
	local version="$1"
	[ -z "${version}" ] && version="@latest"

	echo "Installing Agent Skill Manager ${version}"
	PATH="${AISTACK_NODEJS_BIN_PATH}:${STELLA_ORIGINAL_SYSTEM_PATH}" npm install --verbose -g agent-skill-manager${version}
	# using bun package manager
	# PATH="${AISTACK_BUN_BIN_PATH}:${STELLA_ORIGINAL_SYSTEM_PATH}" bun add --verbose -g agent-skill-manager${version}
}

asm_uninstall() {
	PATH="${AISTACK_NODEJS_BIN_PATH}:${STELLA_ORIGINAL_SYSTEM_PATH}" npm uninstall -g agent-skill-manager
	# using bun package manager
	# PATH="${AISTACK_BUN_BIN_PATH}:${STELLA_ORIGINAL_SYSTEM_PATH}" bun remove -g agent-skill-manager
}

asm_launch_export_variables="AISTACK_RUNTIME_PATH_FILE AISTACK_NODEJS_BIN_PATH"
asm_launch() {
	set -- "$@"

	(
		. "${AISTACK_RUNTIME_PATH_FILE}"

		if [ "$#" -gt 0 ]; then
			"$AISTACK_NODEJS_BIN_PATH/asm" "$@"
		else
			"$AISTACK_NODEJS_BIN_PATH/asm"
		fi
	)
}

asm_launcher_manage() {
	local action="${1:-create}"

	case $action in
		create)
			{
				echo '#!/bin/sh'
				for v in $asm_launch_export_variables; do
					printf '%s=%s\n' "$v" "$(shell_quote_posix "${!v}")"
				done

				declare -f asm_launch

				echo asm_launch \"\$@\"
			} > "${AISTACK_ASM_LAUNCHER_HOME}/asm"

			chmod +x "${AISTACK_ASM_LAUNCHER_HOME}/asm"
			;;
		delete)
			rm -f "${AISTACK_ASM_LAUNCHER_HOME}/asm"
			;;
	esac
}

asm_settings_configure() {
	:
}

asm_settings_remove() {
	rm -Rf "$AISTACK_ASM_CONFIG_HOME"
}

asm_show_config() {
	if [ -f "$AISTACK_ASM_CONFIG_FILE" ]; then
		echo "Current asm configuration file : $AISTACK_ASM_CONFIG_FILE"
		cat "$AISTACK_ASM_CONFIG_FILE"
	else
		echo "No asm configuration file found."
	fi
}
