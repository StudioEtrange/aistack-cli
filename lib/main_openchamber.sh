local sub_command="$1"
shift
case "${sub_command}" in
	install)
		if ! openchamber_install "$1"; then
			echo "ERROR: OpenChamber CLI/Web not installed"
			exit 1
		fi

		openchamber_launcher_manage

		echo "OpenCode is required to start OpenChamber: aistack oc install"
		echo "You should register its path into a specific supported shell OR VS Code terminal"
		echo "aistack och register all|bash|zsh|fish"
		echo "aistack och register vs"
		echo "note: do not register path into shells AND vs"
		;;
	uninstall)
		echo "Uninstalling OpenChamber CLI/Web and unregistering its PATH (keeping configuration unchanged)"
		openchamber_uninstall

		openchamber_path_unregister_for_shell "all"
		openchamber_path_unregister_for_vs_terminal
		openchamber_launcher_manage "delete"
		;;
	info)
		openchamber_info
		;;
	version)
		if openchamber_is_installed; then
			openchamber_version
		else
			echo "ERROR: OpenChamber CLI/Web is not installed"
			exit 1
		fi
		;;
	register)
		echo "Registering OpenChamber launcher in PATH for $1"
		case "$1" in
			vs)
				openchamber_path_register_for_vs_terminal
				;;
			*)
				openchamber_path_register_for_shell "$1"
				;;
		esac
		;;
	unregister)
		echo "Unregistering OpenChamber launcher PATH from ${1:-all}"
		case "$1" in
			vs)
				openchamber_path_unregister_for_vs_terminal
				;;
			*)
				openchamber_path_unregister_for_shell "${1:-all}"
				;;
		esac
		;;
	launch|up|start)
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
			[ "$1" = "--" ] && shift

			if [ "${sub_command}" = "up" ] || [ "${sub_command}" = "start" ]; then
				openchamber_daemon_up "$@" || exit $?
			else
				openchamber_launch "$@"
			fi
		else
			echo "ERROR: OpenChamber CLI/Web is not installed"
			exit 1
		fi
		;;
	down|stop|restart|status|log|logs)
		if ! openchamber_is_installed; then
			echo "ERROR: OpenChamber CLI/Web is not installed"
			exit 1
		fi
		[ "$1" = "--" ] && shift
		case "${sub_command}" in
			down|stop) openchamber_daemon_down "$@" ;;
			restart) openchamber_daemon_restart "$@" ;;
			status) openchamber_daemon_status "$@" ;;
			log|logs) openchamber_daemon_logs "$@" ;;
		esac
		;;
	*)
		echo "ERROR: Unknown command ${sub_command} for OpenChamber CLI/Web"
		usage
		exit 1
		;;
esac
