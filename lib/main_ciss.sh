local sub_command="$1"
shift
case "${sub_command}" in
	install)
		if ! ciss_install; then
            echo "ERROR: ciss not installed"
			exit 1
		else
			ciss_launcher_manage
			echo "You should register its path into a supported shell or VS Code terminal"
			echo "aistack ciss register all|bash|zsh|fish"
			echo "aistack ciss register vs"
			echo "Note: do not register the path into shells and VS Code at the same time"
		fi
		;;
	uninstall)
		echo "Uninstalling ciss"
		ciss_uninstall
		ciss_path_unregister_for_shell "all"
		ciss_path_unregister_for_vs_terminal
		ciss_launcher_manage "delete"
		;;
	register)
		echo "Registering ciss launcher in PATH"
		case "$1" in
			vs) ciss_path_register_for_vs_terminal ;;
			*) ciss_path_register_for_shell "$1" ;;
		esac
		;;
	unregister)
		echo "Unregistering ciss launcher PATH from $1"
		case "$1" in
			vs) ciss_path_unregister_for_vs_terminal ;;
			*) ciss_path_unregister_for_shell "$1" ;;
		esac
		;;
	info)
		ciss_info
		;;
	launch)
		if ciss_is_installed; then
			local folder=
			if [ -n "$1" ] && [ "$1" != "--" ]; then
				folder="$1"
				if [ -d "${folder}" ]; then
					echo "change to context folder: ${folder}"
					cd "${folder}" || exit 1
					shift
				else
					echo "ERROR: Directory '${folder}' not found"
					exit 1
				fi
			fi
			[ "$1" = "--" ] && shift
			ciss_launch "$@"
		else
			echo "ERROR: ciss is not installed"
			exit 1
		fi
		;;
	connect)
		case "$1" in
			cpa)
				echo "Connecting Cisco AI Skill Scanner to CLIProxyAPI"
				ciss_connect_cpa "$2"
				;;
			*)
				echo "Connecting Cisco AI Skill Scanner to $*"
				ciss_register_model "$1" "$2" "$3" "$4"
				;;
		esac
		;;
	disconnect)
		ciss_unregister_model "CPA"
		ciss_unregister_model
		ciss_launcher_manage "create"
		;;
	*)
		echo "ERROR: Unknown command ${sub_command} for ciss"
		usage
		exit 1
		;;
esac
