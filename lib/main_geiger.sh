local sub_command="${1}"
[ "$#" -eq 0 ] || shift
case "${sub_command}" in
	install)
		geiger_install "${@}" || exit $?
		geiger_launcher_and_context_files_manage create || exit $?
		echo "INFO: Register Geiger in your shell with: aistack geiger register"
		;;
	uninstall)
		geiger_uninstall || exit $?
		geiger_path_unregister_for_shell all || exit $?
		geiger_path_unregister_for_vs_terminal || exit $?
		geiger_launcher_and_context_files_manage delete
		;;
	info)
		geiger_info
		;;
	register)
		case "${1}" in
			vs) geiger_path_register_for_vs_terminal ;;
			*) geiger_path_register_for_shell "${1:-current}" ;;
		esac
		;;
	unregister)
		case "${1:-all}" in
			all)
				geiger_path_unregister_for_shell all || exit $?
				geiger_path_unregister_for_vs_terminal
				;;
			vs) geiger_path_unregister_for_vs_terminal ;;
			*) geiger_path_unregister_for_shell "${1}" ;;
		esac
		;;
	launch)
		geiger_is_installed || {
			echo "ERROR: Geiger is not installed or its managed runtime is missing" >&2
			exit 1
		}
		if [ -n "${1}" ] && [ "${1}" != "--" ]; then
			if [ ! -d "${1}" ]; then
				echo "ERROR: Directory '${1}' not found; use launch -- <Geiger options>" >&2
				exit 1
			fi
			cd "${1}" || exit 1
			shift
		fi
		[ "${1}" != "--" ] || shift
		geiger_launch "${@}"
		;;
	*)
		echo "ERROR: Missing or unknown Geiger command '${sub_command}'" >&2
		echo "Usage: aistack geiger install [@version] | uninstall | info | register | unregister | launch [folder] -- <options>" >&2
		exit 1
		;;
esac
