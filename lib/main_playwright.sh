local sub_command="$1"
shift
case "${sub_command}" in
	install)
		if ! playwright_install "$1"; then
			echo "ERROR: Playwright CLI not installed"
			exit 1
		fi

		playwright_launcher_and_context_files_manage
        echo "You should register it's path into your current shell: aistack ${command} register"
		;;
	uninstall)
		echo "Uninstalling Playwright CLI and unregistering Playwright CLI PATH"
		playwright_uninstall

		playwright_path_unregister_for_shell "all"
		playwright_path_unregister_for_vs_terminal

		playwright_launcher_and_context_files_manage "delete"
		;;
	info)
		playwright_info
		;;
	register)
		case "$1" in
			"vs")
				playwright_path_register_for_vs_terminal
				;;
			*)
				playwright_path_register_for_shell "$1"
				;;
		esac
		;;
	unregister)
        [ -z "${1}" ] && target="all" || target="${1}"
        case "${target}" in
			"all")
				playwright_path_unregister_for_shell "all"
				playwright_path_unregister_for_vs_terminal
				;;
			"vs")
				playwright_path_unregister_for_vs_terminal
				;;
			*)
				playwright_path_unregister_for_shell "${1:-all}"
				;;
		esac
		;;
	launch)
		if playwright_is_installed; then
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
			playwright_launch "$@"
		else
			echo "ERROR: Playwright CLI is not installed"
			exit 1
		fi
		;;
	*)
		echo "ERROR: Unknown command ${sub_command} for Playwright CLI"
		usage
		exit 1
		;;
esac
