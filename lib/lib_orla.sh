orla_path() {
    # aistack path for orla
    export AISTACK_ORLA_CONFIG_HOME="${HOME}/.orla"
    mkdir -p "${AISTACK_ORLA_CONFIG_HOME}"

    export AISTACK_ORLA_LAUNCHER_HOME="${AISTACK_LAUNCHER_HOME}/orla"
    mkdir -p "${AISTACK_ORLA_LAUNCHER_HOME}"


    # orla specific paths
    export AISTACK_ORLA_CONFIG_FILE="${AISTACK_ORLA_CONFIG_HOME}/orla.yaml"
    
    # cpa key for orla to connect to cpa backend
    export AISTACK_CLIPROXYAPI_KEY_FOR_ORLA_FILE="${AISTACK_ORLA_CONFIG_HOME}/cpa_key_for_orla"
    [ -f "$AISTACK_CLIPROXYAPI_KEY_FOR_ORLA_FILE" ] && export AISTACK_CLIPROXYAPI_KEY_FOR_ORLA="$(cat "$AISTACK_CLIPROXYAPI_KEY_FOR_ORLA_FILE")"

    export ORLA_FEAT_INSTALL_ROOT="$AISTACK_ISOLATED_DEPENDENCIES_ROOT/orla"
    mkdir -p "${ORLA_FEAT_INSTALL_ROOT}"
    
}


# Download and install cliproxyapi from GitHub releases.
# @param {string} $1 - Optional version to install (e.g., "v0.1.0").
#                      If not provided, the latest version will be fetched.
# This function relies on the following environment variables to be set:
# - ORLA_FEAT_INSTALL_ROOT: The directory where cliproxyapi will be installed.
orla_install() {
    local version="$1"
    
    if [ -z "$version" ] || [ "$version" = "latest" ]; then
        echo "No version provided, fetching the latest version..."
        version=$(github_get_latest_release "dorcha-inc/orla")
        echo "latest version is ${version}"
    fi

    local os_arch
    case "$STELLA_CURRENT_PLATFORM" in
        linux)
            [ "$STELLA_CURRENT_CPU_FAMILY" = "intel" ] && os_arch="linux-amd64"
            [ "$STELLA_CURRENT_CPU_FAMILY" = "arm" ] && os_arch="linux-arm64"
            ;;
        darwin)
            [ "$STELLA_CURRENT_CPU_FAMILY" = "intel" ] && os_arch="darwin-amd64"
            [ "$STELLA_CURRENT_CPU_FAMILY" = "arm" ] && os_arch="darwin-arm64"
            ;;
    esac
    local filename="orla-${os_arch}.tar.gz"
    local download_url="https://github.com/dorcha-inc/orla/releases/download/${version}/${filename}"

    echo "Downloading and installing Orla ${version} from ${download_url} to ${ORLA_FEAT_INSTALL_ROOT}..."
    $STELLA_API get_resource "Orla" "${download_url}" "HTTP_ZIP" "$ORLA_FEAT_INSTALL_ROOT" "DEST_ERASE"
    echo "Orla installed successfully."
}
 
orla_uninstall() {
    echo "Uninstalling Orla from ${ORLA_FEAT_INSTALL_ROOT}..."
    rm -Rf "${ORLA_FEAT_INSTALL_ROOT}"
    echo "Orla uninstalled successfully."
}


# add gemini launcher in path for shell
orla_path_register_for_shell() {
    local shell_name="$1"
    path_register_for_shell "orla" "$shell_name" "${AISTACK_ORLA_LAUNCHER_HOME}"
}
orla_path_unregister_for_shell() {
    local shell_name="$1"
    path_unregister_for_shell "orla" "$shell_name"
}
orla_path_register_for_vs_terminal() {
    vscode_path_register_for_vs_terminal "orla" "${AISTACK_ORLA_LAUNCHER_HOME}"
}
orla_path_unregister_for_vs_terminal() {
    vscode_path_unregister_for_vs_terminal "orla" "${AISTACK_ORLA_LAUNCHER_HOME}"
}



orla_launch_export_variables="AISTACK_CLIPROXYAPI_KEY_FOR_ORLA AISTACK_RUNTIME_PATH_FILE AISTACK_ORLA_CONFIG_FILE ORLA_FEAT_INSTALL_ROOT"
orla_launch() {
    set -- "$@"

    if [ -f "$AISTACK_ORLA_CONFIG_FILE" ]; then
        set -- "$@" --config "$AISTACK_ORLA_CONFIG_FILE"
    fi

    (
        . "${AISTACK_RUNTIME_PATH_FILE}"

        if [ "$#" -gt 0 ]; then
            "${ORLA_FEAT_INSTALL_ROOT}/orla" "$@"
        else
            "${ORLA_FEAT_INSTALL_ROOT}/orla"
        fi
    )
}

orla_launcher_manage() {
    local action="${1:-create}"

    case $action in

        create)
            # echo "Create an Orla launcher"
            # rm -f "${AISTACK_ORLA_LAUNCHER_HOME}/orla"
            # # launcher based on a symbolic link
            # ln -fsv "${ORLA_FEAT_INSTALL_ROOT}/orla" "${AISTACK_ORLA_LAUNCHER_HOME}/orla"

            # echo '#!/bin/sh' > "${AISTACK_ORLA_LAUNCHER_HOME}/orla"
            # if [ -f "$AISTACK_ORLA_CONFIG_FILE" ]; then
            #     echo "${ORLA_FEAT_INSTALL_ROOT}/orla \$@ --config \"$AISTACK_ORLA_CONFIG_FILE\"" >> "${AISTACK_ORLA_LAUNCHER_HOME}/orla"
            # else
            #     echo "${ORLA_FEAT_INSTALL_ROOT}/orla \$@" >> "${AISTACK_ORLA_LAUNCHER_HOME}/orla"
            # fi
            # chmod +x "${AISTACK_ORLA_LAUNCHER_HOME}/orla"

            #runtime_path_file_generate
            {
                echo '#!/bin/sh'
                for v in $orla_launch_export_variables; do
                    printf '%s=%s\n' "$v" "$(shell_quote_posix "${!v}")"
                done

                declare -f orla_launch

                echo orla_launch \"\$@\"
            } > "${AISTACK_ORLA_LAUNCHER_HOME}/orla"

            chmod +x "${AISTACK_ORLA_LAUNCHER_HOME}/orla"
            ;;

        delete)
            rm -f "${AISTACK_ORLA_LAUNCHER_HOME}/orla"
            ;;
    esac
    
}


orla_settings_configure() {

    echo "add some default settings :"
    echo " - set default listening address for orla service to localhost:8081"
    orla_settings_set_listen_address "localhost:8081"
    echo " - set for orla agent mode a default backend named ollama with endpoint http://localhost:11434"
    orla_agent_register_default_backend "default_ollama" "ollama" "http://localhost:11434"
    orla_agent_register_default_model

    echo " - generate a CLIProxyAPI API key for Orla to connect to CPA backend"
    orla_generate_cpa_key
}

orla_settings_remove() {
    orla_unregister_cpa_key
    rm -Rf "$AISTACK_ORLA_CONFIG_HOME"
}


orla_info() {
    if [ -f "$AISTACK_ORLA_CONFIG_FILE" ]; then
        echo "CLIProxyAPI configuration file : $AISTACK_ORLA_CONFIG_FILE"

        echo "Orla API endpoint : $(orla_settings_get_api_endpoint)"

        [ -n "$AISTACK_CLIPROXYAPI_KEY_FOR_ORLA" ] && echo "Connected to CLIProxyAPI using API key : $AISTACK_CLIPROXYAPI_KEY_FOR_ORLA"
    else
        echo "No Orla configuration file found. ($AISTACK_ORLA_CONFIG_FILE)"
    fi
}



# generic config management -----------------
orla_remove_config() {
    local key_path="$1"

    case "$key_path" in
        .*) ;;
        *)  key_path=".$key_path" ;;
    esac
    
    yaml_del_key_from_file "$AISTACK_ORLA_CONFIG_FILE" "$key_path"
}

orla_set_config() {
    local key_path="$1"
    local value="$2"
    local string_style="$3"

    case "$key_path" in
        .*) ;;
        *)  key_path=".$key_path" ;;
    esac

    yaml_set_key_into_file "$AISTACK_ORLA_CONFIG_FILE" "$key_path" "$value" "$string_style"

}

orla_get_config() {
    local key_path="$1"

    case "$key_path" in
        .*) ;;
        *)  key_path=".$key_path" ;;
    esac

    yaml_get_key_from_file "$AISTACK_ORLA_CONFIG_FILE" "$key_path"
}



# host management ------------------------
orla_settings_set_listen_address() {
    local address="$1"
    # Orla API endpoint - default is localhost:8081
    orla_set_config "listen_address" "$address"
}

orla_settings_get_listen_address() {
    orla_get_config ".listen_address"
}

orla_settings_get_api_endpoint() {
    local scheme="http"
    echo -n "${scheme}://$(orla_settings_get_listen_address)/api/v1"
}

# orla agent management ------------------------
# the default backend is defined in orla configuration
# https://github.com/dorcha-inc/orla/blob/main/internal/config/config.go
orla_agent_register_default_backend() {
    local nickname="$1"
    local type="$2" # ollama or openai or sglang
    local endpoint="$3"
    local api_key_env_var="$4"
    local max_concurrency="$5"
    local queue_capacity="$6"
    #local default_model="$7"


    # Default llm backend used for AGENT mode only ---
    orla_remove_config "llm_backend"

    orla_set_config "llm_backend.name" "$nickname"
    orla_set_config "llm_backend.type" "$type"
    orla_set_config "llm_backend.endpoint" "$endpoint"
    
    [ -n "$api_key_env_var" ] && orla_set_config "llm_backend.api_key_env_var" "$api_key_env_var"

    # MaxConcurrency is the maximum number of concurrent inference requests dispatched to this backend
    # A value of 0 or 1 means serial dispatch.
    # https://github.com/dorcha-inc/orla/blob/4eb6ca0ebcd5f4fe9e21116cb866d749f0877bdd/internal/core/types.go#L30
    [ -n "$max_concurrency" ] && orla_set_config "llm_backend.max_concurrency" "$max_concurrency"
    # QueueCapacity is the maximum number of requests that may be queued for this backend.
    [ -n "$queue_capacity" ] && orla_set_config "llm_backend.queue_capacity" "$queue_capacity"

    # Default model used for orla AGENT mode only ---
    #orla_agent_register_default_model "${type}" "${default_model}"
}



orla_agent_register_default_model() {
    local type="$1"
    local default_model="$2"

    # Default model used for orla AGENT mode only ---
    orla_remove_config "model"
    [ -n "$type" ] && [ -n "$default_model" ] && orla_set_config "model" "${type}:${default_model}"
    
}

# cliproxy api connection management ------------------------

orla_generate_cpa_key() {
    orla_unregister_cpa_key

    # Generating a CPA API key for Orla
    export AISTACK_CLIPROXYAPI_KEY_FOR_ORLA="$($STELLA_API generate_password 48 "[:alnum:]")"
    cpa_settings_api_key_add "$AISTACK_CLIPROXYAPI_KEY_FOR_ORLA"
    echo "$AISTACK_CLIPROXYAPI_KEY_FOR_ORLA" > "$AISTACK_CLIPROXYAPI_KEY_FOR_ORLA_FILE"
}

orla_unregister_cpa_key() {
    if [ -n "$AISTACK_CLIPROXYAPI_KEY_FOR_ORLA" ]; then
        # Remove existing CPA API key for Orla
        cpa_settings_api_key_del "$AISTACK_CLIPROXYAPI_KEY_FOR_ORLA"
    fi
}

orla_connect_cpa() {
    local orla_mode="${1}" # agent or serve
    local model="${2}"

    local default_model
    if [ -n "${model}" ]; then
        default_model="$model"
    else
        # request cpa to get the first model available as the default model for orla AGENT mode
        default_model="$(cpa_get_model_list | head -n 1)"
    fi

    case "$orla_mode" in
        agent)
            orla_agent_register_default_backend "cpa" "openai" "$(cpa_settings_get_api_endpoint)" "AISTACK_CLIPROXYAPI_KEY_FOR_ORLA"
            [ -n "$default_model" ] && orla_agent_register_default_model "openai" "$default_model"
            ;;
        serve)
            # register cpa as a backend for orla service mode (orla service mode do not read the default backend from configuration file))
            curl -skL -X POST "$(orla_settings_get_api_endpoint)/backends" \
                        -H "Content-Type: application/json" \
                        -d \
                            '{
                                "name": "cpa",
                                "endpoint": "'$(cpa_settings_get_api_endpoint)'",
                                "type": "openai",
                                "api_key_env_var": "AISTACK_CLIPROXYAPI_KEY_FOR_ORLA",
                                "model_id": "openai:'${default_model}'"
                            }'
            ;;
        *)
            echo "Error: Unknown Orla mode $orla_mode for CPA connection"
            exit 1
            ;;
    esac

}


