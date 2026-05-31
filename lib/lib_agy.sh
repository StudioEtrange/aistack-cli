agy_init() {

	# Antigravity CLI specific paths
	export AISTACK_ANTIGRAVITY_CONFIG_HOME="${HOME}/.gemini/antigravity-cli"
    export AISTACK_ANTIGRAVITY_CONFIG_FILE="${AISTACK_ANTIGRAVITY_CONFIG_HOME}/settings.json"


	# aistack path for Antigravity CLI
	export AISTACK_ANTIGRAVITY_LAUNCHER_HOME="${AISTACK_LAUNCHER_HOME}/antigravity"
	mkdir -p "${AISTACK_ANTIGRAVITY_LAUNCHER_HOME}"

	export AGY_FEAT_INSTALL_ROOT="$AISTACK_ISOLATED_DEPENDENCIES_ROOT/antigravity"
	mkdir -p "${AGY_FEAT_INSTALL_ROOT}"
}

agy_is_installed() {
	export AISTACK_ANTIGRAVITY_TOOL_AVAILABLE="false"
	[ -x "$AGY_FEAT_INSTALL_ROOT/agy" ] || return 1
	export AISTACK_ANTIGRAVITY_TOOL_AVAILABLE="true"
	export AISTACK_ANTIGRAVITY_TOOL_PATH="$AGY_FEAT_INSTALL_ROOT/agy"
	return 0
}

agy_get_platform() {
	local os_arch=""
	local platform=""

	case "$STELLA_CURRENT_PLATFORM" in
		linux)
			[ "$STELLA_CURRENT_CPU_FAMILY" = "intel" ] && os_arch="linux_amd64"
            [ "$STELLA_CURRENT_CPU_FAMILY" = "arm" ] && os_arch="linux_arm64"
			platform="${os_arch}"
			if [ -f /lib/libc.musl-x86_64.so.1 ] || [ -f /lib/libc.musl-aarch64.so.1 ] || ldd /bin/ls 2>&1 | grep -q musl; then
				platform="${platform}_musl"
			fi
			;;
		darwin)
            [ "$STELLA_CURRENT_CPU_FAMILY" = "intel" ] && os_arch="darwin_amd64"
            [ "$STELLA_CURRENT_CPU_FAMILY" = "arm" ] && os_arch="darwin_arm64"
			platform="${os_arch}"
			;;
		*)
			echo "ERROR: Unsupported architecture: $STELLA_CURRENT_CPU_FAMILY" >&2
			return 1
			;;
	esac

	printf '%s' "$platform"
}

# Download and install antigravity-cli from the official Antigravity CLI manifests.
# @param {string} $1 - Optional version to install. If not provided, latest is used.
#
# This function relies on the following environment variables to be set:
# - AGY_FEAT_INSTALL_ROOT: The directory where antigravity-cli will be installed.
agy_install() {
	local version="$1"
	local download_base_url="https://antigravity-cli-auto-updater-974169037036.us-central1.run.app"
	local platform=""
	local manifest_url=""
	local manifest_json=""
	local manifest_version=""
	local download_url=""
	local sha512=""
	local downloader=""
	local staging_dir=""
	local staging_payload=""
	local extracted_binary=""
	local actual_hash=""

	platform="$(agy_get_platform)" || return 1
	manifest_url="${download_base_url}/manifests/${platform}.json"

	if command -v curl >/dev/null 2>&1; then
		downloader="curl"
	elif command -v wget >/dev/null 2>&1; then
		downloader="wget"
	else
		echo "ERROR: Either curl or wget is required to install Antigravity CLI."
		return 1
	fi

	echo "Querying Antigravity CLI release manifest for ${platform}..."
	if [ "$downloader" = "curl" ]; then
		manifest_json="$(curl -fsSL "$manifest_url")" || return 1
	else
		manifest_json="$(wget -q -O - "$manifest_url")" || return 1
	fi

	manifest_version="$(printf '%s' "$manifest_json" | jq -r '.version // empty')"
	download_url="$(printf '%s' "$manifest_json" | jq -r '.url // empty')"
	sha512="$(printf '%s' "$manifest_json" | jq -r '.sha512 // empty')"

	if [ -z "$manifest_version" ] || [ -z "$download_url" ] || [ -z "$sha512" ]; then
		echo "ERROR: Failed to parse Antigravity CLI release manifest."
		return 1
	fi

	if [ -n "$version" ] && [ "$version" != "latest" ] && [ "$version" != "$manifest_version" ]; then
		echo "ERROR: Antigravity CLI manifest only exposes latest version ${manifest_version}; requested ${version}."
		return 1
	fi

	staging_dir="${AGY_FEAT_INSTALL_ROOT}/staging"
	rm -Rf "$staging_dir"
	mkdir -p "$staging_dir" "$AGY_FEAT_INSTALL_ROOT" || return 1

	case "$download_url" in
		*.tar.gz*)
			staging_payload="$staging_dir/agy.tar.gz"
			extracted_binary="$staging_dir/antigravity"
			;;
		*)
			staging_payload="$staging_dir/agy"
			extracted_binary="$staging_payload"
			;;
	esac

	echo "Downloading Antigravity CLI ${manifest_version} from ${download_url}..."
	if [ "$downloader" = "curl" ]; then
		curl -fsSL -o "$staging_payload" "$download_url" || return 1
	else
		wget -q -O "$staging_payload" "$download_url" || return 1
	fi

	case "$download_url" in
		*.tar.gz*)
			tar -xzf "$staging_payload" -C "$staging_dir" antigravity || return 1
			;;
	esac

	cp "$extracted_binary" "$AGY_FEAT_INSTALL_ROOT/agy" || return 1
	chmod +x "$AGY_FEAT_INSTALL_ROOT/agy"

	# if [ "$STELLA_CURRENT_PLATFORM" = "darwin" ]; then
	# 	xattr -d com.apple.quarantine "$AGY_FEAT_INSTALL_ROOT/agy" 2>/dev/null || true
	# fi

	rm -Rf "$staging_dir"
	echo "Antigravity CLI installed successfully."

	agy_is_installed
}

agy_uninstall() {
	echo "Uninstalling Antigravity CLI from ${AGY_FEAT_INSTALL_ROOT}..."
	rm -Rf "${AGY_FEAT_INSTALL_ROOT}"
	echo "Antigravity CLI uninstalled successfully."

	agy_is_installed
}

agy_path_register_for_shell() {
	local shell_name="$1"
	if agy_is_installed; then
		path_register_for_shell "antigravity" "${AISTACK_ANTIGRAVITY_LAUNCHER_HOME}" "$shell_name"
	fi
}

agy_path_unregister_for_shell() {
	local shell_name="${1:-all}"
	path_unregister_for_shell "antigravity" "$shell_name"
}

agy_path_register_for_vs_terminal() {
	if agy_is_installed; then
		vscode_path_register_for_vs_terminal "antigravity" "${AISTACK_ANTIGRAVITY_LAUNCHER_HOME}"
	fi
}

agy_path_unregister_for_vs_terminal() {
	vscode_path_unregister_for_vs_terminal "antigravity" "${AISTACK_ANTIGRAVITY_LAUNCHER_HOME}"
}

agy_launch_export_variables="AISTACK_RUNTIME_BOOTSTRAP_FILE AGY_FEAT_INSTALL_ROOT"
agy_launch() {
	(
		# antigravity does not need any runtime to be run
		# but we give runtime to it can run some code
        . "${AISTACK_RUNTIME_BOOTSTRAP_FILE}"

		if [ "$#" -gt 0 ]; then
			"$AGY_FEAT_INSTALL_ROOT/agy" "$@"
		else
			"$AGY_FEAT_INSTALL_ROOT/agy"
		fi
	)
}

agy_launcher_manage() {
	local action="${1:-create}"

	case $action in
		create)
			if agy_is_installed; then
				# create a compatible POSIX shell script to be called from bash, zsh, fish and so on
				# and executed by the default /bin/sh on the current system
				{
					echo '#!/bin/sh'
					for v in $agy_launch_export_variables; do
						printf 'export %s=%s\n' "$v" "$(shell_quote_posix "${!v}")"
					done

					declare -f agy_launch

					echo agy_launch \"\$@\"
				} > "${AISTACK_ANTIGRAVITY_LAUNCHER_HOME}/agy"

				chmod +x "${AISTACK_ANTIGRAVITY_LAUNCHER_HOME}/agy"
			fi
			;;

		delete)
			rm -f "${AISTACK_ANTIGRAVITY_LAUNCHER_HOME}/agy"
			;;

		refresh_if_exists)
			[ -f "${AISTACK_ANTIGRAVITY_LAUNCHER_HOME}/agy" ] && ( agy_launcher_manage "delete"; agy_launcher_manage "create" )
			;;
	esac
}

agy_info() {
	echo "Configuration file : $AISTACK_ANTIGRAVITY_CONFIG_FILE"
	echo
	echo "Antigravity CLI available : $AISTACK_ANTIGRAVITY_TOOL_AVAILABLE"
	echo "Antigravity CLI path : $AISTACK_ANTIGRAVITY_TOOL_PATH"
	echo "Antigravity CLI install root : $AGY_FEAT_INSTALL_ROOT"
	echo "Antigravity CLI launcher home : $AISTACK_ANTIGRAVITY_LAUNCHER_HOME"
}



agy_show_config() {
    if [ -f "$AISTACK_ANTIGRAVITY_CONFIG_FILE" ]; then
        echo "Current configuration file : $AISTACK_ANTIGRAVITY_CONFIG_FILE"
        cat "$AISTACK_ANTIGRAVITY_CONFIG_FILE"
    else
        echo "No configuration file found. ($AISTACK_ANTIGRAVITY_CONFIG_FILE)"
    fi
}

# generic config management -----------------
agy_settings_configure() {
	echo "add some default settings :"
    echo " - disable statistics usage data send"
    cat "${AISTACK_POOL}/settings/antigravity-cli/settings.json"
    printf "\n"
    merge_json_file "${AISTACK_POOL}/settings/antigravity-cli/settings.json" "${AISTACK_ANTIGRAVITY_CONFIG_FILE}"
}

agy_settings_remove() {
	rm -Rf "$AISTACK_ANTIGRAVITY_CONFIG_HOME"
}


agy_merge_config() {
    local file_to_merge="$1"
    merge_json_file "$file_to_merge" "$AISTACK_ANTIGRAVITY_CONFIG_FILE"
}

agy_remove_config() {
    local key_path="$1"
    json_del_key_from_file "$AISTACK_ANTIGRAVITY_CONFIG_FILE" "$key_path"
}

agy_set_config() {
    local key_path="$1"
    local value="$2"
    json_set_key_into_file "$AISTACK_ANTIGRAVITY_CONFIG_FILE" "$key_path" "$value"
}
