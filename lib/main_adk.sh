if ! check_requirements "python"; then echo " -- ERROR : python missing, launch aistack init"; exit 1; fi;
local sub_command="$1"
shift
case "$sub_command" in
    install)
        adk_install


        adk_launcher_manage

        echo "You could now register it's path in shell OR vscode terminal"
        echo "$0 adk register bash|zsh|fish"
        echo "   OR"
        echo "$0 adk register vs"
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
        echo "Unegistering adk launcher PATH from $1"
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
        adk_launcher_manage

        [ "$1" = "--" ] && shift

        adk_launch "$@"
        ;;
    *)
        echo "Error: Unknown command $sub_command for adk"
        usage
        exit 1
        ;;
esac