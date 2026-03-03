if ! check_requirements "jq"; then echo " -- ERROR : jq missing, launch aistack init"; exit 1; fi;
local sub_command="$1"
shift
case "$sub_command" in
    install)
        if ! check_requirements "nodejs"; then echo " -- ERROR : nodejs missing, launch aistack init"; exit 1; fi;

        local version="$1"
        [ -z "${version}" ] && version="@latest"

        echo "Installing Gemini CLI ${version}"
        # available versions : https://www.npmjs.com/package/@google/gemini-cli-core
        # latest is stable version
        PATH="${AISTACK_NODEJS_BIN_PATH}:${STELLA_ORIGINAL_SYSTEM_PATH}" npm install --verbose -g @google/gemini-cli${version}
        
        echo "Configuring Gemini CLI"
        gemini_settings_configure
        vscode_settings_configure "gemini"
        #gemini_path_register_for_vs_terminal

        gemini_launcher_manage

        echo "You could now register it's path in shell OR vscode terminal"
        echo "$0 gc register bash|zsh|fish"
        echo "   OR"
        echo "$0 gc register vs"      
        ;;
    uninstall)
        if ! check_requirements "nodejs"; then echo " -- ERROR : nodejs missing, launch aistack init"; exit 1; fi;

        echo "Uninstalling Gemini CLI and unregister Gemini CLI PATH (keep all configuration unchanged, to remove configuration use reset command)"
        
        PATH="${AISTACK_NODEJS_BIN_PATH}:${STELLA_ORIGINAL_SYSTEM_PATH}" npm uninstall -g @google/gemini-cli
        gemini_path_unregister_for_shell "all"
        gemini_path_unregister_for_vs_terminal

        gemini_launcher_manage
        ;;
    configure)
        echo "Configuring Gemini CLI"
        gemini_settings_configure
        vscode_settings_configure "gemini"

        gemini_launcher_manage
        ;;
    register)
        echo "Registering Gemini CLI launcher in PATH for $1"
        case "$1" in
            "vs")
                gemini_path_register_for_vs_terminal
                ;;
            *)
                gemini_path_register_for_shell "$1"
                ;;
        esac
        ;;
    unregister)
        echo "Unegistering Gemini CLI launcher PATH from $1"
        case "$1" in
            "vs")
                gemini_path_unregister_for_vs_terminal
                ;;
            *)
                gemini_path_unregister_for_shell "$1"
                ;;
        esac
        ;;
    show-config)
        if [ -f "$AISTACK_GEMINI_CONFIG_FILE" ]; then
            echo "Current Gemini CLI configuration file : $AISTACK_GEMINI_CONFIG_FILE"
            cat "$AISTACK_GEMINI_CONFIG_FILE"
        else
            echo "No Gemini CLI configuration file found."
        fi
        ;;
    reset)
        echo "Resetting Gemini CLI configuration"
        gemini_settings_remove
        vscode_settings_remove "gemini"

        gemini_launcher_manage
        ;;
    launch)
        gemini_launcher_manage

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

        gemini_launch "$@"
        ;;
    cmd-plan)
        case "$1" in
            "install")
                gemini_add_command "${AISTACK_POOL}/cmd/plan/plan.toml"
                ;;
            "uninstall")
                gemini_remove_command "plan.toml"
                ;;
        esac
        ;;
    mcp)
        mcp_server_manage "$1" "$2" "$command" "$3"
        ;;
    *)
        echo "Error: Unknown command $sub_command for gc"
        usage
        exit 1
        ;;
esac