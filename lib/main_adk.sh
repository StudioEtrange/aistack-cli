local sub_command="$1"
shift
case "${sub_command}" in
    install)
        if ! adk_install; then
            echo "ERROR: adk not installed"
            exit 1
        else
            adk_launcher_and_context_files_manage
            echo "You should register it's path into your current shell: aistack ${command} register"
        fi
        ;;
    uninstall)
        echo "Uninstalling adk and unregister adk PATH (keep all configuration unchanged, to remove configuration use reset command)"
        adk_uninstall

        adk_path_unregister_for_shell "all"
        adk_path_unregister_for_vs_terminal

        adk_launcher_and_context_files_manage "delete"
        ;;
    register)
        case "$1" in
            "vs")
                adk_path_register_for_vs_terminal
                ;;
            *)
                adk_path_register_for_shell "$1"
                ;;
        esac
        ;;
    unregister)
		[ -z "${1}" ] && target="all" || target="${1}"
        case "${target}" in
			"all")
				adk_path_unregister_for_shell "all"
				adk_path_unregister_for_vs_terminal
				;;
            "vs")
                adk_path_unregister_for_vs_terminal
                ;;
            *)
                adk_path_unregister_for_shell "$1"
                ;;
        esac
        ;;
    launch)
        #adk_launcher_and_context_files_manage
		if adk_is_installed; then
			[ "$1" = "--" ] && shift

			adk_launch "$@"
		else
			echo "ERROR: adk is not installed"
			exit 1
		fi
        ;;
    *)
        echo "ERROR: Unknown command ${sub_command} for adk"
        usage
        exit 1
        ;;
esac
