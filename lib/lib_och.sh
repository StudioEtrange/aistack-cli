
openchamber_init() {
	# openchamber specific variables
	export AISTACK_OPENCHAMBER_CONFIG_HOME="${OPENCHAMBER_DATA_DIR:-${HOME}/.config/openchamber}"
	export AISTACK_OPENCHAMBER_CONFIG_FILE="${AISTACK_OPENCHAMBER_CONFIG_HOME}/settings.json"
	
	# openchamber launcher

	# openchamber context
	export AISTACK_OPENCHAMBER_CONTEXT_HOME="${AISTACK_CONTEXT_HOME}/openchamber"
	mkdir -p "${AISTACK_OPENCHAMBER_CONTEXT_HOME}"
	export AISTACK_OPENCHAMBER_CONTEXT_FILE="${AISTACK_OPENCHAMBER_CONTEXT_HOME}/openchamber_context.sh"
	# any variables needed to run this component or used by _launch function
	# NOTE: do not need to declare those variables:
	#		AISTACK_*_CONTEXT_FILE and AISTACK_GENERIC_CONTEXT_FILE are already exported
	#		every *_SEARCH_PATH variable related to a REQUIRED_RUNTIME or REQUIRED_MODULE are already exported
	export AISTACK_OPENCHAMBER_CONTEXT_EXPORT_VARIABLES=""

	# openchamber requirement - those will be installed and presence checked to run the current component
	# NOTE:	those search path will be injected in context file
	export AISTACK_OPENCHAMBER_RUNTIME_REQUIRED=""
	export AISTACK_OPENCHAMBER_MODULE_REQUIRED=""
	# remove from context any runtime or module any item already in generic aistack context
	export AISTACK_OPENCHAMBER_RUNTIME_REQUIRED_IN_CONTEXT="$($STELLA_API filter_list_with_list "${AISTACK_OPENCHAMBER_RUNTIME_REQUIRED}" "${AISTACK_GENERIC_CONTEXT_ADD_RUNTIME}")"
	export AISTACK_OPENCHAMBER_MODULE_REQUIRED_IN_CONTEXT="$($STELLA_API filter_list_with_list "${AISTACK_OPENCHAMBER_MODULE_REQUIRED}" "${AISTACK_GENERIC_CONTEXT_ADD_MODULE}")"
}


# NOTE: openchamber does not have launcher, only context file
openchamber_launcher_and_context_files_manage() {
    local action="${1:-create}"

	case $action in
		create)
			# GENERATE CONTEXT FILE ----
			openchamber_context_file_generate
            ;;
        delete)
			openchamber_context_file_generate_remove
            ;;
		refresh_if_exists)
			[ -f "${AISTACK_OPENCHAMBER_CONTEXT_FILE}" ] && ( openchamber_launcher_and_context_files_manage "delete"; openchamber_launcher_and_context_files_manage "create" )
			;;
    esac
}


openchamber_context_file_generate() {
	# GENERATE CONTEXT FILE ----
	echo '#!/bin/sh' > "${AISTACK_OPENCHAMBER_CONTEXT_FILE}"
	chmod +x "${AISTACK_OPENCHAMBER_CONTEXT_FILE}"

	# VARIABLES
	aistack_context_file_export_variables "${AISTACK_OPENCHAMBER_CONTEXT_FILE}" "AISTACK_GENERIC_CONTEXT_FILE AISTACK_OPENCODE_CONTEXT_FILE ${AISTACK_OPENCHAMBER_CONTEXT_EXPORT_VARIABLES}"

	# NOTE: special case, because it is normaly the launcher which includes those files, but there is no launcher script for openchamber
	{
		echo '[ -f "${AISTACK_GENERIC_CONTEXT_FILE}" ] && . "${AISTACK_GENERIC_CONTEXT_FILE}"'
		#if opencode_is_installed; then
        #	echo '[ -f "${AISTACK_OPENCODE_CONTEXT_FILE}" ] && . "${AISTACK_OPENCODE_CONTEXT_FILE}"'
		#fi

	} >> "${AISTACK_OPENCHAMBER_CONTEXT_FILE}"

	# PATH
	local m r list_path
	for r in ${AISTACK_OPENCHAMBER_RUNTIME_REQUIRED_IN_CONTEXT}; do list_path="$(aistack_context_path_add_component "runtime" "${r}" "VARIABLE_LIST") ${list_path}"; done
	for m in ${AISTACK_OPENCHAMBER_MODULE_REQUIRED_IN_CONTEXT}; do list_path="$(aistack_context_path_add_component "module" "${m}" "VARIABLE_LIST") ${list_path}"; done
	aistack_context_file_export_path "${AISTACK_OPENCHAMBER_CONTEXT_FILE}" "${list_path}" "VARIABLE_LIST"
}

openchamber_context_file_generate_remove() {
	rm -f "${AISTACK_OPENCHAMBER_CONTEXT_FILE}"
}

openchamber_info() {
	echo "OpenChamber context file : $AISTACK_OPENCHAMBER_CONTEXT_FILE"
	echo "OpenChamber Configuration file : $AISTACK_OPENCHAMBER_CONFIG_FILE"
}

openchamber_show_config() {
    if [ -f "$AISTACK_OPENCHAMBER_CONFIG_FILE" ]; then
        cat "$AISTACK_OPENCHAMBER_CONFIG_FILE"
    else
        echo "No configuration file found. ($AISTACK_OPENCHAMBER_CONFIG_FILE)"
    fi
}



# generic config management -----------------
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
openchamber_connect_aistack() {
	local shell_name_list="${1:-current}"
	local result

	# generate openchamber context file
	openchamber_context_file_generate || return $?
	
	# register a shell hook that loads the openchamber context file when openchamber desktop, web or ssh, launch a selected shell
	# Load the OpenChamber context file when OPENCHAMBER_RUNTIME is setted in such process launched by OpenChamber.
	# This allows for openchamber to use aistack managed tools and runtime
	openchamber_context_load_register_for_shell "$shell_name_list" || return $?

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
	fi
}



openchamber_disconnect_aistack() {
	local shell_name_list="${1:-all}"
	local name="aistack-openchamber-connect"
	unregister_named_bloc_for_shell "${name}" "${shell_name_list}"

	openchamber_remove_config "opencodeBinary"
	vscode_remove_config "openchamber\.opencodeBinary"
}

# allow to inject openchamber context file in shell launched by openchamber
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
						echo "$BEGIN_MARK"
						echo 'case "${OPENCHAMBER_RUNTIME:-}" in'
						echo '	desktop|web|ssh-remote)'
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

