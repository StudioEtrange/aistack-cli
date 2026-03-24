cpa_path() {
    # aistack path for cli proxy api
    export AISTACK_CLIPROXYAPI_CONFIG_HOME="${HOME}/.cli-proxy-api"
    mkdir -p "${AISTACK_CLIPROXYAPI_CONFIG_HOME}"

    export AISTACK_CLIPROXYAPI_LAUNCHER_HOME="${AISTACK_LAUNCHER_HOME}/cli-proxy-api"
    mkdir -p "${AISTACK_CLIPROXYAPI_LAUNCHER_HOME}"


    # cli proxy api specific paths
    export AISTACK_CLIPROXYAPI_CONFIG_FILE="${AISTACK_CLIPROXYAPI_CONFIG_HOME}/config.yaml"
    
    export AISTACK_CLIPROXYAPI_MANAGEMENT_API_KEY_FILE="${AISTACK_CLIPROXYAPI_CONFIG_HOME}/management-api-key"
    

    export CPA_FEAT_INSTALL_ROOT="$AISTACK_ISOLATED_DEPENDENCIES_ROOT/cli-proxy-api"
    mkdir -p "${CPA_FEAT_INSTALL_ROOT}"
    
}


# Download and install cliproxyapi from GitHub releases.
# @param {string} $1 - Optional version to install (e.g., "v0.1.0").
#                      If not provided, the latest version will be fetched.
#
# This function relies on the following environment variables to be set:
# - CPA_FEAT_INSTALL_ROOT: The directory where cliproxyapi will be installed.
cpa_install() {
    local version="$1"
    
    if [ -z "$version" ] || [ "$version" = "latest" ]; then
        echo "No version provided, fetching the latest version..."
        version=$(github_get_latest_release "router-for-me/CLIProxyAPI")
        echo "latest version is ${version}"
    fi

    local os_arch
    case "$STELLA_CURRENT_PLATFORM" in
        linux)
            [ "$STELLA_CURRENT_CPU_FAMILY" = "intel" ] && os_arch="linux_amd64"
            [ "$STELLA_CURRENT_CPU_FAMILY" = "arm" ] && os_arch="linux_arm64"
            ;;
        darwin)
            [ "$STELLA_CURRENT_CPU_FAMILY" = "intel" ] && os_arch="darwin_amd64"
            [ "$STELLA_CURRENT_CPU_FAMILY" = "arm" ] && os_arch="darwin_arm64"
            ;;
    esac
    local filename="CLIProxyAPI_${version#v}_${os_arch}.tar.gz"
    local download_url="https://github.com/router-for-me/CLIProxyAPI/releases/download/${version}/${filename}"

    echo "Downloading and installing CLIProxyAPI ${version} from ${download_url} to ${CPA_FEAT_INSTALL_ROOT}..."
    $STELLA_API get_resource "CLIProxyAPI" "${download_url}" "HTTP_ZIP" "$CPA_FEAT_INSTALL_ROOT" "DEST_ERASE"
    echo "CLIProxyAPI installed successfully."
}
 
cpa_uninstall() {
    echo "Uninstalling CLIProxyAPI from ${CPA_FEAT_INSTALL_ROOT}..."
    rm -Rf "${CPA_FEAT_INSTALL_ROOT}"
    echo "CLIProxyAPI uninstalled successfully."
}

cpa_launch_export_variables="AISTACK_CLIPROXYAPI_CONFIG_FILE CPA_FEAT_INSTALL_ROOT"
cpa_launch() {
    if [ -f "$AISTACK_CLIPROXYAPI_CONFIG_FILE" ]; then
        set -- --config "$AISTACK_CLIPROXYAPI_CONFIG_FILE" "$@"
    fi

    if [ "$#" -gt 0 ]; then
        "$CPA_FEAT_INSTALL_ROOT/cli-proxy-api" "$@"
    else
        "$CPA_FEAT_INSTALL_ROOT/cli-proxy-api"
    fi
}

cpa_launcher_manage() {
    local action="${1:-create}"

    case $action in
        create)
            if [ -x "${CPA_FEAT_INSTALL_ROOT}/cli-proxy-api" ]; then
                # echo "Create an CLIProxyAPI launcher"
                # rm -f "${AISTACK_CLIPROXYAPI_LAUNCHER_HOME}/cli-proxy-api"
                # # launcher based on a symbolic link
                # ln -fsv "${CPA_FEAT_INSTALL_ROOT}/cli-proxy-api" "${AISTACK_CLIPROXYAPI_LAUNCHER_HOME}/cli-proxy-api"
                {
                    echo '#!/bin/sh'
                    for v in $cpa_launch_export_variables; do
                        printf '%s=%s\n' "$v" "$(shell_quote_posix "${!v}")"
                    done

                    declare -f cpa_launch

                    echo cpa_launch \"\$@\"
                } > "${AISTACK_CLIPROXYAPI_LAUNCHER_HOME}/cli-proxy-api"

                chmod +x "${AISTACK_CLIPROXYAPI_LAUNCHER_HOME}/cli-proxy-api"

            fi
            ;;

        delete)
            rm -f "${AISTACK_CLIPROXYAPI_LAUNCHER_HOME}/cli-proxy-api"
            ;;
    esac
}


cpa_settings_configure() {

   [ ! -f "${AISTACK_CLIPROXYAPI_CONFIG_FILE}" ] && cp -f "$CPA_FEAT_INSTALL_ROOT/config.example.yaml" "$AISTACK_CLIPROXYAPI_CONFIG_FILE"

    echo "add some default settings :"
    cpa_settings_set_host "localhost"
    cpa_settings_set_port "8317"
    cpa_settings_api_key_reset
    cpa_settings_api_key_create
    
    cpa_settings_management_api_key_reset
    cpa_settings_management_api_key_create

    # TODO : kilocode do not support yet insecure self signed certificate : https://github.com/Kilo-Org/kilocode/issues/6827
    #cpa_settings_configure_tls
}

cpa_settings_remove() {
    rm -Rf "$AISTACK_CLIPROXYAPI_CONFIG_HOME"
}


cpa_info() {
    if [ -f "$AISTACK_CLIPROXYAPI_CONFIG_FILE" ]; then
        echo "CLIProxyAPI configuration file : $AISTACK_CLIPROXYAPI_CONFIG_FILE"

        local address="$(cpa_settings_get_address)"

        echo "Management UI : ${address}/management.html"
        echo "Management key : $(cpa_settings_management_api_key_get)"

        echo "CLIProxyAPI API endpoint : $(cpa_settings_get_api_endpoint)" 
        echo "CLIProxyAPI API keys list :" 
        cpa_settings_api_key_list
    else
        echo "No CLIProxyAPI configuration file found. $AISTACK_CLIPROXYAPI_CONFIG_FILE"
    fi
}




# login management -----------------

# gemini oauth 
#  cpa_login_gemini_oauth [--project_id <your_project_id>]
cpa_login_gemini_oauth() {
    echo "Login to Gemini OAuth"
    echo "The local OAuth callback uses port 8085"
    cpa_launch --login --no-browser "$@"
}

# openai oauth
cpa_login_openai_oauth() {
    echo "Login to OpenAI OAuth"
    echo "The local OAuth callback uses port 1455"
    cpa_launch --codex-login --no-browser "$@"
}

# qwen oauth
cpa_login_qwen_oauth() {
    echo "Login to Qwen OAuth"
    cpa_launch --qwen-login --no-browser "$@"
}

# generic config management -----------------
cpa_remove_config() {
    local key_path="$1"

    case "$key_path" in
        .*) ;;
        *)  key_path=".$key_path" ;;
    esac

    yaml_del_key_from_file "$AISTACK_CLIPROXYAPI_CONFIG_FILE" "$key_path"
}

cpa_set_config() {
    local key_path="$1"
    local value="$2"
    local string_style="$3"

    case "$key_path" in
        .*) ;;
        *)  key_path=".$key_path" ;;
    esac

    yaml_set_key_into_file "$AISTACK_CLIPROXYAPI_CONFIG_FILE" "$key_path" "$value" "$string_style"

}

cpa_get_config() {
    local key_path="$1"

    case "$key_path" in
        .*) ;;
        *)  key_path=".$key_path" ;;
    esac

    yaml_get_key_from_file "$AISTACK_CLIPROXYAPI_CONFIG_FILE" "$key_path"
}



# host management ------------------------
cpa_settings_set_host() {
    local host="$1"
    # TODO check double option
    cpa_set_config "host" "$host" "double"
}

cpa_settings_set_port() {
    local port="$1"
    cpa_set_config "port" "$port"
}

cpa_settings_get_address() {
    local tls="$(cpa_get_config ".tls.enable")"
    local scheme="http"
    [ "$tls" = "true" ] && scheme="https"
    local api_uri="${scheme}://$(cpa_get_config ".host"):$(cpa_get_config ".port")"
    echo -n "$api_uri"
}

cpa_settings_get_api_endpoint() {
    echo -n "$(cpa_settings_get_address)/v1"
}

# remote management ------------------------
# to fully disable management api, set secret-key to empty
cpa_settings_management_api_disable() {
    cpa_settings_management_api_key_reset
}


cpa_settings_management_api_key_reset() {
    cpa_set_config ".remote-management.secret-key" "" "double"

    echo "" > "$AISTACK_CLIPROXYAPI_MANAGEMENT_API_KEY_FILE"
}

cpa_settings_management_api_key_create() {
    local key="$($STELLA_API generate_password 12 "[:alnum:]")"
    cpa_settings_management_api_key_set "$key"

    echo "$key" > "$AISTACK_CLIPROXYAPI_MANAGEMENT_API_KEY_FILE"

    echo "New management API key created : $key"
}

# note : the management API key is hashed in the config file
cpa_settings_management_api_key_set() {
    local key="$1"
    cpa_set_config ".remote-management.secret-key" "$key" "double"
}

cpa_settings_management_api_key_get() {
    [ -f "$AISTACK_CLIPROXYAPI_MANAGEMENT_API_KEY_FILE" ] && cat "$AISTACK_CLIPROXYAPI_MANAGEMENT_API_KEY_FILE"
}

# API key management ------------------------
cpa_settings_api_key_reset() {
    cpa_remove_config ".api-keys"
}

cpa_settings_api_key_create() {
    local key="$($STELLA_API generate_password 48 "[:alnum:]")"
    cpa_settings_api_key_add "$key"
    echo "New API key created: $key"
}

cpa_settings_api_key_add() {
    local key="$1"

    local tmp_target_file="$(mktemp)"
    # NOTE : avoid using -i (and -P) to preserve file formatting like quote style for values
    #if ! KEY="$key" yq eval -i '.["api-keys"] += [strenv(KEY)] | .["api-keys"][] style="double"' "$AISTACK_CLIPROXYAPI_CONFIG_FILE"; then
    if ! KEY="$key" yq eval '.["api-keys"] += [strenv(KEY)] | .["api-keys"][] style="double"' "$AISTACK_CLIPROXYAPI_CONFIG_FILE" > "$tmp_target_file"; then
        echo "ERROR: Failed to add API key to configuration" >&2
        rm -f "$tmp_target_file"
        return 1
    fi
    
    cp -f "$tmp_target_file" "$AISTACK_CLIPROXYAPI_CONFIG_FILE"
    rm -f "$tmp_target_file"
}

cpa_settings_api_key_del() {
    local key="$1"

    [ -f "$AISTACK_CLIPROXYAPI_CONFIG_FILE" ] || { echo "ERROR: file $AISTACK_CLIPROXYAPI_CONFIG_FILE not found" >&2; return 1; }

    local tmp_target_file="$(mktemp)"
    # NOTE : avoid using -i (and -P) to preserve file formatting like quote style for values
    KEY="$key" yq eval '
        .["api-keys"] |= (
        (. // [])
        | map(select(. != strenv(KEY)))
        )
    ' "$AISTACK_CLIPROXYAPI_CONFIG_FILE" > "$tmp_target_file" || {
        echo "ERROR: Failed to remove API key from configuration" >&2
        rm -f "$tmp_target_file"
        return 1
    }

    
    cp -f "$tmp_target_file" "$AISTACK_CLIPROXYAPI_CONFIG_FILE"
    rm -f "$tmp_target_file"
}


cpa_settings_api_key_list() {
    yaml_get_key_from_file "$AISTACK_CLIPROXYAPI_CONFIG_FILE" ".api-keys" | yq -r '.[]'
}

cpa_settings_api_key_get() {
    local index="${1:-0}"
    if ! cat "$AISTACK_CLIPROXYAPI_CONFIG_FILE" 2>/dev/null | yq '.api-keys['$index'] | sub("^null$"; "")' 2>/dev/null; then
        return 1
    fi
}


# tls management ------------------------
cpa_settings_configure_tls() {
    echo "Configuring TLS"
    local key_path="${1:-}"
    local cert_path="${2:-}"

    local self_signed=0
    [ "$key_path" = "" ] && self_signed=1
    [ "$cert_path" = "" ] && self_signed=1

    if [ $self_signed -eq 1 ]; then
        
        if ! command -v openssl >/dev/null 2>&1; then
            echo "WARN: cannot generate self-signed certificate because openssl is missing." >&2
            return 1
        else
            echo "generate auto signed certificate"
            key_path="${AISTACK_CLIPROXYAPI_CONFIG_HOME}/server.key"
            cert_path="${AISTACK_CLIPROXYAPI_CONFIG_HOME}/server.crt"

            generate_self_signed_cert "$key_path" "$cert_path" "localhost"
            if [ $? -ne 0 ]; then
                echo "ERROR: Failed to generate self-signed certificate for CLIProxyAPI." >&2
                return 1
            fi
        fi
    fi 

    cpa_set_config ".tls.enable" "true"
    cpa_set_config ".tls.cert" "$cert_path" "double"
    cpa_set_config ".tls.key" "$key_path" "double"

    echo "TLS with certificate configured successfully with $cert_path and $key_path."
}



cpa_get_model_list() {
    curl -skL -X GET http://localhost:8317/v1/models \
        -H "Authorization: Bearer $(cpa_settings_api_key_get 0)" \
        -H "Content-Type: application/json" | jq -r '.data[]?.id // empty' | sort

}
