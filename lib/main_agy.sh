local sub_command="$1"
shift
case "${sub_command}" in
	install)
		if ! agy_install "$1"; then
            echo "ERROR: Antigravity CLI not installed"
			exit 1
		else
			echo "Configuring Antigravity CLI"
			agy_settings_configure
			vscode_settings_configure "antigravity"

			agy_launcher_and_context_files_manage
            echo "You should register it's path into your current shell: aistack ${command} register"
		fi
		;;
	uninstall)
		echo "Uninstalling Antigravity CLI and unregister Antigravity CLI PATH"
		agy_uninstall

		agy_path_unregister_for_shell "all"
		agy_path_unregister_for_vs_terminal

		agy_launcher_and_context_files_manage "delete"
		;;
	configure)
        echo "Configuring Antigravity CLI"
        agy_settings_configure
		vscode_settings_configure "antigravity"
        ;;
	reset)
        echo "Resetting Antigravity CLI configuration"
        agy_settings_remove
        vscode_settings_remove "antigravity"
        ;;
	register)
		case "$1" in
			"vs")
				agy_path_register_for_vs_terminal
				;;
			*)
				agy_path_register_for_shell "$1"
				;;
		esac
		;;
	unregister)
		[ -z "${1}" ] && target="all" || target="${1}"
		case "${target}" in
			"all")
				agy_path_unregister_for_shell "all"
				agy_path_unregister_for_vs_terminal
				;;
			"vs")
				agy_path_unregister_for_vs_terminal
				;;
			*)
				agy_path_unregister_for_shell "${target}"
				;;
		esac
		;;
	info)
		agy_info
		;;
	show-config)
		agy_show_config
		;;
	launch)
		if agy_is_installed; then
			local folder=
			if [ -n "$1" ] && [ "$1" != "--" ]; then
				folder="$1"
				if [ -d "$folder" ]; then
					echo "change to context folder : $folder"
					cd "$folder" || exit 1
					shift
				else
					echo "ERROR: Directory '$folder' not found"
					exit 1
				fi
			fi
			[ "$1" = "--" ] && shift

			agy_launch "$@"
		else
			echo "ERROR: Antigravity CLI is not installed"
			exit 1
		fi
		;;
	*)
		echo "ERROR: Unknown command ${sub_command} for Antigravity CLI"
		usage
		exit 1
		;;
esac
