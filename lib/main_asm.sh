local sub_command="$1"
shift
case "${sub_command}" in
	install)
		if ! asm_install "$1"; then
            echo "ERROR: asm not installed"
			exit 1
		else
			echo "Configuring asm"
			asm_settings_configure

			asm_launcher_and_context_files_manage
            echo "You should register it's path into your current shell: aistack ${command} register"
		fi
		;;
	uninstall)
		echo "Uninstalling asm and unregister asm PATH"
		asm_uninstall

		asm_path_unregister_for_shell "all"
		asm_path_unregister_for_vs_terminal

		asm_launcher_and_context_files_manage "delete"
		;;
	configure)
		echo "Configuring asm"
		asm_settings_configure
		;;
	reset)
		echo "Resetting asm configuration"
		asm_settings_remove
		;;
	register)
		case "$1" in
			"vs")
				asm_path_register_for_vs_terminal
				;;
			*)
				asm_path_register_for_shell "$1"
				;;
		esac
		;;
	unregister)
		[ -z "${1}" ] && target="all" || target="${1}"
		case "${target}" in
			"all")
				asm_path_unregister_for_shell "all"
				asm_path_unregister_for_vs_terminal
				;;
			"vs")
				asm_path_unregister_for_vs_terminal
				;;
			*)
				asm_path_unregister_for_shell "$1"
				;;
		esac
		;;
	info)
		asm_info
		;;
	show-config)
		asm_show_config
		;;
	launch)
		#asm_launcher_and_context_files_manage
		if asm_is_installed; then
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
			asm_launch "$@"
		else
			echo "ERROR: asm is not installed"
			exit 1
		fi
		;;
	*)
		echo "ERROR: Unknown command ${sub_command} for asm"
		usage
		exit 1
		;;
esac
