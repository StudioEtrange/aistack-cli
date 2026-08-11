local sub_command="$1"
shift
case "${sub_command}" in
	install)
		if ! ciss_install; then
            echo "ERROR: ciss not installed"
			exit 1
		else
			ciss_launcher_and_context_files_manage
            echo "You should register it's path into your current shell: aistack ${command} register"
		fi
		;;
	uninstall)
		echo "Uninstalling ciss"
		ciss_uninstall
		ciss_path_unregister_for_shell "all"
		ciss_path_unregister_for_vs_terminal
		ciss_launcher_and_context_files_manage "delete"
		;;
	register)
		case "$1" in
			vs) ciss_path_register_for_vs_terminal ;;
			*) ciss_path_register_for_shell "$1" ;;
		esac
		;;
	unregister)
        [ -z "${1}" ] && target="all" || target="${1}"
        case "${target}" in
			"all")
				ciss_path_unregister_for_shell "all"
				ciss_path_unregister_for_vs_terminal
				;;
			"vs") ciss_path_unregister_for_vs_terminal ;;
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
		ciss_launcher_and_context_files_manage "create"
		;;
	*)
		echo "ERROR: Unknown command ${sub_command} for ciss"
		usage
		exit 1
		;;
esac
