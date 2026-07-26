local sub_command="$1"
shift
case "${sub_command}" in
    install)

        sktor_install
        
        sktor_launcher_manage

        echo "You should register it's path into a spacific supported shell OR vscode terminal"
        echo "aistack sktor register all|bash|zsh|fish"
        echo "aistack sktor register vs"
		echo "note: do not register path into shells AND vs"
        ;;
    uninstall)

        echo "Uninstalling sktor"
        sktor_uninstall

        sktor_path_unregister_for_shell "all"
        sktor_path_unregister_for_vs_terminal

        sktor_launcher_manage "delete"
        ;;
    register)
        echo "Registering sktor launcher in PATH"
        case "$1" in
            "vs")
                sktor_path_register_for_vs_terminal
                ;;
            *)
                sktor_path_register_for_shell "$1"
                ;;
        esac
        ;;
    unregister)
        echo "Unregistering sktor launcher PATH from $1"
        case "$1" in
            "vs")
                sktor_path_unregister_for_vs_terminal
                ;;
            *)
                sktor_path_unregister_for_shell "$1"
                ;;
        esac
        ;;
    info)
        sktor_info
        ;;

    launch)
		if sktor_is_installed; then
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

			sktor_launch "$@"
		else
			echo "ERROR: sktor is not installed"
			exit 1
		fi
        ;;
    connect)
        case "$1" in
            cpa)
                echo "Connecting skillspector to CLIProxyAPI"
                sktor_connect_cpa "$2" "$3" "$4"
                ;;
            *)
                echo "Connecting skillspector to $@"
                sktor_register_model "$1" "$2" "$3" "$4" "$5" "$6"
                ;;
        esac
        ;;
    disconnect)
        sktor_unregister_model "CPA"
        sktor_unregister_model

        sktor_launcher_manage "create"
        ;;
    *)
        echo "ERROR: Unknown command ${sub_command} for sktor"
        usage
        exit 1
        ;;
esac