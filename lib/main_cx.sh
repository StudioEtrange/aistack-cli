if ! check_requirements "jq"; then echo " -- ERROR : jq missing, launch aistack init"; exit 1; fi;
local sub_command="$1"
shift
case "$sub_command" in
    install)
        if ! check_requirements "nodejs"; then echo " -- ERROR : nodejs missing, launch aistack init"; exit 1; fi;

        codex_install "$1"

        echo "Configuring Codex CLI"
        codex_settings_configure

        codex_launcher_manage

        echo "You could now register it's path in shell OR vscode terminal"
        echo "$0 cx register bash|zsh|fish"
        echo "   OR"
        echo "$0 cx register vs"
        ;;
    uninstall)
        if ! check_requirements "nodejs"; then echo " -- ERROR : nodejs missing, launch aistack init"; exit 1; fi;

        echo "Uninstalling Codex CLI and unregister Codex CLI PATH (keep all configuration unchanged, to remove configuration use reset command)"
        codex_uninstall

        codex_path_unregister_for_shell "all"
        codex_path_unregister_for_vs_terminal

        codex_launcher_manage "delete"
        ;;
    configure)
        echo "Configuring Codex CLI"
        codex_settings_configure

        codex_launcher_manage
        ;;
    reset)
        echo "Resetting Codex CLI configuration"
        codex_settings_remove

        codex_launcher_manage
        ;;
    register)
        echo "Registering Codex CLI launcher in PATH for $1"
        case "$1" in
            "vs")
                codex_path_register_for_vs_terminal
                ;;
            *)
                codex_path_register_for_shell "$1"
                ;;
        esac
        ;;
    unregister)
        echo "Unegistering Codex CLI launcher PATH from $1"
        case "$1" in
            "vs")
                codex_path_unregister_for_vs_terminal
                ;;
            *)
                codex_path_unregister_for_shell "$1"
                ;;
        esac
        ;;
    show-config)
        if [ -f "$AISTACK_CODEX_CONFIG_FILE" ]; then
            echo "Current Codex CLI configuration file : $AISTACK_CODEX_CONFIG_FILE"
            cat "$AISTACK_CODEX_CONFIG_FILE"
        else
            echo "No Codex CLI configuration file found."
        fi
        ;;

    launch)
        codex_launcher_manage

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

        codex_launch "$@"
        ;;
    *)
        echo "Error: Unknown command $sub_command for cx"
        usage
        exit 1
        ;;
esac
