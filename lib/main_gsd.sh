if ! check_requirements "jq"; then echo " -- ERROR : jq missing, launch aistack init"; exit 1; fi;
local sub_command="$1"
shift
case "$sub_command" in
    install)
        if ! check_requirements "nodejs"; then echo " -- ERROR : nodejs missing, launch aistack init"; exit 1; fi;

        gsd_install "$1"

        echo "Configuring gsd"
        gsd_settings_configure

        gsd_launcher_manage

        echo "You should register it's path into a spacific supported shell OR vscode terminal"
        echo "$0 gsd register all|bash|zsh|fish"
        echo "$0 gsd register vs"
        ;;
    uninstall)
        if ! check_requirements "nodejs"; then echo " -- ERROR : nodejs missing, launch aistack init"; exit 1; fi;

        echo "Uninstalling gsd and unregister gsd PATH (keep all configuration unchanged, to remove configuration use reset command)"
        gsd_uninstall

        gsd_path_unregister_for_shell "all"
        gsd_path_unregister_for_vs_terminal

        gsd_launcher_manage "delete"
        ;;
    register)
        echo "Registering gsd launcher in PATH for $1"
        case "$1" in
            "vs")
                gsd_path_register_for_vs_terminal
                ;;
            *)
                gsd_path_register_for_shell "$1"
                ;;
        esac
        ;;
    unregister)
        echo "Unegistering gsd launcher PATH from $1"
        case "$1" in
            "vs")
                gsd_path_unregister_for_vs_terminal
                ;;
            *)
                gsd_path_unregister_for_shell "$1"
                ;;
        esac
        ;;
    launch)
        gsd_launcher_manage

        [ "$1" = "--" ] && shift

        gsd_launch "$@"
        ;;
    *)
        echo "Error: Unknown command $sub_command for gsd"
        usage
        exit 1
        ;;
esac