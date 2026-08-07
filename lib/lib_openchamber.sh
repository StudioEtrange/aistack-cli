openchamber_init() {
	[ -n "${OPENCHAMBER_DATA_DIR}" ] && export AISTACK_OPENCHAMBER_CONFIG_HOME="${OPENCHAMBER_DATA_DIR}" || export AISTACK_OPENCHAMBER_CONFIG_HOME="${HOME}/.config/openchamber"
	mkdir -p "${AISTACK_OPENCHAMBER_CONFIG_HOME}"
	export AISTACK_OPENCHAMBER_UI_PASSWORD_FILE="${AISTACK_OPENCHAMBER_CONFIG_HOME}/ui-password"
	export AISTACK_OPENCHAMBER_LAUNCHER_HOME="${AISTACK_LAUNCHER_HOME}/openchamber"
	mkdir -p "${AISTACK_OPENCHAMBER_LAUNCHER_HOME}"

	export AISTACK_OPENCHAMBER_RUNTIME_REQUIRED="nodejs"
	export AISTACK_OPENCHAMBER_MODULE_REQUIRED=""
}

# return 0 : is installed
# return 1 : tool is not installed
# return 2 : missing runtime
openchamber_is_installed() {
	local r m
	export AISTACK_OPENCHAMBER_TOOL_AVAILABLE="false"
	for r in ${AISTACK_OPENCHAMBER_RUNTIME_REQUIRED}; do aistack_runtime_is_detected "${r}" || return 2; done
	for m in ${AISTACK_OPENCHAMBER_MODULE_REQUIRED}; do aistack_module_is_detected "${m}" || return 2; done
	opencode_is_installed || return 2

	[ -x "${AISTACK_RUNTIME_NODEJS_SEARCH_PATH}/openchamber" ] || return 1
	export AISTACK_OPENCHAMBER_TOOL_PATH="${AISTACK_RUNTIME_NODEJS_SEARCH_PATH}/openchamber"
	export AISTACK_OPENCHAMBER_TOOL_AVAILABLE="true"
	return 0
}

openchamber_install() {
	local r m
	local version="$1"
	[ -z "${version}" ] && version="@latest"

	for r in ${AISTACK_OPENCHAMBER_RUNTIME_REQUIRED}; do
		echo "INFO: OpenChamber requires ${r} managed runtime"
		aistack_runtime_require "${r}" || return $?
	done

	for m in ${AISTACK_OPENCHAMBER_MODULE_REQUIRED}; do 
		echo "INFO: OpenChamber require ${m} managed module"
		aistack_module_require "${m}"
	done

	
	if ! opencode_is_installed; then
		echo "ERROR: OpenChamber requires OpenCode. Install it with 'aistack oc install'."
		return 1
	fi


	echo "Installing OpenChamber CLI/Web ${version}"
	node_package_install --allow-scripts=node-pty "@openchamber/web${version}" || return $?

	openchamber_settings_ui_password_reset || return $?
	openchamber_settings_ui_password_create || return $?

	openchamber_is_installed
	return $?
}

openchamber_uninstall() {
	if openchamber_is_installed; then
		openchamber_daemon_down >/dev/null 2>&1 || :
		
		node_package_uninstall "@openchamber/web"
	
		openchamber_is_installed
	else
		echo "WARN: not installed or missing a required managed runtime ${AISTACK_OPENCHAMBER_RUNTIME_REQUIRED}"
	fi
}



openchamber_path_register_for_shell() {
	local shell_name="$1"
	if openchamber_is_installed; then
		path_register_for_shell "openchamber" "${AISTACK_OPENCHAMBER_LAUNCHER_HOME}" "${shell_name}"
	fi
}

openchamber_path_unregister_for_shell() {
	local shell_name="${1:-all}"
	path_unregister_for_shell "openchamber" "${shell_name}"
}

openchamber_path_register_for_vs_terminal() {
	if openchamber_is_installed; then
		vscode_path_register_for_vs_terminal "openchamber" "${AISTACK_OPENCHAMBER_LAUNCHER_HOME}"
	fi
}

openchamber_path_unregister_for_vs_terminal() {
	vscode_path_unregister_for_vs_terminal "openchamber" "${AISTACK_OPENCHAMBER_LAUNCHER_HOME}"
}

openchamber_launch_export_variables="AISTACK_TOOL_CONTEXT_FILE AISTACK_RUNTIME_NODEJS_SEARCH_PATH AISTACK_OPENCHAMBER_TOOL_PATH AISTACK_OPENCODE_TOOL_PATH OPENCODE_BINARY OPENCHAMBER_DATA_DIR AISTACK_OPENCHAMBER_CONFIG_HOME AISTACK_OPENCHAMBER_UI_PASSWORD_FILE"
openchamber_launch() {
	(
		. "${AISTACK_TOOL_CONTEXT_FILE}"

		# TODO review this line and var AISTACK_OPENCODE_TOOL_PATH
		[ -n "${AISTACK_OPENCODE_TOOL_PATH}" ] && export OPENCODE_BINARY="${AISTACK_OPENCODE_TOOL_PATH}"

		export OPENCHAMBER_DATA_DIR="${AISTACK_OPENCHAMBER_CONFIG_HOME}"

		if [ "$#" -gt 0 ]; then
			"$AISTACK_RUNTIME_NODEJS_SEARCH_PATH/openchamber" "$@"
		else
			"$AISTACK_RUNTIME_NODEJS_SEARCH_PATH/openchamber"
		fi

	)
}

openchamber_daemon_up() {
	local arg ui_password

	if ! opencode_is_installed; then
		echo "ERROR: OpenChamber requires OpenCode. Install it with 'aistack oc install'."
		return 1
	fi

	if [ ! -s "${AISTACK_OPENCHAMBER_UI_PASSWORD_FILE}" ]; then
		openchamber_settings_ui_password_create || return $?
	fi

	for arg in "$@"; do
		case "${arg}" in
			--ui-password|--ui-password=*)
				echo "ERROR: OpenChamber UI password is managed in ${AISTACK_OPENCHAMBER_UI_PASSWORD_FILE}" >&2
				return 1
				;;
		esac
	done

	ui_password="$(openchamber_settings_ui_password_get)"
	[ -n "${ui_password}" ] || {
		echo "ERROR: OpenChamber UI password is empty" >&2
		return 1
	}

	OPENCHAMBER_UI_PASSWORD="${ui_password}" openchamber_launch serve "$@"
}

openchamber_daemon_down() {
	openchamber_launch stop "$@"
}

openchamber_daemon_status() {
	openchamber_launch status "$@"
}

openchamber_daemon_logs() {
	openchamber_launch logs "$@"
}

openchamber_daemon_restart() {
	local arg ui_password

	if [ ! -s "${AISTACK_OPENCHAMBER_UI_PASSWORD_FILE}" ]; then
		openchamber_settings_ui_password_create || return $?
	fi

	for arg in "$@"; do
		case "${arg}" in
			--ui-password|--ui-password=*)
				echo "ERROR: OpenChamber UI password is managed in ${AISTACK_OPENCHAMBER_UI_PASSWORD_FILE}" >&2
				return 1
				;;
		esac
	done

	ui_password="$(openchamber_settings_ui_password_get)"
	[ -n "${ui_password}" ] || {
		echo "ERROR: OpenChamber UI password is empty" >&2
		return 1
	}

	OPENCHAMBER_UI_PASSWORD="${ui_password}" openchamber_launch restart "$@"
}

openchamber_settings_ui_password_reset() {
	: > "${AISTACK_OPENCHAMBER_UI_PASSWORD_FILE}"
}

openchamber_settings_ui_password_create() {
	local password

	password="$("${STELLA_API}" generate_password 12 "[:alnum:]")" || return $?
	openchamber_settings_ui_password_set "${password}" || return $?
	echo "New OpenChamber UI password created : ${password}"
}

openchamber_settings_ui_password_set() {
	local password="$1"

	[ -n "${password}" ] || {
		echo "ERROR: OpenChamber UI password cannot be empty" >&2
		return 1
	}

	printf '%s\n' "${password}" > "${AISTACK_OPENCHAMBER_UI_PASSWORD_FILE}" || return $?
	chmod 600 "${AISTACK_OPENCHAMBER_UI_PASSWORD_FILE}" 2>/dev/null || :
}

openchamber_settings_ui_password_get() {
	[ -f "${AISTACK_OPENCHAMBER_UI_PASSWORD_FILE}" ] && cat "${AISTACK_OPENCHAMBER_UI_PASSWORD_FILE}"
}

openchamber_version() {
	openchamber_launch --version
}

openchamber_launcher_manage() {
	local action="${1:-create}"

	case "${action}" in
		create)
			if openchamber_is_installed; then
				{
					echo '#!/bin/sh'
					for v in ${openchamber_launch_export_variables}; do
						printf '[ -n "$%s" ] && export %s="$%s" || export %s=%s\n' "${v}" "${v}" "${v}" "${v}" "$(shell_quote_posix "${!v}")"
					done

					declare -f openchamber_launch

					echo openchamber_launch \"\$@\"
				} > "${AISTACK_OPENCHAMBER_LAUNCHER_HOME}/openchamber"

				chmod +x "${AISTACK_OPENCHAMBER_LAUNCHER_HOME}/openchamber"
			fi
			;;
		delete)
			rm -Rf "${AISTACK_OPENCHAMBER_LAUNCHER_HOME}"
			mkdir -p "${AISTACK_OPENCHAMBER_LAUNCHER_HOME}"
			;;
		refresh_if_exists)
			[ -f "${AISTACK_OPENCHAMBER_LAUNCHER_HOME}/openchamber" ] && ( openchamber_launcher_manage "delete"; openchamber_launcher_manage "create" )
			;;
	esac
}

openchamber_info() {
	echo "OpenChamber CLI/Web available : ${AISTACK_OPENCHAMBER_TOOL_AVAILABLE}"
	echo "OpenChamber CLI/Web path : ${AISTACK_OPENCHAMBER_TOOL_PATH}"
	echo "OpenChamber configuration home : ${AISTACK_OPENCHAMBER_CONFIG_HOME}"
	echo "OpenChamber UI password file : ${AISTACK_OPENCHAMBER_UI_PASSWORD_FILE}"
	echo "OpenChamber UI password : $(openchamber_settings_ui_password_get)"
	echo "OpenChamber needed managed runtime : ${AISTACK_OPENCHAMBER_RUNTIME_REQUIRED}"
	echo "OpenCode available : ${AISTACK_OPENCODE_TOOL_AVAILABLE}"
	echo "OpenCode path : ${AISTACK_OPENCODE_TOOL_PATH}"
}
