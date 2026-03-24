if ! check_requirements "jq"; then echo " -- ERROR : jq missing, launch aistack init"; exit 1; fi;
local sub_command="$1"
shift
case "$sub_command" in
    install)
        if ! check_requirements "nodejs"; then echo " -- ERROR : nodejs missing, launch aistack init"; exit 1; fi;

        opencode_install  "latest"

        echo "Configuring Opencode CLI"
        opencode_settings_configure
        vscode_settings_configure "opencode"
        
        opencode_launcher_manage

        echo "You could now register it's path in shell OR vscode terminal"
        echo "$0 oc register bash|zsh|fish"
        echo "   OR"
        echo "$0 oc register vs"
        ;;
    uninstall)
        if ! check_requirements "nodejs"; then echo " -- ERROR : nodejs missing, launch aistack init"; exit 1; fi;

        echo "Uninstalling Opencode CLI and Opencode Gemini CLI PATH (keep all configuration unchanged, to remove configuration use reset command)"
        opencode_uninstall
        
        opencode_path_unregister_for_shell "all"
        opencode_path_unregister_for_vs_terminal

        opencode_launcher_manage "delete"
        ;;
    configure)
        echo "Configuring Opencode CLI"
        opencode_settings_configure
        vscode_settings_configure "opencode"

        opencode_launcher_manage
        ;;
    reset)
        echo "Resetting Opencode configuration"
        opencode_settings_remove
        vscode_settings_remove "opencode"

        opencode_launcher_manage
        ;;
    register)
        echo "Registering Gemini CLI launcher in PATH for $1"
        case "$1" in
            "vs")
                opencode_path_register_for_vs_terminal
                ;;
            *)
                opencode_path_register_for_shell "$1"
                ;;
        esac
        ;;
    unregister)
        echo "Unegistering Opencode launcher PATH from $1"
        case "$1" in
            "vs")
                opencode_path_unregister_for_vs_terminal
                ;;
            *)
                opencode_path_unregister_for_shell "$1"
                ;;
        esac
        ;;
    show-config)
        if [ -f "$AISTACK_OPENCODE_CONFIG_FILE" ]; then
            echo "Current Opencode configuration file : $AISTACK_OPENCODE_CONFIG_FILE"
            cat "$AISTACK_OPENCODE_CONFIG_FILE"
        else
            echo "No Opencode configuration file found."
        fi
        ;;

    launch)
        opencode_launcher_manage

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

        opencode_launch "$@"
        ;;
    mcp)
        mcp_server_manage "$1" "$2" "$command" "$3"
        ;;
    *)
        echo "Error: Unknown command $sub_command for oc"
        usage
        exit 1
        ;;
esac