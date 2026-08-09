sktor_init() {
	# skillspector launcher
	export AISTACK_SKTOR_LAUNCHER_HOME="${AISTACK_LAUNCHER_HOME}/sktor"
	mkdir -p "${AISTACK_SKTOR_LAUNCHER_HOME}"
	export AISTACK_SKTOR_LAUNCHER_FILE="${AISTACK_SKTOR_LAUNCHER_HOME}/skillspector"

	# skillspector context
	export AISTACK_SKTOR_CONTEXT_HOME="${AISTACK_CONTEXT_HOME}/sktor"
	mkdir -p "${AISTACK_SKTOR_CONTEXT_HOME}"
	export AISTACK_SKTOR_CONTEXT_FILE="${AISTACK_SKTOR_CONTEXT_HOME}/sktor_context.sh"
	# any variables needed to run this component or used by _launch function
	# NOTE: do not need to declare those variables:
	#		AISTACK_*_CONTEXT_FILE and AISTACK_GENERIC_CONTEXT_FILE are already exported
	#		every *_SEARCH_PATH variable related to a REQUIRED_RUNTIME or REQUIRED_MODULE are already exported
	export AISTACK_SKTOR_CONTEXT_EXPORT_VARIABLES=""

	# cpa key for skillspector to connect to cpa backend
	# context folder will also contain CPA key
	export AISTACK_CLIPROXYAPI_KEY_FOR_SKTOR_FILE="${AISTACK_SKTOR_CONTEXT_HOME}/cpa_key_for_sktor"
	[ -f "$AISTACK_CLIPROXYAPI_KEY_FOR_SKTOR_FILE" ] && export AISTACK_CLIPROXYAPI_KEY_FOR_SKTOR="$(cat "$AISTACK_CLIPROXYAPI_KEY_FOR_SKTOR_FILE")"
	export AISTACK_CLIPROXYAPI_MODEL_FOR_SKTOR_FILE="${AISTACK_SKTOR_CONTEXT_HOME}/cpa_model_for_sktor"
	[ -f "$AISTACK_CLIPROXYAPI_MODEL_FOR_SKTOR_FILE" ] && export AISTACK_CLIPROXYAPI_MODEL_FOR_SKTOR="$(cat "$AISTACK_CLIPROXYAPI_MODEL_FOR_SKTOR_FILE")"

    export AISTACK_MODEL_KEY_FOR_SKTOR_FILE="${AISTACK_SKTOR_CONTEXT_HOME}/model_key_for_sktor"
    [ -f "$AISTACK_MODEL_KEY_FOR_SKTOR_FILE" ] && export AISTACK_MODEL_KEY_FOR_SKTOR="$(cat "$AISTACK_MODEL_KEY_FOR_SKTOR_FILE")"
    export AISTACK_MODEL_ID_FOR_SKTOR_FILE="${AISTACK_SKTOR_CONTEXT_HOME}/model_id_for_sktor"
    [ -f "$AISTACK_MODEL_ID_FOR_SKTOR_FILE" ] && export AISTACK_MODEL_ID_FOR_SKTOR="$(cat "$AISTACK_MODEL_ID_FOR_SKTOR_FILE")"
    export AISTACK_MODEL_PROVIDER_FOR_SKTOR_FILE="${AISTACK_SKTOR_CONTEXT_HOME}/model_provider_for_sktor"
    [ -f "$AISTACK_MODEL_PROVIDER_FOR_SKTOR_FILE" ] && export AISTACK_MODEL_PROVIDER_FOR_SKTOR="$(cat "$AISTACK_MODEL_PROVIDER_FOR_SKTOR_FILE")"
    export AISTACK_MODEL_PROVIDER_URL_FOR_SKTOR_FILE="${AISTACK_SKTOR_CONTEXT_HOME}/model_provider_url_for_sktor"
    [ -f "$AISTACK_MODEL_PROVIDER_URL_FOR_SKTOR_FILE" ] && export AISTACK_MODEL_PROVIDER_URL_FOR_SKTOR="$(cat "$AISTACK_MODEL_PROVIDER_URL_FOR_SKTOR_FILE")"

	export AISTACK_SKILLSPECTOR_MODEL_REGISTRY="${AISTACK_SKTOR_CONTEXT_HOME}/model_registry.yaml"

	# skillspector requirement - those will be installed and presence checked to run the current component
	# NOTE:	those search path will be injected in context file
	export AISTACK_SKTOR_RUNTIME_REQUIRED="python"
	export AISTACK_SKTOR_MODULE_REQUIRED=""
	if [ ! "${STELLA_CURRENT_PLATFORM}" = "darwin" ]; then
		# if we are on glibc2.17 we need to build tiktoken with rust compiler
		case $(glibc_version_compare "${AISTACK_GLIBC_CURRENT_VERSION}" "2.17") in
			-1|0) 
				# yara-x is available for glibc 2.17 with yara-x<1.0.2 but cisco-ai-skill-scanner 2.x needs yara-x=>1.10
				# need to build it and install it before cisco-ai-skill-scanner
				export AISTACK_SKTOR_RUNTIME_REQUIRED="python rust"
				;;
		esac
	fi
	# remove from context any runtime or module any item already in generic aistack context
	export AISTACK_SKTOR_RUNTIME_REQUIRED_IN_CONTEXT="$($STELLA_API filter_list_with_list "${AISTACK_SKTOR_RUNTIME_REQUIRED}" "${AISTACK_GENERIC_CONTEXT_ADD_RUNTIME}")"
	export AISTACK_SKTOR_MODULE_REQUIRED_IN_CONTEXT="$($STELLA_API filter_list_with_list "${AISTACK_SKTOR_MODULE_REQUIRED}" "${AISTACK_GENERIC_CONTEXT_ADD_MODULE}")"
}

# test if skillspector is installed
# return 0 : is installed
# return 1 : tool is not installed
# return 2 : missing runtime
sktor_is_installed() {
	local r m
	export AISTACK_SKTOR_TOOL_AVAILABLE="false"
	export AISTACK_SKTOR_TOOL_PATH=""
	for r in ${AISTACK_SKTOR_RUNTIME_REQUIRED}; do aistack_runtime_is_detected "${r}" || return 2; done
	for m in ${AISTACK_SKTOR_MODULE_REQUIRED}; do aistack_module_is_detected "${m}" || return 2; done
	[ -x "${AISTACK_RUNTIME_PYTHON_SEARCH_PATH}/skillspector" ] || return 1
	export AISTACK_SKTOR_TOOL_PATH="${AISTACK_RUNTIME_PYTHON_SEARCH_PATH}/skillspector"
	export AISTACK_SKTOR_TOOL_AVAILABLE="true"
	return 0
}



sktor_install() {
	local r m

	for r in ${AISTACK_SKTOR_RUNTIME_REQUIRED}; do
		echo "INFO: skillspector require ${r} managed runtime"
		aistack_runtime_require "${r}"
	done
	for m in ${AISTACK_SKTOR_MODULE_REQUIRED}; do
		echo "INFO: skillspector require ${m} managed module"
		aistack_module_require "${m}"
	done

	echo "Installing skillspector"
	python_uv_package_install 'skillspector[mcp] @ git+https://github.com/NVIDIA/skillspector.git' || return $?
	
	sktor_is_installed
	return $?
}
 
sktor_uninstall() {
	if sktor_is_installed; then
		python_uv_package_uninstall 'skillspector[mcp]' || return $?
		sktor_is_installed && return 1
		return 0
	else
		echo "WARN : not installed or missing a required managed runtime $AISTACK_SKTOR_RUNTIME_REQUIRED"
	fi
}


sktor_path_register_for_shell() {
    local shell_name="$1"
	if sktor_is_installed; then
    	path_register_for_shell "skillspector" "${AISTACK_SKTOR_LAUNCHER_HOME}" "$shell_name"
	fi
}
sktor_path_unregister_for_shell() {
    local shell_name="${1:-all}"
    path_unregister_for_shell "skillspector" "$shell_name"
}
sktor_path_register_for_vs_terminal() {
	if sktor_is_installed; then
    	vscode_path_register_for_vs_terminal "skillspector" "${AISTACK_SKTOR_LAUNCHER_HOME}"
	fi
}
sktor_path_unregister_for_vs_terminal() {
    vscode_path_unregister_for_vs_terminal "skillspector" "${AISTACK_SKTOR_LAUNCHER_HOME}"
}

sktor_launch() {
	(
		[ -f "${AISTACK_GENERIC_CONTEXT_FILE}" ] && . "${AISTACK_GENERIC_CONTEXT_FILE}"
		[ -f "${AISTACK_SKTOR_CONTEXT_FILE}" ] && . "${AISTACK_SKTOR_CONTEXT_FILE}"

		if [ "$#" -gt 0 ]; then
			"${AISTACK_RUNTIME_PYTHON_SEARCH_PATH}/skillspector" "$@"
		else
			"${AISTACK_RUNTIME_PYTHON_SEARCH_PATH}/skillspector"
		fi
	)
}

sktor_launcher_manage() {
    local action="${1:-create}"

    case ${action} in
		create)
			if sktor_is_installed; then
				# GENERATE CONTEXT FILE ----
				sktor_context_file_generate

				# GENERATE LAUNCHER FILE ----
				{
					echo '#!/bin/sh'

					printf 'export %s=%s\n' "AISTACK_GENERIC_CONTEXT_FILE" "$(shell_quote_posix "${AISTACK_GENERIC_CONTEXT_FILE}")"
					printf 'export %s=%s\n' "AISTACK_SKTOR_CONTEXT_FILE" "$(shell_quote_posix "${AISTACK_SKTOR_CONTEXT_FILE}")"

					declare -f sktor_launch

					echo sktor_launch \"\$@\"
				} > "${AISTACK_SKTOR_LAUNCHER_FILE}"

				chmod +x "${AISTACK_SKTOR_LAUNCHER_FILE}"
			fi
            ;;

        delete)
			rm -Rf "${AISTACK_SKTOR_LAUNCHER_HOME}"
			mkdir -p "${AISTACK_SKTOR_LAUNCHER_HOME}"
			sktor_context_file_generate_remove
            ;;

		refresh_if_exists)
			[ -f "${AISTACK_SKTOR_LAUNCHER_FILE}" ] && ( sktor_launcher_manage "delete"; sktor_launcher_manage "create" )
			;;
    esac
}



sktor_info() {
	echo "SKTOR available : ${AISTACK_SKTOR_TOOL_AVAILABLE}"
	echo "SKTOR path : ${AISTACK_SKTOR_TOOL_PATH}"
	echo "SKTOR needed managed runtime : ${AISTACK_SKTOR_RUNTIME_REQUIRED}"
	echo "SKTOR needed managed module : ${AISTACK_SKTOR_MODULE_REQUIRED}"
	echo "SKTOR launcher : ${AISTACK_SKTOR_LAUNCHER_FILE}"
	echo "SKTOR context file : ${AISTACK_SKTOR_CONTEXT_FILE}"
	echo
    
    echo "SKTOR LLM informations"
    echo "- from CLIProxyAPI"
    echo "  AISTACK_CLIPROXYAPI_KEY_FOR_SKTOR (exported as OPENAI_API_KEY or ANTHROPIC_API_KEY in sktor context) : ${AISTACK_CLIPROXYAPI_KEY_FOR_SKTOR}"
    echo "  AISTACK_CLIPROXYAPI_MODEL_FOR_SKTOR (exported as SKILLSPECTOR_MODEL in sktor context) : ${AISTACK_CLIPROXYAPI_MODEL_FOR_SKTOR}"
    echo "-"
    echo "  AISTACK_MODEL_PROVIDER_FOR_SKTOR (exported as SKILLSPECTOR_PROVIDER in sktor context) : ${AISTACK_MODEL_PROVIDER_FOR_SKTOR}"
    echo "  AISTACK_MODEL_PROVIDER_URL_FOR_SKTOR (if openai provider exported as OPENAI_BASE_URL in sktor context) : ${AISTACK_MODEL_PROVIDER_URL_FOR_SKTOR}"
    echo "  AISTACK_MODEL_ID_FOR_SKTOR (exported as SKILLSPECTOR_MODEL in sktor context) : ${AISTACK_MODEL_ID_FOR_SKTOR}"
    echo "  AISTACK_MODEL_KEY_FOR_SKTOR (exported as OPENAI_API_KEY in sktor context) : ${AISTACK_MODEL_KEY_FOR_SKTOR}"
    echo "-"
    echo "Model registry file:"
    echo "  AISTACK_SKILLSPECTOR_MODEL_REGISTRY exported as SKILLSPECTOR_MODEL_REGISTRY in sktor context) : ${AISTACK_SKILLSPECTOR_MODEL_REGISTRY}"
    [ -f "${AISTACK_SKILLSPECTOR_MODEL_REGISTRY}" ] && echo "   Model registry file exists" || echo "   Model registry file do not exists" 

}

sktor_settings_configure() {
	:
}

sktor_settings_remove() {
    sktor_unregister_cpa_key
    rm -Rf "${AISTACK_SKTOR_CONTEXT_HOME}"
}

sktor_context_file_generate() {
	local m r 
    local list_path=""

	# GENERATE CONTEXT FILE ----
	echo '#!/bin/sh' > "${AISTACK_SKTOR_CONTEXT_FILE}"
	chmod +x "${AISTACK_SKTOR_CONTEXT_FILE}"


    if [ -n "${AISTACK_CLIPROXYAPI_KEY_FOR_SKTOR}" ]; then  
        if [ -n "${AISTACK_CLIPROXYAPI_MODEL_FOR_SKTOR}" ]; then
            if cpa_is_configured; then
                (
                    export SKILLSPECTOR_PROVIDER="openai"
                    export OPENAI_API_KEY="${AISTACK_CLIPROXYAPI_KEY_FOR_SKTOR}"
                    export OPENAI_BASE_URL="$(cpa_settings_get_api_endpoint)"
                    export SKILLSPECTOR_MODEL="${AISTACK_CLIPROXYAPI_MODEL_FOR_SKTOR}"
                    [ -f "${AISTACK_SKILLSPECTOR_MODEL_REGISTRY}" ] && export SKILLSPECTOR_MODEL_REGISTRY="${AISTACK_SKILLSPECTOR_MODEL_REGISTRY}"
	                
                    aistack_context_file_export_variables "${AISTACK_SKTOR_CONTEXT_FILE}" "SKILLSPECTOR_PROVIDER OPENAI_API_KEY OPENAI_BASE_URL SKILLSPECTOR_MODEL SKILLSPECTOR_MODEL_REGISTRY"
                )
            fi
        fi
    elif [ -n "${AISTACK_MODEL_KEY_FOR_SKTOR}" ]; then  
        if [ -n "${AISTACK_MODEL_ID_FOR_SKTOR}" ]; then
            ( 
                export SKILLSPECTOR_PROVIDER="${AISTACK_MODEL_PROVIDER_FOR_SKTOR}"
                # NOTE : see https://github.com/nvidia/skillspector#llm-analysis for specific variables
                case "${AISTACK_MODEL_PROVIDER_FOR_SKTOR}" in
                    "openai")
                        export OPENAI_API_KEY="${AISTACK_MODEL_KEY_FOR_SKTOR}"
                        export OPENAI_BASE_URL="${AISTACK_MODEL_PROVIDER_URL_FOR_SKTOR}"
                        ;;
                    "anthropic")
                        export ANTHROPIC_API_KEY="${AISTACK_MODEL_KEY_FOR_SKTOR}"
                        ;;
                esac
                export SKILLSPECTOR_MODEL="${AISTACK_MODEL_ID_FOR_SKTOR}"
                [ -f "${AISTACK_SKILLSPECTOR_MODEL_REGISTRY}" ] && export SKILLSPECTOR_MODEL_REGISTRY="${AISTACK_SKILLSPECTOR_MODEL_REGISTRY}"
            
                aistack_context_file_export_variables "${AISTACK_SKTOR_CONTEXT_FILE}" "SKILLSPECTOR_PROVIDER OPENAI_API_KEY OPENAI_BASE_URL ANTHROPIC_API_KEY SKILLSPECTOR_MODEL SKILLSPECTOR_MODEL_REGISTRY"
            )
        fi
    fi

	# VARIABLES
	aistack_context_file_export_variables "${AISTACK_SKTOR_CONTEXT_FILE}" "${AISTACK_SKTOR_CONTEXT_EXPORT_VARIABLES}"
    
	# PATH
	for r in ${AISTACK_SKTOR_RUNTIME_REQUIRED_IN_CONTEXT}; do list_path="$(aistack_context_path_add_component "runtime" "${r}" "VARIABLE_LIST") ${list_path}"; done
	for m in ${AISTACK_SKTOR_MODULE_REQUIRED_IN_CONTEXT}; do list_path="$(aistack_context_path_add_component "module" "${m}" "VARIABLE_LIST") ${list_path}"; done
	aistack_context_file_export_path "${AISTACK_SKTOR_CONTEXT_FILE}" "${list_path}" "VARIABLE_LIST"

}

sktor_context_file_generate_remove() {
	rm -f "${AISTACK_SKTOR_CONTEXT_FILE}"
}


# cliproxy api connection management ------------------------

sktor_generate_cpa_key() {
    sktor_unregister_cpa_key

    # Generating a CPA API key for Sktor
    export AISTACK_CLIPROXYAPI_KEY_FOR_SKTOR="$($STELLA_API generate_password 48 "[:alnum:]")"
    cpa_settings_api_key_add "$AISTACK_CLIPROXYAPI_KEY_FOR_SKTOR"
    if [ $? -ne 0 ]; then
        export AISTACK_CLIPROXYAPI_KEY_FOR_SKTOR=
        echo "ERROR: Failed to generate and register CPA API key for skillspector."
        return 1
    fi
    echo "$AISTACK_CLIPROXYAPI_KEY_FOR_SKTOR" > "$AISTACK_CLIPROXYAPI_KEY_FOR_SKTOR_FILE"

    # each time an api key is generated we need to refresh the launcher to update env vars
    sktor_launcher_manage "create"
}

sktor_unregister_cpa_key() {
    # Remove existing CPA API key for Sktor
    cpa_settings_api_key_del "${AISTACK_CLIPROXYAPI_KEY_FOR_SKTOR}"
    export AISTACK_CLIPROXYAPI_KEY_FOR_SKTOR=
    rm -f "${AISTACK_CLIPROXYAPI_KEY_FOR_SKTOR_FILE}"
}

# unregister any previsously registered model
# use "CPA" as providerif to unregister model from CLIProxyAPI
sktor_unregister_model() {
    local provider="${1}"

    rm -f "${AISTACK_SKILLSPECTOR_MODEL_REGISTRY}"

    case ${provider} in
        CPA)
            # remove model from CLIProxyAPI
            sktor_unregister_cpa_key
            export AISTACK_CLIPROXYAPI_MODEL_FOR_SKTOR=
            rm -f ${AISTACK_CLIPROXYAPI_MODEL_FOR_SKTOR_FILE}
        ;;
        *)
            # remove other provider LLM info
            export AISTACK_MODEL_KEY_FOR_SKTOR=
            rm -f ${AISTACK_MODEL_KEY_FOR_SKTOR_FILE}
            export AISTACK_MODEL_ID_FOR_SKTOR=
            rm -f ${AISTACK_MODEL_ID_FOR_SKTOR_FILE}
            export AISTACK_MODEL_PROVIDER_FOR_SKTOR=
            rm -f ${AISTACK_MODEL_PROVIDER_FOR_SKTOR_FILE}
            export AISTACK_MODEL_PROVIDER_URL_FOR_SKTOR=
            rm -f ${AISTACK_MODEL_PROVIDER_URL_FOR_SKTOR_FILE}
        ;;
    esac
}

# use "CPA" as provider if it is a model from CLIProxyAPI
sktor_register_model() {
    local provider="${1}"
    local id_model="${2}"
    local model_key="${3}"
    local provider_url="${4:-}"
    local context_length="${5:-}"
    local max_output_tokens="${6:-}"
    
    case $provider in
        CPA)
            sktor_unregister_model

            # set model id from cliproxyapi
            export AISTACK_CLIPROXYAPI_MODEL_FOR_SKTOR="${id_model}"
            echo "${AISTACK_CLIPROXYAPI_MODEL_FOR_SKTOR}" > "${AISTACK_CLIPROXYAPI_MODEL_FOR_SKTOR_FILE}"
        
        ;;
        *)
            sktor_unregister_model "CPA"

            # set model info from provider
            export AISTACK_MODEL_KEY_FOR_SKTOR="${model_key}"
            echo "${AISTACK_MODEL_KEY_FOR_SKTOR}" > "${AISTACK_MODEL_KEY_FOR_SKTOR_FILE}"
            export AISTACK_MODEL_ID_FOR_SKTOR="${id_model}"
            echo "${AISTACK_MODEL_ID_FOR_SKTOR}" > "${AISTACK_MODEL_ID_FOR_SKTOR_FILE}"
            export AISTACK_MODEL_PROVIDER_FOR_SKTOR="${provider}"
            echo "${AISTACK_MODEL_PROVIDER_FOR_SKTOR}" > "${AISTACK_MODEL_PROVIDER_FOR_SKTOR_FILE}"
            export AISTACK_MODEL_PROVIDER_URL_FOR_SKTOR="${provider_url}"
            echo "${AISTACK_MODEL_PROVIDER_URL_FOR_SKTOR}" > "${AISTACK_MODEL_PROVIDER_URL_FOR_SKTOR_FILE}"
        ;;
    esac
    
    sktor_register_model_in_model_registry "${id_model}" "${context_length}" "${max_output_tokens}"
    sktor_launcher_manage "create"

}

sktor_register_model_in_model_registry() {
    local id_model="${1}"
    local context_length="${2:-128000}"
    local max_output_tokens="${3:-16384}"
    
    # manage sktor registry model
    # default file model_registry.yaml : https://github.com/NVIDIA/SkillSpector/blob/c2d09df019e358d3dc12d980b82c798b87cb9f56/model_registry.yaml
    # models:
    #     "<model-label>":
    #     context_length: <int>          # total context window in tokens (required)
    #     max_output_tokens: <int>       # model's max output cap (optional)
    rm -f "${AISTACK_SKILLSPECTOR_MODEL_REGISTRY}"

    id_model="${id_model//./\\.}"
    yaml_set_key_into_file "${AISTACK_SKILLSPECTOR_MODEL_REGISTRY}" ".models.${id_model}.context_length" "${context_length}"
    yaml_set_key_into_file "${AISTACK_SKILLSPECTOR_MODEL_REGISTRY}" ".models.${id_model}.max_output_tokens" "${max_output_tokens}"
}

# needs cpa to be running
sktor_connect_cpa() {
    local model="${1}"
    local context_length="${2}"
    local max_output_tokens="${3}"

    if ! cpa_is_configured; then
        echo "ERROR: Failed to generate and register CLIProxyAPI API key for skillspector : CLIProxyAPI is not configured."
        return 1
    fi
    
    # needs cpa conf file exists
    echo "generate a CLIProxyAPI API key for skillspector to connect to CPA backend"
    sktor_generate_cpa_key
    if [ $? -ne 0 ]; then
        echo "ERROR: Failed to generate and register CLIProxyAPI API key for skillspector."
        return 1
    fi
   
	local selected_model
    if [ -n "${model}" ]; then
        selected_model="${model}"
    else
        # request cpa to get the first model available as the default model for orla AGENT mode
        # cpa_get_model_list needs cpa to be running
         if ! cpa_instance_reachable; then
            echo "ERROR: CLIProxyAPI instance is not reachable. Please make sure CLIProxyAPI is running and properly configured."
            return 1
        fi
        selected_model="$(cpa_get_model_list | head -n 1)"
    fi

    echo "Connect skillspector to model ${selected_model}."
    sktor_register_model "CPA" "${selected_model}" "" "" "${context_length}" "${max_output_tokens}"

}
