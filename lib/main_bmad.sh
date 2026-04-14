if ! check_requirements "jq"; then echo " -- ERROR : jq missing, launch aistack init"; exit 1; fi;
local sub_command="$1"
shift
case "$sub_command" in
    install)
        if ! check_requirements "nodejs"; then echo " -- ERROR : nodejs missing, launch aistack init"; exit 1; fi;

        bmad_install "$1"

        echo "Configuring bmad"
        bmad_settings_configure

        bmad_launcher_manage

        echo "You could now register it's path in shell OR vscode terminal"
        echo "$0 bmad register bash|zsh|fish"
        echo "   OR"
        echo "$0 bmad register vs"
        ;;
    uninstall)
        if ! check_requirements "nodejs"; then echo " -- ERROR : nodejs missing, launch aistack init"; exit 1; fi;

        echo "Uninstalling bmad and unregister bmad PATH (keep all configuration unchanged, to remove configuration use reset command)"
        bmad_uninstall
        
        bmad_path_unregister_for_shell "all"
        bmad_path_unregister_for_vs_terminal

        bmad_launcher_manage "delete"
        ;;
    configure)
        echo "Configuring bmad"
        bmad_settings_configure
        #vscode_settings_configure "bmad"

        bmad_launcher_manage
        ;;
    reset)
        echo "Resetting bmad configuration"
        bmad_settings_remove
        #vscode_settings_remove "bmad"

        bmad_launcher_manage
        ;;
    register)
        echo "Registering bmad launcher in PATH for $1"
        case "$1" in
            "vs")
                bmad_path_register_for_vs_terminal
                ;;
            *)
                bmad_path_register_for_shell "$1"
                ;;
        esac
        ;;
    unregister)
        echo "Unegistering bmad launcher PATH from $1"
        case "$1" in
            "vs")
                bmad_path_unregister_for_vs_terminal
                ;;
            *)
                bmad_path_unregister_for_shell "$1"
                ;;
        esac
        ;;
    show-config)
        ;;

    launch)
        bmad_launcher_manage

        bmad_launch "$@"
        ;;
    *)
        echo "Error: Unknown command $sub_command for bmad"
        usage
        exit 1
        ;;
esac