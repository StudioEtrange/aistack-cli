local sub_command="$1"
shift
case "${sub_command}" in
    install)

		# TODO : fix version to 1.2.15, last version including an agent and not only a server
        #if ! orla_install "latest"; then
		if ! orla_install "latest"; then
            echo "ERROR: orla not installed"
            exit 1
        else
            echo "Configuring Orla"
            orla_settings_configure

            orla_launcher_and_context_files_manage
            echo "You should register it's path into your current shell: aistack ${command} register"
        fi
        ;;
    uninstall)
        # clean running process
        process_kill_by_port "8081" 1>/dev/null 2>&1
        
        echo "Uninstalling Orla (keeping all configuration unchanged. to remove configuration use reset command)"
        orla_uninstall

        orla_path_unregister_for_shell "all"
        orla_path_unregister_for_vs_terminal

        orla_launcher_and_context_files_manage "delete"
        ;;
    configure)
        echo "Configuring Orla"
        orla_settings_configure
        ;;
    reset)
        echo "Resetting Orla configuration"
        orla_settings_remove
        ;;
    register)
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
        [ -z "${1}" ] && target="all" || target="${1}"
        case "${target}" in
			"all")
				orla_path_unregister_for_shell "all"
				orla_path_unregister_for_vs_terminal
				;;
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
		orla_show_config
        ;;

    launch)
        #orla_launcher_and_context_files_manage
		if orla_is_installed; then
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

			orla_launch "$@"
		else
			echo "ERROR: Orla is not installed"
			exit 1
		fi
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
        orla_launch "${sub_command}" "$@"
        ;;
    *)
        echo "ERROR: Unknown command ${sub_command} for Orla"
        usage
        exit 1
        ;;
esac
