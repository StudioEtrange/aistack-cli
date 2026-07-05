local sub_command="$1"
shift
case "${sub_command}" in
    install)

        spr_install
        
        spr_launcher_manage

        echo "You should register it's path into a spacific supported shell OR vscode terminal"
        echo "aistack spr register all|bash|zsh|fish"
        echo "aistack spr register vs"
		echo "note: do not register path into shells AND vs"
        ;;
    uninstall)

        echo "Uninstalling spr"
        spr_uninstall

        spr_path_unregister_for_shell "all"
        spr_path_unregister_for_vs_terminal

        spr_launcher_manage "delete"
        ;;
    register)
        echo "Registering spr launcher in PATH"
        case "$1" in
            "vs")
                spr_path_register_for_vs_terminal
                ;;
            *)
                spr_path_register_for_shell "$1"
                ;;
        esac
        ;;
    unregister)
        echo "Unregistering spr launcher PATH from $1"
        case "$1" in
            "vs")
                spr_path_unregister_for_vs_terminal
                ;;
            *)
                spr_path_unregister_for_shell "$1"
                ;;
        esac
        ;;
    info)
        spr_info
        ;;

    launch)
		if spr_is_installed; then
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

			spr_launch "$@"
		else
			echo "ERROR: spr is not installed"
			exit 1
		fi
        ;;
    *)
        echo "ERROR: Unknown command ${sub_command} for spr"
        usage
        exit 1
        ;;
esac