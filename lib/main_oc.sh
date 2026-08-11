local sub_command="$1"
shift
case "${sub_command}" in
    install)
        if ! opencode_install "$1"; then
            echo "ERROR: Opencode CLI not installed"
            exit 1
        else
            echo "Configuring Opencode CLI"
            opencode_settings_configure
            vscode_settings_configure "opencode"
            
            opencode_launcher_and_context_files_manage
            echo "You should register it's path into your current shell: aistack ${command} register"
        fi
        ;;
    uninstall)

        echo "Uninstalling Opencode CLI and unregister Opencode CLI PATH (keep all configuration unchanged, to remove configuration use reset command)"
        opencode_uninstall
        
        opencode_path_unregister_for_shell "all"
        opencode_path_unregister_for_vs_terminal

        opencode_launcher_and_context_files_manage "delete"
        ;;
    configure)
        echo "Configuring Opencode CLI"
        opencode_settings_configure
        vscode_settings_configure "opencode"
        ;;
    reset)
        echo "Resetting Opencode configuration"
        opencode_settings_remove
        vscode_settings_remove "opencode"
        ;;
    register)
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
        [ -z "${1}" ] && target="all" || target="${1}"
        case "${target}" in
			"all")
				opencode_path_unregister_for_shell "all"
				opencode_path_unregister_for_vs_terminal
				;;
            "vs")
                opencode_path_unregister_for_vs_terminal
                ;;
            *)
                opencode_path_unregister_for_shell "$1"
                ;;
        esac
        ;;
    show-config)
        opencode_show_config
        ;;
    info)
        opencode_info
        ;;

    connect)
        case "$1" in
            cpa)
                echo "INFO: Connecting Opencode to CLIProxyAPI"
                opencode_connect_cpa "$2" "$3"
                ;;
        esac
        ;;

    launch)
        #opencode_launcher_and_context_files_manage
		if opencode_is_installed; then
			local folder=
			if [ -n "$1" ] && [ "$1" != "--" ]; then
				folder="$1"
				if [ -d "$folder" ]; then
					echo "change to context folder : $folder"
					cd "$folder" || exit 1
					shift
				else
					echo "ERROR: Directory '$folder' not found"
					exit 1
				fi
			fi
			[ "$1" = "--" ] && shift

			opencode_launch "$@"
		else
			echo "ERROR: Opencode is not installed"
			exit 1
		fi
        ;;
    mcp)
        mcp_server_manage "$1" "$2" "$command" "$3"
        ;;
    *)
        echo "ERROR: Unknown command ${sub_command} for oc"
        usage
        exit 1
        ;;
esac
