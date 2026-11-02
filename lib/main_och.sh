local sub_command="${1}"
[ "$#" -eq 0 ] || shift
case "${sub_command}" in
	install)
		openchamber_install "${@}" || exit $?
		openchamber_settings_configure
		openchamber_launcher_and_context_files_manage create || exit $?
		echo "INFO: Register openchamber in your shell with: aistack och register"
        ;;
	uninstall)
		echo "Uninstalling openchamber (keeping all configuration unchanged. to remove configuration use reset command)"
		openchamber_uninstall
        openchamber_launcher_and_context_files_manage "delete"
		;;
	up|launch)
		if openchamber_is_installed; then
			local folder=
			if [ -n "$1" ] && [ "$1" != "--" ]; then
				folder="$1"
				if [ -d "${folder}" ]; then
					echo "change to context folder : ${folder}"
					cd "${folder}" || exit 1
					shift
				else
					echo "ERROR: Directory '${folder}' not found"
					exit 1
				fi
			fi
			[ "${1}" = "--" ] && shift

			if [ "${sub_command}" = "up" ]; then
				openchamber_server_up "$@" || exit $?
			else
				openchamber_launch "$@"
			fi
		else
			echo "ERROR: openchamber is not installed"
			exit 1
		fi
		;;
	down|status|logs|restart)
		openchamber_server_"${sub_command}" "${@}"
		;;
	configure)
        echo "Configuring openchamber"
        openchamber_settings_configure
		;;
	show-config)
        openchamber_show_config
        ;;
	reset)
        echo "Resetting openchamber configuration"
        openchamber_settings_remove
        vscode_settings_remove "openchamber"
		;;
	disconnect)
		openchamber_disconnect_aistack
		;;
    connect)
		openchamber_connect_to_aistack "$1"
        ;;
    info)
        openchamber_info
        ;;
	register)
		case "${1}" in
			vs) openchamber_path_register_for_vs_terminal ;;
			*) openchamber_path_register_for_shell "${1:-current}" ;;
		esac
		;;
	unregister)
		case "${1:-all}" in
			all)
				openchamber_path_unregister_for_shell all || exit $?
				openchamber_path_unregister_for_vs_terminal
				;;
			vs) openchamber_path_unregister_for_vs_terminal ;;
			*) openchamber_path_unregister_for_shell "${1}" ;;
		esac
		;;
	*)
        echo "ERROR: Unknown command ${sub_command} for och"
        usage
        exit 1
        ;;
esac
