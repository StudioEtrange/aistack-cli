ciss_init() {
	# cisco ai skill scanner launcher
	export AISTACK_CISS_LAUNCHER_HOME="${AISTACK_LAUNCHER_HOME}/ciss"
	mkdir -p "${AISTACK_CISS_LAUNCHER_HOME}"
	export AISTACK_CISS_LAUNCHER_FILE="${AISTACK_CISS_LAUNCHER_HOME}/skill-scanner"

	# cisco ai skill scanner context
	export AISTACK_CISS_CONTEXT_HOME="${AISTACK_CONTEXT_HOME}/ciss"
	mkdir -p "${AISTACK_CISS_CONTEXT_HOME}"
	export AISTACK_CISS_CONTEXT_FILE="${AISTACK_CISS_CONTEXT_HOME}/ciss_context.sh"
	# any variables needed to run this component or used by _launch function
	# NOTE: do not need to declare those variables:
	#		AISTACK_*_CONTEXT_FILE and AISTACK_GENERIC_CONTEXT_FILE are already exported
	#		every *_SEARCH_PATH variable related to a REQUIRED_RUNTIME or REQUIRED_MODULE are already exported
	export AISTACK_CISS_CONTEXT_EXPORT_VARIABLES=""

	export AISTACK_CLIPROXYAPI_KEY_FOR_CISS_FILE="${AISTACK_CISS_CONTEXT_HOME}/cpa_key_for_ciss"
	[ -f "${AISTACK_CLIPROXYAPI_KEY_FOR_CISS_FILE}" ] && export AISTACK_CLIPROXYAPI_KEY_FOR_CISS="$(cat "${AISTACK_CLIPROXYAPI_KEY_FOR_CISS_FILE}")"
	export AISTACK_CLIPROXYAPI_MODEL_FOR_CISS_FILE="${AISTACK_CISS_CONTEXT_HOME}/cpa_model_for_ciss"
	[ -f "${AISTACK_CLIPROXYAPI_MODEL_FOR_CISS_FILE}" ] && export AISTACK_CLIPROXYAPI_MODEL_FOR_CISS="$(cat "${AISTACK_CLIPROXYAPI_MODEL_FOR_CISS_FILE}")"

	export AISTACK_MODEL_KEY_FOR_CISS_FILE="${AISTACK_CISS_CONTEXT_HOME}/model_key_for_ciss"
	[ -f "${AISTACK_MODEL_KEY_FOR_CISS_FILE}" ] && export AISTACK_MODEL_KEY_FOR_CISS="$(cat "${AISTACK_MODEL_KEY_FOR_CISS_FILE}")"
	export AISTACK_MODEL_ID_FOR_CISS_FILE="${AISTACK_CISS_CONTEXT_HOME}/model_id_for_ciss"
	[ -f "${AISTACK_MODEL_ID_FOR_CISS_FILE}" ] && export AISTACK_MODEL_ID_FOR_CISS="$(cat "${AISTACK_MODEL_ID_FOR_CISS_FILE}")"
	export AISTACK_MODEL_PROVIDER_FOR_CISS_FILE="${AISTACK_CISS_CONTEXT_HOME}/model_provider_for_ciss"
	[ -f "${AISTACK_MODEL_PROVIDER_FOR_CISS_FILE}" ] && export AISTACK_MODEL_PROVIDER_FOR_CISS="$(cat "${AISTACK_MODEL_PROVIDER_FOR_CISS_FILE}")"
	export AISTACK_MODEL_PROVIDER_URL_FOR_CISS_FILE="${AISTACK_CISS_CONTEXT_HOME}/model_provider_url_for_ciss"
	[ -f "${AISTACK_MODEL_PROVIDER_URL_FOR_CISS_FILE}" ] && export AISTACK_MODEL_PROVIDER_URL_FOR_CISS="$(cat "${AISTACK_MODEL_PROVIDER_URL_FOR_CISS_FILE}")"

	# cisco ai skill scanner requirement - those will be installed and presence checked to run the current component
	# NOTE:	those search path will be injected in context file
	export AISTACK_CISS_RUNTIME_REQUIRED="python"
	export AISTACK_CISS_MODULE_REQUIRED=""
	# remove from context any runtime or module any item already in generic aistack context
	export AISTACK_CISS_RUNTIME_REQUIRED_IN_CONTEXT="$($STELLA_API filter_list_with_list "${AISTACK_CISS_RUNTIME_REQUIRED}" "${AISTACK_GENERIC_CONTEXT_ADD_RUNTIME}")"
	export AISTACK_CISS_MODULE_REQUIRED_IN_CONTEXT="$($STELLA_API filter_list_with_list "${AISTACK_CISS_MODULE_REQUIRED}" "${AISTACK_GENERIC_CONTEXT_ADD_MODULE}")"
}

# test if cisco ai skill scanner is installed
# return 0 : is installed
# return 1 : tool is not installed
# return 2 : missing runtime
ciss_is_installed() {
	local r m
	export AISTACK_CISS_TOOL_AVAILABLE="false"
	export AISTACK_CISS_TOOL_PATH=""
	for r in ${AISTACK_CISS_RUNTIME_REQUIRED}; do aistack_runtime_is_detected "${r}" || return 2; done
	for m in ${AISTACK_CISS_MODULE_REQUIRED}; do aistack_module_is_detected "${m}" || return 2; done
	[ -x "${AISTACK_RUNTIME_PYTHON_SEARCH_PATH}/skill-scanner" ] || return 1
	export AISTACK_CISS_TOOL_PATH="${AISTACK_RUNTIME_PYTHON_SEARCH_PATH}/skill-scanner"
	export AISTACK_CISS_TOOL_AVAILABLE="true"
	return 0
}

ciss_install() {
	local r m
	for r in ${AISTACK_CISS_RUNTIME_REQUIRED}; do
		echo "INFO: CISS require ${r} managed runtime"
		aistack_runtime_require "${r}"
	done

	for m in ${AISTACK_CISS_MODULE_REQUIRED}; do
		echo "INFO: CISS require ${m} managed module"
		aistack_module_require "${m}"
	done

	if [ ! "${STELLA_CURRENT_PLATFORM}" = "darwin" ]; then
		case $(glibc_version_compare "${AISTACK_GLIBC_CURRENT_VERSION}" "2.17") in
			-1|0) 
				# yara-x is available for glibc 2.17 with yara-x<1.0.2 but cisco-ai-skill-scanner 2.x needs yara-x=>1.10
				# need to build it and install it before cisco-ai-skill-scanner
				python_yara_x_package_build_install || return $?
				;;
		esac
	fi

	python_uv_package_install "cisco-ai-skill-scanner" || return $?
	ciss_is_installed
	return $?
}




ciss_uninstall() {
	if ciss_is_installed; then
		python_uv_package_uninstall "cisco-ai-skill-scanner" || return $?
		ciss_is_installed && return 1
		return 0
	else
		echo "WARN: not installed or missing a required managed runtime ${AISTACK_CISS_RUNTIME_REQUIRED}"
	fi
}

ciss_path_register_for_shell() {
	local shell_name="$1"
	if ciss_is_installed; then
		path_register_for_shell "skill-scanner" "${AISTACK_CISS_LAUNCHER_HOME}" "${shell_name}"
	fi
}

ciss_path_unregister_for_shell() {
	local shell_name="${1:-all}"
	path_unregister_for_shell "skill-scanner" "${shell_name}"
}

ciss_path_register_for_vs_terminal() {
	if ciss_is_installed; then
		vscode_path_register_for_vs_terminal "skill-scanner" "${AISTACK_CISS_LAUNCHER_HOME}"
	fi
}

ciss_path_unregister_for_vs_terminal() {
	vscode_path_unregister_for_vs_terminal "skill-scanner" "${AISTACK_CISS_LAUNCHER_HOME}"
}

ciss_launch() {
	(
		[ -f "${AISTACK_GENERIC_CONTEXT_FILE}" ] && . "${AISTACK_GENERIC_CONTEXT_FILE}"
		[ -f "${AISTACK_CISS_CONTEXT_FILE}" ] && . "${AISTACK_CISS_CONTEXT_FILE}"

		if [ "$#" -gt 0 ]; then
			"${AISTACK_RUNTIME_PYTHON_SEARCH_PATH}/skill-scanner" "$@"
		else
			"${AISTACK_RUNTIME_PYTHON_SEARCH_PATH}/skill-scanner"
		fi
	)
}

ciss_launcher_and_context_files_manage() {
	local action="${1:-create}"

	case "${action}" in
		create)
			if ciss_is_installed; then
				# GENERATE CONTEXT FILE ----
				ciss_context_file_generate

				# GENERATE LAUNCHER FILE ----
				{
					echo '#!/bin/sh'

					printf 'export %s=%s\n' "AISTACK_GENERIC_CONTEXT_FILE" "$(shell_quote_posix "${AISTACK_GENERIC_CONTEXT_FILE}")"
					printf 'export %s=%s\n' "AISTACK_CISS_CONTEXT_FILE" "$(shell_quote_posix "${AISTACK_CISS_CONTEXT_FILE}")"

					declare -f ciss_launch

					echo ciss_launch \"\$@\"
				} > "${AISTACK_CISS_LAUNCHER_FILE}"

				chmod +x "${AISTACK_CISS_LAUNCHER_FILE}"
			fi
			;;
		delete)
			rm -Rf "${AISTACK_CISS_LAUNCHER_HOME}"
			mkdir -p "${AISTACK_CISS_LAUNCHER_HOME}"
			ciss_context_file_generate_remove
			;;
		refresh_if_exists)
			[ -f "${AISTACK_CISS_LAUNCHER_FILE}" ] && ( ciss_launcher_and_context_files_manage "delete"; ciss_launcher_and_context_files_manage "create" )
			;;
	esac
}

ciss_info() {
	echo "CISS available: ${AISTACK_CISS_TOOL_AVAILABLE}"
	echo "CISS path: ${AISTACK_CISS_TOOL_PATH}"
	echo "CISS needed managed runtime: ${AISTACK_CISS_RUNTIME_REQUIRED}"
	echo "CISS needed managed module: ${AISTACK_CISS_MODULE_REQUIRED}"
	echo "CISS launcher: ${AISTACK_CISS_LAUNCHER_FILE}"
	echo "CISS context file: ${AISTACK_CISS_CONTEXT_FILE}"
	echo
	echo "CISS LLM informations"
	echo "- from CLIProxyAPI"
    echo "  AISTACK_CLIPROXYAPI_KEY_FOR_CISS (exported as SKILL_SCANNER_LLM_API_KEY in ciss context) : ${AISTACK_CLIPROXYAPI_KEY_FOR_CISS}"
	echo "  AISTACK_CLIPROXYAPI_MODEL_FOR_CISS (exported as SKILL_SCANNER_LLM_MODEL): ${AISTACK_CLIPROXYAPI_MODEL_FOR_CISS}"
    echo "-"	
	echo "  AISTACK_MODEL_PROVIDER_FOR_CISS (exported as SKILL_SCANNER_LLM_PROVIDER): ${AISTACK_MODEL_PROVIDER_FOR_CISS}"
	echo "  AISTACK_MODEL_PROVIDER_URL_FOR_CISS (exported as SKILL_SCANNER_LLM_BASE_URL): ${AISTACK_MODEL_PROVIDER_URL_FOR_CISS}"
	echo "  AISTACK_MODEL_ID_FOR_CISS (exported as SKILL_SCANNER_LLM_MODEL): ${AISTACK_MODEL_ID_FOR_CISS}"
    echo "  AISTACK_MODEL_KEY_FOR_CISS (exported as SKILL_SCANNER_LLM_API_KEY in ciss context) : ${AISTACK_MODEL_KEY_FOR_CISS}"

}

ciss_settings_configure() {
	:
}

ciss_settings_remove() {
	ciss_unregister_cpa_key
	rm -Rf "${AISTACK_CISS_CONTEXT_HOME}"
}

ciss_context_file_generate() {
	local m r list_path

	echo '#!/bin/sh' > "${AISTACK_CISS_CONTEXT_FILE}"
	
	if [ -n "${AISTACK_CLIPROXYAPI_KEY_FOR_CISS}" ]; then  
        if [ -n "${AISTACK_CLIPROXYAPI_MODEL_FOR_CISS}" ]; then
			if cpa_is_configured; then
                (
					export SKILL_SCANNER_LLM_API_KEY="${AISTACK_CLIPROXYAPI_KEY_FOR_CISS}"
					export SKILL_SCANNER_LLM_PROVIDER="openai"
					export SKILL_SCANNER_LLM_BASE_URL="$(cpa_settings_get_api_endpoint)"
					export SKILL_SCANNER_LLM_MODEL="${AISTACK_CLIPROXYAPI_MODEL_FOR_CISS}"
				
                    aistack_context_file_export_variables "${AISTACK_CISS_CONTEXT_FILE}" "SKILL_SCANNER_LLM_API_KEY SKILL_SCANNER_LLM_PROVIDER SKILL_SCANNER_LLM_BASE_URL SKILL_SCANNER_LLM_MODEL"
				)
			fi
		fi
	elif [ -n "${AISTACK_MODEL_KEY_FOR_CISS}" ]; then
		if [ -n "${AISTACK_MODEL_ID_FOR_CISS}" ]; then
			(
				export SKILL_SCANNER_LLM_API_KEY="${AISTACK_MODEL_KEY_FOR_CISS}"
				export SKILL_SCANNER_LLM_PROVIDER="${AISTACK_MODEL_PROVIDER_FOR_CISS}"
				export SKILL_SCANNER_LLM_BASE_URL="${AISTACK_MODEL_PROVIDER_URL_FOR_CISS}"
				export SKILL_SCANNER_LLM_MODEL="${AISTACK_MODEL_ID_FOR_CISS}"

				aistack_context_file_export_variables "${AISTACK_CISS_CONTEXT_FILE}" "SKILL_SCANNER_LLM_API_KEY SKILL_SCANNER_LLM_PROVIDER SKILL_SCANNER_LLM_BASE_URL SKILL_SCANNER_LLM_MODEL"
			)
		fi
	fi

	# VARIABLES
	aistack_context_file_export_variables "${AISTACK_CISS_CONTEXT_FILE}" "${AISTACK_CISS_CONTEXT_EXPORT_VARIABLES}"

	# PATH
	for r in ${AISTACK_CISS_RUNTIME_REQUIRED_IN_CONTEXT}; do list_path="$(aistack_context_path_add_component "runtime" "${r}" "VARIABLE_LIST") ${list_path}"; done
	for m in ${AISTACK_CISS_MODULE_REQUIRED_IN_CONTEXT}; do list_path="$(aistack_context_path_add_component "module" "${m}" "VARIABLE_LIST") ${list_path}"; done
	aistack_context_file_export_path "${AISTACK_CISS_CONTEXT_FILE}" "${list_path}" "VARIABLE_LIST"

	chmod +x "${AISTACK_CISS_CONTEXT_FILE}"
}

ciss_context_file_generate_remove() {
	rm -f "${AISTACK_CISS_CONTEXT_FILE}"
}

ciss_generate_cpa_key() {
	ciss_unregister_cpa_key
	export AISTACK_CLIPROXYAPI_KEY_FOR_CISS="$(${STELLA_API} generate_password 48 "[:alnum:]")"
	cpa_settings_api_key_add "${AISTACK_CLIPROXYAPI_KEY_FOR_CISS}" || {
		export AISTACK_CLIPROXYAPI_KEY_FOR_CISS=
		echo "ERROR: Failed to generate and register CLIProxyAPI API key for Cisco AI Skill Scanner."
		return 1
	}
	echo "${AISTACK_CLIPROXYAPI_KEY_FOR_CISS}" > "${AISTACK_CLIPROXYAPI_KEY_FOR_CISS_FILE}"
	ciss_launcher_and_context_files_manage "create"
}

ciss_unregister_cpa_key() {
	cpa_settings_api_key_del "${AISTACK_CLIPROXYAPI_KEY_FOR_CISS}"
	export AISTACK_CLIPROXYAPI_KEY_FOR_CISS=
	rm -f "${AISTACK_CLIPROXYAPI_KEY_FOR_CISS_FILE}"
}

ciss_unregister_model() {
	local provider="${1}"
	case "${provider}" in
		CPA)
			ciss_unregister_cpa_key
			export AISTACK_CLIPROXYAPI_MODEL_FOR_CISS=
			rm -f "${AISTACK_CLIPROXYAPI_MODEL_FOR_CISS_FILE}"
			;;
		*)
			export AISTACK_MODEL_KEY_FOR_CISS=
			rm -f "${AISTACK_MODEL_KEY_FOR_CISS_FILE}"
			export AISTACK_MODEL_ID_FOR_CISS=
			rm -f "${AISTACK_MODEL_ID_FOR_CISS_FILE}"
			export AISTACK_MODEL_PROVIDER_FOR_CISS=
			rm -f "${AISTACK_MODEL_PROVIDER_FOR_CISS_FILE}"
			export AISTACK_MODEL_PROVIDER_URL_FOR_CISS=
			rm -f "${AISTACK_MODEL_PROVIDER_URL_FOR_CISS_FILE}"
			;;
	esac
}

ciss_register_model() {
	local provider="${1}"
	local id_model="${2}"
	local model_key="${3}"
	local provider_url="${4:-}"

	case "${provider}" in
		CPA)
			ciss_unregister_model
			export AISTACK_CLIPROXYAPI_MODEL_FOR_CISS="${id_model}"
			echo "${AISTACK_CLIPROXYAPI_MODEL_FOR_CISS}" > "${AISTACK_CLIPROXYAPI_MODEL_FOR_CISS_FILE}"
			;;
		*)
			ciss_unregister_model "CPA"
			export AISTACK_MODEL_KEY_FOR_CISS="${model_key}"
			echo "${AISTACK_MODEL_KEY_FOR_CISS}" > "${AISTACK_MODEL_KEY_FOR_CISS_FILE}"
			export AISTACK_MODEL_ID_FOR_CISS="${id_model}"
			echo "${AISTACK_MODEL_ID_FOR_CISS}" > "${AISTACK_MODEL_ID_FOR_CISS_FILE}"
			export AISTACK_MODEL_PROVIDER_FOR_CISS="${provider}"
			echo "${AISTACK_MODEL_PROVIDER_FOR_CISS}" > "${AISTACK_MODEL_PROVIDER_FOR_CISS_FILE}"
			export AISTACK_MODEL_PROVIDER_URL_FOR_CISS="${provider_url}"
			echo "${AISTACK_MODEL_PROVIDER_URL_FOR_CISS}" > "${AISTACK_MODEL_PROVIDER_URL_FOR_CISS_FILE}"
			;;
	esac
	ciss_launcher_and_context_files_manage "create"
}

ciss_connect_cpa() {
	local model="${1}"
	local selected_model
	if ! cpa_is_configured; then
		echo "ERROR: CLIProxyAPI is not configured."
		return 1
	fi

	echo "Generating a CLIProxyAPI API key for Cisco AI Skill Scanner"
	ciss_generate_cpa_key || return 1
	if [ -n "${model}" ]; then
		selected_model="${model}"
	else
		if ! cpa_instance_reachable; then
			echo "ERROR: CLIProxyAPI instance is not reachable. Please make sure CLIProxyAPI is running and properly configured."
			return 1
		fi
		selected_model="$(cpa_get_model_list | head -n 1)"
	fi

	echo "Connecting Cisco AI Skill Scanner to model ${selected_model}."
	ciss_register_model "CPA" "${selected_model}"
}
