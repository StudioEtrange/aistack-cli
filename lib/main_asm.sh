if ! check_requirements "nodejs"; then echo " -- ERROR : nodejs missing, launch aistack init"; exit 1; fi;
if ! check_requirements "bun"; then echo " -- ERROR : bun missing, launch aistack init"; exit 1; fi;
local sub_command="$1"
shift
case "$sub_command" in
	install)
		asm_install "$1"

		echo "Configuring asm"
		asm_settings_configure

		asm_launcher_manage

		echo "You could now register it's path in shell OR vscode terminal"
		echo "$0 asm register bash|zsh|fish"
		echo "   OR"
		echo "$0 asm register vs"
		;;
	uninstall)
		echo "Uninstalling asm and unregister asm PATH"
		asm_uninstall

		asm_path_unregister_for_shell "all"
		asm_path_unregister_for_vs_terminal

		asm_launcher_manage "delete"
		;;
	configure)
		echo "Configuring asm"
		asm_settings_configure

		asm_launcher_manage
		;;
	reset)
		echo "Resetting asm configuration"
		asm_settings_remove

		asm_launcher_manage
		;;
	register)
		echo "Registering asm launcher in PATH for $1"
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
		echo "Unegistering asm launcher PATH from $1"
		case "$1" in
			"vs")
				asm_path_unregister_for_vs_terminal
				;;
			*)
				asm_path_unregister_for_shell "$1"
				;;
		esac
		;;
	show-config)
		asm_show_config
		;;
	launch)
		asm_launcher_manage

		local folder=
		if [ -n "$1" ] && [ "$1" != "--" ]; then
			folder="$1"
			if [ -d "$folder" ]; then
				echo "change to context folder : $folder"
				cd "$folder" || exit 1
				shift
			else
				echo "Error: Directory '$folder' not found"
				exit 1
			fi
		fi
		[ "$1" = "--" ] && shift

		asm_launch "$@"
		;;
	*)
		echo "Error: Unknown command $sub_command for asm"
		usage
		exit 1
		;;
esac
