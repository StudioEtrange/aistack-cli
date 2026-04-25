if ! check_requirements "yq"; then echo " -- ERROR : yq missing, launch aistack init"; exit 1; fi;
local sub_command="$1"
shift
case "$sub_command" in
    install)

        orla_install "latest"
        
        echo "Configuring Orla"
        orla_settings_configure

        orla_launcher_manage

        echo "You should register it's path into a spacific supported shell OR vscode terminal"
        echo "$0 orla register all|bash|zsh|fish"
        echo "$0 orla register vs"
        ;;
    uninstall)
        # clean running process
        process_kill_by_port "8081" 1>/dev/null 2>&1
        
        echo "Uninstalling Orla (keeping all configuration unchanged. to remove configuration use reset command)"
        orla_uninstall

        orla_path_unregister_for_shell "all"
        orla_path_unregister_for_vs_terminal

        orla_launcher_manage "delete"
        ;;
    configure)
        echo "Configuring Orla"
        orla_settings_configure

        orla_launcher_manage
        ;;
    reset)
        echo "Resetting Orla configuration"
        orla_settings_remove

        orla_launcher_manage
        ;;
    register)
        echo "Registering Orla launcher in PATH"
        case "$1" in
            "vs")
                orla_path_register_for_vs_terminal
                ;;
            *)
                orla_path_register_for_shell "$1"
                ;;
        esac
        ;;
    unregister)
        echo "Unegistering Orla launcher PATH from $1"
        case "$1" in
            "vs")
                orla_path_unregister_for_vs_terminal
                ;;
            *)
                orla_path_unregister_for_shell "$1"
                ;;
        esac
        ;;
    info)
        orla_info
        ;;
    show-config)
        if [ -f "$AISTACK_ORLA_CONFIG_FILE" ]; then
            echo "Current Orla configuration file : $AISTACK_ORLA_CONFIG_FILE"
            cat "$AISTACK_ORLA_CONFIG_FILE"
        else
            echo "No Orla configuration file found."
        fi
        ;;

    launch)
        orla_launcher_manage

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

        orla_launch "$@"
        ;;
    set)
        case "$3" in
            "string")
                orla_set_config "$1" "$2" "double"
                ;;
            *)
                orla_set_config "$1" "$2"
                ;;
        esac
        ;;
    get)
        orla_get_config "$1"
        ;;
    connect)
        case "$2" in
            cpa)
                case "$1" in
                    agent)
                        echo "Connecting Orla agent mode to CLIProxyAPI"
                        orla_connect_cpa "agent" "$3"
                        ;;
                    serve)
                        echo "Connecting Orla API service mode to CLIProxyAPI"
                        orla_connect_cpa "serve" "$3"
                        ;;
                    *)
                        echo "ERROR: Unknown service $1 for Orla connect command"
                        usage
                        exit 1
                        ;;
                esac
                ;;
			*)
				echo "ERROR: Unknown target $2 for Orla connect command"
				usage
				exit 1
				;;
        esac
        ;;
    agent|serve)
        orla_launch "$sub_command" "$@"
        ;;
    *)
        echo "Error: Unknown command $sub_command for Orla"
        usage
        exit 1
        ;;
esac