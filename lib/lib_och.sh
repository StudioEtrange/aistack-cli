
openchamber_init() {
	# openchamber specific variables

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

	# NOTE: special case, because the launcher do not dot this
	{
		echo '[ -f "${AISTACK_GENERIC_CONTEXT_FILE}" ] && . "${AISTACK_GENERIC_CONTEXT_FILE}"'
		if opencode_is_installed; then
        	echo '[ -f "${AISTACK_OPENCODE_CONTEXT_FILE}" ] && . "${AISTACK_OPENCODE_CONTEXT_FILE}"'
		fi

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
}

openchamber_disconnect_aistack() {
	local shell_name="${1:-all}"
	local name="aistack-openchamber-connect"
	unregister_for_shell "${name}" "${shell_name}"
}

openchamber_connect_aistack() {
	openchamber_context_file_generate

    local shell_name="${1:-all}"
	local name="aistack-openchamber-connect"
    local rc_file
	local err=0

    local BEGIN_MARK="# >>> ${name} >>>"
    local END_MARK="# <<< ${name} <<<"
	[ "$shell_name" = "all" ] && shell_list="bash zsh" || shell_list="$shell_name"

	for s in $shell_list; do
		[ "$s" = "bash" ] && rc_file="$HOME/.bashrc"
		[ "$s" = "zsh" ] && rc_file="$HOME/.zshrc"

		case "$s" in
			"bash"|"zsh")
				[ -f "$rc_file" ] && unregister_for_shell "$name" "$s" 1>/dev/null 2>&1 || touch "$rc_file"
				if ! grep -Fq "$BEGIN_MARK" "$rc_file"; then
					{
						echo "$BEGIN_MARK"
						echo 'case "${OPENCHAMBER_RUNTIME:-}" in'
						echo '	desktop|web|ssh-remote)'
						echo "		[ -f "$(shell_quote_posix "${AISTACK_OPENCHAMBER_CONTEXT_FILE}")" ] && . "$(shell_quote_posix "${AISTACK_OPENCHAMBER_CONTEXT_FILE}")""
						echo '		;;'
						echo 'esac'
						echo "$END_MARK"
					} >> "$rc_file"
				fi
    			echo "- register openchamber connection to aistack for shell $s"
				;;
			*) 
				echo "ERROR : unsupported shell $s"
				err=1
				;;
		esac
	done

	return $err

}