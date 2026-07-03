local sub_command="$1"
shift
case "${sub_command}" in
    install)
        adk_install


        adk_launcher_manage

        echo "You should register it's path into a spacific supported shell OR vscode terminal"
        echo "aistack adk register all|bash|zsh|fish"
        echo "aistack adk register vs"
		echo "note: do not register path into shells AND vs"
        ;;
    uninstall)

        echo "Uninstalling adk and unregister adk PATH (keep all configuration unchanged, to remove configuration use reset command)"
        adk_uninstall

        adk_path_unregister_for_shell "all"
        adk_path_unregister_for_vs_terminal

        adk_launcher_manage "delete"
        ;;
    register)
        echo "Registering adk launcher in PATH for $1"
        case "$1" in
            "vs")
                adk_path_register_for_vs_terminal
                ;;
            *)
                adk_path_register_for_shell "$1"
                ;;
        esac
        ;;
    unregister)
        echo "Unregistering adk launcher PATH from $1"
        case "$1" in
            "vs")
                adk_path_unregister_for_vs_terminal
                ;;
            *)
                adk_path_unregister_for_shell "$1"
                ;;
        esac
        ;;
    launch)
        #adk_launcher_manage
		if adk_is_installed; then
			[ "$1" = "--" ] && shift

			adk_launch "$@"
		else
			echo "ERROR: adk is not installed"
			exit 1
		fi
        ;;
    *)
        echo "ERROR: Unknown command ${sub_command} for adk"
        usage
        exit 1
        ;;
esac