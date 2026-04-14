

aistack_path() {
    export AISTACK_POOL="${STELLA_APP_ROOT}/pool"
    
    export AISTACK_LAUNCHER_HOME="${STELLA_APP_WORK_ROOT}/launcher"
    mkdir -p "${AISTACK_LAUNCHER_HOME}"

    export AISTACK_MCP_LAUNCHER_HOME="${AISTACK_LAUNCHER_HOME}/mcp"
    mkdir -p "${AISTACK_MCP_LAUNCHER_HOME}"

    export AISTACK_ISOLATED_DEPENDENCIES_ROOT="${STELLA_APP_WORK_ROOT}/isolated_dependencies"
    mkdir -p "${AISTACK_ISOLATED_DEPENDENCIES_ROOT}"

    export AISTACK_RUNTIME_PATH_FILE="${STELLA_APP_WORK_ROOT}/path/runtime_path.sh"
    mkdir -p "${STELLA_APP_WORK_ROOT}/path"

    node_path
    gemini_path
    opencode_path
    # FORCE_VSCODE_MODE could be "remote" : means using vscode remote extension
    # FORCE_VSCODE_MODE could be empty "" : try to guess
    vscode_path "$FORCE_VSCODE_MODE"
    cpa_path
    orla_path
    bmad_path
}


runtime_path() {
    
    runtime_analysis_all

    # TODO : do we set launcher in PATH ?
    # add launchers to current path
    # WARN : in AISTACK_RUNTIME_PATH_FILE launchers are after runtime path in resolution order
    # export PATH="${AISTACK_GEMINI_LAUNCHER_HOME}:${PATH}"
    # export PATH="${AISTACK_OPENCODE_LAUNCHER_HOME}:${PATH}"
    # export PATH="${AISTACK_ORLA_LAUNCHER_HOME}:${PATH}"
    # export PATH="${AISTACK_CLIPROXYAPI_LAUNCHER_HOME}:${PATH}"

    if [ "$AISTACK_INTERNAL_NODEJS_RUNTIME_AVAILABLE" = "true" ]; then
        # bin folder which contains node
        export AISTACK_NODEJS_BIN_PATH="$(dirname $AISTACK_INTERNAL_NODEJS_RUNTIME_PATH)/"
    else
        # we use an already installed nodejs, not aistack nodejs
        export AISTACK_NODEJS_BIN_PATH=""
    fi
    
    # used by MCP local server
    if [ "$AISTACK_INTERNAL_NODEJS_RUNTIME_AVAILABLE" = "true" ]; then
        # bin folder which contains python
        export AISTACK_PYTHON_BIN_PATH="$(dirname $AISTACK_INTERNAL_PYTHON_RUNTIME_PATH)/"
    else
        # we use an already installed python, not aistack python
        export AISTACK_PYTHON_BIN_PATH=""
    fi

    runtime_path_file_generate

}


aistack_info() {

    echo "AISTACK_POOL: $AISTACK_POOL"
    echo "AISTACK_LAUNCHER_HOME: $AISTACK_LAUNCHER_HOME"
    echo "AISTACK_MCP_LAUNCHER_HOME: $AISTACK_MCP_LAUNCHER_HOME"
    echo "AISTACK_ISOLATED_DEPENDENCIES_ROOT: $AISTACK_ISOLATED_DEPENDENCIES_ROOT"
    echo "AISTACK_RUNTIME_PATH_FILE: $AISTACK_RUNTIME_PATH_FILE"
    echo
    echo "--nodejs--"
    echo "AISTACK_INTERNAL_NVM_AVAILABLE : $AISTACK_INTERNAL_NVM_AVAILABLE"

    echo "AISTACK_INTERNAL_NODEJS_RUNTIME_AVAILABLE : $AISTACK_INTERNAL_NODEJS_RUNTIME_AVAILABLE"
    if [ "$AISTACK_INTERNAL_NODEJS_RUNTIME_AVAILABLE" = "true" ]; then
        echo "AISTACK_NODEJS_BIN_PATH : $AISTACK_NODEJS_BIN_PATH"
        echo "AISTACK_INTERNAL_NODEJS_RUNTIME_PATH : $AISTACK_INTERNAL_NODEJS_RUNTIME_PATH"
    fi

    echo "--python--"
    echo "AISTACK_INTERNAL_PYTHON_RUNTIME_AVAILABLE : $AISTACK_INTERNAL_PYTHON_RUNTIME_AVAILABLE"
    if [ "$AISTACK_INTERNAL_PYTHON_RUNTIME_AVAILABLE" = "true" ]; then
        echo "AISTACK_PYTHON_BIN_PATH : $AISTACK_PYTHON_BIN_PATH"
        echo "AISTACK_INTERNAL_PYTHON_RUNTIME_PATH : $AISTACK_INTERNAL_PYTHON_RUNTIME_PATH"
    fi
    echo "AISTACK_INTERNAL_MAMBA_AVAILABLE : $AISTACK_INTERNAL_MAMBA_AVAILABLE"
    echo
    echo "--dependencies--"
    for f in $STELLA_APP_FEATURE_LIST; do
        echo "  - $f"
    done
    echo
    echo "PATH : $PATH"
}

# create files to add runtime dependencies needed for any tool to run
runtime_path_file_generate() {
    echo '#!/bin/sh' > "${AISTACK_RUNTIME_PATH_FILE}"
    # kodejs bin tools
    [ -n "$AISTACK_NODEJS_BIN_PATH" ] && echo "export PATH=\"${AISTACK_NODEJS_BIN_PATH}:\${PATH}\"" >> "${AISTACK_RUNTIME_PATH_FILE}"
    # python bin tools
    [ -n "$AISTACK_PYTHON_BIN_PATH" ] && echo "export PATH=\"${AISTACK_PYTHON_BIN_PATH}:\${PATH}\"" >> "${AISTACK_RUNTIME_PATH_FILE}"
    
    chmod +x "${AISTACK_RUNTIME_PATH_FILE}"
}

runtime_path_file_remove() {
    rm -f "${AISTACK_RUNTIME_PATH_FILE}"
}


runtime_analysis() {
    local dep="$1"

    case "$dep" in
        "miniforge3")
            if [ -f "${AISTACK_ISOLATED_DEPENDENCIES_ROOT}/miniforge3/bin/python" ]; then
                export AISTACK_INTERNAL_PYTHON_RUNTIME_AVAILABLE="true"
                export AISTACK_INTERNAL_PYTHON_RUNTIME_PATH="${AISTACK_ISOLATED_DEPENDENCIES_ROOT}/miniforge3/bin/python"
            fi
            if [ -f "${AISTACK_ISOLATED_DEPENDENCIES_ROOT}/miniforge3/bin/mamba" ]; then
                export AISTACK_INTERNAL_MAMBA_AVAILABLE="true"
            fi
            ;;
        "nodejs")
            if [ -s "${AISTACK_NVM_HOME}/nvm.sh" ]; then
                export AISTACK_INTERNAL_NVM_AVAILABLE="true"
                if nvm which default >/dev/null 2>&1; then
                    export AISTACK_INTERNAL_NODEJS_RUNTIME_AVAILABLE="true"
                    export AISTACK_INTERNAL_NODEJS_RUNTIME_PATH="$(nvm which default)"
                fi
            fi
            ;;
    esac
}

runtime_analysis_all() {
    for f in $STELLA_APP_FEATURE_LIST; do
        runtime_analysis "$f"
    done
}

aistack_install_dependency() {
    local dep="$1"

    case "$dep" in
        yq*)
            # internal dependencies for aistack (which will be added to aistack PATH while running)
            $STELLA_API get_feature "yq"
            ;;
        jq*)
            # internal dependencies for aistack (which will be added to aistack PATH while running)
            $STELLA_API get_feature "jq"
            ;;
        bats*|patchelf*|cliproxyapi*);;

        # install other dependencies in an isolated way. (None of those will never been added aistack PATH while running)
        nodejs)
            node_install
            # TODO : change install nvm for glibc 2.17
            # if [ "$STELLA_CURRENT_PLATFORM" = "linux" ]; then
            #     if [ "$STELLA_CURRENT_CPU_FAMILY" = "intel" ]; then
            #         _ldd_version="$(ldd --version 2>/dev/null | awk '/ldd/{print $NF}')"
            #         if [ "${_ldd_version}" = "2.17" ]; then
            #             dep="nodejs#23_7_0_glibc_217"
            #             echo "-- detected glibc 2.17 switch to nodejs special build for it"
            #         fi
            #     fi
            # fi
        # this notation do not stop case statement workflow and continue to next pattern without testing any match
        #;&
            ;;
        *)
            # other dependencies (for mcp servers and other commands) in an isolated way. (None of those will never been added to any PATH)
            _feature=""
            _feature_name=""

            $STELLA_API select_official_schema "$dep" "_feature" "_feature_name"
            if [ ! "$_feature" = "" ]; then
                echo "-- install $_feature"
                mkdir -p "${AISTACK_ISOLATED_DEPENDENCIES_ROOT}/${_feature_name}"
                $STELLA_API feature_install "$dep" "EXPORT ${AISTACK_ISOLATED_DEPENDENCIES_ROOT}/${_feature_name}"
            else
                echo "!! WARN : $dep is not a valid feature for stella framework"
            fi
            # this notation do not stop case statement workflow and continue to next pattern by testing next pattern
            ;;&
        miniforge3)
            # install pipx and uv after having installaing miniforge3 in previsous case match
            echo "-- install python pipx and uv package/project manager"
            PATH="${AISTACK_PYTHON_BIN_PATH}:${PATH}" mamba install -y pipx uv
            ;;
    esac
}

aistack_install_dependencies() {

    echo "- Install internal dependencies for aistack"
    aistack_install_dependency "jq"
    aistack_install_dependency "yq"

    echo "- Install other dependencies (for mcp servers and other commands) in an isolated way. (None of those will never been added to system PATH)"
    for f in $STELLA_APP_FEATURE_LIST; do
        aistack_install_dependency "$f"
    done

    # generate runtime path files with dependencies path to use them in launchers and other tools
    runtime_path_file_generate
}


aistack_remove_dependencies() {
    # remove isolated dependencies and runtime
    rm -Rf "${AISTACK_ISOLATED_DEPENDENCIES_ROOT}"
    # remove dependencies
    rm -Rf "${STELLA_APP_FEATURE_ROOT}"

    runtime_path_file_remove
}



aistack_init() {
    aistack_remove_dependencies
    aistack_install_dependencies
}

aistack_uninstall() {
    # TODO : check missing unregister functions in this list of call
    gemini_path_unregister_for_shell "all"
    gemini_path_unregister_for_vs_terminal
    opencode_path_unregister_for_shell "all"
    opencode_path_unregister_for_vs_terminal
    orla_path_unregister_for_shell "all"
    orla_path_unregister_for_vs_terminal

    aistack_remove_dependencies
    runtime_path_file_remove

    rm -Rf "${AISTACK_MCP_LAUNCHER_HOME}"
    rm -Rf "${AISTACK_LAUNCHER_HOME}"

    rm -Rf "${STELLA_APP_WORK_ROOT}"
}

# check availability
check_requirements() {
    feature="$1"
    mode="$2"
    [ "$mode" = "" ] && mode="SILENT"
    case "$feature" in
        "yq")
            if command -v yq >/dev/null 2>&1; then
                [ "$mode" = "VERBOSE" ] && echo "-- yq detected in $(command -v yq)"
                return 0
            else
                return 1
            fi
            ;;
        "jq")
            if command -v jq >/dev/null 2>&1; then
                [ "$mode" = "VERBOSE" ] && echo "-- jq detected in $(command -v jq)"
                return 0
            else
                return 1
            fi
            ;;
        "nodejs") 
            if [ "$AISTACK_INTERNAL_NODEJS_RUNTIME_AVAILABLE" = "true" ]; then
                [ "$mode" = "VERBOSE" ] && echo "-- nodejs detected in ${AISTACK_INTERNAL_NODEJS_RUNTIME_PATH}"
                return 0
            else
                if command -v node >/dev/null 2>&1; then
                    [ "$mode" = "VERBOSE" ] && echo "-- nodejs detected in $(command -v node)"
                    return 0
                fi
            fi
            return 1
            ;;
        "nvm")
            if type nvm >/dev/null 2>&1; then
                return 0
            fi
            return 1
            ;;
        "python")
            if [ "$AISTACK_INTERNAL_PYTHON_RUNTIME_AVAILABLE" = "true" ]; then
                [ "$mode" = "VERBOSE" ] && echo "-- python detected in ${AISTACK_INTERNAL_PYTHON_RUNTIME_PATH}"
                return 0
            else
                if command -v python >/dev/null 2>&1; then
                    [ "$mode" = "VERBOSE" ] && echo "-- python detected in $(command -v python)"
                    return 0
                fi
            fi
            return 1
            ;;
        *)
            ;;
    esac
}

require() {
    local feature="$1"

    case "$feature" in
        "json5")
            if ! PATH="${AISTACK_NODEJS_BIN_PATH}:${PATH}" type json5 >/dev/null 2>&1; then
                # install json5 nodejs package (to correct invalid json)
                # https://github.com/json5/json5
                PATH="${AISTACK_NODEJS_BIN_PATH}:${PATH}" npm install -g json5 1>/dev/null
                [ $? -ne 0 ] && {
                    echo "ERROR : installing json5 nodejs package"
                    return 1
                }
            fi
            ;;
        *)
            echo "ERROR : unknown require $feature"
            return 1
            ;;
    esac
}


# Generate a self-signed certificate
# @param {string} $1 - key file path
# @param {string} $2 - cert file path
# @param {string} $3 - CN (optional, default to localhost)
generate_self_signed_cert() {
    local key_path="$1"
    local cert_path="$2"
    local cn="${3:-localhost}"

    if ! command -v openssl >/dev/null 2>&1; then
        echo "ERROR: openssl is not installed." >&2
        return 1
    fi

    echo "Generating self-signed certificate..."
    openssl req -x509 -newkey rsa:2048 -keyout "$key_path" -out "$cert_path" -days 365 -nodes -subj "/CN=$cn"
    if [ $? -ne 0 ]; then
        echo "ERROR: Failed to generate self-signed certificate." >&2
        return 1
    fi
    echo "Self-signed certificate generated successfully at $cert_path expires in 365 days"
}


process_kill_by_port() {
    local port="$1"
    local pid

    if command -v lsof >/dev/null 2>&1; then
        pid=$(lsof -t -i:"$port" 2>/dev/null)
        if $? -ne 0; then
            pid=""
        fi
    fi
    if [ "$pid" = "" ]; then
        if command -v netstat >/dev/null 2>&1; then
            # WARN to get PID or process name with netstat, we need to be root user
            pid=$(netstat -ltnp 2>/dev/null | awk -v port=":$port$" '$4 ~ port {split($7, a, "/"); print a[1]; exit}')
        fi
    fi

    if [ -n "$pid" ]; then
        # lsof can return multiple PIDs (as a newline-separated string), so we loop
        for p in $pid; do
            echo "Killing process on port $port with PID $p"
            kill -9 "$p"
        done
    else
        echo "Error: lsof nor netstat able to find process."
        return 1
    fi
}

shell_quote_posix() {
    printf "'%s'" "$(printf '%s' "$1" | sed "s/'/'\\\\''/g")"
}

github_get_latest_release() {
    local repo="$1" # i.e StudioEtrange/aistack-cli

    local api_url="https://api.github.com/repos/${repo}/releases/latest"

    local latest_tag
    latest_tag=$(curl -sLk "$api_url" | yq -r .tag_name)

    if [ $? -ne 0 ]; then
        echo "ERROR: Failed to fetch release information from GitHub." >&2
        return 1
    fi

    if [ -z "$latest_tag" ] || [ "$latest_tag" = "null" ]; then
        echo "ERROR: Could not fetch the latest version from GitHub." >&2
        return 1
    fi

    echo -n "$latest_tag"
}



# add a path at PATH env variable list when a shell launch
path_register_for_shell() {
    local name="$1"
    local shell_name="$2"
    local path_to_add="$3"
    local set_path_now="${4:-false}"

    local rc_file

    local BEGIN_MARK="# >>> aistack-${name}-path >>>"
    local END_MARK="# <<< aistack-${name}-path <<<"

    [ "$shell_name" = "bash" ] && rc_file="$HOME/.bashrc"
    [ "$shell_name" = "zsh" ] && rc_file="$HOME/.zshrc"
    [ "$shell_name" = "fish" ] && rc_file="$HOME/.config/fish/config.fish"

    case "$shell_name" in
        "bash"|"zsh")
            [ -f "$rc_file" ] && path_unregister_for_shell "$name" "$shell_name" || touch "$rc_file"
            if ! grep -Fq "$BEGIN_MARK" "$rc_file"; then
                {
                    echo "$BEGIN_MARK"
                    echo "export PATH=\"${path_to_add}:\$PATH\""
                    echo "$END_MARK"
                } >> "$rc_file"
            fi
            ;;
        "fish")
            mkdir -p "$(dirname "$rc_file")"
            [ -f "$rc_file" ] && path_unregister_for_shell "$name" "$shell_name" || touch "$rc_file"
            if ! grep -Fq "$BEGIN_MARK" "$rc_file"; then
                {
                    echo "$BEGIN_MARK"
                    echo "set -gx PATH \"${path_to_add}\" \$PATH"
                    echo "$END_MARK"
                } >> "$rc_file"
            fi
            ;;
         *) 
            echo "error : unsupported shell $shell_name"
            ;;
    esac

}

# remove path
# use 'all' shell_name to unregister to all known shell
path_unregister_for_shell() {
    local name="$1"
    local shell_name="$2"
    local rc_file

    local BEGIN_MARK="# >>> aistack-${name}-path >>>"
    local END_MARK="# <<< aistack-${name}-path <<<"

    local shell_list
    [ "$shell_name" = "all" ] && shell_list="bash zsh fish" || shell_list="$shell_name"

    for s in $shell_list; do
        [ "$s" = "bash" ] && rc_file="$HOME/.bashrc"
        [ "$s" = "zsh" ] && rc_file="$HOME/.zshrc"
        [ "$s" = "fish" ] && rc_file="$HOME/.config/fish/config.fish"

        case "$s" in
            "bash"|"zsh"|"fish")
                if [ -f "$rc_file" ]; then
                    local tmp_file="$(mktemp)"
                    awk -v begin="$BEGIN_MARK" -v end="$END_MARK" ' 
                        $0 == begin { skip=1; next } 
                        $0 == end { skip=0; next } !skip 
                    ' "$rc_file" > "$tmp_file" && mv "$tmp_file" "$rc_file"
                    rm -f "$tmp_file"
                fi
                ;;
            *) 
                echo "error : unsupported shell : $s"
                ;;
        esac
    done
}
