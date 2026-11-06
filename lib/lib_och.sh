
openchamber_init() {
	# openchamber specific variables
	export AISTACK_OPENCHAMBER_CONFIG_HOME="${OPENCHAMBER_DATA_DIR:-${HOME}/.config/openchamber}"
	mkdir -p "${AISTACK_OPENCHAMBER_CONFIG_HOME}" || return $?
	export AISTACK_OPENCHAMBER_CONFIG_FILE="${AISTACK_OPENCHAMBER_CONFIG_HOME}/settings.json"
	export OPENCHAMBER_FEAT_INSTALL_ROOT="${AISTACK_ISOLATED_ROOT}/openchamber"
	mkdir -p "${OPENCHAMBER_FEAT_INSTALL_ROOT}"
	
	export AISTACK_OPENCHAMBER_UI_PASSWORD_FILE="${AISTACK_OPENCHAMBER_CONFIG_HOME}/ui-password"
	[ -f "${AISTACK_OPENCHAMBER_UI_PASSWORD_FILE}" ] && export AISTACK_OPENCHAMBER_UI_PASSWORD="$(cat "$AISTACK_OPENCHAMBER_UI_PASSWORD_FILE")"


	# openchamber launcher
	export AISTACK_OPENCHAMBER_LAUNCHER_HOME="${AISTACK_LAUNCHER_HOME}/openchamber"
	mkdir -p "${AISTACK_OPENCHAMBER_LAUNCHER_HOME}"
	export AISTACK_OPENCHAMBER_LAUNCHER_FILE="${AISTACK_OPENCHAMBER_LAUNCHER_HOME}/openchamber"

	# openchamber context
	export AISTACK_OPENCHAMBER_CONTEXT_HOME="${AISTACK_CONTEXT_HOME}/openchamber"
	mkdir -p "${AISTACK_OPENCHAMBER_CONTEXT_HOME}"
	export AISTACK_OPENCHAMBER_CONTEXT_FILE="${AISTACK_OPENCHAMBER_CONTEXT_HOME}/openchamber_context.sh"
	# any variables needed to run this component or used by _launch function
	# NOTE: do not need to declare those variables:
	#		AISTACK_*_CONTEXT_FILE and AISTACK_GENERIC_CONTEXT_FILE are already exported
	#		every *_SEARCH_PATH variable related to a REQUIRED_RUNTIME or REQUIRED_MODULE are already exported
	export AISTACK_OPENCHAMBER_CONTEXT_EXPORT_VARIABLES="AISTACK_OPENCHAMBER_TOOL_PATH AISTACK_OPENCHAMBER_CONFIG_HOME AISTACK_OPENCHAMBER_UI_PASSWORD AISTACK_OPENCODE_LAUNCHER_HOME AISTACK_OPENCODE_LAUNCHER_FILE"

	# openchamber requirements - those will be installed and presence checked to run the current component
	# NOTE:	those search path will be injected in context file
	export AISTACK_OPENCHAMBER_RUNTIME_REQUIRED="nodejs"
	export AISTACK_OPENCHAMBER_MODULE_REQUIRED=""
	# remove from context any runtime or module any item already in generic aistack context
	export AISTACK_OPENCHAMBER_RUNTIME_REQUIRED_IN_CONTEXT="$($STELLA_API filter_list_with_list "${AISTACK_OPENCHAMBER_RUNTIME_REQUIRED}" "${AISTACK_GENERIC_CONTEXT_ADD_RUNTIME}")"
	export AISTACK_OPENCHAMBER_MODULE_REQUIRED_IN_CONTEXT="$($STELLA_API filter_list_with_list "${AISTACK_OPENCHAMBER_MODULE_REQUIRED}" "${AISTACK_GENERIC_CONTEXT_ADD_MODULE}")"
}

# test if openchamber is installed
# return 0 : is installed
# return 1 : tool is not installed
# return 2 : missing runtime
openchamber_is_installed() {
	local r m
	export AISTACK_OPENCHAMBER_TOOL_AVAILABLE="false"
	export AISTACK_OPENCHAMBER_TOOL_SEARCH_PATH=""
	export AISTACK_OPENCHAMBER_TOOL_PATH=""
	for r in ${AISTACK_OPENCHAMBER_RUNTIME_REQUIRED}; do aistack_runtime_is_detected "${r}" || return 2; done
	for m in ${AISTACK_OPENCHAMBER_MODULE_REQUIRED}; do aistack_module_is_detected "${m}" || return 2; done
	[ -x "${OPENCHAMBER_FEAT_INSTALL_ROOT}/bin/openchamber" ] || return 1
	export AISTACK_OPENCHAMBER_TOOL_AVAILABLE="true"
	export AISTACK_OPENCHAMBER_TOOL_SEARCH_PATH="${OPENCHAMBER_FEAT_INSTALL_ROOT}/bin"
	export AISTACK_OPENCHAMBER_TOOL_PATH="${AISTACK_OPENCHAMBER_TOOL_SEARCH_PATH}/openchamber"
	return 0
}


openchamber_install() {
	local r m
	local version="${1:-@latest}"

	for r in ${AISTACK_OPENCHAMBER_RUNTIME_REQUIRED}; do 
		echo "INFO: require ${r} managed runtime"
		aistack_runtime_require "${r}"
	done

	for m in ${AISTACK_OPENCHAMBER_MODULE_REQUIRED}; do 
		echo "INFO: require ${m} managed module"
		aistack_module_require "${m}"
	done

	echo "INFO: Installing OpenChamber ${version}"
	node_isolated_package_install "${OPENCHAMBER_FEAT_INSTALL_ROOT}" --allow-scripts="@openchamber/web" "@openchamber/web${version}" || return $?
	openchamber_is_installed

	return $?
}

openchamber_uninstall() {
	if openchamber_is_installed; then

		openchamber_server_down || :
		node_isolated_package_uninstall "${OPENCHAMBER_FEAT_INSTALL_ROOT}" --allow-scripts="@openchamber/web" "@openchamber/web" || return $?
		rm -Rf "${OPENCHAMBER_FEAT_INSTALL_ROOT}"
		openchamber_is_installed && return 1
		return 0
	else
		echo "WARN: OpenChamber is not installed or its managed Node.js runtime is missing"
	fi
}

openchamber_path_register_for_shell() {
	local shell_name="${1:-current}"
	if openchamber_is_installed; then
		register_path_named_bloc_for_shell "openchamber" "${AISTACK_OPENCHAMBER_LAUNCHER_HOME}" "$shell_name"
	fi
}
openchamber_path_unregister_for_shell() {
    local shell_name="${1:-all}"
	unregister_path_named_bloc_for_shell "openchamber" "$shell_name"
}
openchamber_path_register_for_vs_terminal() {
	if openchamber_is_installed; then
		vscode_path_register_for_vs_terminal "openchamber" "${AISTACK_OPENCHAMBER_LAUNCHER_HOME}"
	fi
}
openchamber_path_unregister_for_vs_terminal() {
	vscode_path_unregister_for_vs_terminal "openchamber" "${AISTACK_OPENCHAMBER_LAUNCHER_HOME}"
}


# todo review this if only use desktop independently and och connect command alone
openchamber_launch() {
	(
		[ ! -f "${AISTACK_GENERIC_CONTEXT_FILE}" ] || . "${AISTACK_GENERIC_CONTEXT_FILE}" || return $?
		[ ! -f "${AISTACK_OPENCHAMBER_CONTEXT_FILE}" ] || . "${AISTACK_OPENCHAMBER_CONTEXT_FILE}" || return $?
		
		"${AISTACK_OPENCHAMBER_TOOL_PATH}" "${@}"
	)
}

openchamber_launcher_and_context_files_manage() {
    local action="${1:-create}"

	case ${action} in
		create)
			if openchamber_is_installed; then
				# GENERATE CONTEXT FILE ----
				openchamber_context_file_generate
				
				# GENERATE LAUNCHER FILE ----
				{
					echo '#!/bin/sh'

					printf 'export %s=%s\n' "AISTACK_GENERIC_CONTEXT_FILE" "$(shell_quote_posix "${AISTACK_GENERIC_CONTEXT_FILE}")"
					printf 'export %s=%s\n' "AISTACK_OPENCHAMBER_CONTEXT_FILE" "$(shell_quote_posix "${AISTACK_OPENCHAMBER_CONTEXT_FILE}")"

					declare -f openchamber_launch

					echo openchamber_launch \"\$@\"
				} > "${AISTACK_OPENCHAMBER_LAUNCHER_FILE}"

				chmod +x "${AISTACK_OPENCHAMBER_LAUNCHER_FILE}"
			fi
            ;;
        delete)
			rm -Rf "${AISTACK_OPENCHAMBER_LAUNCHER_HOME}"
			mkdir -p "${AISTACK_OPENCHAMBER_LAUNCHER_HOME}"
			openchamber_context_file_generate_remove
            ;;
		refresh_if_exists)
			[ -f "${AISTACK_OPENCHAMBER_LAUNCHER_FILE}" ] && ( openchamber_launcher_and_context_files_manage "delete"; openchamber_launcher_and_context_files_manage "create" )
			;;
    esac
}


openchamber_context_file_generate() {
	# GENERATE CONTEXT FILE ----
	echo '#!/bin/sh' > "${AISTACK_OPENCHAMBER_CONTEXT_FILE}"
	chmod +x "${AISTACK_OPENCHAMBER_CONTEXT_FILE}"

	# VARIABLES
	aistack_context_file_export_variables "${AISTACK_OPENCHAMBER_CONTEXT_FILE}" "${AISTACK_OPENCHAMBER_CONTEXT_EXPORT_VARIABLES}"
	export OPENCHAMBER_DATA_DIR="${AISTACK_OPENCHAMBER_CONFIG_HOME}"
	export OPENCHAMBER_UI_PASSWORD="${AISTACK_OPENCHAMBER_UI_PASSWORD}"
	aistack_context_file_export_variables "${AISTACK_OPENCHAMBER_CONTEXT_FILE}" "${AISTACK_OPENCHAMBER_CONTEXT_EXPORT_VARIABLES} OPENCHAMBER_DATA_DIR OPENCHAMBER_UI_PASSWORD"

	# PATH
	local m r list_path
	for r in ${AISTACK_OPENCHAMBER_RUNTIME_REQUIRED_IN_CONTEXT}; do list_path="$(aistack_component_get_search_path "runtime" "${r}" "VARIABLE_LIST") ${list_path}"; done
	for m in ${AISTACK_OPENCHAMBER_MODULE_REQUIRED_IN_CONTEXT}; do list_path="$(aistack_component_get_search_path "module" "${m}" "VARIABLE_LIST") ${list_path}"; done
	aistack_context_file_export_path "${AISTACK_OPENCHAMBER_CONTEXT_FILE}" "${list_path}" "VARIABLE_LIST"

}

openchamber_context_file_generate_remove() {
	rm -f "${AISTACK_OPENCHAMBER_CONTEXT_FILE}"
}

openchamber_info() {
	echo "OpenChamber available : ${AISTACK_OPENCHAMBER_TOOL_AVAILABLE}"
	echo "OpenChamber CLI path : ${AISTACK_OPENCHAMBER_TOOL_PATH}"
	echo "OpenChamber needed managed runtime : ${AISTACK_OPENCHAMBER_RUNTIME_REQUIRED}"
	echo "OpenChamber needed managed module : ${AISTACK_OPENCHAMBER_MODULE_REQUIRED}"
	echo "OpenChamber install root : ${OPENCHAMBER_FEAT_INSTALL_ROOT}"
	echo "OpenChamber launcher : ${AISTACK_OPENCHAMBER_LAUNCHER_FILE}"
	echo "OpenChamber context file : ${AISTACK_OPENCHAMBER_CONTEXT_FILE}"
	echo "OpenChamber Configuration file : ${AISTACK_OPENCHAMBER_CONFIG_FILE}"
	echo "OpenChamber UI password file : ${AISTACK_OPENCHAMBER_UI_PASSWORD_FILE}"
	echo
    [ -n "$AISTACK_OPENCHAMBER_UI_PASSWORD" ] && echo "OpenChamber UI password : $AISTACK_OPENCHAMBER_UI_PASSWORD (from file : $AISTACK_OPENCHAMBER_UI_PASSWORD_FILE)" || \
        echo "No OpenChamber UI password"
}

# generic config management -----------------
openchamber_show_config() {
    if [ -f "$AISTACK_OPENCHAMBER_CONFIG_FILE" ]; then
        cat "$AISTACK_OPENCHAMBER_CONFIG_FILE"
    else
        echo "No configuration file found. ($AISTACK_OPENCHAMBER_CONFIG_FILE)"
    fi
}

openchamber_settings_configure() {
	openchamber_settings_ui_password_create
}

openchamber_settings_remove() {
	rm -Rf "$AISTACK_OPENCHAMBER_CONFIG_HOME"
}


openchamber_merge_config() {
    local file_to_merge="$1"
    merge_json_file "$file_to_merge" "$AISTACK_OPENCHAMBER_CONFIG_FILE"
}

openchamber_remove_config() {
    local key_path="$1"
    json_del_key_from_file "$AISTACK_OPENCHAMBER_CONFIG_FILE" "$key_path"
}

openchamber_set_config() {
    local key_path="$1"
    local value="$2"
    json_set_key_into_file "$AISTACK_OPENCHAMBER_CONFIG_FILE" "$key_path" "$value"
}


# integration  management -----------------
openchamber_connect_to_aistack() {
	local shell_name_list="${1:-current}"
	local result

	# generate openchamber context file
	openchamber_context_file_generate || return $?
	
	# register a shell hook that loads the openchamber context file when openchamber desktop, web or ssh, launch a selected shell with its builtin terminal
	# Load the OpenChamber context file when OPENCHAMBER_RUNTIME is setted in such process launched by OpenChamber.
	# This allows for openchamber to use aistack managed tools and runtime
	openchamber_context_load_register_for_shell "${shell_name_list}" || return $?

	# OpenChamber VS Code extension does not set OPENCHAMBER_RUNTIME.
	# openchamber vs code extension using the opencode launcher loads the OpenCode context file for the OpenCode server and its child processes.
	# This allows for opencode used by openchamber to use aistack managed tools and runtime

	# force openchamber to use opencode from aistack
	if opencode_is_installed; then
		# NOTE : to locate opencode binary we do prefer explicit settings in settings file over relying on OPENCODE_BINARY
		# openchamber setting file shared setting used by Desktop, Web and the VS Code extension
		openchamber_set_config "opencodeBinary" "\"${AISTACK_OPENCODE_LAUNCHER_FILE}\""

		# configure openchamber vscode extension to use opencode launcher file
		# for openchamber vscode extension "openchamber.opencodeBinary" vscode settings have priority over "opencodeBinary" regular openchamber config file
		if [ -n "${AISTACK_VSCODE_CONFIG_FILE}" ]; then
			vscode_set_config "openchamber\.opencodeBinary" "\"${AISTACK_OPENCODE_LAUNCHER_FILE}\""
		fi

		# TODO : this is not persitent ! need to redo it after each openchamber_launcher_and_context_files_manage call
		# modify openchamber context file to inject opencode related variables and search PATH
		export OPENCODE_BINARY="${AISTACK_OPENCODE_LAUNCHER_FILE}"
		aistack_context_file_export_variables "${AISTACK_OPENCHAMBER_CONTEXT_FILE}" "OPENCODE_BINARY"
		aistack_context_file_export_path "${AISTACK_OPENCHAMBER_CONTEXT_FILE}" "AISTACK_OPENCODE_LAUNCHER_HOME" "VARIABLE_LIST"
	fi
}



openchamber_disconnect_aistack() {
	local shell_name_list="${1:-all}"
	local name="aistack-openchamber-connect"
	unregister_named_bloc_for_shell "${name}" "${shell_name_list}"

	openchamber_remove_config "opencodeBinary"
	vscode_remove_config "openchamber\.opencodeBinary"
}

# TODO what is this
# allow to inject openchamber context files in shell launched by openchamber builtin terminal
# env var OPENCHAMBER_RUNTIME allow to detect if the current shell was launched by openchamber (desktop, web or remote ssh)
# OPENCHAMBER_RUNTIME is not documented, see https://github.com/search?q=repo%3Aopenchamber%2Fopenchamber+OPENCHAMBER_RUNTIME&type=code
openchamber_context_load_register_for_shell() {
	local name="aistack-openchamber-connect"
    local shell_name_list="${1:-current}"
    local rc_file parent_dir
	local res=0

	local BEGIN_MARK="# >>> ${name} >>>"
    local END_MARK="# <<< ${name} <<<"

    case "${shell_name_list}" in
		"current")
			shell_name_list="$(find_parent_calling_shell)"
			echo "INFO: current user shell detected: ${shell_name_list}"
			;;
		"all")
			shell_name_list="bash zsh sh dash ksh mksh"
			;;
	esac

	for s in ${shell_name_list}; do
        rc_file="$(get_user_shell_config_files "${s}")"
        parent_dir="$(dirname "${rc_file}")"
        if [ ! -d "${parent_dir}" ]; then
            mkdir -p "${parent_dir}"
		fi
        if [ -f "${rc_file}" ]; then
            unregister_named_bloc_for_shell "${name}" "${s}" 1>/dev/null 2>&1
        else
            touch "${rc_file}"
        fi

		case "${s}" in
			"bash"|"zsh"|"ksh"|"sh"|"dash"|"mksh")
				if ! grep -Fq "$BEGIN_MARK" "${rc_file}"; then
					{
						if [ -s "${rc_file}" ] && [ -n "$(tail -c 1 "${rc_file}")" ]; then
							printf '\n'
						fi
						echo "$BEGIN_MARK"
						echo 'case "${OPENCHAMBER_RUNTIME:-}" in'
						echo '	desktop|web|ssh-remote)'
						printf '\t\t[ -f %s ] && . %s\n' "$(shell_quote_posix "${AISTACK_GENERIC_CONTEXT_FILE}")" "$(shell_quote_posix "${AISTACK_GENERIC_CONTEXT_FILE}")"
						printf '\t\t[ -f %s ] && . %s\n' "$(shell_quote_posix "${AISTACK_OPENCHAMBER_CONTEXT_FILE}")" "$(shell_quote_posix "${AISTACK_OPENCHAMBER_CONTEXT_FILE}")"
						echo '		;;'
						echo 'esac'
						echo "$END_MARK"
					} >> "${rc_file}" || return $?
				fi
				echo "- register ${name} for shell ${s} into ${rc_file}"
				;;
			*) 
				echo "WARN: unsupported shell $s"
				res=1
				;;
		esac
	done

	return ${res}
}

# UI password management ------------------------
openchamber_settings_ui_password_create() {
	local password
	password="$("${STELLA_API}" generate_password 12 "[:alnum:]")" || return $?
	openchamber_settings_ui_password_set "${password}"
	
	echo "New UI password created : $password"

	# each time a password is generated we need to refresh the launcher to update env vars
    openchamber_launcher_and_context_files_manage
}

openchamber_settings_ui_password_set() {
    local password="${1:-}"
    echo "${password}" > "${AISTACK_OPENCHAMBER_UI_PASSWORD_FILE}"
	export AISTACK_OPENCHAMBER_UI_PASSWORD="${password}"
}

openchamber_settings_ui_password_get() {
    [ -f "$AISTACK_OPENCHAMBER_UI_PASSWORD_FILE" ] && cat "${AISTACK_OPENCHAMBER_UI_PASSWORD_FILE}"
}

openchamber_settings_ui_password_reset() {
	openchamber_settings_ui_password_set ""
}


# openchamber server management ----------------------
openchamber_server_up() {
    openchamber_launch "serve" "${@}"
}
openchamber_server_down() {
    openchamber_launch "stop" "${@}"
}
openchamber_server_restart() {
	openchamber_launch "restart" "${@}"
}
openchamber_server_status() {
    openchamber_launch "status" "${@}"
}
openchamber_server_logs() {
	openchamber_launch "logs" "${@}"
}


# Check an HTTP address, independently of the managed CLI installation.
# Return 0 only for HTTP 200
openchamber_server_instance_reachable() {
	local address="${1:-http://127.0.0.1:3000}"
	local http_code
	local curl_rc

	http_code="$(
		curl -skL \
			-X GET "${address}" \
			-H "Content-Type: application/json" \
			-o /dev/null \
			-w "%{http_code}" \
			2>/dev/null
	)" && curl_rc=0 || curl_rc=$?

	if [ "${curl_rc}" -ne 0 ]; then
		echo "ERROR: unable to reach server: ${address}" >&2
		return 1
	fi

	if [ "${http_code}" != "200" ]; then
		echo "ERROR: server returned HTTP ${http_code} for ${address}" >&2
		return 1
	fi

	return 0
}


