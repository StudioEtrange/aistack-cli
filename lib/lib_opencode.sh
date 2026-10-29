opencode_init() {
	# opencode specific variables
	export AISTACK_OPENCODE_CONFIG_HOME="${HOME}/.config/opencode"
	mkdir -p "${AISTACK_OPENCODE_CONFIG_HOME}"
	# OPENCODE_CONFIG takes precedence over the global and project configurations.
	[ -z "${OPENCODE_CONFIG}" ] && export AISTACK_OPENCODE_CONFIG_FILE="${AISTACK_OPENCODE_CONFIG_HOME}/opencode.json" || export AISTACK_OPENCODE_CONFIG_FILE="${OPENCODE_CONFIG}"
	export OPENCODE_CONFIG="${AISTACK_OPENCODE_CONFIG_FILE}"
	export OPENCODE_FEAT_INSTALL_ROOT="${AISTACK_ISOLATED_ROOT}/opencode"
	mkdir -p "${OPENCODE_FEAT_INSTALL_ROOT}"

	export AISTACK_OPENCODE_CLI_CONFIG_FILE="${AISTACK_OPENCODE_CONFIG_HOME}/cli.json"

	# cpa key for opencode to connect to cpa backend
	export AISTACK_CLIPROXYAPI_KEY_FOR_OPENCODE_FILE="${AISTACK_OPENCODE_CONFIG_HOME}/cpa_key_for_oc"
	[ -f "$AISTACK_CLIPROXYAPI_KEY_FOR_OPENCODE_FILE" ] && export AISTACK_CLIPROXYAPI_KEY_FOR_OPENCODE="$(cat "$AISTACK_CLIPROXYAPI_KEY_FOR_OPENCODE_FILE")"

	# opencode launcher
	export AISTACK_OPENCODE_LAUNCHER_HOME="${AISTACK_LAUNCHER_HOME}/opencode"
	mkdir -p "${AISTACK_OPENCODE_LAUNCHER_HOME}"
	export AISTACK_OPENCODE_LAUNCHER_FILE="${AISTACK_OPENCODE_LAUNCHER_HOME}/opencode"

	# opencode context
	export AISTACK_OPENCODE_CONTEXT_HOME="${AISTACK_CONTEXT_HOME}/opencode"
	mkdir -p "${AISTACK_OPENCODE_CONTEXT_HOME}"
	export AISTACK_OPENCODE_CONTEXT_FILE="${AISTACK_OPENCODE_CONTEXT_HOME}/opencode_context.sh"
	# any variables needed to run this component or used by _launch function
	# NOTE: do not need to declare those variables:
	#		AISTACK_*_CONTEXT_FILE and AISTACK_GENERIC_CONTEXT_FILE are already exported
	#		every *_SEARCH_PATH variable related to a REQUIRED_RUNTIME or REQUIRED_MODULE are already exported
	export AISTACK_OPENCODE_CONTEXT_EXPORT_VARIABLES="OPENCODE_FEAT_INSTALL_ROOT AISTACK_CLIPROXYAPI_KEY_FOR_OPENCODE OPENCODE_CONFIG"

	# opencode requirement - those will be installed and presence checked to run the current component
	# NOTE:	those search path will be injected in context file
	export AISTACK_OPENCODE_RUNTIME_REQUIRED="nodejs"
	export AISTACK_OPENCODE_MODULE_REQUIRED=""
	# remove from context any runtime or module any item already in generic aistack context
	export AISTACK_OPENCODE_RUNTIME_REQUIRED_IN_CONTEXT="$($STELLA_API filter_list_with_list "${AISTACK_OPENCODE_RUNTIME_REQUIRED}" "${AISTACK_GENERIC_CONTEXT_ADD_RUNTIME}")"
	export AISTACK_OPENCODE_MODULE_REQUIRED_IN_CONTEXT="$($STELLA_API filter_list_with_list "${AISTACK_OPENCODE_MODULE_REQUIRED}" "${AISTACK_GENERIC_CONTEXT_ADD_MODULE}")"

}

# test if opencode is installed
# return 0 : is installed
# return 1 : tool is not installed
# return 2 : missing runtime
opencode_is_installed() {
	local r m
	export AISTACK_OPENCODE_TOOL_AVAILABLE="false"
	export AISTACK_OPENCODE_TOOL_SEARCH_PATH=""
	export AISTACK_OPENCODE_TOOL_PATH=""
	#export OPENCODE_BINARY=""
	for r in ${AISTACK_OPENCODE_RUNTIME_REQUIRED}; do aistack_runtime_is_detected "${r}" || return 2; done
	for m in ${AISTACK_OPENCODE_MODULE_REQUIRED}; do aistack_module_is_detected "${m}" || return 2; done
	[ -x "${OPENCODE_FEAT_INSTALL_ROOT}/bin/opencode" ] || return 1
	export AISTACK_OPENCODE_TOOL_AVAILABLE="true"
	export AISTACK_OPENCODE_TOOL_SEARCH_PATH="${OPENCODE_FEAT_INSTALL_ROOT}/bin"
	export AISTACK_OPENCODE_TOOL_PATH="${AISTACK_OPENCODE_TOOL_SEARCH_PATH}/opencode"

	# NOTE : we do not use it
	# export OPENCODE_BINARY="$AISTACK_OPENCODE_LAUNCHER_FILE"
	return 0
}

# flavor : 1 for opencode 1.x or 2 for opencode 2.x
# version : specific version or latest
opencode_install() {
	local r m
	local version="$1"
	[ -z "${version}" ] && version="@latest"
	local flavor="$2"
	[ -z "${flavor}" ] && flavor="2"

	for r in ${AISTACK_OPENCODE_RUNTIME_REQUIRED}; do
		echo "INFO: OpenCode require ${r} managed runtime"
		aistack_runtime_require "${r}"
	done

	for m in ${AISTACK_OPENCODE_MODULE_REQUIRED}; do
		echo "INFO: OpenCode require ${m} managed module"
		aistack_module_require "${m}"
	done

	echo "Installing Opencode CLI flavor $flavor version ${version}"
	case "$flavor" in
		"1")
			node_isolated_package_install "${OPENCODE_FEAT_INSTALL_ROOT}" --allow-scripts=opencode-ai "opencode-ai${version}" || return $?
			;;
		"2")
			node_isolated_package_install "${OPENCODE_FEAT_INSTALL_ROOT}" --allow-scripts=@opencode/cli "@opencode/cli${version}" || return $?
			;;
	esac



	opencode_is_installed
	return $?
}

opencode_uninstall() {
	local flavor="$1"
	[ -z "${flavor}" ] && flavor="2"
	if opencode_is_installed; then
		case "$flavor" in
			"1")
				node_isolated_package_uninstall "${OPENCODE_FEAT_INSTALL_ROOT}" "opencode-ai" || return $?
				;;
			"2")
				node_isolated_package_uninstall "${OPENCODE_FEAT_INSTALL_ROOT}" "@opencode/cli" || return $?
				;;
		esac
		rm -Rf "${OPENCODE_FEAT_INSTALL_ROOT}"
		opencode_is_installed && return 1
		return 0
	else
		echo "WARN : not installed or missing requirements."
	fi
}


opencode_path_register_for_shell() {
    local shell_name="${1:-current}"
	if opencode_is_installed; then
    	register_path_named_bloc_for_shell "opencode" "${AISTACK_OPENCODE_LAUNCHER_HOME}" "$shell_name"
	fi
}
opencode_path_unregister_for_shell() {
    local shell_name="${1:-all}"
    unregister_path_named_bloc_for_shell "opencode" "$shell_name"
}
opencode_path_register_for_vs_terminal() {
	if opencode_is_installed; then
    	vscode_path_register_for_vs_terminal "opencode" "${AISTACK_OPENCODE_LAUNCHER_HOME}"
	fi
}
opencode_path_unregister_for_vs_terminal() {
    vscode_path_unregister_for_vs_terminal "opencode" "${AISTACK_OPENCODE_LAUNCHER_HOME}"
}

opencode_launch() {
	(
		[ -f "${AISTACK_GENERIC_CONTEXT_FILE}" ] && . "${AISTACK_GENERIC_CONTEXT_FILE}"
		[ -f "${AISTACK_OPENCODE_CONTEXT_FILE}" ] && . "${AISTACK_OPENCODE_CONTEXT_FILE}"

		if [ "$#" -gt 0 ]; then
			"${OPENCODE_FEAT_INSTALL_ROOT}/bin/opencode" "$@"
		else
			"${OPENCODE_FEAT_INSTALL_ROOT}/bin/opencode"
		fi
	)
}

opencode_launcher_and_context_files_manage() {
    local action="${1:-create}"

	case $action in
		create)
			if opencode_is_installed; then
				# GENERATE CONTEXT FILE ----
				opencode_context_file_generate

				# GENERATE LAUNCHER FILE ----
				{
					echo '#!/bin/sh'

					printf 'export %s=%s\n' "AISTACK_GENERIC_CONTEXT_FILE" "$(shell_quote_posix "${AISTACK_GENERIC_CONTEXT_FILE}")"
					printf 'export %s=%s\n' "AISTACK_OPENCODE_CONTEXT_FILE" "$(shell_quote_posix "${AISTACK_OPENCODE_CONTEXT_FILE}")"

					declare -f opencode_launch

					echo opencode_launch \"\$@\"
				} > "${AISTACK_OPENCODE_LAUNCHER_FILE}"

				chmod +x "${AISTACK_OPENCODE_LAUNCHER_FILE}"
			fi
            ;;

        delete)
			rm -f "${AISTACK_OPENCODE_LAUNCHER_FILE}"
			opencode_context_file_generate_remove
            ;;
	
		refresh_if_exists)
			[ -f "${AISTACK_OPENCODE_LAUNCHER_FILE}" ] && ( opencode_launcher_and_context_files_manage "delete"; opencode_launcher_and_context_files_manage "create" )
			;;
    esac
}

opencode_context_file_generate() {
	# GENERATE CONTEXT FILE ----
	echo '#!/bin/sh' > "${AISTACK_OPENCODE_CONTEXT_FILE}"
	chmod +x "${AISTACK_OPENCODE_CONTEXT_FILE}"

	# VARIABLES
	aistack_context_file_export_variables "${AISTACK_OPENCODE_CONTEXT_FILE}" "${AISTACK_OPENCODE_CONTEXT_EXPORT_VARIABLES}"

	# PATH
	local m r list_path
	for r in ${AISTACK_OPENCODE_RUNTIME_REQUIRED_IN_CONTEXT}; do list_path="$(aistack_component_get_search_path "runtime" "${r}" "VARIABLE_LIST") ${list_path}"; done
	for m in ${AISTACK_OPENCODE_MODULE_REQUIRED_IN_CONTEXT}; do list_path="$(aistack_component_get_search_path "module" "${m}" "VARIABLE_LIST") ${list_path}"; done
	aistack_context_file_export_path "${AISTACK_OPENCODE_CONTEXT_FILE}" "${list_path}" "VARIABLE_LIST"
}

opencode_context_file_generate_remove() {
	rm -f "${AISTACK_OPENCODE_CONTEXT_FILE}"
}

opencode_settings_configure() {

    echo "add some default settings :"
    merge_json_file "${AISTACK_POOL}/settings/opencode/opencode.json" "$AISTACK_OPENCODE_CONFIG_FILE"
    merge_json_file "${AISTACK_POOL}/settings/opencode/cli.json" "$AISTACK_OPENCODE_CLI_CONFIG_FILE"
}


opencode_info() {
    echo "Configuration file : $AISTACK_OPENCODE_CONFIG_FILE"
	echo "Cli configuration file : $AISTACK_OPENCODE_CLI_CONFIG_FILE"
	echo
	echo "OPENCODE available : $AISTACK_OPENCODE_TOOL_AVAILABLE"
	echo "OPENCODE path : $AISTACK_OPENCODE_TOOL_PATH"
	echo "OPENCODE needed managed runtime : $AISTACK_OPENCODE_RUNTIME_REQUIRED"
	echo "OPENCODE needed managed module : $AISTACK_OPENCODE_MODULE_REQUIRED"
	echo "OPENCODE install root : $OPENCODE_FEAT_INSTALL_ROOT"
	echo "OPENCODE launcher : $AISTACK_OPENCODE_LAUNCHER_FILE"
	echo "OPENCODE context file : $AISTACK_OPENCODE_CONTEXT_FILE"
	echo
    [ -n "$AISTACK_CLIPROXYAPI_KEY_FOR_OPENCODE" ] && echo "To request CLIProxyAPI, use API key : $AISTACK_CLIPROXYAPI_KEY_FOR_OPENCODE (from file : $AISTACK_CLIPROXYAPI_KEY_FOR_OPENCODE_FILE)" || \
        echo "Not connected to CLIProxyAPI (no API key for CPA found in file $AISTACK_CLIPROXYAPI_KEY_FOR_OPENCODE_FILE)"
}

opencode_show_config() {
	echo "---- $AISTACK_OPENCODE_CLI_CONFIG_FILE"
	if [ -f "$AISTACK_OPENCODE_CLI_CONFIG_FILE" ]; then
		cat "$AISTACK_OPENCODE_CLI_CONFIG_FILE"
    fi
	echo "---- $AISTACK_OPENCODE_CONFIG_FILE"
	if [ -f "$AISTACK_OPENCODE_CONFIG_FILE" ]; then
		cat "$AISTACK_OPENCODE_CONFIG_FILE"
    fi
}


opencode_settings_remove() {
    opencode_unregister_cpa_key
    rm -Rf "$AISTACK_OPENCODE_CONFIG_HOME"
}

opencode_merge_config() {
    local file_to_merge="$1"
    merge_json_file "$file_to_merge" "$AISTACK_OPENCODE_CONFIG_FILE"
}

opencode_set_config() {
    local key_path="$1"
    local value="$2"

    case "$key_path" in
        .*) ;;
        *)  key_path=".$key_path" ;;
    esac

    json_set_key_into_file "$AISTACK_OPENCODE_CONFIG_FILE" "$key_path" "$value"
}

opencode_remove_config() {
    local key_path="$1"

    case "$key_path" in
        .*) ;;
        *)  key_path=".$key_path" ;;
    esac

    json_del_key_from_file "$AISTACK_OPENCODE_CONFIG_FILE" "$key_path"
}


# ai provider management ------------------------
opencode_register_provider() {
    local provider_id="$1"
    local provider_display_name="$2"
    local provider_type="$3"
    local endpoint="$4"
    local api_key="$5"
    local api_key_env_var="$6"

    [ -z "${provider_display_name}" ] && provider_display_name="$provider_id"

    [ -n "${provider_id}" ] && provider_id="${provider_id//./\\.}" || { echo "ERROR opencode_register_provider : missing provider_id"; return 1; }

	# providers v2 doc : https://opencode.ai/v2/docs/providers
	opencode_remove_config "providers.${provider_id}" || return $?
	opencode_set_config "providers.${provider_id}.package" "\"${provider_type}\"" || return $?
	opencode_set_config "providers.${provider_id}.name" "\"${provider_display_name}\"" || return $?
	opencode_set_config "providers.${provider_id}.settings.baseURL" "\"${endpoint}\"" || return $?
	if [ -n "$api_key" ]; then
		opencode_set_config "providers.${provider_id}.settings.apiKey" "\"${api_key}\"" || return $?
	fi
	if [ -n "$api_key_env_var" ]; then
		opencode_set_config "providers.${provider_id}.settings.apiKey" "\"{env:${api_key_env_var}}\"" || return $?
	fi
}

opencode_register_model() {
    local provider_id="$1"
    local model_id="$2"
    local real_model_id="$3"
    local model_display_name="$4"
    local tool_call="$5" # true | false
    local limit_context="$6"
    local limit_output="$7"

    local original_provider_id="$provider_id"
    [ -n "${provider_id}" ] && provider_id="${provider_id//./\\.}" || { echo "ERROR opencode_register_model : missing provider_id"; return 1; }
    local original_model_id="$model_id"
    [ -n "${model_id}" ] && model_id="${model_id//./\\.}" || { echo "ERROR opencode_register_model : missing model_id"; return 1; }

    [ -z "${real_model_id}" ] && { echo "ERROR opencode_register_model : missing real_model_id"; return 1; }

    [ -z "${model_display_name}" ] && model_display_name="$original_model_id"

	opencode_remove_config "providers.${provider_id}.models.${model_id}" || return $?
	opencode_set_config "providers.${provider_id}.models.${model_id}.modelID" "\"${real_model_id}\"" || return $?
	opencode_set_config "providers.${provider_id}.models.${model_id}.name" "\"${model_display_name}\"" || return $?
	if [ -n "${tool_call}" ]; then
		opencode_set_config "providers.${provider_id}.models.${model_id}.capabilities.tools" "${tool_call}" || return $?
	fi
	if [ -n "${limit_context}" ]; then
		opencode_set_config "providers.${provider_id}.models.${model_id}.limit.context" "${limit_context}" || return $?
	fi
	if [ -n "${limit_output}" ]; then
		opencode_set_config "providers.${provider_id}.models.${model_id}.limit.output" "${limit_output}" || return $?
	fi
	return 0
}

# set a default model in opencode config
opencode_set_default_model() {
    local provider_id="$1"
    local model_id="$2"

    opencode_remove_config "model"
    [ -n "$provider_id" ] && [ -n "$model_id" ] && opencode_set_config "model" "\"${provider_id}/${model_id}\""
}

# Select the OpenCode v2 title-generation agent model.
# replace "small_model" key in v1
opencode_set_title_model() {
	local provider_id="${1}"
	local model_id="${2}"
	if [ -z "${provider_id}" ] || [ -z "${model_id}" ]; then
		echo "ERROR: opencode_set_title_model requires provider_id and model_id."
		return 1
	fi
	opencode_set_config "agents.title.model" "\"${provider_id}/${model_id}\"" || return $?
}
opencode_set_small_model() {
	opencode_set_title_model "$@"
}


# cliproxy api connection management ------------------------
opencode_generate_cpa_key() {
    opencode_unregister_cpa_key

    # Generating a CPA API key for Opencode
    export AISTACK_CLIPROXYAPI_KEY_FOR_OPENCODE="$($STELLA_API generate_password 48 "[:alnum:]")"
    cpa_settings_api_key_add "$AISTACK_CLIPROXYAPI_KEY_FOR_OPENCODE"
    if [ $? -ne 0 ]; then
        export AISTACK_CLIPROXYAPI_KEY_FOR_OPENCODE=
        echo "ERROR: Failed to generate and register CPA API key for Opencode."
        return 1
    fi
    echo "$AISTACK_CLIPROXYAPI_KEY_FOR_OPENCODE" > "$AISTACK_CLIPROXYAPI_KEY_FOR_OPENCODE_FILE"

    # each time an api key is generated we need to refresh the launcher to update env vars
    opencode_launcher_and_context_files_manage "create"
}

opencode_unregister_cpa_key() {
    # Remove existing CPA API key for Opencode
    cpa_settings_api_key_del "$AISTACK_CLIPROXYAPI_KEY_FOR_OPENCODE"
    export AISTACK_CLIPROXYAPI_KEY_FOR_OPENCODE=
    rm -f "$AISTACK_CLIPROXYAPI_KEY_FOR_OPENCODE_FILE"
}

# needs cpa to be running if model is empty, to retrieve model list from CLIProxyAPI
opencode_connect_cpa() {
    # empty means all available models
    local wanted_default_model="${1}"
    local wanted_title_model="${2}"
    local model_list
    local default_model
    local title_model

	echo "generate a CLIProxyAPI API key for Opencode to connect to CPA backend"
	echo "and register model cpa as provider in opencode configuration ($AISTACK_OPENCODE_CONFIG_FILE)"
  
    if ! cpa_is_configured; then
        echo "ERROR: Failed to connect Opencode to CLIProxyAPI : CLIProxyAPI is not configured."
        return 1
    fi

    # needs cpa conf file exists
    opencode_generate_cpa_key
    if [ $? -ne 0 ]; then
        echo "ERROR: Failed to generate and register a CLIProxyAPI API key dedicated to Opencode."
        return 1
    fi

    # register provider AIStack CLIProxyAPI
    opencode_register_provider "aistack-cpa" "AIStack CLIProxyAPI" "@opencode/ai/providers/openai-compatible" "$(cpa_settings_get_api_endpoint)" "$AISTACK_CLIPROXYAPI_KEY_FOR_OPENCODE" "" || return $?


    if ! cpa_instance_reachable; then
        if [ -z "${wanted_default_model}" ]; then
            echo "ERROR: Failed to request CLIProxyAPI, instance is not reachable and default model id not provided, can not automaticly pick a model from CLIProxyAPI by requesting a model list. Please launch CLIProxyAPI OR provide a default model id"
            return 1
        fi
        echo "WARN: Failed to request CLIProxyAPI, instance is not reachable - Only the provided default model id will be registered not all models."
    else
        # retrieve cliproxyapi models list and register them
        # function cpa_get_model_list needs cpa to be running
        model_list="$(cpa_get_model_list)"
        for m in ${model_list}; do
            # the first model available will be the default model
            [ -z "${default_model}" ] && default_model="${m}"
             opencode_register_model "aistack-cpa" "${m}" "${m}" "AIStack cpa-${m}" || return $?
        done
    fi

    # default model
    [ -n "${wanted_default_model}" ] && default_model="${wanted_default_model}"
    # NOTE : the wanted_default_model might have been already registered into opencode just before.
    if [ -n "${default_model}" ]; then
        opencode_register_model "aistack-cpa" "${default_model}" "${default_model}" "AIStack cpa-${default_model}" || return $?
        opencode_set_default_model "aistack-cpa" "${default_model}" || return $?
    fi

    # Optional title-generation model.
    if [ -n "${wanted_title_model}" ]; then
        title_model="${wanted_title_model}"
        opencode_register_model "aistack-cpa" "${title_model}" "${title_model}" "AIStack cpa-${title_model}" || return $?
        opencode_set_title_model "aistack-cpa" "${title_model}"
    fi

}
