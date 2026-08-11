local sub_command="$1"
shift
case "${sub_command}" in
    install)
        if ! bmad_install "$1"; then
            echo "ERROR: bmad not installed"
            exit 1
        else
            echo "Configuring bmad"
            bmad_settings_configure

            bmad_launcher_and_context_files_manage
            echo "You should register it's path into your current shell: aistack ${command} register"        
		fi
        ;;
    uninstall)
        echo "Uninstalling bmad and unregister bmad PATH (keep all configuration unchanged, to remove configuration use reset command)"
        bmad_uninstall

        bmad_path_unregister_for_shell "all"
        bmad_path_unregister_for_vs_terminal

        bmad_launcher_and_context_files_manage "delete"
        ;;
    register)
        case "$1" in
            "vs")
                bmad_path_register_for_vs_terminal
                ;;
            *)
                bmad_path_register_for_shell "$1"
                ;;
        esac
        ;;
    unregister)
        [ -z "${1}" ] && target="all" || target="${1}"
        case "${target}" in
			"all")
                bmad_path_unregister_for_shell "all"
                bmad_path_unregister_for_vs_terminal
				;;
            "vs")
                bmad_path_unregister_for_vs_terminal
                ;;
            *)
                bmad_path_unregister_for_shell "$1"
                ;;
        esac
        ;;
    launch)
        #bmad_launcher_and_context_files_manage
		if bmad_is_installed; then
			[ "$1" = "--" ] && shift

			bmad_launch "$@"
		else
			echo "ERROR: bmad is not installed"
			exit 1
		fi
        ;;
    *)
        echo "ERROR: Unknown command ${sub_command} for bmad"
        usage
        exit 1
        ;;
esac
