if ! check_requirements "jq"; then echo " -- ERROR : jq missing, launch aistack init"; exit 1; fi;
local sub_command="$1"
shift
case "$sub_command" in
    set)
        vscode_set_config "$1" "$2"
        ;;
    del)
        vscode_remove_config "$1"
        ;;
    show-config)
         if [ -f "$AISTACK_VSCODE_CONFIG_FILE" ]; then
            echo "Current VSCode configuration file : $AISTACK_VSCODE_CONFIG_FILE"
            cat "$AISTACK_VSCODE_CONFIG_FILE"
        else
            echo "No VSCode configuration file found."
        fi
        ;;
    *)
        echo "Error: Unknown command $sub_command for gc"
        usage
        exit 1
        ;;
esac