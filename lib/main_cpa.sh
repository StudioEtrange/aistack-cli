if ! check_requirements "yq"; then echo " -- ERROR : yq missing, launch aistack init"; exit 1; fi;
local sub_command="$1"
shift
case "$sub_command" in
    install)

        echo "Installing CLIProxyAPI"
        cpa_install "latest"
        
        echo "Configuring CLIProxyAPI"
        cpa_settings_configure

        cpa_launcher_manage
        ;;
    uninstall)
        # clean running process
        local port="8317"
        if [ -f "$AISTACK_CLIPROXYAPI_CONFIG_FILE" ]; then
            port="$(cpa_get_config ".port")"
        fi
        process_kill_by_port "$port" 1>/dev/null 2>&1
        
        echo "Uninstalling CLIProxyAPI (keeping all configuration unchanged. to remove configuration use reset command)"
        cpa_uninstall

        cpa_launcher_manage
        ;;
    configure)
        echo "Configuring CLIProxyAPI"
        cpa_settings_configure

        cpa_launcher_manage
        ;;
    info)
        cpa_info
        ;;
    show-config)
        if [ -f "$AISTACK_CLIPROXYAPI_CONFIG_FILE" ]; then
            echo "Current CLIProxyAPI configuration file : $AISTACK_CLIPROXYAPI_CONFIG_FILE"
            cat "$AISTACK_CLIPROXYAPI_CONFIG_FILE"
        else
            echo "No CLIProxyAPI configuration file found."
        fi
        ;;
    set)
        case "$3" in
            "string")
                cpa_set_config "$1" "$2" "double"
                ;;
            *)
                cpa_set_config "$1" "$2"
                ;;
        esac
        ;;
    get)
        cpa_get_config "$1"
        ;;
    reset)
        echo "Resetting CLIProxyAPI configuration"
        cpa_settings_remove

        cpa_launcher_manage
        ;;
    key)
        case "$1" in
            generate)
                cpa_settings_api_key_create
                ;;
            reset)
                cpa_settings_api_key_reset
                ;;
            delete)
                cpa_settings_api_key_del "$2"
                ;;
            list)
                cpa_settings_api_key_list
                ;;
            get)
                cpa_settings_api_key_get "$2"
                ;;
            *)
                echo "Error: Unknown command $1 for CLIProxyAPI key"
                usage
                exit 1
                ;;
        esac
        ;;
    launch)
        cpa_launcher_manage

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

        cpa_launch "$@"
        ;;
    model)
        case "$1" in
            list)
                cpa_get_model_list
                ;;
            *)
                echo "Error: Unknown command $1 for CLIProxyAPI model"
                usage
                exit 1
                ;;
        esac
        ;;
    login)
        case "$1" in
            gemini-oauth)
                shift
                cpa_login_gemini_oauth "${@}"
                ;; 
            openai-oauth)
                shift
                cpa_login_openai_oauth "${@}"
                ;;
            qwen-oauth)
                shift
                cpa_login_qwen_oauth "${@}"
                ;;
            *)
                echo "Error: not supported $1"
                usage
                exit 1
                ;;
        esac
        ;;
    
    *)
        echo "Error: Unknown command $sub_command for CLIProxyAPI"
        usage
        exit 1
        ;;
esac