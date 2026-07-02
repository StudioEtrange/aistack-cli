local sub_command="$1"
shift
case "${sub_command}" in
    install)
        gsd_install "--install $@"
        ;;
    uninstall)
        echo "Uninstalling GSD"
        gsd_uninstall "--uninstall $@"
        ;;

    *)
        echo "ERROR: Unknown command ${sub_command} for gsd"
        usage
        exit 1
        ;;
esac