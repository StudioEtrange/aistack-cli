local sub_command="$1"
shift
case "${sub_command}" in
	disconnect)
		openchamber_disconnect_aistack
		;;
    connect)
		
        case "$1" in
            aistack)
                echo "INFO: Connecting Openchamber to AIStack-cli context so its shell session will use aistack tools and runtimes"
				openchamber_connect_aistack
                ;;
        esac
        ;;
esac
