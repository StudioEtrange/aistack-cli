opencode_init() {
    # oc specific paths
    export AISTACK_OPENCODE_LOCAL_SHARE_HOME="$HOME/.local/share/opencode"
    export AISTACK_OPENCODE_CONFIG_HOME="$HOME/.config/opencode"
    #You can also specify a custom config file path using the OPENCODE_CONFIG environment variable. This takes precedence over the global and project configs.
    [ "$OPENCODE_CONFIG" = "" ] && export AISTACK_OPENCODE_CONFIG_FILE="$AISTACK_OPENCODE_CONFIG_HOME/opencode.json" || export AISTACK_OPENCODE_CONFIG_FILE="$OPENCODE_CONFIG"

    # cpa key for opencode to connect to cpa backend
    export AISTACK_CLIPROXYAPI_KEY_FOR_OPENCODE_FILE="${AISTACK_OPENCODE_CONFIG_HOME}/cpa_key_for_oc"
    [ -f "$AISTACK_CLIPROXYAPI_KEY_FOR_OPENCODE_FILE" ] && export AISTACK_CLIPROXYAPI_KEY_FOR_OPENCODE="$(cat "$AISTACK_CLIPROXYAPI_KEY_FOR_OPENCODE_FILE")"

    # aistack path for oc
    export AISTACK_OPENCODE_LAUNCHER_HOME="${AISTACK_LAUNCHER_HOME}/opencode"
    mkdir -p "${AISTACK_OPENCODE_LAUNCHER_HOME}"

	export AISTACK_OPENCODE_RUNTIME_REQUIRED="nodejs"
}

# return 0 : is installed
# return 1 : tool is not installed
# return 2 : missing runtime
opencode_is_installed() {
	local r
	export AISTACK_OPENCODE_TOOL_AVAILABLE="false"
	for r in $AISTACK_OPENCODE_RUNTIME_REQUIRED; do aistack_runtime_is_detected "${r}" || return 2; done
	[ -x "$AISTACK_RUNTIME_NODEJS_SEARCH_PATH/opencode" ] || return 1
	export AISTACK_OPENCODE_TOOL_PATH="$AISTACK_RUNTIME_NODEJS_SEARCH_PATH/opencode"
	export AISTACK_OPENCODE_TOOL_AVAILABLE="true"
	return 0
}

opencode_install() {
	local r
    local version="$1"
    [ -z "${version}" ] && version="@latest"

	for r in $AISTACK_OPENCODE_RUNTIME_REQUIRED; do 
		echo "Require needed ${r} rmanaged untime"
		aistack_runtime_require "${r}"
	done

    echo "Installing Opencode CLI"
	node_package_install "opencode-ai${version}"
    #PATH="${AISTACK_RUNTIME_NODEJS_SEARCH_PATH}:${STELLA_ORIGINAL_SYSTEM_PATH}" npm install --verbose -g opencode-ai${version}

	opencode_is_installed
}

opencode_uninstall() {
	if opencode_is_installed; then
		node_package_uninstall "opencode-ai"
		#PATH="${AISTACK_RUNTIME_NODEJS_SEARCH_PATH}:${STELLA_ORIGINAL_SYSTEM_PATH}" npm uninstall -g opencode-ai
		opencode_is_installed
	else
		echo "WARN : not installed or missing a required managed runtime $AISTACK_OPENCODE_RUNTIME_REQUIRED"
	fi
}


# add opencode launcher in path for shell
opencode_path_register_for_shell() {
    local shell_name="$1"
	if opencode_is_installed; then
    	path_register_for_shell "opencode" "${AISTACK_OPENCODE_LAUNCHER_HOME}" "$shell_name"
	fi
}
opencode_path_unregister_for_shell() {
    local shell_name="${1:-all}"
    path_unregister_for_shell "opencode" "$shell_name"
}
opencode_path_register_for_vs_terminal() {
	if opencode_is_installed; then
    	vscode_path_register_for_vs_terminal "opencode" "${AISTACK_OPENCODE_LAUNCHER_HOME}"
	fi
}
opencode_path_unregister_for_vs_terminal() {
    vscode_path_unregister_for_vs_terminal "opencode" "${AISTACK_OPENCODE_LAUNCHER_HOME}"
}

opencode_launch_variables="AISTACK_CLIPROXYAPI_KEY_FOR_OPENCODE AISTACK_RUN_CONTEXT_FILE AISTACK_RUNTIME_NODEJS_SEARCH_PATH"
opencode_launch() {
    (
        . "${AISTACK_RUN_CONTEXT_FILE}"

        if [ "$#" -gt 0 ]; then
            "$AISTACK_RUNTIME_NODEJS_SEARCH_PATH/opencode" "$@"
        else
            "$AISTACK_RUNTIME_NODEJS_SEARCH_PATH/opencode"
        fi
    )
}

opencode_launcher_manage() {
    local action="${1:-create}"

    case $action in
        create)
            # echo '#!/bin/sh' > "${AISTACK_OPENCODE_LAUNCHER_HOME}/opencode"
            # echo ". ${AISTACK_RUN_CONTEXT_FILE}" >> "${AISTACK_OPENCODE_LAUNCHER_HOME}/opencode"
            # echo "opencode \$@" >> "${AISTACK_OPENCODE_LAUNCHER_HOME}/opencode"
            # chmod +x "${AISTACK_OPENCODE_LAUNCHER_HOME}/opencode"

            # launcher based on a symbolic link - test link does not exist OR is not valid
            # if [ ! -L "${AISTACK_OPENCODE_LAUNCHER_HOME}/opencode" ] || [ ! -e "${AISTACK_OPENCODE_LAUNCHER_HOME}/opencode" ]; then
            #     echo "Create an opencode launcher"
            #     ln -fsv "${AISTACK_RUNTIME_NODEJS_SEARCH_PATH}opencode" "${AISTACK_OPENCODE_LAUNCHER_HOME}/opencode"
            # fi

			if opencode_is_installed; then
				# create a compatible POSIX shell script to be called from bash, zsn, fish and wo on
				# and executed by the default /bin/sh on the current system
				{
					echo '#!/bin/sh'
					for v in $opencode_launch_variables; do
						printf 'export %s=%s\n' "$v" "$(shell_quote_posix "${!v}")"
					done

					declare -f opencode_launch

					echo opencode_launch \"\$@\"
				} > "${AISTACK_OPENCODE_LAUNCHER_HOME}/opencode"

				chmod +x "${AISTACK_OPENCODE_LAUNCHER_HOME}/opencode"
			fi
            ;;

        delete)
            rm -Rf "${AISTACK_OPENCODE_LAUNCHER_HOME}"
            mkdir -p "${AISTACK_OPENCODE_LAUNCHER_HOME}"
            ;;
	
		refresh_if_exists)
			[ -f "${AISTACK_OPENCODE_LAUNCHER_HOME}/opencode" ] && ( opencode_launcher_manage "delete"; opencode_launcher_manage "create" )
			;;
    esac
}

opencode_settings_configure() {

    echo "add some default settings :"
    merge_json_file "${AISTACK_POOL}/settings/opencode/opencode.json" "$AISTACK_OPENCODE_CONFIG_FILE"
}


opencode_info() {
    echo "Configuration file : $AISTACK_OPENCODE_CONFIG_FILE"
	echo
	echo "OPENCODE available : $ISTACK_OPENCODE_TOOL_AVAILABLE"
	echo "OPENCODE path : $ISTACK_OPENCODE_TOOL_PATH"
	echo "OPENCODE needed managed runtime : $AISTACK_OPENCODE_RUNTIME_REQUIRED"
	echo
    [ -n "$AISTACK_CLIPROXYAPI_KEY_FOR_OPENCODE" ] && echo "To request CLIProxyAPI, use API key : $AISTACK_CLIPROXYAPI_KEY_FOR_OPENCODE (from file : $AISTACK_CLIPROXYAPI_KEY_FOR_OPENCODE_FILE)" || \
        echo "Not connected to CLIProxyAPI (no API key for CPA found in file $AISTACK_CLIPROXYAPI_KEY_FOR_OPENCODE_FILE)"
}

opencode_show_config() {
    if [ -f "$AISTACK_OPENCODE_CONFIG_FILE" ]; then
        echo "Current configuration file : $AISTACK_OPENCODE_CONFIG_FILE"
        cat "$AISTACK_OPENCODE_CONFIG_FILE"
    else
        echo "No configuration file found. ($AISTACK_OPENCODE_CONFIG_FILE)"
    fi
}


opencode_settings_remove() {
    opencode_unregister_cpa_key
    rm -Rf "$AISTACK_OPENCODE_LOCAL_SHARE_HOME"
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

    opencode_remove_config "provider.${provider_id}"

    opencode_set_config "provider.${provider_id}.npm" "\"$provider_type\""
    opencode_set_config "provider.${provider_id}.name" "\"$provider_display_name\""
    opencode_set_config "provider.${provider_id}.options.baseURL" "\"$endpoint\""
    [ -n "$api_key" ] && opencode_set_config "provider.${provider_id}.options.apiKey" "\"$api_key\""
    [ -n "$api_key_env_var" ] && opencode_set_config "provider.${provider_id}.options.apiKey" "\"{env:$api_key_env_var}\""
}

opencode_register_model() {
    local provider_id="$1"
    local model_id="$2"
    local real_model_id="$3"
    local model_display_name="$4"
    local reasoning="$5" # true | false
    local tool_call="$6" # true | false
    local limit_context="$7"
    local limit_output="$8"

    local original_provider_id="$provider_id"
    [ -n "${provider_id}" ] && provider_id="${provider_id//./\\.}" || { echo "ERROR opencode_register_model : missing provider_id"; return 1; }
    local original_model_id="$model_id"
    [ -n "${model_id}" ] && model_id="${model_id//./\\.}" || { echo "ERROR opencode_register_model : missing model_id"; return 1; }

    [ -z "${real_model_id}" ] && { echo "ERROR opencode_register_model : missing real_model_id"; return 1; }

    [ -z "${model_display_name}" ] && model_display_name="$original_model_id"

    opencode_remove_config "provider.${provider_id}.models.${model_id}"
    opencode_set_config "provider.${provider_id}.models.${model_id}.id" "\"$real_model_id\""
    opencode_set_config "provider.${provider_id}.models.${model_id}.name" "\"$model_display_name\""

    [ -n "$reasoning" ] && opencode_set_config "provider.${provider_id}.models.${model_id}.reasoning" "$reasoning"
    [ -n "$tool_call" ] && opencode_set_config "provider.${provider_id}.models.${model_id}.tool_call" "$tool_call"

    [ -n "$limit_context" ] && opencode_set_config "provider.${provider_id}.models.${model_id}.limit.context" "$limit_context"
    [ -n "$limit_output" ] && opencode_set_config "provider.${provider_id}.models.${model_id}.limit.output" "$limit_output"
}

opencode_register_default_model() {
    local provider_id="$1"
    local default_model_id="$2"

    opencode_remove_config "model"
    [ -n "$provider_id" ] && [ -n "$default_model_id" ] && opencode_set_config "model" "\"${provider_id}/${default_model_id}\""
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
    opencode_launcher_manage "create"
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
    local model="${1}"
    local model_list

    if ! cpa_is_configured; then
        echo "ERROR: Failed to generate and register CLIProxyAPI API key for Opencode : CLIProxyAPI is not configured."
        return 1
    fi

    # needs cpa conf file exists
    echo "generate a CLIProxyAPI API key for Opencode to connect to CPA backend"
    opencode_generate_cpa_key
    if [ $? -ne 0 ]; then
        echo "ERROR: Failed to generate and register CLIProxyAPI API key for Opencode."
        return 1
    fi

    opencode_register_provider "aistack-cpa" "AIStack CLIProxyAPI" "@ai-sdk/openai-compatible" "$(cpa_settings_get_api_endpoint)" "$AISTACK_CLIPROXYAPI_KEY_FOR_OPENCODE" ""

    local default_model
    if [ -n "${model}" ]; then
        opencode_register_model "aistack-cpa" "${model}" "${model}" "AIStack cpa-${model}"
        default_model="${model}"
    else
        if ! cpa_instance_reachable; then
            echo "ERROR: Failed to generate and register CPA API key for Opencode : CLIProxyAPI instance is not reachable. Please make sure CLIProxyAPI is running and properly configured."
            return 1
        fi
        # cpa_get_model_list needs cpa to be running
        model_list="$(cpa_get_model_list)"
        for m in $model_list; do
            # the first model available will be the default model
            [ -z "${default_model}" ] && default_model="${m}"
            opencode_register_model "aistack-cpa" "${m}" "${m}" "AIStack cpa-${m}"
        done
    fi

    [ -n "$default_model" ] && opencode_register_default_model "aistack-cpa" "$default_model"

}
