kcli_path() {
    # aistack path for kilo code
    export AISTACK_KCLI_CONFIG_HOME="${HOME}/.config/kilo"
    mkdir -p "${AISTACK_KCLI_CONFIG_HOME}"

    export AISTACK_KCLI_LAUNCHER_HOME="${AISTACK_LAUNCHER_HOME}/kilo"
    mkdir -p "${AISTACK_KCLI_LAUNCHER_HOME}"


    # kilo code specific paths
    # The Kilo CLI is a fork of OpenCode and supports the same configuration options
    export AISTACK_KCLI_CONFIG_FILE="${AISTACK_KCLI_CONFIG_HOME}/kilo.jsonc"
    
    # cpa key for orla to connect to cpa backend
    export AISTACK_CLIPROXYAPI_KEY_FOR_KCLI_FILE="${AISTACK_KCLI_CONFIG_HOME}/cpa_key_for_kcli"
    [ -f "$AISTACK_CLIPROXYAPI_KEY_FOR_KCLI_FILE" ] && export AISTACK_CLIPROXYAPI_KEY_FOR_KCLI="$(cat "$AISTACK_CLIPROXYAPI_KEY_FOR_KCLI_FILE")"

}

kcli_install() {
    local version="$1"
    [ -z "${version}" ] && version="@latest"

    echo "Installing Kilo Code CLI ${version}"
    # available versions : https://www.npmjs.com/package/@kilocode/cli
    PATH="${AISTACK_NODEJS_BIN_PATH}:${STELLA_ORIGINAL_SYSTEM_PATH}" npm install --verbose -g @kilocode/cli${version}
}

kcli_uninstall() {
    PATH="${AISTACK_NODEJS_BIN_PATH}:${STELLA_ORIGINAL_SYSTEM_PATH}" npm uninstall -g @kilocode/cli
}


# add gemini launcher in path for shell
kcli_path_register_for_shell() {
    local shell_name="$1"
    path_register_for_shell "kilo" "$shell_name" "${AISTACK_KCLI_LAUNCHER_HOME}"
}
kcli_path_unregister_for_shell() {
    local shell_name="$1"
    path_unregister_for_shell "kilo" "$shell_name"
}
kcli_path_register_for_vs_terminal() {
    vscode_path_register_for_vs_terminal "kilo" "${AISTACK_KCLI_LAUNCHER_HOME}"
}
kcli_path_unregister_for_vs_terminal() {
    vscode_path_unregister_for_vs_terminal "kilo" "${AISTACK_KCLI_LAUNCHER_HOME}"
}



kcli_launch_export_variables="AISTACK_RUNTIME_PATH_FILE AISTACK_NODEJS_BIN_PATH"
kcli_launch() {
    set -- "$@"

    # if [ -f "$AISTACK_KCLI_CONFIG_FILE" ]; then
    #     set -- "$@" --config "$AISTACK_KCLI_CONFIG_FILE"
    # fi

    (
        . "${AISTACK_RUNTIME_PATH_FILE}"

        if [ "$#" -gt 0 ]; then
            "$AISTACK_NODEJS_BIN_PATH/kilo" "$@"
        else
            "$AISTACK_NODEJS_BIN_PATH/kilo"
        fi
    )
}

kcli_launcher_manage() {
    local action="${1:-create}"

    case $action in

        create)
            {
                echo '#!/bin/sh'
                for v in $kcli_launch_export_variables; do
                    printf '%s=%s\n' "$v" "$(shell_quote_posix "${!v}")"
                done

                declare -f kcli_launch

                echo kcli_launch \"\$@\"
            } > "${AISTACK_KCLI_LAUNCHER_HOME}/kilo"

            chmod +x "${AISTACK_KCLI_LAUNCHER_HOME}/kilo"
            ;;

        delete)
            rm -f "${AISTACK_KCLI_LAUNCHER_HOME}/kilo"
            ;;
    esac
    
}


kcli_settings_configure() {

    echo "add some default settings :"
    echo " - set default listening address for orla service to localhost:8081"
    kcli_settings_set_listen_address "localhost:8081"
    echo " - set for orla agent mode a default backend named ollama with endpoint http://localhost:11434"
    kcli_agent_register_default_backend "default_ollama" "ollama" "http://localhost:11434"
    kcli_agent_register_default_model

    echo " - generate a CLIProxyAPI API key for Orla to connect to CPA backend"
    kcli_generate_cpa_key
}

kcli_settings_remove() {
    kcli_unregister_cpa_key
    rm -Rf "$AISTACK_KCLI_CONFIG_HOME"
}


kcli_info() {
    if [ -f "$AISTACK_KCLI_CONFIG_FILE" ]; then
        echo "CLIProxyAPI configuration file : $AISTACK_KCLI_CONFIG_FILE"

        echo "Orla API endpoint : $(kcli_settings_get_api_endpoint)"

        [ -n "$AISTACK_CLIPROXYAPI_KEY_FOR_KCLI" ] && echo "Connected to CLIProxyAPI using API key : $AISTACK_CLIPROXYAPI_KEY_FOR_KCLI"
    else
        echo "No Orla configuration file found. $AISTACK_KCLI_CONFIG_FILE"
    fi
}



# generic config management -----------------
kcli_remove_config() {
    local key_path="$1"

    case "$key_path" in
        .*) ;;
        *)  key_path=".$key_path" ;;
    esac
    
    yaml_del_key_from_file "$AISTACK_KCLI_CONFIG_FILE" "$key_path"
}

kcli_set_config() {
    local key_path="$1"
    local value="$2"
    local string_style="$3"

    case "$key_path" in
        .*) ;;
        *)  key_path=".$key_path" ;;
    esac

    yaml_set_key_into_file "$AISTACK_KCLI_CONFIG_FILE" "$key_path" "$value" "$string_style"

}

kcli_get_config() {
    local key_path="$1"

    case "$key_path" in
        .*) ;;
        *)  key_path=".$key_path" ;;
    esac

    yaml_get_key_from_file "$AISTACK_KCLI_CONFIG_FILE" "$key_path"
}



# host management ------------------------
kcli_settings_set_listen_address() {
    local address="$1"
    # Orla API endpoint - default is localhost:8081
    kcli_set_config "listen_address" "$address"
}

kcli_settings_get_listen_address() {
    kcli_get_config ".listen_address"
}

kcli_settings_get_api_endpoint() {
    local scheme="http"
    echo -n "${scheme}://$(kcli_settings_get_listen_address)/api/v1"
}

# orla agent management ------------------------
# the default backend is defined in orla configuration
# https://github.com/dorcha-inc/orla/blob/main/internal/config/config.go
kcli_agent_register_default_backend() {
    local nickname="$1"
    local type="$2" # ollama or openai or sglang
    local endpoint="$3"
    local api_key_env_var="$4"
    local default_model="$5"
    local max_concurrency="$6"
    local queue_capacity="$7"


    # Default llm backend used for AGENT mode only ---
    kcli_remove_config "llm_backend"

    kcli_set_config "llm_backend.name" "$nickname"
    kcli_set_config "llm_backend.type" "$type"
    kcli_set_config "llm_backend.endpoint" "$endpoint"
    
    [ -n "$api_key_env_var" ] && kcli_set_config "llm_backend.api_key_env_var" "$api_key_env_var"

    # MaxConcurrency is the maximum number of concurrent inference requests dispatched to this backend
    # A value of 0 or 1 means serial dispatch.
    # https://github.com/dorcha-inc/orla/blob/4eb6ca0ebcd5f4fe9e21116cb866d749f0877bdd/internal/core/types.go#L30
    [ -n "$max_concurrency" ] && kcli_set_config "llm_backend.max_concurrency" "$max_concurrency"
    # QueueCapacity is the maximum number of requests that may be queued for this backend.
    [ -n "$queue_capacity" ] && kcli_set_config "llm_backend.queue_capacity" "$queue_capacity"

    # Default model used for orla AGENT mode only ---
    kcli_remove_config "model"
    [ -n "$default_model" ] && kcli_set_config "model" "${type}:${default_model}"
    
}



kcli_agent_register_default_model() {
    local type="$1"
    local default_model="$2"

    # Default model used for orla AGENT mode only ---
    kcli_remove_config "model"
    [ -n "$type" ] && [ -n "$default_model" ] && kcli_set_config "model" "${type}:${default_model}"
    
}

# cliproxy api connection management ------------------------

kcli_generate_cpa_key() {
    kcli_unregister_cpa_key

    # Generating a CPA API key for Orla
    export AISTACK_CLIPROXYAPI_KEY_FOR_KCLI="$($STELLA_API generate_password 48 "[:alnum:]")"
    cpa_settings_api_key_add "$AISTACK_CLIPROXYAPI_KEY_FOR_KCLI"
    echo "$AISTACK_CLIPROXYAPI_KEY_FOR_KCLI" > "$AISTACK_CLIPROXYAPI_KEY_FOR_KCLI_FILE"
}

kcli_unregister_cpa_key() {
    if [ -n "$AISTACK_CLIPROXYAPI_KEY_FOR_KCLI" ]; then
        # Remove existing CPA API key for Orla
        cpa_settings_api_key_del "$AISTACK_CLIPROXYAPI_KEY_FOR_KCLI" "$AISTACK_CLIPROXYAPI_KEY_FOR_KCLI"
    fi
}

kcli_connect_cpa() {
    local kcli_mode="${1}" # agent or serve
    local model="${2}"

    local default_model
    if [ -n "${model}" ]; then
        default_model="$model"
    else
        # request cpa to get the first model available as the default model for orla AGENT mode
        default_model="$(cpa_get_model_list | head -n 1)"
    fi

    case "$kcli_mode" in
        agent)
            kcli_agent_register_default_backend "cpa" "openai" "$(cpa_settings_get_api_endpoint)" "AISTACK_CLIPROXYAPI_KEY_FOR_KCLI"
            [ -n "$default_model" ] && kcli_agent_register_default_model "openai" "$default_model"
            ;;
        serve)
            # register cpa as a backend for orla service mode (orla service mode do not read the default backend from configuration file))
            curl -skL -X POST "$(kcli_settings_get_api_endpoint)/backends" \
                        -H "Content-Type: application/json" \
                        -d \
                            '{
                                "name": "cpa",
                                "endpoint": "'$(cpa_settings_get_api_endpoint)'",
                                "type": "openai",
                                "api_key_env_var": "AISTACK_CLIPROXYAPI_KEY_FOR_KCLI",
                                "model_id": "openai:'${default_model}'"
                            }'
            ;;
        *)
            echo "Error: Unknown Orla mode $kcli_mode for CPA connection"
            exit 1
            ;;
    esac

}


