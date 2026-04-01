codex_path() {
    # codex specific paths
    export AISTACK_CODEX_CONFIG_HOME="${HOME}/.codex"
    export AISTACK_CODEX_CONFIG_FILE="${AISTACK_CODEX_CONFIG_HOME}/config.toml"

    # aistack path for codex
    export AISTACK_CODEX_LAUNCHER_HOME="${AISTACK_LAUNCHER_HOME}/codex"
    mkdir -p "${AISTACK_CODEX_LAUNCHER_HOME}"
}

codex_path_register_for_shell() {
    local shell_name="$1"
    path_register_for_shell "codex" "$shell_name" "${AISTACK_CODEX_LAUNCHER_HOME}"
}

codex_path_unregister_for_shell() {
    local shell_name="$1"
    path_unregister_for_shell "codex" "$shell_name"
}

codex_path_register_for_vs_terminal() {
    vscode_path_register_for_vs_terminal "codex" "${AISTACK_CODEX_LAUNCHER_HOME}"
}

codex_path_unregister_for_vs_terminal() {
    vscode_path_unregister_for_vs_terminal "codex" "${AISTACK_CODEX_LAUNCHER_HOME}"
}

codex_install() {
    local version="$1"
    [ -z "${version}" ] && version="@latest"

    echo "Installing Codex CLI ${version}"
    PATH="${AISTACK_NODEJS_BIN_PATH}:${STELLA_ORIGINAL_SYSTEM_PATH}" npm install --verbose -g @openai/codex${version}
}

codex_uninstall() {
    PATH="${AISTACK_NODEJS_BIN_PATH}:${STELLA_ORIGINAL_SYSTEM_PATH}" npm uninstall -g @openai/codex
}

codex_launch_export_variables="AISTACK_RUNTIME_PATH_FILE AISTACK_NODEJS_BIN_PATH"
codex_launch() {
    set -- "$@"

    (
        . "${AISTACK_RUNTIME_PATH_FILE}"

        if [ "$#" -gt 0 ]; then
            "${AISTACK_NODEJS_BIN_PATH}/codex" "$@"
        else
            "${AISTACK_NODEJS_BIN_PATH}/codex"
        fi
    )
}

codex_launcher_manage() {
    local action="${1:-create}"

    case $action in
        create)
            {
                echo '#!/bin/sh'
                for v in $codex_launch_export_variables; do
                    printf '%s=%s\n' "$v" "$(shell_quote_posix "${!v}")"
                done

                declare -f codex_launch

                echo codex_launch \"\$@\"
            } > "${AISTACK_CODEX_LAUNCHER_HOME}/codex"

            chmod +x "${AISTACK_CODEX_LAUNCHER_HOME}/codex"
            ;;
        delete)
            rm -f "${AISTACK_CODEX_LAUNCHER_HOME}/codex"
            ;;
    esac
}

codex_settings_configure() {
    mkdir -p "${AISTACK_CODEX_CONFIG_HOME}"

    local start_marker="# >>> aistack-codex-settings >>>"
    local end_marker="# <<< aistack-codex-settings <<<"
    local template="${AISTACK_POOL}/settings/codex/config.toml"
    local tmp_file="$(mktemp)"

    [ -f "${AISTACK_CODEX_CONFIG_FILE}" ] || touch "${AISTACK_CODEX_CONFIG_FILE}"

    awk -v start="$start_marker" -v end="$end_marker" '
        $0 == start {in_block=1; next}
        $0 == end {in_block=0; next}
        !in_block {print}
    ' "${AISTACK_CODEX_CONFIG_FILE}" > "$tmp_file"

    cat "$tmp_file" > "${AISTACK_CODEX_CONFIG_FILE}"
    rm -f "$tmp_file"

    {
        printf "\n%s\n" "$start_marker"
        cat "$template"
        printf "\n%s\n" "$end_marker"
    } >> "${AISTACK_CODEX_CONFIG_FILE}"
}

codex_settings_remove() {
    rm -Rf "$AISTACK_CODEX_CONFIG_HOME"
}
