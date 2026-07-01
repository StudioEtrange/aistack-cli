orla_init() {
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

    export ORLA_FEAT_INSTALL_ROOT="$AISTACK_ISOLATED_ROOT/orla"
    mkdir -p "${ORLA_FEAT_INSTALL_ROOT}"

	export AISTACK_ORLA_RUNTIME_REQUIRED=""
    
}

# return 0 : is installed
# return 1 : tool is not installed
# return 2 : missing runtime
orla_is_installed() {
	local r
	export AISTACK_ORLA_TOOL_AVAILABLE="false"
	for r in $AISTACK_ORLA_RUNTIME_REQUIRED; do aistack_runtime_is_detected "${r}" || return 2; done
	[ -x "$ORLA_FEAT_INSTALL_ROOT/orla" ] || return 1
	export AISTACK_ORLA_TOOL_AVAILABLE="true"
	export AISTACK_ORLA_TOOL_PATH="$CLIPROXYAPI_FEAT_INSTALL_ROOT/orla"
	return 0
}


# Download and install cliproxyapi from GitHub releases.
# @param {string} $1 - Optional version to install (e.g., "v0.1.0").
#                      If not provided, the latest version will be fetched.
# This function relies on the following environment variables to be set:
# - ORLA_FEAT_INSTALL_ROOT: The directory where cliproxyapi will be installed.
orla_install() {
	local r
    local version="$1"
    
    if [ -z "$version" ] || [ "$version" = "latest" ]; then
        echo "No version provided, fetching the latest version..."
        version=$(github_get_latest_release "dorcha-inc/orla")
        echo "latest version is ${version}"
    fi

	for r in $AISTACK_ORLA_RUNTIME_REQUIRED; do 
		echo "Require needed ${r} managed runtime"
		aistack_runtime_require "${r}"
	done

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

	orla_is_installed
}
 
orla_uninstall() {
	if orla_is_installed; then
		echo "Uninstalling Orla from ${ORLA_FEAT_INSTALL_ROOT}..."
		rm -Rf "${ORLA_FEAT_INSTALL_ROOT}"
		echo "Orla uninstalled successfully."
		orla_is_installed
	else
		echo "WARN : not installed or missing a required managed runtime $AISTACK_ORLA_RUNTIME_REQUIRED"
	fi
}



# add gemini launcher in path for shell
orla_path_register_for_shell() {
    local shell_name="$1"
	if orla_is_installed; then
		path_register_for_shell "orla" "${AISTACK_ORLA_LAUNCHER_HOME}" "$shell_name"
	fi
}
orla_path_unregister_for_shell() {
    local shell_name="${1:-all}"
    path_unregister_for_shell "orla" "$shell_name"
}
orla_path_register_for_vs_terminal() {
	if orla_is_installed; then
    	vscode_path_register_for_vs_terminal "orla" "${AISTACK_ORLA_LAUNCHER_HOME}"
	fi
}
orla_path_unregister_for_vs_terminal() {
    vscode_path_unregister_for_vs_terminal "orla" "${AISTACK_ORLA_LAUNCHER_HOME}"
}


orla_launch_export_variables="AISTACK_CLIPROXYAPI_KEY_FOR_ORLA AISTACK_RUN_CONTEXT_FILE AISTACK_ORLA_CONFIG_FILE ORLA_FEAT_INSTALL_ROOT"
orla_launch() {
    set -- "$@"

    if [ -f "$AISTACK_ORLA_CONFIG_FILE" ]; then
        set -- "$@" --config "$AISTACK_ORLA_CONFIG_FILE"
    fi

    (
        . "${AISTACK_RUN_CONTEXT_FILE}"

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

			if orla_is_installed; then
				# create a compatible POSIX shell script to be called from bash, zsn, fish and wo on
				# and executed by the default /bin/sh on the current system
				{
					echo '#!/bin/sh'
					for v in $orla_launch_export_variables; do
						printf 'export %s=%s\n' "$v" "$(shell_quote_posix "${!v}")"
					done

					declare -f orla_launch

					echo orla_launch \"\$@\"
				} > "${AISTACK_ORLA_LAUNCHER_HOME}/orla"

				chmod +x "${AISTACK_ORLA_LAUNCHER_HOME}/orla"
			fi
            ;;

        delete)
            rm -f "${AISTACK_ORLA_LAUNCHER_HOME}/orla"
            ;;

		refresh_if_exists)
			[ -f "${AISTACK_ORLA_LAUNCHER_HOME}/orla" ] && ( orla_launcher_manage "delete"; orla_launcher_manage "create" )
			;;
    esac
    
}



orla_info() {
    if [ -f "$AISTACK_ORLA_CONFIG_FILE" ]; then
        echo "CLIProxyAPI configuration file : $AISTACK_ORLA_CONFIG_FILE"

        echo "Orla API endpoint : $(orla_settings_get_api_endpoint)"

        [ -n "$AISTACK_CLIPROXYAPI_KEY_FOR_ORLA" ] && echo "To request CLIProxyAPI, use API key : $AISTACK_CLIPROXYAPI_KEY_FOR_ORLA (from file : $AISTACK_CLIPROXYAPI_KEY_FOR_ORLA_FILE)" || \
            echo "Not connected to CLIProxyAPI (no API key for CPA found in file $AISTACK_CLIPROXYAPI_KEY_FOR_ORLA_FILE)"
    else
        echo "No Orla configuration file found. ($AISTACK_ORLA_CONFIG_FILE)"
    fi

	echo
	echo "Orla available : $AISTACK_ORLA_TOOL_AVAILABLE"
	echo "Orla path : $AISTACK_ORLA_TOOL_PATH"
	echo "Orla needed managed runtime : $AISTACK_ORLA_RUNTIME_REQUIRED"

	echo
}


orla_show_config() {
	if [ -f "$AISTACK_ORLA_CONFIG_FILE" ]; then
		echo "Current Orla configuration file : $AISTACK_ORLA_CONFIG_FILE"
		cat "$AISTACK_ORLA_CONFIG_FILE"
	else
		echo "No Orla configuration file found."
	fi
}

orla_settings_configure() {
    echo "add some default settings :"
    echo " - set default listening address for orla service to localhost:8081"
    orla_settings_set_listen_address "localhost:8081"
    echo " - set for orla agent mode a default backend named ollama with endpoint http://localhost:11434"
    orla_agent_register_default_backend "default_ollama" "ollama" "http://localhost:11434"
    orla_agent_register_default_model
}

orla_settings_remove() {
    orla_unregister_cpa_key
    rm -Rf "$AISTACK_ORLA_CONFIG_HOME"
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
    if [ $? -ne 0 ]; then
        export AISTACK_CLIPROXYAPI_KEY_FOR_ORLA=
        echo "ERROR: Failed to generate and register CPA API key for Orla."
        return 1
    fi
    echo "$AISTACK_CLIPROXYAPI_KEY_FOR_ORLA" > "$AISTACK_CLIPROXYAPI_KEY_FOR_ORLA_FILE"

    # each time an api key is generated we need to refresh the launcher to update env vars
    orla_launcher_manage "create"
}

orla_unregister_cpa_key() {
    # Remove existing CPA API key for Orla
    cpa_settings_api_key_del "$AISTACK_CLIPROXYAPI_KEY_FOR_ORLA"
    export AISTACK_CLIPROXYAPI_KEY_FOR_ORLA=
    rm -f "$AISTACK_CLIPROXYAPI_KEY_FOR_ORLA_FILE"
}

# needs cpa to be running
orla_connect_cpa() {
    local orla_mode="${1}" # agent or serve
    local model="${2}"
    
    if ! cpa_is_configured; then
        echo "ERROR: Failed to generate and register CLIProxyAPI API key for Orla : CLIProxyAPI is not configured."
        return 1
    fi
    
    # needs cpa conf file exists
    echo "generate a CLIProxyAPI API key for Orla to connect to CPA backend"
    orla_generate_cpa_key
    if [ $? -ne 0 ]; then
        echo "ERROR: Failed to generate and register CLIProxyAPI API key for Orla."
        return 1
    fi
   
    local default_model
    if [ -n "${model}" ]; then
        default_model="$model"
    else
        # request cpa to get the first model available as the default model for orla AGENT mode
        # cpa_get_model_list needs cpa to be running
         if ! cpa_instance_reachable; then
            echo "ERROR: CLIProxyAPI instance is not reachable. Please make sure CLIProxyAPI is running and properly configured."
            return 1
        fi
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
            echo "ERROR: Unknown Orla mode $orla_mode for CPA connection"
            exit 1
            ;;
    esac

}


