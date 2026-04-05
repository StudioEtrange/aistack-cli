if ! check_requirements "jq"; then echo " -- ERROR : jq missing, launch aistack init"; exit 1; fi;
local sub_command="$1"
shift
case "$sub_command" in
    install)
        if ! check_requirements "nodejs"; then echo " -- ERROR : nodejs missing, launch aistack init"; exit 1; fi;

        kilo_install "$1"
        echo "Configuring Kilo Code CLI"
        kilo_settings_configure
        # TODO
        # vscode_settings_configure "kilo"
        
        kilo_launcher_manage

        echo "You could now register it's path in shell OR vscode terminal"
        echo "$0 kc register bash|zsh|fish"
        echo "   OR"
        echo "$0 kc register vs"
        ;;
    uninstall)
        if ! check_requirements "nodejs"; then echo " -- ERROR : nodejs missing, launch aistack init"; exit 1; fi;

        echo "Uninstalling Kilo Code CLI and unregister Kilo Code CLI PATH (keep all configuration unchanged, to remove configuration use reset command)"
        kilo_uninstall

        kilo_path_unregister_for_shell "all"
        kilo_path_unregister_for_vs_terminal

        kilo_launcher_manage "delete"
        ;;
    configure)
        echo "Configuring Kilo Code CLI and Kilo Code VS Code extension"
        kilo_settings_configure
        # TODO
        #vscode_settings_configure "kilo"

        kilo_launcher_manage
        ;;
    reset)
        echo "Resetting Kilo Code configuration"
        kilo_settings_remove
        # TODO
        #vscode_settings_remove "kilo"

        opencode_launcher_manage
        ;;
    register)
        echo "Registering Kilo Code CLI launcher in PATH for $1"
        case "$1" in
            "vs")
                kilo_path_register_for_vs_terminal
                ;;
            *)
                kilo_path_register_for_shell "$1"
                ;;
        esac
        ;;
    unregister)
        echo "Unegistering Kilo Code CLI launcher PATH from $1"
        case "$1" in
            "vs")
                kilo_path_unregister_for_vs_terminal
                ;;
            *)
                kilo_path_unregister_for_shell "$1"
                ;;
        esac
        ;;
    info)
        kilo_info
        ;;
    show-config)
        kilo_show_config
        ;;

    launch)
        kilo_launcher_manage

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

        kilo_launch "$@"
        ;;
    # mcp)
    #     mcp_server_manage "$1" "$2" "$command" "$3"
    #     ;;
    connect)
        case "$1" in
            cpa)
                echo "Connecting Kilo Code to CLIProxyAPI"
                kilo_connect_cpa
                ;;      
        esac
        ;;
    *)
        echo "Error: Unknown command $sub_command for oc"
        usage
        exit 1
        ;;
esac