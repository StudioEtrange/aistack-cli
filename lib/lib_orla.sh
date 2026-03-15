orla_path() {
    # aistack path for orla
    export AISTACK_ORLA_CONFIG_HOME="${HOME}/.orla"
    mkdir -p "${AISTACK_ORLA_CONFIG_HOME}"

    export AISTACK_ORLA_LAUNCHER_HOME="${AISTACK_LAUNCHER_HOME}/orla"
    mkdir -p "${AISTACK_ORLA_LAUNCHER_HOME}"


    # orla specific paths
    export AISTACK_ORLA_CONFIG_FILE="${AISTACK_ORLA_CONFIG_HOME}/orla.yaml"
    

    export ORLA_FEAT_INSTALL_ROOT="$AISTACK_ISOLATED_DEPENDENCIES_ROOT/orla"
    mkdir -p "${ORLA_FEAT_INSTALL_ROOT}"
    
}


# Download and install cliproxyapi from GitHub releases.
# @param {string} $1 - Optional version to install (e.g., "0.1.0").
#                      If not provided, the latest version will be fetched.
# This function relies on the following environment variables to be set:
# - ORLA_FEAT_INSTALL_ROOT: The directory where cliproxyapi will be installed.
orla_install() {
    local version="$1"
    
    if [ -z "$version" ] || [ "$version" = "latest" ]; then
        echo "No version provided, fetching the latest version..."
        local latest_tag
        latest_tag=$(curl -s "https://api.github.com/repos/dorcha-inc/orla/releases/latest" | yq -r .tag_name)
        if [ -z "$latest_tag" ] || [ "$latest_tag" = "null" ]; then
            echo "ERROR: Could not fetch the latest version from GitHub." >&2
            return 1
        fi
        # remove v prefix
        version="${latest_tag#v}"
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
    local download_url="https://github.com/dorcha-inc/orla/releases/download/v${version}/${filename}"

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

orla_launcher_manage() {
    local action="${1:-create}"

    case $action in

        create)
            if [ "${CPA_TEST_FEATURE}" = "1" ]; then
                # launcher based on a symbolic link - test link does not exist OR is not valid
                if [ ! -L "${AISTACK_ORLA_LAUNCHER_HOME}/orla" ] || [ ! -e "${AISTACK_ORLA_LAUNCHER_HOME}/orla" ]; then
                    echo "Create an Orla launcher"
                    ln -fsv "${ORLA_FEAT_INSTALL_ROOT}/orla" "${AISTACK_ORLA_LAUNCHER_HOME}orla"
                fi
            fi
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

}

orla_settings_remove() {
    rm -Rf "$AISTACK_ORLA_CONFIG_HOME"
}


orla_info() {
    if [ -f "$AISTACK_ORLA_CONFIG_FILE" ]; then
        echo "CLIProxyAPI configuration file : $AISTACK_ORLA_CONFIG_FILE"

        local scheme="http"
        local api_uri="${scheme}://$(orla_get_config ".listen_address")"

        echo "Orla API endpoint : $api_uri" 
    else
        echo "No Orla configuration file found. $AISTACK_ORLA_CONFIG_FILE"
    fi
}

orla_launch() {
    local list_args=()


    for arg in "$@"; do
        list_args+=("$arg")
    done

    if [ -f "$AISTACK_ORLA_CONFIG_FILE" ]; then
        list_args+=("--config" "$AISTACK_ORLA_CONFIG_FILE")
    fi

    if [ ${#list_args[@]} -gt 0 ]; then
        $ORLA_FEAT_INSTALL_ROOT/orla "${list_args[@]}"
    else
        $ORLA_FEAT_INSTALL_ROOT/orla
    fi
}


# generic config management -----------------
orla_remove_config() {
    local key_path="$1"
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
    # default is localhost:8081
    orla_set_config "listen_address" "$address"
}
# model management ------------------------
orla_settings_register_default_backend() {
    local nickname="$1"
    local type"$2" # ollama or openai or sglang
    local endpoint="$3"
    local max_concurrency="${4:-1}"
    local api_key_env_var="$5"

    orla_set_config "llm_backend.name" "$nickname"
    orla_set_config "llm_backend.type" "$type"
    orla_set_config "llm_backend.endpoint" "$endpoint"
    orla_set_config "llm_backend.max_concurrency" "$max_concurrency"

    [ -n "$api_key_env_var" ] && orla_set_config "llm_backend.api_key_env_var" "$api_key_env_var"
}


orla_connect_cpa() {
    export AISTACK_CLIPROXYAPI_KEY_FOR_ORLA="$($STELLA_API generate_password 48 "[:alnum:]")"
    cpa_settings_api_key_add "$AISTACK_CLIPROXYAPI_KEY_FOR_ORLA"
    
    orla_settings_register_default_backend "cpa" "openai" "$(cpa_get_address)/v1" "1" "AISTACK_CLIPROXYAPI_KEY_FOR_ORLA"
}

# curl -X POST http://localhost:8081/api/v1/backends \
#   -H "Content-Type: application/json" \
#   -d '{
#     "name": "ollama",
#     "endpoint": "http://ollama:11434",
#     "type": "ollama",
#     "model_id": "ollama:llama3.2:3b",
#     "api_key_env_var": ""
#   }'

# model: "ollama:qwen3:0.6b"
# llm_backend:
#   type: "ollama"
#   endpoint: "http://localhost:11434"
#   max_concurrency: 1

# model: "openai:gpt-4.1"
# llm_backend:
#   type: "openai"
#   endpoint: "https://mon-endpoint-openai-compatible/v1"
#   api_key_env_var: "MY_LLM_API_KEY"
#   max_concurrency: 8