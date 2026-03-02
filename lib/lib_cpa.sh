cpa_path() {
    # iatools path for cli proxy api
    export IATOOLS_CLIPROXYAPI_CONFIG_HOME="${HOME}/.cli-proxy-api"
    mkdir -p "${IATOOLS_CLIPROXYAPI_CONFIG_HOME}"

    export IATOOLS_CLIPROXYAPI_LAUNCHER_HOME="${IATOOLS_LAUNCHER_HOME}/cli-proxy-api"
    mkdir -p "${IATOOLS_CLIPROXYAPI_LAUNCHER_HOME}"


    # cli proxy api specific paths
    export IATOOLS_CLIPROXYAPI_CONFIG_FILE="${IATOOLS_CLIPROXYAPI_CONFIG_HOME}/config.yaml"
    
    export IATOOLS_CLIPROXYAPI_MANAGEMENT_API_KEY_FILE="${IATOOLS_CLIPROXYAPI_CONFIG_HOME}/management-api-key"

    export CPA_FEAT_INSTALL_ROOT="$IATOOLS_ISOLATED_DEPENDENCIES_ROOT/cli-proxy-api"
    mkdir -p "${CPA_FEAT_INSTALL_ROOT}"
    
}


# Download and install cliproxyapi from GitHub releases.

# @param {string} $1 - Optional version to install (e.g., "0.1.0").
#                      If not provided, the latest version will be fetched.
#
# This function relies on the following environment variables to be set:
# - CPA_FEAT_INSTALL_ROOT: The directory where cliproxyapi will be installed.
cpa_install() {
    local version="$1"
    
    if [ -z "$version" ] || [ "$version" = "latest" ]; then
        echo "CLIProxyAPI : No version provided, fetching the latest version..."
        local latest_tag
        latest_tag=$(curl -s "https://api.github.com/repos/router-for-me/CLIProxyAPI/releases/latest" | yq -r .tag_name)
        if [ -z "$latest_tag" ] || [ "$latest_tag" = "null" ]; then
            echo "ERROR: Could not fetch the latest CLIProxyAPI version from GitHub." >&2
            return 1
        fi
        # remove v prefix
        version="${latest_tag#v}"
        echo "CLIProxyAPI latest version is ${version}"
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
    local filename="CLIProxyAPI_${version}_${os_arch}.tar.gz"
    local download_url="https://github.com/router-for-me/CLIProxyAPI/releases/download/v${version}/${filename}"

    echo "Downloading and installing CLIProxyAPI ${version} from ${download_url} to ${CPA_FEAT_INSTALL_ROOT}..."
    $STELLA_API get_resource "CLIProxyAPI" "${download_url}" "HTTP_ZIP" "$CPA_FEAT_INSTALL_ROOT" "DEST_ERASE"
    echo "CLIProxyAPI installed successfully."
}
 
cpa_uninstall() {
    echo "Uninstalling CLIProxyAPI from ${CPA_FEAT_INSTALL_ROOT}..."
    rm -Rf "${CPA_FEAT_INSTALL_ROOT}"
    echo "CLIProxyAPI uninstalled successfully."
}

cpa_launcher_manage() {
    if [ "${CPA_TEST_FEATURE}" = "1" ]; then
        # launcher based on a symbolic link - test link does not exist OR is not valid
        if [ ! -L "${IATOOLS_CLIPROXYAPI_LAUNCHER_HOME}/cli-proxy-api" ] || [ ! -e "${IATOOLS_CLIPROXYAPI_LAUNCHER_HOME}/cli-proxy-api" ]; then
            echo "Create an CLIProxyAPI launcher"
            ln -fsv "${CPA_FEAT_INSTALL_ROOT}/cli-proxy-api" "${IATOOLS_CLIPROXYAPI_LAUNCHER_HOME}/cli-proxy-api"
        fi
    else
        rm -f "${IATOOLS_CLIPROXYAPI_LAUNCHER_HOME}/cli-proxy-api"
    fi
}


cpa_settings_configure() {

    $STELLA_API feature_info "cliproxyapi" "CPA"

    [ ! -f "${IATOOLS_CLIPROXYAPI_CONFIG_FILE}" ] && cp -f "$CPA_FEAT_INSTALL_ROOT/config.example.yaml" "$IATOOLS_CLIPROXYAPI_CONFIG_FILE"
    # TODO
    echo "add some default settings :"
    cpa_settings_set_host "localhost"
    cpa_settings_api_key_reset
    cpa_settings_api_key_create
    
    cpa_settings_management_api_key_reset
    cpa_settings_management_api_key_create
}

cpa_settings_remove() {
    rm -Rf "$IATOOLS_CLIPROXYAPI_CONFIG_HOME"
}


cpa_info() {
    if [ -f "$IATOOLS_CLIPROXYAPI_CONFIG_FILE" ]; then
        echo "CLIProxyAPI configuration file : $IATOOLS_CLIPROXYAPI_CONFIG_FILE"

        local tls="$(cpa_get_config ".tls.enable")"
        local scheme="http"
        [ "$tls" = "true" ] && scheme="https"
        local api_uri="${scheme}://$(cpa_get_config ".host"):$(cpa_get_config ".port")"
                
        echo "Management UI : ${api_uri}/management.html"
        echo "Management key : $(cat "$IATOOLS_CLIPROXYAPI_MANAGEMENT_API_KEY_FILE")"

        echo "CLIProxyAPI API endpoint : $api_uri" 
        echo "CLIProxyAPI API keys list :" 
        cpa_settings_api_key_list
    else
        echo "No CLIProxyAPI configuration file found. $IATOOLS_CLIPROXYAPI_CONFIG_FILE"
    fi
}

cpa_launch() {
    local list_args=()

    if [ -f "$IATOOLS_CLIPROXYAPI_CONFIG_FILE" ]; then
        list_args+=("--config" "$IATOOLS_CLIPROXYAPI_CONFIG_FILE")
    fi

    for arg in "$@"; do
        list_args+=("$arg")
    done

    if [ ${#list_args[@]} -gt 0 ]; then
        $CPA_FEAT_INSTALL_ROOT/cli-proxy-api "${list_args[@]}"
    else
        $CPA_FEAT_INSTALL_ROOT/cli-proxy-api
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
    yaml_del_key_from_file "$IATOOLS_CLIPROXYAPI_CONFIG_FILE" "$key_path"
}

cpa_set_config() {
    local key_path="$1"
    local value="$2"
    local string_style="$3"

    case "$key_path" in
        .*) ;;
        *)  key_path=".$key_path" ;;
    esac

    yaml_set_key_into_file "$IATOOLS_CLIPROXYAPI_CONFIG_FILE" "$key_path" "$value" "$string_style"
}

cpa_get_config() {
    local key_path="$1"

    case "$key_path" in
        .*) ;;
        *)  key_path=".$key_path" ;;
    esac

    yaml_get_key_from_file "$IATOOLS_CLIPROXYAPI_CONFIG_FILE" "$key_path"
}



# host management ------------------------
cpa_settings_set_host() {
    local host="$1"
    cpa_set_config ".host" "$host" "double"
}

cpa_settings_set_port() {
    local port="$1"
    cpa_set_config ".port" "$port"
}

# remote management ------------------------
# to fully disable management api, set secret-key to empty
cpa_settings_management_api_disable() {
    cpa_settings_management_api_key_reset
}


cpa_settings_management_api_key_reset() {
    cpa_set_config ".remote-management.secret-key" "" "double"

    echo "" > "$IATOOLS_CLIPROXYAPI_MANAGEMENT_API_KEY_FILE"
}

cpa_settings_management_api_key_create() {
    local key="$($STELLA_API generate_password 12 "[:alnum:]")"
    cpa_settings_management_api_key_set "$key"

    echo "$key" > "$IATOOLS_CLIPROXYAPI_MANAGEMENT_API_KEY_FILE"

    echo "New management API key created : $key"
    echo "WARN : management API key is hashed in config file, so save it now"
}

# note : the management API key is hashed in the config file
cpa_settings_management_api_key_set() {
    local key="$1"
    cpa_set_config ".remote-management.secret-key" "$key" "double"
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

    if ! KEY="$key" yq eval -i '.["api-keys"] += [strenv(KEY)] | .["api-keys"][] style="double"' "$IATOOLS_CLIPROXYAPI_CONFIG_FILE"; then
        echo "ERROR: Failed to add API key to configuration" >&2
        return 1
    fi
}

cpa_settings_api_key_del() {
    local key="$1"

    [ -f "$IATOOLS_CLIPROXYAPI_CONFIG_FILE" ] || { echo "ERROR: file $IATOOLS_CLIPROXYAPI_CONFIG_FILE not found" >&2; return 1; }

    KEY="$key" yq eval -i '
        .["api-keys"] |= (
        (. // [])
        | map(select(. != strenv(KEY)))
        )
    ' "$IATOOLS_CLIPROXYAPI_CONFIG_FILE"
}


cpa_settings_api_key_list() {
    yaml_get_key_from_file "$IATOOLS_CLIPROXYAPI_CONFIG_FILE" ".api-keys" 
}
