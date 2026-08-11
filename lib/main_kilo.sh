local sub_command="${1}"
shift
case "${sub_command}" in
    install)
        if ! kilo_install "${1}"; then
            echo "ERROR: Kilo Code not installed"
            exit 1
        else
            echo "Configuring Kilo Code"
            kilo_settings_configure
            # TODO
            # vscode_settings_configure "kilo"
            
            kilo_launcher_and_context_files_manage
            echo "You should register it's path into your current shell: aistack ${command} register"
        fi
        ;;
    uninstall)
        echo "Uninstalling Kilo Code and unregister Kilo Code CLI PATH (keep all configuration unchanged, to remove configuration use reset command)"
        kilo_uninstall

        kilo_path_unregister_for_shell "all"
        kilo_path_unregister_for_vs_terminal

        kilo_launcher_and_context_files_manage "delete"
        ;;
    configure)
        echo "Configuring Kilo Code CLI and Kilo Code VS Code extension"
        kilo_settings_configure
        # TODO
        #vscode_settings_configure "kilo"

        #kilo_launcher_and_context_files_manage
        ;;
    reset)
        echo "Resetting Kilo Code configuration"
        kilo_settings_remove
        # TODO
        #vscode_settings_remove "kilo"

        #kilo_launcher_and_context_files_manage
        ;;
    register)
        case "${1}" in
            "vs")
                kilo_path_register_for_vs_terminal
                ;;
            *)
                kilo_path_register_for_shell "${1}"
                ;;
        esac
        ;;
    unregister)
        [ -z "${1}" ] && target="all" || target="${1}"
        case "${target}" in
			"all")
				kilo_path_unregister_for_shell "all"
				kilo_path_unregister_for_vs_terminal
				;;
            "vs")
                kilo_path_unregister_for_vs_terminal
                ;;
            *)
                kilo_path_unregister_for_shell "${1}"
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
        #kilo_launcher_and_context_files_manage
		if kilo_is_installed; then
			local folder=
			if [ -n "${1}" ] && [ "${1}" != "--" ]; then
				folder="${1}"
				if [ -d "${folder}" ]; then
					echo "change to context folder : ${folder}"
					cd "${folder}" || exit 1
					shift
				else
					echo "ERROR: Directory '${folder}' not found"
					exit 1
				fi
			fi
			[ "${1}" = "--" ] && shift

        	kilo_launch "$@"
		else
			echo "ERROR: kilo is not installed"
			exit 1
		fi
        ;;
    connect)
        case "${1}" in
            cpa)
                echo "INFO: Connecting Kilo Code to CLIProxyAPI"
                if kilo_connect_cpa "${2}" "${3}"; then
					echo "INFO: For VS Code extension, restart VS Code or disable/reload kilo extension"
                fi
				
				if ! kilo_is_installed; then
				    echo "WARN:  Kilo Code cli not installed"
                fi
                ;;      
        esac
        ;;
    *)
        echo "Error: Unknown command ${sub_command} for kc"
        usage
        exit 1
        ;;
esac
