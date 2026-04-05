kilo_path() {
    # aistack path for kilo code
    export AISTACK_KILO_CONFIG_HOME="${HOME}/.config/kilo"
    mkdir -p "${AISTACK_KILO_CONFIG_HOME}"

    export AISTACK_KILO_LAUNCHER_HOME="${AISTACK_LAUNCHER_HOME}/kilo"
    mkdir -p "${AISTACK_KILO_LAUNCHER_HOME}"


    # kilo code specific paths
    # The Kilo CLI is a fork of OpenCode and supports the same configuration options
    export AISTACK_KILO_CONFIG_FILE="${AISTACK_KILO_CONFIG_HOME}/kilo.jsonc"
    
    # cpa key for orla to connect to cpa backend
    export AISTACK_CLIPROXYAPI_KEY_FOR_KILO_FILE="${AISTACK_KILO_CONFIG_HOME}/cpa_key_for_kc"
    [ -f "$AISTACK_CLIPROXYAPI_KEY_FOR_KILO_FILE" ] && export AISTACK_CLIPROXYAPI_KEY_FOR_KILO="$(cat "$AISTACK_CLIPROXYAPI_KEY_FOR_KILO_FILE")"

}

kilo_install() {
    local version="$1"
    [ -z "${version}" ] && version="@latest"

    echo "Installing Kilo Code CLI ${version}"
    # available versions : https://www.npmjs.com/package/@kilocode/cli
    PATH="${AISTACK_NODEJS_BIN_PATH}:${STELLA_ORIGINAL_SYSTEM_PATH}" npm install --verbose -g @kilocode/cli${version}
}

kilo_uninstall() {
    PATH="${AISTACK_NODEJS_BIN_PATH}:${STELLA_ORIGINAL_SYSTEM_PATH}" npm uninstall -g @kilocode/cli
}


# add gemini launcher in path for shell
kilo_path_register_for_shell() {
    local shell_name="$1"
    path_register_for_shell "kilo" "$shell_name" "${AISTACK_KILO_LAUNCHER_HOME}"
}
kilo_path_unregister_for_shell() {
    local shell_name="$1"
    path_unregister_for_shell "kilo" "$shell_name"
}
kilo_path_register_for_vs_terminal() {
    vscode_path_register_for_vs_terminal "kilo" "${AISTACK_KILO_LAUNCHER_HOME}"
}
kilo_path_unregister_for_vs_terminal() {
    vscode_path_unregister_for_vs_terminal "kilo" "${AISTACK_KILO_LAUNCHER_HOME}"
}



kilo_launch_export_variables="AISTACK_CLIPROXYAPI_KEY_FOR_KILO AISTACK_RUNTIME_PATH_FILE AISTACK_NODEJS_BIN_PATH"
kilo_launch() {
    set -- "$@"

    (
        . "${AISTACK_RUNTIME_PATH_FILE}"

        if [ "$#" -gt 0 ]; then
            "$AISTACK_NODEJS_BIN_PATH/kilo" "$@"
        else
            "$AISTACK_NODEJS_BIN_PATH/kilo"
        fi
    )
}

kilo_launcher_manage() {
    local action="${1:-create}"

    case $action in

        create)
            {
                echo '#!/bin/sh'
                for v in $kilo_launch_export_variables; do
                    printf '%s=%s\n' "$v" "$(shell_quote_posix "${!v}")"
                done

                declare -f kilo_launch

                echo kilo_launch \"\$@\"
            } > "${AISTACK_KILO_LAUNCHER_HOME}/kilo"

            chmod +x "${AISTACK_KILO_LAUNCHER_HOME}/kilo"
            ;;

        delete)
            rm -f "${AISTACK_KILO_LAUNCHER_HOME}/kilo"
            ;;
    esac
    
}


kilo_settings_configure() {

    echo "add some default settings :"
    merge_json_file "${AISTACK_POOL}/settings/kilo/kilo.jsonc" "$AISTACK_KILO_CONFIG_FILE"
    
    echo " - generate a CLIProxyAPI API key for Kilo Code to connect to CPA backend"
    kilo_generate_cpa_key
}

kilo_settings_remove() {
    kilo_unregister_cpa_key
    rm -Rf "$AISTACK_KILO_CONFIG_HOME"
}


kilo_info() {
    echo "Configuration file : $AISTACK_KILO_CONFIG_FILE"

    [ -n "$AISTACK_CLIPROXYAPI_KEY_FOR_KILO" ] && echo "Connected to CLIProxyAPI using API key : $AISTACK_CLIPROXYAPI_KEY_FOR_KILO"

    # TODO
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
    local api_key_env_var="$5"

    [ -z "${provider_display_name}" ] && provider_display_name="$provider_id"

    [ -n "${provider_id}" ] && provider_id="${provider_id//./\\.}" || { echo "ERROR kilo_register_model : missing provider_id"; return 1; }


    kilo_remove_config "provider.${provider_id}"

    kilo_set_config "provider.${provider_id}.npm" "\"$provider_type\""
    kilo_set_config "provider.${provider_id}.name" "\"$provider_display_name\""
    kilo_set_config "provider.${provider_id}.options.baseURL" "\"$endpoint\""
    [ -n "$api_key_env_var" ] && kilo_set_config "provider.${provider_id}.options.apiKey" "\"{env:$api_key_env_var}\""
}

kilo_register_model() {
    local provider_id="$1"
    local model_id="$2"
    local real_model_id="$3"
    local model_display_name="$4"
    
    local reasoning="$5" # true | false
    local tool_call="$6" # true | false
    local reasoning="$7" # true | false

    local limit_context="$8"
    local limit_output="$9"


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
    echo "$AISTACK_CLIPROXYAPI_KEY_FOR_KILO" > "$AISTACK_CLIPROXYAPI_KEY_FOR_KILO_FILE"
}

kilo_unregister_cpa_key() {
    if [ -n "$AISTACK_CLIPROXYAPI_KEY_FOR_KILO" ]; then
        # Remove existing CPA API key for kilo
        cpa_settings_api_key_del "$AISTACK_CLIPROXYAPI_KEY_FOR_KILO"
    fi
}

kilo_connect_cpa() {
    # empty means all available models
    local model="${1}"

    kilo_register_provider "aistack-cpa" "AIStack CLIProxyAPI" "@ai-sdk/openai-compatible" "$(cpa_settings_get_api_endpoint)"  "AISTACK_CLIPROXYAPI_KEY_FOR_KILO"

    local default_model
    if [ -n "${model}" ]; then
        kilo_register_model "aistack-cpa" "${model}" "${model}" "AIStack cpa-${mmodel}"
        default_model="${model}"
    else
        for m in $(cpa_get_model_list); do
            # the first model available will be the default model
            [ -z "${default_model}" ] && default_model="${m}"
            kilo_register_model "aistack-cpa" "${m}" "${m}" "AIStack cpa-${m}"
        done
    fi

    [ -n "$default_model" ] && kilo_register_default_model "aistack-cpa" "$default_model"

}


