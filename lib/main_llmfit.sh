local sub_command="$1"
shift
case "${sub_command}" in
    install)

        llmfit_install
        
        llmfit_launcher_manage

        echo "You should register it's path into a spacific supported shell OR vscode terminal"
        echo "aistack llmfit register all|bash|zsh|fish"
        echo "aistack llmfit register vs"
		echo "note: do not register path into shells AND vs"
        ;;
    uninstall)

        echo "Uninstalling llmfit"
        llmfit_uninstall

        llmfit_path_unregister_for_shell "all"
        llmfit_path_unregister_for_vs_terminal

        llmfit_launcher_manage "delete"
        ;;
    register)
        echo "Registering Orla launcher in PATH"
        case "$1" in
            "vs")
                llmfit_path_register_for_vs_terminal
                ;;
            *)
                llmfit_path_register_for_shell "$1"
                ;;
        esac
        ;;
    unregister)
        echo "Unregistering llmfit launcher PATH from $1"
        case "$1" in
            "vs")
                llmfit_path_unregister_for_vs_terminal
                ;;
            *)
                llmfit_path_unregister_for_shell "$1"
                ;;
        esac
        ;;
    info)
        llmfit_info
        ;;

    launch)
        #orla_launcher_manage
		if llmfit_is_installed; then
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

			llmfit_launch "$@"
		else
			echo "ERROR: llmfit is not installed"
			exit 1
		fi
        ;;
    *)
        echo "ERROR: Unknown command ${sub_command} for llmfit"
        usage
        exit 1
        ;;
esac