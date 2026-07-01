local sub_command="$1"
shift
case "${sub_command}" in
    install)
        bmad_install "$1"

        echo "Configuring bmad"
        bmad_settings_configure

        bmad_launcher_manage

        echo "You should register it's path into a spacific supported shell OR vscode terminal"
        echo "$0 bmad register all|bash|zsh|fish"
        echo "$0 bmad register vs"
        ;;
    uninstall)
        echo "Uninstalling bmad and unregister bmad PATH (keep all configuration unchanged, to remove configuration use reset command)"
        bmad_uninstall

        bmad_path_unregister_for_shell "all"
        bmad_path_unregister_for_vs_terminal

        bmad_launcher_manage "delete"
        ;;
    register)
        echo "Registering bmad launcher in PATH for $1"
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
        echo "Unregistering bmad launcher PATH from $1"
        case "$1" in
            "vs")
                bmad_path_unregister_for_vs_terminal
                ;;
            *)
                bmad_path_unregister_for_shell "$1"
                ;;
        esac
        ;;
    launch)
        #bmad_launcher_manage
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