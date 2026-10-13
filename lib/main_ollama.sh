local sub_command="${1}"
[ "$#" -eq 0 ] || shift
case "${sub_command}" in
	install)
		[ "$#" -le 1 ] || { echo "ERROR: Usage: aistack ollama install [version]"; exit 1; }
		ollama_install "${1:-latest}" && ollama_launcher_and_context_files_manage create
		;;
	uninstall)
		ollama_uninstall || exit $?
		ollama_path_unregister_for_shell all
		ollama_path_unregister_for_vs_terminal
		ollama_launcher_and_context_files_manage delete
		;;
	register)
		case "${1}" in
			vs) ollama_path_register_for_vs_terminal ;;
			*) ollama_path_register_for_shell "${1}" ;;
		esac
		;;
	unregister)
		case "${1:-all}" in
			all) ollama_path_unregister_for_shell all; ollama_path_unregister_for_vs_terminal ;;
			vs) ollama_path_unregister_for_vs_terminal ;;
			*) ollama_path_unregister_for_shell "${1}" ;;
		esac
		;;
	info) ollama_info ;;
	launch)
		[ "${1}" != "--" ] || shift
		ollama_launch "$@"
		;;
	serve|list|ps|pull|push|run|stop|show|create|cp|rm)
		case "${sub_command}" in
			pull|push|run|stop|show|create|cp|rm)
				[ "$#" -gt 0 ] || { echo "ERROR: Missing arguments for ollama ${sub_command}"; exit 1; }
				;;
		esac
		ollama_launch "${sub_command}" "$@"
		;;
	*)
		echo "ERROR: Unknown or missing command for Ollama: ${sub_command}; use aistack help"
		exit 1
		;;
esac
