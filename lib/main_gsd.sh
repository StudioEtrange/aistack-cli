local sub_command="$1"
shift
case "${sub_command}" in
    install)
        if ! gsd_install "--install $@"; then
            echo "ERROR: GSD not installed"
            exit 1
        fi
        ;;
    uninstall)
        echo "Uninstalling GSD"
        gsd_uninstall "--uninstall $@"
        ;;
    help)
        gsd_help
        ;;
    *)
        echo "ERROR: Unknown command ${sub_command} for gsd"
        usage
        exit 1
        ;;
esac
