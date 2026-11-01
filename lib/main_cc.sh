local sub_command="${1}"
[ "$#" -eq 0 ] || shift
case "${sub_command}" in
	install)
		claude_install "$@" || exit $?
		claude_launcher_and_context_files_manage create || exit $?
		echo "INFO: Register Claude Code in your shell with: aistack cc register"
		;;
	uninstall)
		claude_uninstall || exit $?
		claude_path_unregister_for_shell all || exit $?
		claude_path_unregister_for_vs_terminal || exit $?
		claude_launcher_and_context_files_manage delete
		;;
	info)
		claude_info
		;;
	register)
		case "${1}" in
			vs) claude_path_register_for_vs_terminal ;;
			*) claude_path_register_for_shell "${1:-current}" ;;
		esac
		;;
	unregister)
		case "${1:-all}" in
			all)
				claude_path_unregister_for_shell all || exit $?
				claude_path_unregister_for_vs_terminal
				;;
			vs) claude_path_unregister_for_vs_terminal ;;
			*) claude_path_unregister_for_shell "${1}" ;;
		esac
		;;
	launch)
		claude_is_installed || {
			echo "ERROR: Claude Code is not installed or requirements are missing." >&2
			exit 1
		}
		if [ -n "${1}" ] && [ "${1}" != "--" ]; then
			if [ ! -d "${1}" ]; then
				echo "ERROR: Directory '${1}' not found; use launch -- <Claude Code options>." >&2
				exit 1
			fi
			cd "${1}" || exit 1
			shift
		fi
		[ "${1}" != "--" ] || shift
		claude_launch "$@"
		;;
	*)
		echo "ERROR: Missing or unknown Claude Code command '${sub_command}'." >&2
		echo "Usage: aistack cc install | uninstall | info | register | unregister | launch [folder] -- <options>" >&2
		exit 1
		;;
esac
