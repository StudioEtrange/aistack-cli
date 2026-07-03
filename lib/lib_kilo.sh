kilo_init() {
    # aistack path for kilo code
    export AISTACK_KILO_CONFIG_HOME="${HOME}/.config/kilo"
    mkdir -p "${AISTACK_KILO_CONFIG_HOME}"

    export AISTACK_KILO_LAUNCHER_HOME="${AISTACK_LAUNCHER_HOME}/kilo"
    mkdir -p "${AISTACK_KILO_LAUNCHER_HOME}"

    # kilo code specific paths
    # The Kilo CLI is a fork of OpenCode and supports the same configuration options
    export AISTACK_KILO_CONFIG_FILE="${AISTACK_KILO_CONFIG_HOME}/kilo.jsonc"
    
    # cpa key for kilo to connect to cpa backend
    export AISTACK_CLIPROXYAPI_KEY_FOR_KILO_FILE="${AISTACK_KILO_CONFIG_HOME}/cpa_key_for_kc"
    [ -f "$AISTACK_CLIPROXYAPI_KEY_FOR_KILO_FILE" ] && export AISTACK_CLIPROXYAPI_KEY_FOR_KILO="$(cat "$AISTACK_CLIPROXYAPI_KEY_FOR_KILO_FILE")"

	export AISTACK_KILO_RUNTIME_REQUIRED="nodejs"

}

# return 0 : is installed
# return 1 : tool is not installed
# return 2 : missing runtime
kilo_is_installed() {
	local r
	export AISTACK_KILO_TOOL_AVAILABLE="false"
	for r in $AISTACK_KILO_RUNTIME_REQUIRED; do aistack_runtime_is_detected "${r}" || return 2; done
	[ -x "${AISTACK_RUNTIME_NODEJS_SEARCH_PATH}/kilo" ] || return 1
	export AISTACK_KILO_TOOL_AVAILABLE="true"
	export AISTACK_KILO_TOOL_PATH="${AISTACK_RUNTIME_NODEJS_SEARCH_PATH}/kilo"
	return 0
}

kilo_install() {
    local type="${1:-cli}"
    # available versions : https://www.npmjs.com/package/@kilocode/cli
    local version="$2"
    [ -z "${version}" ] && version="@latest"
	local r

    case "$type" in
        "cli")
			for r in $AISTACK_KILO_RUNTIME_REQUIRED; do 
				echo "Require needed ${r} rmanaged untime"
				aistack_runtime_require "${r}"
			done
			
            echo "Installing Kilo Code CLI ${version}"
			node_package_install "@kilocode/cli${version}"
            #PATH="${AISTACK_RUNTIME_NODEJS_SEARCH_PATH}:${STELLA_ORIGINAL_SYSTEM_PATH}" npm install --verbose -g @kilocode/cli${version}
            kilo_is_installed
			;;
        "extension")
            vscode_extension_manage "kilocode.Kilo-Code" "install"
            ;;
        *) echo "Invalid type '$type'. Supported types are 'cli' and 'extension'." ; return 1 ;;
    esac
}

kilo_uninstall() {
    local type="${1:-cli}"

    case "$type" in
        "cli")
			if kilo_is_installed; then
				echo "Uninstalling Kilo Code CLI"
				node_package_uninstall "@kilocode/cli"
				#PATH="${AISTACK_RUNTIME_NODEJS_SEARCH_PATH}:${STELLA_ORIGINAL_SYSTEM_PATH}" npm uninstall -g @kilocode/cli
				kilo_is_installed
			else
				echo "WARN : not installed or missing a required managed runtime $AISTACK_KILO_RUNTIME_REQUIRED"
			fi
            ;;
        "extension")
            vscode_extension_manage "kilocode.Kilo-Code" "uninstall"
            ;;
        *) echo "Invalid type '$type'. Supported types are 'cli' and 'extension'." ; return 1 ;;
    esac
}


kilo_path_register_for_shell() {
    local shell_name="$1"
	if kilo_is_installed; then
    	path_register_for_shell "kilo" "${AISTACK_KILO_LAUNCHER_HOME}" "$shell_name"
	fi
}
kilo_path_unregister_for_shell() {
    local shell_name="${1:-all}"
    path_unregister_for_shell "kilo" "$shell_name"
}
kilo_path_register_for_vs_terminal() {
	if kilo_is_installed; then
    	vscode_path_register_for_vs_terminal "kilo" "${AISTACK_KILO_LAUNCHER_HOME}"
	fi
}
kilo_path_unregister_for_vs_terminal() {
    vscode_path_unregister_for_vs_terminal "kilo" "${AISTACK_KILO_LAUNCHER_HOME}"
}


kilo_launch_export_variables="AISTACK_CLIPROXYAPI_KEY_FOR_KILO AISTACK_RUN_CONTEXT_FILE AISTACK_RUNTIME_NODEJS_SEARCH_PATH"
kilo_launch() {
    (
        . "${AISTACK_RUN_CONTEXT_FILE}"

        if [ "$#" -gt 0 ]; then
            "$AISTACK_RUNTIME_NODEJS_SEARCH_PATH/kilo" "$@"
        else
            "$AISTACK_RUNTIME_NODEJS_SEARCH_PATH/kilo"
        fi
    )
}

kilo_launcher_manage() {
    local action="${1:-create}"

    case $action in

        create)
			if kilo_is_installed; then
				# create a compatible POSIX shell script to be called from bash, zsn, fish and wo on
				# and executed by the default /bin/sh on the current system
				{
					echo '#!/bin/sh'
					for v in $kilo_launch_export_variables; do
						printf 'export %s=%s\n' "$v" "$(shell_quote_posix "${!v}")"
					done

					declare -f kilo_launch

					echo kilo_launch \"\$@\"
				} > "${AISTACK_KILO_LAUNCHER_HOME}/kilo"
				chmod +x "${AISTACK_KILO_LAUNCHER_HOME}/kilo"
			fi
            ;;

        delete)
            rm -Rf "${AISTACK_KILO_LAUNCHER_HOME}"
            mkdir -p "${AISTACK_KILO_LAUNCHER_HOME}"
            ;;

		refresh_if_exists)
			[ -f "${AISTACK_KILO_LAUNCHER_HOME}/kilo" ] && ( kilo_launcher_manage "delete"; kilo_launcher_manage "create" )
			;;
    esac
    
}


kilo_info() {
    echo "Configuration file : $AISTACK_KILO_CONFIG_FILE"
	echo
	echo "KILO available : $AISTACK_KILO_TOOL_AVAILABLE"
	echo "KILO path : $AISTACK_KILO_TOOL_PATH"
	echo "KILO needed managed runtime : $AISTACK_KILO_RUNTIME_REQUIRED"
	echo
    [ -n "$AISTACK_CLIPROXYAPI_KEY_FOR_KILO" ] && echo "To request CLIProxyAPI, use API key : $AISTACK_CLIPROXYAPI_KEY_FOR_KILO (from file : $AISTACK_CLIPROXYAPI_KEY_FOR_KILO_FILE)" || \
        echo "Not connected to CLIProxyAPI (no API key for CPA found in file $AISTACK_CLIPROXYAPI_KEY_FOR_KILO_FILE)"
}

kilo_show_config() {
    if [ -f "$AISTACK_KILO_CONFIG_FILE" ]; then
        echo "Current configuration file : $AISTACK_KILO_CONFIG_FILE"
        cat "$AISTACK_KILO_CONFIG_FILE"
    else
        echo "No configuration file found. ($AISTACK_KILO_CONFIG_FILE)"
    fi
}


# generic config management -----------------
kilo_settings_configure() {

    echo "add some default settings :"
    merge_json_file "${AISTACK_POOL}/settings/kilo/kilo.jsonc" "$AISTACK_KILO_CONFIG_FILE"

}

kilo_settings_remove() {
    kilo_unregister_cpa_key
    rm -Rf "$AISTACK_KILO_CONFIG_HOME"
}

kilo_remove_config() {
    local key_path="$1"

    case "$key_path" in
        .*) ;;
        *)  key_path=".$key_path" ;;
    esac
    
    json_del_key_from_file "$AISTACK_KILO_CONFIG_FILE" "$key_path"
}

kilo_set_config() {
    local key_path="$1"
    local value="$2"

    case "$key_path" in
        .*) ;;
        *)  key_path=".$key_path" ;;
    esac

    json_set_key_into_file "$AISTACK_KILO_CONFIG_FILE" "$key_path" "$value"

}



# ai provider management ------------------------
# Kilo Code is built upon Vercel AI SDK using its unified provider architecture 
# https://ai-sdk.dev/docs/foundations/providers-and-models
# https://kilo.ai/docs/ai-providers
# https://github.com/Kilo-Org/kilocode/issues/6315#issuecomment-4120354102
# set a provider
# "provider": {
#     "my-custom-provider-id": {
#         "npm": "@ai-sdk/openai-compatible",
#         "name": "My LiteLLM API",
#         "options": {
#             "baseURL": "https://my.litellm.org",  // Base URL where LiteLLM API is hosted
#             "apiKey": "{env:LITELLM_API_KEY}"     // or whatever it's called in your shell env
#         },
#         "models": {
#             "org/my-custom-model": {              // This is just a key for the config
#                 "id": "my-custom-model",            // Needs to match the actual model key via API
#                 "name": "Custom Coder",             // Appears in the `/models` list
#                 "reasoning": true,
#                 "tool_call": true,
#                 "limit": {
#                     "context": 131072,
#                     "output": 131072
#                 }
#             },
#             "org/claude-sonnet": {
#                 "id": "anthropic/claude-sonnet",
#                 "name": "LiteLLM Claude Sonnet",
#                 "reasoning": true,
#                 "tool_call": true,
#                 "limit": {
#                     "context": 200000,
#                     "output": 16384
#                 }
#             }
#         }
#     }
# }
kilo_register_provider() {
    local provider_id="$1"
    local provider_display_name="$2"
    local provider_type="$3"
    local endpoint="$4"
    local api_key="$5"
    local api_key_env_var="$6"

    [ -z "${provider_display_name}" ] && provider_display_name="$provider_id"

    [ -n "${provider_id}" ] && provider_id="${provider_id//./\\.}" || { echo "ERROR kilo_register_model : missing provider_id"; return 1; }


    kilo_remove_config "provider.${provider_id}"

    kilo_set_config "provider.${provider_id}.npm" "\"$provider_type\""
    kilo_set_config "provider.${provider_id}.name" "\"$provider_display_name\""
    kilo_set_config "provider.${provider_id}.options.baseURL" "\"$endpoint\""
    [ -n "$api_key" ] && kilo_set_config "provider.${provider_id}.options.apiKey" "\"$api_key\""
    [ -n "$api_key_env_var" ] && kilo_set_config "provider.${provider_id}.options.apiKey" "\"{env:$api_key_env_var}\""
}

kilo_register_model() {
    local provider_id="$1"
    local model_id="$2"
    local real_model_id="$3"
    local model_display_name="$4"
    
    local reasoning="$5" # true | false
    local tool_call="$6" # true | false

    local limit_context="$7"
    local limit_output="$8"


    original_provider_id="$provider_id"
    [ -n "${provider_id}" ] && provider_id="${provider_id//./\\.}" || { echo "ERROR kilo_register_model : missing provider_id"; return 1; }
    original_model_id="$model_id"
    [ -n "${model_id}" ] && model_id="${model_id//./\\.}" || { echo "ERROR kilo_register_model : missing model_id"; return 1; }
    
    [ -z "${real_model_id}" ] && { echo "ERROR kilo_register_model : missing real_model_id"; return 1; }

    [ -z "${model_display_name}" ] && model_display_name="$original_model_id"

    kilo_remove_config "provider.${provider_id}.models.${model_id}"
    kilo_set_config "provider.${provider_id}.models.${model_id}.id" "\"$real_model_id\""
    kilo_set_config "provider.${provider_id}.models.${model_id}.name" "\"$model_display_name\""
    
    [ -n "$reasoning" ] && kilo_set_config "provider.${provider_id}.models.${model_id}.reasoning" "$reasoning"
    [ -n "$tool_call" ] && kilo_set_config "provider.${provider_id}.models.${model_id}.tool_call" "$tool_call"
    
    [ -n "$limit_context" ] && kilo_set_config "provider.${provider_id}.models.${model_id}.limit.context" "$limit_context"
    [ -n "$limit_output" ] && kilo_set_config "provider.${provider_id}.models.${model_id}.limit.output" "$limit_output"
}


kilo_register_default_model() {
    local provider_id="$1"
    local default_model_id="$2"

    kilo_remove_config "model"
    [ -n "$provider_id" ] && [ -n "$default_model" ] && kilo_set_config "model" "\"${provider_id}/${default_model_id}\""
}

# cliproxy api connection management ------------------------
kilo_generate_cpa_key() {
    kilo_unregister_cpa_key

    # Generating a CPA API key for kilo
    export AISTACK_CLIPROXYAPI_KEY_FOR_KILO="$($STELLA_API generate_password 48 "[:alnum:]")"
    cpa_settings_api_key_add "$AISTACK_CLIPROXYAPI_KEY_FOR_KILO"
    if [ $? -ne 0 ]; then
        export AISTACK_CLIPROXYAPI_KEY_FOR_KILO=
        echo "ERROR: Failed to generate and register CPA API key for Kilo Code."
        return 1
    fi
    echo "$AISTACK_CLIPROXYAPI_KEY_FOR_KILO" > "$AISTACK_CLIPROXYAPI_KEY_FOR_KILO_FILE"

    # each time an api key is generated we need to refrech the launcher to update env vars
    kilo_launcher_manage "create"
}

kilo_unregister_cpa_key() {
    # Remove existing CPA API key for kilo
    cpa_settings_api_key_del "$AISTACK_CLIPROXYAPI_KEY_FOR_KILO"
    export AISTACK_CLIPROXYAPI_KEY_FOR_KILO=
    rm -f "$AISTACK_CLIPROXYAPI_KEY_FOR_KILO_FILE"
}

# needs cpa to be running if model is empty, to retrieve model list from CLIProxyAPI
kilo_connect_cpa() {
    # empty means all available models
    local model="${1}"
    local model_list

    if ! cpa_is_configured; then
        echo "ERROR: Failed to generate and register CLIProxyAPI API key for Kilo Code : CLIProxyAPI is not configured."
        return 1
    fi

    # needs cpa conf file exists
    echo "generate a CLIProxyAPI API key for Kilo Code to connect to CPA backend"
    kilo_generate_cpa_key
    if [ $? -ne 0 ]; then
        echo "ERROR: Failed to generate and register CLIProxyAPI API key for Kilo Code."
        return 1
    fi

    kilo_register_provider "aistack-cpa" "AIStack CLIProxyAPI" "@ai-sdk/openai-compatible" "$(cpa_settings_get_api_endpoint)" "$AISTACK_CLIPROXYAPI_KEY_FOR_KILO" ""

    local default_model
    if [ -n "${model}" ]; then
        kilo_register_model "aistack-cpa" "${model}" "${model}" "AIStack cpa-${mmodel}"
        default_model="${model}"
    else
        if ! cpa_instance_reachable; then
            echo "ERROR: Failed to generate and register CPA API key for Kilo Code : CLIProxyAPI instance is not reachable. Please make sure CLIProxyAPI is running and properly configured."
            return 1
        fi
        # cpa_get_model_list needs cpa to be running
        model_list="$(cpa_get_model_list)"
        for m in $model_list; do
            # the first model available will be the default model
            [ -z "${default_model}" ] && default_model="${m}"
            kilo_register_model "aistack-cpa" "${m}" "${m}" "AIStack cpa-${m}"
        done
    fi

    [ -n "$default_model" ] && kilo_register_default_model "aistack-cpa" "$default_model"

}
