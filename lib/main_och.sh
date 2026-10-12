local sub_command="$1"
shift
case "${sub_command}" in
	reset)
        echo "Resetting OpenChamber configuration"
        openchamber_settings_remove
        vscode_settings_remove "openchamber"
		;;
	disconnect)
		openchamber_disconnect_aistack
		;;
    connect)
		openchamber_connect_aistack "$1"
        ;;
	show-config)
        openchamber_show_config
        ;;
    info)
        openchamber_info
        ;;
	*)
        echo "ERROR: Unknown command ${sub_command} for och"
        usage
        exit 1
        ;;
esac
