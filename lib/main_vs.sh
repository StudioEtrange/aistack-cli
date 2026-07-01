local sub_command="${1}"
shift
case "${sub_command}" in
    set)
        vscode_set_config "${1}" "${2}"
        ;;
    del)
        vscode_remove_config "${1}"
        ;;
    info)
        vscode_info
        ;;
    show-config)
         if [ -f "${AISTACK_VSCODE_CONFIG_FILE}" ]; then
            echo "Current VS Code configuration file : ${AISTACK_VSCODE_CONFIG_FILE}"
            cat "${AISTACK_VSCODE_CONFIG_FILE}"
        else
            echo "No VS Code configuration file found."
        fi
        ;;
    install|uninstall)
        vscode_extension_manage "${1}" "${sub_command}"
        ;;
    *)
        echo "Error: Unknown command ${sub_command} for vs"
        usage
        exit 1
        ;;
esac