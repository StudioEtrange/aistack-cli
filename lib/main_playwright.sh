local sub_command="$1"
shift
case "${sub_command}" in
	install)
		if ! playwright_install "$1"; then
			echo "ERROR: Playwright CLI not installed"
			exit 1
		fi

		playwright_launcher_manage

		echo "You should register its path into a specific supported shell OR VS Code terminal"
		echo "aistack plw register all|bash|zsh|fish"
		echo "aistack plw register vs"
		echo "note: do not register path into shells AND vs"
		;;
	uninstall)
		echo "Uninstalling Playwright CLI and unregistering Playwright CLI PATH"
		playwright_uninstall

		playwright_path_unregister_for_shell "all"
		playwright_path_unregister_for_vs_terminal

		playwright_launcher_manage "delete"
		;;
	info)
		playwright_info
		;;
	register)
		echo "Registering Playwright CLI launcher in PATH for $1"
		case "$1" in
			vs)
				playwright_path_register_for_vs_terminal
				;;
			*)
				playwright_path_register_for_shell "$1"
				;;
		esac
		;;
	unregister)
		echo "Unregistering Playwright CLI launcher PATH from ${1:-all}"
		case "$1" in
			vs)
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
