cpa_init() {
	# cli proxy api specific variables
	export AISTACK_CLIPROXYAPI_CONFIG_HOME="${HOME}/.cli-proxy-api"
	mkdir -p "${AISTACK_CLIPROXYAPI_CONFIG_HOME}"
	export AISTACK_CLIPROXYAPI_CONFIG_FILE="${AISTACK_CLIPROXYAPI_CONFIG_HOME}/config.yaml"
	export AISTACK_CLIPROXYAPI_MANAGEMENT_API_KEY_FILE="${AISTACK_CLIPROXYAPI_CONFIG_HOME}/management-api-key"
	export CLIPROXYAPI_FEAT_INSTALL_ROOT="${AISTACK_ISOLATED_ROOT}/cli-proxy-api"
	mkdir -p "${CLIPROXYAPI_FEAT_INSTALL_ROOT}"

	# cli proxy api launcher
	export AISTACK_CLIPROXYAPI_LAUNCHER_HOME="${AISTACK_LAUNCHER_HOME}/cli-proxy-api"
	mkdir -p "${AISTACK_CLIPROXYAPI_LAUNCHER_HOME}"
	export AISTACK_CLIPROXYAPI_LAUNCHER_FILE="${AISTACK_CLIPROXYAPI_LAUNCHER_HOME}/cli-proxy-api"

	# cli proxy api context
	export AISTACK_CLIPROXYAPI_CONTEXT_HOME="${AISTACK_CONTEXT_HOME}/cli-proxy-api"
	mkdir -p "${AISTACK_CLIPROXYAPI_CONTEXT_HOME}"
	export AISTACK_CLIPROXYAPI_CONTEXT_FILE="${AISTACK_CLIPROXYAPI_CONTEXT_HOME}/cli_proxy_api_context.sh"
	# any variables needed to run this component or used by _launch function
	# NOTE: do not need to declare those variables:
	#		AISTACK_*_CONTEXT_FILE and AISTACK_GENERIC_CONTEXT_FILE are already exported
	#		every *_SEARCH_PATH variable related to a REQUIRED_RUNTIME or REQUIRED_MODULE are already exported
	export AISTACK_CLIPROXYAPI_CONTEXT_EXPORT_VARIABLES="AISTACK_CLIPROXYAPI_CONFIG_FILE CLIPROXYAPI_FEAT_INSTALL_ROOT"

	# cli proxy api requirement - those will be installed and presence checked to run the current component
	# NOTE:	those search path will be injected in context file
	export AISTACK_CLIPROXYAPI_RUNTIME_REQUIRED=""
	export AISTACK_CLIPROXYAPI_MODULE_REQUIRED=""
	# remove from context any runtime or module any item already in generic aistack context
	export AISTACK_CLIPROXYAPI_RUNTIME_REQUIRED_IN_CONTEXT="$($STELLA_API filter_list_with_list "${AISTACK_CLIPROXYAPI_RUNTIME_REQUIRED}" "${AISTACK_GENERIC_CONTEXT_ADD_RUNTIME}")"
	export AISTACK_CLIPROXYAPI_MODULE_REQUIRED_IN_CONTEXT="$($STELLA_API filter_list_with_list "${AISTACK_CLIPROXYAPI_MODULE_REQUIRED}" "${AISTACK_GENERIC_CONTEXT_ADD_MODULE}")"

}

# test if cli proxy api is installed
# return 0 : is installed
# return 1 : tool is not installed
# return 2 : missing runtime
cpa_is_installed() {
	local r m
	export AISTACK_CLIPROXYAPI_TOOL_AVAILABLE="false"
	export AISTACK_CLIPROXYAPI_TOOL_PATH=""
	for r in ${AISTACK_CLIPROXYAPI_RUNTIME_REQUIRED}; do aistack_runtime_is_detected "${r}" || return 2; done
	for m in ${AISTACK_CLIPROXYAPI_MODULE_REQUIRED}; do aistack_module_is_detected "${m}" || return 2; done
	[ -x "${CLIPROXYAPI_FEAT_INSTALL_ROOT}/cli-proxy-api" ] || return 1
	export AISTACK_CLIPROXYAPI_TOOL_AVAILABLE="true"
	export AISTACK_CLIPROXYAPI_TOOL_PATH="${CLIPROXYAPI_FEAT_INSTALL_ROOT}/cli-proxy-api"
	return 0
}



# Download and install cliproxyapi from GitHub releases.
# @param {string} $1 - Optional version to install (e.g., "v0.1.0").
#                      If not provided, the latest version will be fetched.
cpa_install() {
	local r m
	local version="$1"

	if [ -z "${version}" ] || [ "${version}" = "latest" ]; then
		echo "No version provided, fetching the latest version..."
		version="$(github_get_latest_release "router-for-me/CLIProxyAPI")" || return $?
		[ -n "${version}" ] || { echo "ERROR: Failed to retrieve latest CLIProxyAPI version"; return 1; }
		echo "latest version is ${version}"
	fi

	for r in ${AISTACK_CLIPROXYAPI_RUNTIME_REQUIRED}; do
		echo "INFO: CLIProxyAPI require ${r} managed runtime"
		aistack_runtime_require "${r}"
	done

	for m in ${AISTACK_CLIPROXYAPI_MODULE_REQUIRED}; do
		echo "INFO: CLIProxyAPI require ${m} managed module"
		aistack_module_require "${m}"
	done

	local os_arch
	case "${STELLA_CURRENT_PLATFORM}" in
		linux)
			[ "${STELLA_CURRENT_CPU_FAMILY}" = "intel" ] && os_arch="linux_amd64"
			[ "${STELLA_CURRENT_CPU_FAMILY}" = "arm" ] && os_arch="linux_arm64"
			;;
		darwin)
			[ "${STELLA_CURRENT_CPU_FAMILY}" = "intel" ] && os_arch="darwin_amd64"
			[ "${STELLA_CURRENT_CPU_FAMILY}" = "arm" ] && os_arch="darwin_arm64"
			;;
	esac
	[ -n "${os_arch}" ] || { echo "ERROR: Unsupported platform or CPU family: ${STELLA_CURRENT_PLATFORM}/${STELLA_CURRENT_CPU_FAMILY}"; return 1; }

	local filename="CLIProxyAPI_${version#v}_${os_arch}.tar.gz"
	local download_url="https://github.com/router-for-me/CLIProxyAPI/releases/download/${version}/${filename}"

	echo "Downloading and installing CLIProxyAPI ${version} from ${download_url} to ${CLIPROXYAPI_FEAT_INSTALL_ROOT}..."
	# DEST_ERASE allow to uninstall before install
	"${STELLA_API}" get_resource "CLIProxyAPI" "${download_url}" "HTTP_ZIP" "${CLIPROXYAPI_FEAT_INSTALL_ROOT}" "DEST_ERASE" || return $?
	echo "CLIProxyAPI installed successfully."

	cpa_is_installed
	return $?
}
 
cpa_uninstall() {
	if cpa_is_installed; then
		echo "Uninstalling CLIProxyAPI from ${CLIPROXYAPI_FEAT_INSTALL_ROOT}..."

		cpa_daemon_down >/dev/null 2>&1 || :

		rm -Rf "${CLIPROXYAPI_FEAT_INSTALL_ROOT}" || return $?
		echo "CLIProxyAPI uninstalled successfully."

		cpa_is_installed && return 1
		return 0
	else
		echo "WARN : not installed or missing a required managed runtime ${AISTACK_CLIPROXYAPI_RUNTIME_REQUIRED}"
	fi
}

cpa_launch() {
	(
		[ -f "${AISTACK_GENERIC_CONTEXT_FILE}" ] && . "${AISTACK_GENERIC_CONTEXT_FILE}"
		[ -f "${AISTACK_CLIPROXYAPI_CONTEXT_FILE}" ] && . "${AISTACK_CLIPROXYAPI_CONTEXT_FILE}"

		if [ -f "${AISTACK_CLIPROXYAPI_CONFIG_FILE}" ]; then
			set -- --config "${AISTACK_CLIPROXYAPI_CONFIG_FILE}" "$@"
		fi

		if [ "$#" -gt 0 ]; then
			"${CLIPROXYAPI_FEAT_INSTALL_ROOT}/cli-proxy-api" "$@"
		else
			"${CLIPROXYAPI_FEAT_INSTALL_ROOT}/cli-proxy-api"
		fi
	)
}

cpa_daemon_up() {
	local daemon_name="cpa"
	local log_file="${AISTACK_CLIPROXYAPI_CONFIG_HOME}/cli-proxy-api.log"

	# if ! cpa_is_installed; then
	# 	echo "ERROR: CLIProxyAPI is not installed"
	# 	return 1
	# fi
    #cpa_daemon_down

    if [ -f "${AISTACK_CLIPROXYAPI_CONFIG_FILE}" ]; then
        set -- --config "${AISTACK_CLIPROXYAPI_CONFIG_FILE}" "$@"
    fi

	if [ "$#" -gt 0 ]; then
		STELLA_LOG_STATE="ON" "${STELLA_API}" daemon_start \
			"${daemon_name}" \
			"${AISTACK_CLIPROXYAPI_TOOL_PATH}" \
			"${log_file}" \
			"$@"
	else
		STELLA_LOG_STATE="ON" "${STELLA_API}" daemon_start \
			"${daemon_name}" \
			"${AISTACK_CLIPROXYAPI_TOOL_PATH}" \
			"${log_file}"
	fi

}

cpa_daemon_down() {
    STELLA_LOG_STATE="ON" "${STELLA_API}" daemon_stop "cpa"
}

cpa_daemon_status() {
	STELLA_LOG_STATE="ON" "${STELLA_API}" daemon_status "cpa"
}

cpa_daemon_logs() {
    STELLA_LOG_STATE="ON" "${STELLA_API}" daemon_logs "cpa"
}

# TODO restart with save and reuse parameters from up command
# cpa_daemon_restart() {
# 	cpa_daemon_down || :
# 	cpa_daemon_up "$@"
# }

cpa_launcher_and_context_files_manage() {
	local action="${1:-create}"

	case ${action} in
		create)
			if cpa_is_installed; then
				# GENERATE CONTEXT FILE ----
				cpa_context_file_generate

				# GENERATE LAUNCHER FILE ----
				{
					echo '#!/bin/sh'

					printf 'export %s=%s\n' "AISTACK_GENERIC_CONTEXT_FILE" "$(shell_quote_posix "${AISTACK_GENERIC_CONTEXT_FILE}")"
					printf 'export %s=%s\n' "AISTACK_CLIPROXYAPI_CONTEXT_FILE" "$(shell_quote_posix "${AISTACK_CLIPROXYAPI_CONTEXT_FILE}")"

					declare -f cpa_launch

					echo cpa_launch \"\$@\"
				} > "${AISTACK_CLIPROXYAPI_LAUNCHER_FILE}"

				chmod +x "${AISTACK_CLIPROXYAPI_LAUNCHER_FILE}"
			fi
			;;

		delete)
			rm -Rf "${AISTACK_CLIPROXYAPI_LAUNCHER_HOME}"
			mkdir -p "${AISTACK_CLIPROXYAPI_LAUNCHER_HOME}"
			cpa_context_file_generate_remove
			;;

		refresh_if_exists)
			[ -f "${AISTACK_CLIPROXYAPI_LAUNCHER_FILE}" ] && ( cpa_launcher_and_context_files_manage "delete"; cpa_launcher_and_context_files_manage "create" )
			;;
	esac
}

cpa_context_file_generate() {
	# GENERATE CONTEXT FILE ----
	echo '#!/bin/sh' > "${AISTACK_CLIPROXYAPI_CONTEXT_FILE}"
	chmod +x "${AISTACK_CLIPROXYAPI_CONTEXT_FILE}"

	# VARIABLES
	aistack_context_file_export_variables "${AISTACK_CLIPROXYAPI_CONTEXT_FILE}" "${AISTACK_CLIPROXYAPI_CONTEXT_EXPORT_VARIABLES}"

	# PATH
	local m r list_path
	for r in ${AISTACK_CLIPROXYAPI_RUNTIME_REQUIRED_IN_CONTEXT}; do list_path="$(aistack_context_path_add_component "runtime" "${r}" "VARIABLE_LIST") ${list_path}"; done
	for m in ${AISTACK_CLIPROXYAPI_MODULE_REQUIRED_IN_CONTEXT}; do list_path="$(aistack_context_path_add_component "module" "${m}" "VARIABLE_LIST") ${list_path}"; done
	aistack_context_file_export_path "${AISTACK_CLIPROXYAPI_CONTEXT_FILE}" "${list_path}" "VARIABLE_LIST"
}

cpa_context_file_generate_remove() {
	rm -f "${AISTACK_CLIPROXYAPI_CONTEXT_FILE}"
}


cpa_info() {
    if [ -f "${AISTACK_CLIPROXYAPI_CONFIG_FILE}" ]; then
        echo "CLIProxyAPI configuration file : $AISTACK_CLIPROXYAPI_CONFIG_FILE"

        local address="$(cpa_settings_get_address)"

        echo "Management UI : ${address}/management.html"
        echo "Management key : $(cpa_settings_management_api_key_get)"

        echo "CLIProxyAPI API endpoint : $(cpa_settings_get_api_endpoint)" 
        echo "CLIProxyAPI API keys list :" 
        cpa_settings_api_key_list
    else
        echo "No CLIProxyAPI configuration file found. ($AISTACK_CLIPROXYAPI_CONFIG_FILE)"
    fi
	echo
	echo "CLIProxyAPI available : ${AISTACK_CLIPROXYAPI_TOOL_AVAILABLE}"
	echo "CLIProxyAPI path : ${AISTACK_CLIPROXYAPI_TOOL_PATH}"
	echo "CLIProxyAPI needed managed runtime : ${AISTACK_CLIPROXYAPI_RUNTIME_REQUIRED}"
	echo "CLIProxyAPI needed managed module : ${AISTACK_CLIPROXYAPI_MODULE_REQUIRED}"
	echo "CLIProxyAPI install root : ${CLIPROXYAPI_FEAT_INSTALL_ROOT}"
	echo "CLIProxyAPI launcher : ${AISTACK_CLIPROXYAPI_LAUNCHER_FILE}"
	echo "CLIProxyAPI context file : ${AISTACK_CLIPROXYAPI_CONTEXT_FILE}"
	echo
}

cpa_show_config() {
	if [ -f "$AISTACK_CLIPROXYAPI_CONFIG_FILE" ]; then
		cat "$AISTACK_CLIPROXYAPI_CONFIG_FILE"
	else
		echo "No CLIProxyAPI configuration file found. ($AISTACK_CLIPROXYAPI_CONFIG_FILE)"
	fi
}

cpa_settings_configure() {

   [ ! -f "${AISTACK_CLIPROXYAPI_CONFIG_FILE}" ] && cp -f "$CLIPROXYAPI_FEAT_INSTALL_ROOT/config.example.yaml" "$AISTACK_CLIPROXYAPI_CONFIG_FILE"

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
    rm -Rf "${AISTACK_CLIPROXYAPI_CONFIG_HOME}"
}






# login management -----------------

# antigravity oauth 
#  cpa_login_agy_oauth [--project_id <your_project_id>]
cpa_login_agy_oauth() {
    echo "Login to Antigravity OAuth"
    echo "The local OAuth callback uses port 8085"
    cpa_launch --antigravity-login --no-browser "$@"
}

# codex oauth
cpa_login_codex_oauth() {
    echo "Login to Codex OAuth"
    echo "The local OAuth callback uses port 1455"
    cpa_launch --codex-login --no-browser "$@"
}

# kimi oauth
cpa_login_kimi_oauth() {
    echo "Login to Kimi OAuth"
    cpa_launch --kimi-login --no-browser "$@"
}

# claude oauth
cpa_login_claude_oauth() {
    echo "Login to Claude OAuth"
    cpa_launch --claude-login --no-browser "$@"
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

# cpa must have been installed before
cpa_settings_api_key_create() {
    local key="$($STELLA_API generate_password 48 "[:alnum:]")"
    cpa_settings_api_key_add "$key"
    echo "New API key created: $key"
}

# cpa must have been installed before, for the config file exists
cpa_settings_api_key_add() {
    local key="$1"

    if ! cpa_is_configured; then
        echo "ERROR: file $AISTACK_CLIPROXYAPI_CONFIG_FILE not found"
        return 1
    fi

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

    if [ -z "$key" ]; then
        return 1
    fi

    if ! cpa_is_configured; then
        return 1
    fi

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
    
    if ! cpa_instance_reachable; then
        return 1
    fi

    curl -skL -X GET http://localhost:8317/v1/models \
        -H "Authorization: Bearer $(cpa_settings_api_key_get 0)" \
        -H "Content-Type: application/json" | jq -r '.data[]?.id // empty' | sort

}

cpa_is_configured() {
    [ -f "$AISTACK_CLIPROXYAPI_CONFIG_FILE" ]
}

cpa_instance_reachable() {
    local address
    local http_code
    local curl_rc

    address="$(cpa_settings_get_address)"

    http_code="$(
        curl -skL \
            -X GET "${address}" \
            -H "Content-Type: application/json" \
            -o /dev/null \
            -w "%{http_code}" \
            2>/dev/null
    )"
    curl_rc=$?

    # curl execution error (DNS, timeout, connection refused, TLS failure, etc.)
    if [ "$curl_rc" -ne 0 ]; then
        echo "ERROR: unable to reach server: ${address}" >&2
        return 1
    fi

    # HTTP response is not 200
    if [ "$http_code" != "200" ]; then
        echo "ERROR: server returned HTTP ${http_code} for ${address}" >&2
        return 1
    fi

    return 0
}
