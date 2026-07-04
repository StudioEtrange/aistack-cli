

# initialize global variables and folders
aistack_initialize() {

    # components ---
    # runtime lists
    export AISTACK_RUNTIME_TO_DETECT="python nodejs bun"
	# runtimes required for AIStack
    export AISTACK_RUNTIME_CORE="nodejs"

    # modules lists
    export AISTACK_MODULE_TO_DETECT="yq jq json5 uv pipx mamba npm"
	# modules required for AIStack - installed before everything else at init - MUST not depends on any runtimes
    export AISTACK_MODULE_CORE_BOOTSTRAP="yq"
	# modules required for AIStack - installed after required runtime
    export AISTACK_MODULE_CORE="jq json5"


    # add search path of runtimes and modules to tool run context
    #export AISTACK_TOOL_RUN_CONTEXT_ADD_RUNTIME="nodejs bun python"
    #export AISTACK_TOOL_RUN_CONTEXT_ADD_MODULE="yq jq"
    $STELLA_API get_app_property "AISTACK" "TOOL_RUN_CONTEXT_ADD_RUNTIME"
    $STELLA_API get_app_property "AISTACK" "TOOL_RUN_CONTEXT_ADD_MODULE"

    # paths ---
    export AISTACK_POOL="${STELLA_APP_ROOT}/pool"

    export AISTACK_LAUNCHER_HOME="${STELLA_APP_WORK_ROOT}/launcher"
    mkdir -p "${AISTACK_LAUNCHER_HOME}"

    export AISTACK_MCP_LAUNCHER_HOME="${STELLA_APP_WORK_ROOT}/launcher-mcp"
    mkdir -p "${AISTACK_MCP_LAUNCHER_HOME}"

    export AISTACK_ISOLATED_ROOT="${STELLA_APP_WORK_ROOT}/isolated_dependencies"
    mkdir -p "${AISTACK_ISOLATED_ROOT}"

    export AISTACK_RUN_CONTEXT_FILE="${STELLA_APP_WORK_ROOT}/context/run_context.sh"
    mkdir -p "${STELLA_APP_WORK_ROOT}/context"


    # init variables ---
	node_init
    bun_init

    # AISTACK_INIT_FORCE_VSCODE_MODE could be "remote" : means using vscode remote extension
    # AISTACK_INIT_FORCE_VSCODE_MODE could be empty "" : try to guess
	vscode_init "${AISTACK_INIT_FORCE_VSCODE_MODE}"

	gemini_init
	agy_init
    opencode_init
    cpa_init
    orla_init
    kilo_init
    bmad_init
	gsd_init
    adk_init
    asm_init
	llmfit_init
}

aistack_info() {
    echo "--*== AIStack Informations ==*--"
    echo
    echo "AISTACK_POOL: $AISTACK_POOL"
    echo "AISTACK_LAUNCHER_HOME: $AISTACK_LAUNCHER_HOME"
    echo "AISTACK_MCP_LAUNCHER_HOME: $AISTACK_MCP_LAUNCHER_HOME"
    echo "AISTACK_ISOLATED_ROOT: $AISTACK_ISOLATED_ROOT"
    echo "AISTACK_RUN_CONTEXT_FILE: $AISTACK_RUN_CONTEXT_FILE"
    echo
    echo "--JavaScript ecosystem--"
    echo "AISTACK_MODULE_NVM_AVAILABLE : $AISTACK_MODULE_NVM_AVAILABLE"
    echo "AISTACK_NVM_HOME : $AISTACK_NVM_HOME"
    echo "NVM_DIR : $NVM_DIR"
    echo "AISTACK_NVM_CACHE (npm/npx): $AISTACK_NVM_CACHE"

    echo "AISTACK_RUNTIME_NODEJS_AVAILABLE : $AISTACK_RUNTIME_NODEJS_AVAILABLE"
    if [ "$AISTACK_RUNTIME_NODEJS_AVAILABLE" = "true" ]; then
        echo "AISTACK_RUNTIME_NODEJS_SEARCH_PATH : $AISTACK_RUNTIME_NODEJS_SEARCH_PATH"
        echo "AISTACK_RUNTIME_NODEJS_PATH : $AISTACK_RUNTIME_NODEJS_PATH"
        echo "AISTACK_MODULE_NPM_AVAILABLE : $AISTACK_MODULE_NPM_AVAILABLE"
        echo "NodeJS version : $($AISTACK_RUNTIME_NODEJS_PATH --version)"
        echo "NPM version : $(PATH="${AISTACK_RUNTIME_NODEJS_SEARCH_PATH}:${STELLA_ORIGINAL_SYSTEM_PATH}" npm --version)"
        echo "NPM cache dir : $(PATH="${AISTACK_RUNTIME_NODEJS_SEARCH_PATH}:${STELLA_ORIGINAL_SYSTEM_PATH}" npm --global config get cache)"
        local npm_userconfig="$(PATH="${AISTACK_RUNTIME_NODEJS_SEARCH_PATH}:${STELLA_ORIGINAL_SYSTEM_PATH}" npm --global config get userconfig)"
        case "$npm_userconfig" in
            "undefined"|"")
                echo "NPM userconfig file : not defined"
                ;;
            *)
                echo "NPM userconfig file : $npm_userconfig"
                [ -f "$npm_userconfig" ] && echo "NPM userconfig file exists" || echo "NPM userconfig file does not exist"
                ;;
        esac
    fi
    echo
    echo "AISTACK_RUNTIME_BUN_AVAILABLE : $AISTACK_RUNTIME_BUN_AVAILABLE"
    if [ "$AISTACK_RUNTIME_BUN_AVAILABLE" = "true" ]; then
        echo "AISTACK_RUNTIME_BUN_SEARCH_PATH : $AISTACK_RUNTIME_BUN_SEARCH_PATH"
        echo "AISTACK_RUNTIME_BUN_PATH : $AISTACK_RUNTIME_BUN_PATH"
        echo "Bun version : $($AISTACK_RUNTIME_BUN_PATH --version)"
    fi

    echo
    echo "--python ecosystem--"
    echo "AISTACK_RUNTIME_PYTHON_AVAILABLE : $AISTACK_RUNTIME_PYTHON_AVAILABLE"
    if [ "$AISTACK_RUNTIME_PYTHON_AVAILABLE" = "true" ]; then
        echo "AISTACK_RUNTIME_PYTHON_SEARCH_PATH : $AISTACK_RUNTIME_PYTHON_SEARCH_PATH"
        echo "AISTACK_RUNTIME_PYTHON_PATH : $AISTACK_RUNTIME_PYTHON_PATH"
        echo "Python version : $($AISTACK_RUNTIME_PYTHON_PATH --version)"
    fi
    echo "AISTACK_MODULE_MAMBA_AVAILABLE : $AISTACK_MODULE_MAMBA_AVAILABLE"
    echo
    echo "--components management--"
	echo "AISTACK_RUNTIME_TO_DETECT : $AISTACK_RUNTIME_TO_DETECT"
	echo "AISTACK_RUNTIME_CORE : $AISTACK_RUNTIME_CORE"
    echo "AISTACK_MODULE_TO_DETECT : $AISTACK_MODULE_TO_DETECT"
	echo "AISTACK_MODULE_CORE : $AISTACK_MODULE_CORE"
	echo "AISTACK_MODULE_CORE_BOOTSTRAP : $AISTACK_MODULE_CORE_BOOTSTRAP"
    echo
    echo "AISTACK_TOOL_RUN_CONTEXT_ADD_RUNTIME : $AISTACK_TOOL_RUN_CONTEXT_ADD_RUNTIME"
    echo "AISTACK_TOOL_RUN_CONTEXT_ADD_MODULE : $AISTACK_TOOL_RUN_CONTEXT_ADD_MODULE"
    echo
    echo "--module status--"
    local var name p
	while IFS= read -r var; do
		case "$var" in
			AISTACK_MODULE_*_AVAILABLE)
                name="${var#AISTACK_MODULE_}"
                name="${name%_AVAILABLE}"
                printf '%s available : %s\n' "$name" "${!var}"
                path_var="${var/_AVAILABLE/_PATH}"
                printf '%s path : %s\n' "$name" "${!path_var}"
                ;;
		esac
	done < <(compgen -v AISTACK_ | sort)
    echo "--tools status--"
	while IFS= read -r var; do
		case "$var" in
			AISTACK_*_TOOL_AVAILABLE)
                name="${var#AISTACK_}"
                name="${name%_TOOL_AVAILABLE}"
                printf '%s available : %s\n' "$name" "${!var}"
                path_var="${var/_TOOL_AVAILABLE/_TOOL_PATH}"
                printf '%s path : %s\n' "$name" "${!path_var}"
                ;;
		esac
	done < <(compgen -v AISTACK_ | sort)
	echo
	echo "-- CURRENT SEARCH PATH --"
    echo "PATH : $PATH"
}


aistack_install() {
    # TODO : do we need to remove all ?
    aistack_component_remove_all
    aistack_component_core_install
}

aistack_uninstall() {
    # TODO : check missing unregister functions in this list

	echo "INFO : clean various PATHs for shells"
	gemini_path_unregister_for_shell "all"
	opencode_path_unregister_for_shell "all"
	orla_path_unregister_for_shell "all"
	bmad_path_unregister_for_shell "all"
	#gsd_path_unregister_for_shell "all"
	adk_path_unregister_for_shell "all"
	asm_path_unregister_for_shell "all"
	kilo_path_unregister_for_shell "all"
	agy_path_unregister_for_shell "all"
	llmfit_path_unregister_for_shell "all"
    
    # NOTE : because need lib_json which use json5 which needs nodesjs
	if aistack_module_is_detected "json5"; then 
		gemini_path_unregister_for_vs_terminal
		opencode_path_unregister_for_vs_terminal
		orla_path_unregister_for_vs_terminal
		bmad_path_unregister_for_vs_terminal
		#gsd_path_unregister_for_vs_terminal
		adk_path_unregister_for_vs_terminal
		asm_path_unregister_for_vs_terminal
		kilo_path_unregister_for_vs_terminal
		agy_path_unregister_for_vs_terminal
		llmfit_path_unregister_for_vs_terminal
	else
		echo "INFO : registred PATHs from vscode will not be cleaned because nodejs ecosystem is not available "
	fi

	echo "INFO : delete all components and runtimes"

    aistack_component_remove_all

	echo "INFO : delete tools and launchers"
    rm -Rf "${AISTACK_MCP_LAUNCHER_HOME}"
    rm -Rf "${AISTACK_LAUNCHER_HOME}"

    rm -Rf "${STELLA_APP_WORK_ROOT}"
    rm -Rf "${AISTACK_NVM_CACHE}"
    
}

# create files that centralize components and runtime PATH
aistack_run_context_file_generate() {
    local m r va vp list_path

    echo '#!/bin/sh' > "${AISTACK_RUN_CONTEXT_FILE}"

    # add to run context runtime search path
    for r in ${AISTACK_TOOL_RUN_CONTEXT_ADD_RUNTIME}; do
        va="AISTACK_RUNTIME_$(printf '%s' "${r}" | tr '[:lower:]' '[:upper:]')_AVAILABLE"
        vp="AISTACK_RUNTIME_$(printf '%s' "${r}" | tr '[:lower:]' '[:upper:]')_SEARCH_PATH"
        [ "${!va}" = "true" ] && [ -n "${!vp}" ] && list_path="$($STELLA_API path_append_to_list "${list_path}" "${!vp}" "ALWAYS_PREPEND")"
    done

    # add to run context module search path
    for m in ${AISTACK_TOOL_RUN_CONTEXT_ADD_MODULE}; do
        va="AISTACK_MODULE_$(printf '%s' "${m}" | tr '[:lower:]' '[:upper:]')_AVAILABLE"
        vp="AISTACK_MODULE_$(printf '%s' "${m}" | tr '[:lower:]' '[:upper:]')_SEARCH_PATH"
        [ "${!va}" = "true" ] && [ -n "${!vp}" ] && list_path="$($STELLA_API path_append_to_list "${list_path}" "${!vp}" "ALWAYS_PREPEND")"
    done

    
    [ -n "${list_path}" ] && echo "export PATH=\"${list_path}:\${PATH}\"" >> "${AISTACK_RUN_CONTEXT_FILE}"
    chmod +x "${AISTACK_RUN_CONTEXT_FILE}"
}

aistack_run_context_file_remove() {
    rm -f "${AISTACK_RUN_CONTEXT_FILE}"
}

aistack_launcher_regenerate() {
	aistack_tool_launcher_regenerate
	aistack_mcp_launcher_regenerate
}


# --------------- RUNTIME MANAGEMENT -----------------------------
# detect all installed managed runtimes
aistack_runtime_detect() {
    local r e va vp

    for r in ${AISTACK_RUNTIME_TO_DETECT}; do
        
        case "${r}" in
            "python")
                if aistack_component_is_installed "miniforge3"; then
                    export AISTACK_RUNTIME_PYTHON_AVAILABLE="true"
                    export AISTACK_RUNTIME_PYTHON_PATH="${AISTACK_ISOLATED_ROOT}/miniforge3/bin/python"
                    # bin folder which contains python
                    export AISTACK_RUNTIME_PYTHON_SEARCH_PATH="$(dirname ${AISTACK_RUNTIME_PYTHON_PATH})"
                    # mamba module is always included in miniforge3 installation
                    export AISTACK_MODULE_MAMBA_AVAILABLE="true"
                    export AISTACK_MODULE_MAMBA_PATH="${AISTACK_RUNTIME_PYTHON_SEARCH_PATH}/mamba"
                    export AISTACK_MODULE_MAMBA_SEARCH_PATH="${AISTACK_RUNTIME_PYTHON_SEARCH_PATH}"
                    # # modules that is installed at the same time as python runtuime
                    # for ingredient in "uv pipx"; do
                    #     va="AISTACK_MODULE_${ingredient}_AVAILABLE"; vp="AISTACK_MODULE_${ingredient}_PATH";
                    #     if aistack_component_is_installed "${ingredient}"; then
                    #         printf -v "${va}" '%s' "true"; export ${va};
                    #         printf -v "${vp}" '%s' "${AISTACK_RUNTIME_PYTHON_SEARCH_PATH}/${ingredient}"; export ${vp};
                    #     fi
                    # fi
                fi
                ;;
            "nodejs")
                if aistack_component_is_installed "nvm"; then
                    export AISTACK_MODULE_NVM_AVAILABLE="true"
                    if aistack_component_is_installed "${r}"; then
                        export AISTACK_RUNTIME_NODEJS_AVAILABLE="true"
                        export AISTACK_RUNTIME_NODEJS_PATH="$(nvm which default)"
                        # bin folder which contains node
                        export AISTACK_RUNTIME_NODEJS_SEARCH_PATH="$(dirname ${AISTACK_RUNTIME_NODEJS_PATH})"
                        # npm module is always included in nodejs installation
                        export AISTACK_MODULE_NPM_AVAILABLE="true"
                        export AISTACK_MODULE_NPM_PATH="${AISTACK_RUNTIME_NODEJS_SEARCH_PATH}/npm"
                        export AISTACK_MODULE_NPM_SEARCH_PATH="${AISTACK_RUNTIME_NODEJS_SEARCH_PATH}"
                    fi
                fi
                ;;
            "bun")
                if aistack_component_is_installed "${r}"; then
                    export AISTACK_RUNTIME_BUN_AVAILABLE="true"
                    export AISTACK_RUNTIME_BUN_PATH="${AISTACK_ISOLATED_ROOT}/bun/bun"
                    # bin folder which contains bun
                    export AISTACK_RUNTIME_BUN_SEARCH_PATH="$(dirname ${AISTACK_RUNTIME_BUN_PATH})"
                fi
                ;;
        esac
    done

}


# check if a runtime have been detected as available
aistack_runtime_is_detected() {
    local r="${1}"
    local _var="AISTACK_RUNTIME_$(printf '%s' "${r}" | tr '[:lower:]' '[:upper:]')_AVAILABLE"

    [ "${!_var}" = "true" ] || return 1
}

# check if a managed runtime is installed else install it
aistack_runtime_require() {
    local r="${1}"

    if ! aistack_runtime_is_detected "${r}"; then
        aistack_runtime_install "${r}"
        aistack_runtime_detect
		aistack_run_context_file_generate
    fi

    if ! aistack_runtime_is_detected "${r}"; then
        echo "ERROR : error while requiring runtime ${r}"
        exit 1
    fi
}


# install managed runtime
aistack_runtime_install() {
    local r="$1"

    case "${r}" in
        "python")
            aistack_component_install "miniforge3"
            echo "-- install python pipx and uv package/project manager"
            # NOTE : Here $AISTACK_RUNTIME_PYTHON_SEARCH_PATH is empty so we launch aistack_runtime_detect
            # to set it to be able to install pipx and uv with manba
            aistack_runtime_detect

            aistack_module_install "pipx"
            aistack_module_install "uv"
            #PATH="${AISTACK_RUNTIME_PYTHON_SEARCH_PATH}:${STELLA_ORIGINAL_SYSTEM_PATH}" mamba install -y pipx uv
            aistack_module_detect
            aistack_run_context_file_generate
            ;;
        "nodejs")
            aistack_component_install "nodejs"
            ;;
        "bun")
            aistack_component_install "bun"
            ;;
        *)
			echo "ERROR: Unknown runtime $r"
            return 1
            ;;
    esac
}

aistack_runtime_uninstall() {
    local r="$1"
    case "${r}" in
        "python")
            rm -Rf "${AISTACK_ISOLATED_ROOT}/miniforge3"
            ;;
        "nodejs")
            node_uninstall
            ;;
        "bun")
            bun_uninstall
            ;;
    esac
}


# --------------- MODULE MANAGEMENT -----------------------------

# detect all installed module
aistack_module_detect() {
    local m

    for m in ${AISTACK_MODULE_TO_DETECT}; do
        case ${m} in
            # modules from stella framework -------
            # NOTE :
            #       as a stella feature which is in enabled list
            #       command -v will always return jq path installed from stella over system path
            jq)
                if aistack_component_is_installed "${m}"; then
                    export AISTACK_MODULE_JQ_AVAILABLE="true"
                    export AISTACK_MODULE_JQ_PATH="$(command -v jq)"
                    export AISTACK_MODULE_JQ_SEARCH_PATH="$(dirname ${AISTACK_MODULE_JQ_PATH})"
                fi
                ;;
            yq)
                if aistack_component_is_installed "${m}"; then
                    export AISTACK_MODULE_YQ_AVAILABLE="true"
                    export AISTACK_MODULE_YQ_PATH="$(command -v yq)"
                    export AISTACK_MODULE_YQ_SEARCH_PATH="$(dirname ${AISTACK_MODULE_YQ_PATH})"
                fi
                ;;

            # nodejs modules -------
            json5)
                if aistack_component_is_installed "${m}"; then
                    export AISTACK_MODULE_JSON5_AVAILABLE="true"
                    #export AISTACK_MODULE_JSON5_PATH="$(PATH="${AISTACK_RUNTIME_NODEJS_SEARCH_PATH}:${STELLA_ORIGINAL_SYSTEM_PATH}" command -v json5)"
                    export AISTACK_MODULE_JSON5_PATH="$AISTACK_RUNTIME_NODEJS_SEARCH_PATH/json5"
                    export AISTACK_MODULE_JSON5_SEARCH_PATH="$(dirname ${AISTACK_MODULE_JSON5_PATH})"

                fi
                ;;
            # python modules -------
            pipx)
                if aistack_component_is_installed "${m}"; then
                    export AISTACK_MODULE_PIPX_AVAILABLE="true"
                    #export AISTACK_MODULE_PIPX_PATH="$(PATH="${AISTACK_RUNTIME_PYTHON_SEARCH_PATH}:${STELLA_ORIGINAL_SYSTEM_PATH}" command -v json5)"
                    export AISTACK_MODULE_PIPX_PATH="$AISTACK_RUNTIME_PYTHON_SEARCH_PATH/pipx"
                    export AISTACK_MODULE_PIPX_SEARCH_PATH="$(dirname ${AISTACK_MODULE_PIPX_PATH})"
                fi
                ;;
            uv)
                if aistack_component_is_installed "${m}"; then
                    export AISTACK_MODULE_UV_AVAILABLE="true"
                    #export AISTACK_MODULE_UV_PATH="$(PATH="${AISTACK_RUNTIME_PYTHON_SEARCH_PATH}:${STELLA_ORIGINAL_SYSTEM_PATH}" command -v json5)"
                    export AISTACK_MODULE_UV_PATH="$AISTACK_RUNTIME_PYTHON_SEARCH_PATH/uv"
                    export AISTACK_MODULE_UV_SEARCH_PATH="$(dirname ${AISTACK_MODULE_UV_PATH})"
                fi
                ;;
            # various modules -------
            mamba|npm)
                # already detected at python/nodejs runtime install
                ;;
        esac
    done
}


# check if a module have been detected as available
aistack_module_is_detected() {
    local m="${1}"
    local _var="AISTACK_MODULE_$(printf '%s' "${m}" | tr '[:lower:]' '[:upper:]')_AVAILABLE"

    [ "${!_var}" = "true" ] || return 1
}


# check if a module is installed else install it
aistack_module_require() {
    local m="${1}"

    if ! aistack_module_is_detected "${m}"; then
        aistack_module_install "${m}"
        aistack_module_detect
		aistack_run_context_file_generate
    fi

    if ! aistack_module_is_detected "${m}"; then
        echo "ERROR : error while requiring module ${m}"
        exit 1
    fi
}

# NOTE : we do not need to implements this function
# use aistack_component_install instead
aistack_module_install() {
    aistack_component_install "$@"
}

# NOTE : we do not need to implements this function
# we never need to uninstall a specific module because all are mandatories and should not be removed
aistack_module_uninstall() {
    :
}



# --------------- TOOL MANAGEMENT -----------------------------


aistack_tool_launcher_regenerate() (

	adk_launcher_manage "refresh_if_exists"
	agy_launcher_manage "refresh_if_exists"
	asm_launcher_manage "refresh_if_exists"
	bmad_launcher_manage "refresh_if_exists"
	cpa_launcher_manage "refresh_if_exists"
	gemini_launcher_manage "refresh_if_exists"
	gsd_launcher_manage "refresh_if_exists"
	kilo_launcher_manage "refresh_if_exists"
	opencode_launcher_manage "refresh_if_exists"
	orla_launcher_manage "refresh_if_exists"
	llmfit_launcher_manage "refresh_if_exists"

)


# tools detect
aistack_tool_detect() {
	agy_is_installed
	asm_is_installed
	adk_is_installed
	bmad_is_installed
	cpa_is_installed
	gemini_is_installed
	gsd_is_installed
	kilo_is_installed
	opencode_is_installed
	orla_is_installed
	llmfit_is_installed
}


# --------------- MCP MANAGEMENT -----------------------------


aistack_mcp_detect() {
	:
}


aistack_mcp_launcher_regenerate() (
	# NOTE : for now, we do not use any launcher for mcp server
	:
)


# --------------- COMPONENT MANAGEMENT -----------------------------

# check mandatories components for aistack
aistack_component_core_is_detected() {
    local m r

    for m in ${AISTACK_MODULE_CORE_BOOTSTRAP}; do
        if ! aistack_module_is_detected "${m}"; then
            echo "ERROR : missing ${m} mandatory bootstrap core module - please init AIStack"
            exit 1
        fi
    done

    for r in ${AISTACK_RUNTIME_CORE}; do
        if ! aistack_runtime_is_detected "${r}"; then
            echo "ERROR : missing ${r} mandatory core runtime - please init AIStack"
            exit 1
        fi
    done

    for m in ${AISTACK_MODULE_CORE}; do
        if ! aistack_module_is_detected "${m}"; then
            echo "ERROR : missing ${m} mandatory core module - please init AIStack"
            exit 1
        fi
    done

    return 0
}


# install mandatories components for aistack
aistack_component_core_install() {
	local m r

    echo "- Install some module to bootstrap AIStack"
    for m in ${AISTACK_MODULE_CORE_BOOTSTRAP}; do
        aistack_component_install "${m}"
    done

    echo "- Install core mandatories runtimes managed by AIStack"
    for r in ${AISTACK_RUNTIME_CORE}; do
        aistack_runtime_install "${r}"
        if [ "${r}" = "nodejs" ]; then
            if [ -n "${AISTACK_INIT_FORCE_NPM_REGISTRY}" ]; then
                if check_binary "npm"; then
                    npm config set registry "${AISTACK_INIT_FORCE_NPM_REGISTRY}" -g
                fi
            fi
        fi
    done

    aistack_runtime_detect
	
	echo "- Install internal core mandatories modules for AIStack"
    for m in ${AISTACK_MODULE_CORE}; do
        aistack_component_install "${m}"
    done
    
    aistack_module_detect
  	aistack_run_context_file_generate

}


# return 0 : is installed
# return 1 : component is not installed
# return 2 : component do not support those options
aistack_component_is_installed() {
	local c="$1"
	
    case ${c} in
        # components LOADED IN_PATH -----------
        # module --
        jq|yq)
            stella_feature_installed "${c}" "LOADED_IN_PATH"
            return $?
            ;;
        nvm)
            # check if nvm.sh file is installed
            if [ -s "${AISTACK_NVM_HOME}/nvm.sh" ]; then
                # check if nvm alias command is loaded
                if type nvm >/dev/null 2>&1; then
                    return 0
                fi
            fi
            return 1
            ;;
        # components NOT_LOADED_IN_PATH -----------
        # runtime --
        miniforge3)
            [ -f "${AISTACK_ISOLATED_ROOT}/miniforge3/bin/python" ]
            return $?
            ;;
		llmfit)
            [ -f "${AISTACK_ISOLATED_ROOT}/llmfit/llmfit" ]
            return $?
            ;;
        nodejs)
            if aistack_component_is_installed "nvm"; then
            #if [ -s "${AISTACK_NVM_HOME}/nvm.sh" ]; then
                if nvm which default >/dev/null 2>&1; then
                    return 0
                fi
            fi
            return 1
            ;;
        bun)
            [ -f "${AISTACK_ISOLATED_ROOT}/bun/bun" ]
            return $?
            ;;
        # module -- runtime variable are available
        mamba|pipx|uv)
            [ -f "${AISTACK_RUNTIME_PYTHON_SEARCH_PATH}/${c}" ]
            return $?
            ;;
        npm|json5)
            # TODO
            [ -f "$AISTACK_RUNTIME_NODEJS_SEARCH_PATH/${c}" ]
            return $?
            ;;
        # other  -----------
        *)
            return 2
            ;;
    esac
}


# install components of any kind
aistack_component_install() {
    local c="$1"
    
    echo "INFO: install component ${c}"

    case ${c} in
        # components LOADED IN_PATH -----------
        # module --
        jq|yq)
            stella_feature_install "${c}" "LOADED_IN_PATH"
            ;;
        # components NOT_LOADED_IN_PATH -----------
        # runtime --
        miniforge3)
            stella_feature_install "${c}" "NOT_LOADED_IN_PATH"
            ;;
        nodejs)
            node_install
            ;;
        bun)
            bun_install
            ;;
        # module --
        pipx|uv)
            aistack_runtime_require "python"
            PATH="${AISTACK_RUNTIME_PYTHON_SEARCH_PATH}:${STELLA_ORIGINAL_SYSTEM_PATH}" mamba install -y "${c}"
            ;;
        json5) 
            aistack_runtime_require "nodejs"
            # install json5 nodejs package (to correct invalid json)
            # https://github.com/json5/json5
            PATH="${AISTACK_RUNTIME_NODEJS_SEARCH_PATH}:${STELLA_ORIGINAL_SYSTEM_PATH}" npm install -g "${c}" 1>/dev/null
            [ $? -ne 0 ] && {
                echo "ERROR : installing module ${c}"
                return 1
            }
            ;;
    esac
}


# remove tools, managed runtime and modules
aistack_component_remove_all() {
	aistack_run_context_file_remove

    # remove isolated vomponent (tuntimes, tools, component)
    rm -Rf "${AISTACK_ISOLATED_ROOT}"
    # remove component from stella framework
    rm -Rf "${STELLA_APP_FEATURE_ROOT}"

    # NOTE : we keep cache folder
}





# --------------- SPECIFIC INSTALLER -----------------------------
# note : install or reinstall/complete package
node_package_install() {
	local p="${1}"
	PATH="${AISTACK_RUNTIME_NODEJS_SEARCH_PATH}:${STELLA_ORIGINAL_SYSTEM_PATH}" npm install --verbose -g "${p}"
}
node_package_uninstall() {
	local p="${1}"
	PATH="${AISTACK_RUNTIME_NODEJS_SEARCH_PATH}:${STELLA_ORIGINAL_SYSTEM_PATH}" npm uninstall -g "${p}"
}


bun_package_install() {
	local p="${1}"
	PATH="${AISTACK_RUNTIME_BUN_SEARCH_PATH}:${STELLA_ORIGINAL_SYSTEM_PATH}" bun add --verbose -g "${p}"
}
bun_package_uninstall() {
	local p="${1}"
	PATH="${AISTACK_RUNTIME_BUN_SEARCH_PATH}:${STELLA_ORIGINAL_SYSTEM_PATH}" bun remove -g "${p}"
}

python_uv_package_install() {
	local p="${1}"
    PATH="${AISTACK_RUNTIME_PYTHON_SEARCH_PATH}:${STELLA_ORIGINAL_SYSTEM_PATH}" uv pip install --system --reinstall --verbose "${p}"
}
python_uv_package_uninstall() {
	local p="${1}"
	PATH="${AISTACK_RUNTIME_PYTHON_SEARCH_PATH}:${STELLA_ORIGINAL_SYSTEM_PATH}" uv pip uninstall --system --verbose "${p}"
}


stella_feature_install() {
    local f="$1"
    local opt="$2"
    local o
    
    local loaded_in_path_during_aistack_run="ON"
	local not_loaded_in_path_during_aistack_run=""
	for o in $opt; do
		[ "$o" = "LOADED_IN_PATH" ] && loaded_in_path_during_aistack_run="ON"
		[ "$o" = "NOT_LOADED_IN_PATH" ] && not_loaded_in_path_during_aistack_run="ON"
	done

    if [ "${loaded_in_path_during_aistack_run}" = "ON" ]; then
        # PATH is injected in current and next aistack run context
        $STELLA_API get_feature "${f}"
    fi

    if [ "${not_loaded_in_path_during_aistack_run}" = "ON" ]; then
        local _feature=""
        local _feature_name=""

        $STELLA_API select_official_schema "${f}" "_feature" "_feature_name"
        if [ ! "$_feature" = "" ]; then
            echo "-- install ${_feature}"
            mkdir -p "${AISTACK_ISOLATED_ROOT}/${_feature_name}"
            # PATH is not injected in current or next aistack run context
            $STELLA_API feature_install "${f}" "NO_PATH_UPDATE EXPORT ${AISTACK_ISOLATED_ROOT}/${_feature_name}"
        else
            echo "!! WARN : ${f} is not a valid feature for stella framework"
        fi
    fi

}

# return 0 : is installed
# return 1 : component is not installed
# return 2 : component do not support those options
stella_feature_installed() {
    local f="$1"
    local opt="$2"
    local o

    local loaded_in_path_during_aistack_run="ON"
	local not_loaded_in_path_during_aistack_run=""
	for o in $opt; do
		[ "$o" = "LOADED_IN_PATH" ] && loaded_in_path_during_aistack_run="ON"
		[ "$o" = "NOT_LOADED_IN_PATH" ] && not_loaded_in_path_during_aistack_run="ON"
	done

    if [ "${loaded_in_path_during_aistack_run}" = "ON" ]; then
        local _feature_schema=""
        local _feature_name=""
        local _feature_ver=""
        $STELLA_API select_official_schema "${f}" "_feature_schema" "_feature_name" "_feature_ver"
        list_contains "$FEATURE_LIST_ENABLED" "${_feature_name}#${_feature_ver}"
        return $?
    fi

    if [ "${not_loaded_in_path_during_aistack_run}" = "ON" ]; then
        # a component from stella framework NOT_LOADED_IN_PATH must be checked
        # with some special code checking binary presence in AISTACK_ISOLATED_ROOT 
        
        echo "WARN : this test mode for $f stella feature with path not loaded must be specificly coded in aistack_component_is_installed"
        return 2
    fi
}


# --------------- VARIOUS -----------------------------

# return 0 if list contains items, else 1
# list_contains "aa bb xx" "bb"
# echo $? ==> 0
# list_contains "aa bb xx" "b"
# echo $? ==> 1
# list_contains "aa bb xx" "bb xx"
# echo $? ==> 0
# list_contains "aa bb xx" "aa xx"
# echo $? ==> 1
# https://stackoverflow.com/a/20473191/5027535
# in a test : 
# if list_contains "aa bb xx" "bb"; then
# fi
list_contains() {
	local _list="$1"
	local _item="$2"
	[ "$_list" = "" ] && return 1
	[[ "$_list" =~ (^|[[:space:]])"$_item"($|[[:space:]]) ]]
}


# TODO : use this every where ?
# test if a binary is reachable in current PATH context
check_binary() {
	local b="${1}"
	command -v "${b}" >/dev/null 2>&1
}

# NOT used
get_platform() {
	local os_arch=""
	local platform=""

	case "${STELLA_CURRENT_PLATFORM}" in
		linux)
			[ "${STELLA_CURRENT_CPU_FAMILY}" = "intel" ] && os_arch="linux_amd64"
            [ "${STELLA_CURRENT_CPU_FAMILY}" = "arm" ] && os_arch="linux_arm64"
			platform="${os_arch}"
			if [ -f /lib/libc.musl-x86_64.so.1 ] || [ -f /lib/libc.musl-aarch64.so.1 ] || ldd /bin/ls 2>&1 | grep -q musl; then
				platform="${platform}_musl"
			fi
			;;
		darwin)
            [ "${STELLA_CURRENT_CPU_FAMILY}" = "intel" ] && os_arch="darwin_amd64"
            [ "${STELLA_CURRENT_CPU_FAMILY}" = "arm" ] && os_arch="darwin_arm64"
			platform="${os_arch}"
			;;
		*)
			echo "ERROR: Unsupported architecture: ${STELLA_CURRENT_CPU_FAMILY}" >&2
			return 1
			;;
	esac

	printf '%s' "${platform}"
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

	if [ -z "$port" ]; then
        echo "ERROR: missing port"
        return 1
    fi

    case "$port" in
        ''|*[!0-9]*)
            echo "ERROR: invalid port: $port"
            return 1
            ;;
    esac

    if command -v lsof >/dev/null 2>&1; then
        pid=$(lsof -t -i:"$port" 2>/dev/null)
    fi

	if [ "${STELLA_CURRENT_PLATFORM}" = "linux" ]; then

		# Older Linux fallback only
		if [ "$pid" = "" ]; then
			if command -v netstat >/dev/null 2>&1; then
				# WARN to get PID or process name with netstat, we need to be root user
				pid=$(netstat -ltnp 2>/dev/null | awk -v port=":$port$" '$4 ~ port {split($7, a, "/"); print a[1]; exit}')
			fi
		fi
	fi

    if [ -n "$pid" ]; then
        # lsof can return multiple PIDs (as a newline-separated string), so we loop
        for p in $pid; do
            echo "Killing process on port $port with PID $p"
            kill -9 "$p"
        done
    else
        echo "ERROR: lsof nor netstat able to find process."
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

# Sample:
# remove_dir_except_names "$HOME/.gemini" \
#     "antigravity-cli" \
#	  "GEMINI.md" \
#  	  "settings.json"
remove_dir_with_exceptions() {
    local target_dir="$1"
    shift

    if [ -z "$target_dir" ]; then
        echo "ERROR: missing target_dir" >&2
        return 1
    fi

    if [ "$#" -eq 0 ]; then
        echo "ERROR: missing names to keep" >&2
        return 1
    fi

    [ -d "$target_dir" ] || return 0

    local find_args=()
    local keep_name

    for keep_name in "$@"; do
        find_args+=( ! -name "$keep_name" )
    done

    find "$target_dir" -mindepth 1 -maxdepth 1 \
        "${find_args[@]}" \
        -exec rm -rf -- {} +
}

# add a PATH env variable by configuring shell rc files
path_register_for_shell() {
    local name="$1"
	local path_to_add="$2"
    local shell_name="$3"

    local rc_file
	local err=0

	if [ -z "$path_to_add" ]; then
        echo "ERROR: No path to add parameter provided."
        return 1
    fi

	if [ -z "$shell_name" ]; then
        echo "ERROR: No shell name provided."
        return 1
    fi

    local BEGIN_MARK="# >>> aistack-${name}-path >>>"
    local END_MARK="# <<< aistack-${name}-path <<<"

	[ "$shell_name" = "all" ] && shell_list="bash zsh fish" || shell_list="$shell_name"

	for s in $shell_list; do
		# TODO : for bash also modify $HOME/.bash_profile ?
		[ "$s" = "bash" ] && rc_file="$HOME/.bashrc"
		[ "$s" = "zsh" ] && rc_file="$HOME/.zshrc"
		[ "$s" = "fish" ] && rc_file="$HOME/.config/fish/config.fish"

		case "$s" in
			"bash"|"zsh")
				[ -f "$rc_file" ] && path_unregister_for_shell "$name" "$s" 1>/dev/null 2>&1 || touch "$rc_file"
				if ! grep -Fq "$BEGIN_MARK" "$rc_file"; then
					{
						echo "$BEGIN_MARK"
						echo "export PATH=\"${path_to_add}:\$PATH\""
						echo "$END_MARK"
					} >> "$rc_file"
				fi
    			echo "- register $name PATH for shell $s"
				;;
			"fish")
				mkdir -p "$(dirname "$rc_file")"
				[ -f "$rc_file" ] && path_unregister_for_shell "$name" "$s" 1>/dev/null 2>&1 || touch "$rc_file"
				if ! grep -Fq "$BEGIN_MARK" "$rc_file"; then
					{
						echo "$BEGIN_MARK"
						echo "set -gx PATH \"${path_to_add}\" \$PATH"
						echo "$END_MARK"
					} >> "$rc_file"
				fi
    			echo "- register $name PATH for shell $s"
				;;
			*) 
				echo "ERROR : unsupported shell $s"
				err=1
				;;
		esac
	done

	return $err
}

# remove path
# use 'all' to unregister to all known shell
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
    				echo "- unregister $name PATH for shell $s"
                fi
                ;;
            *) 
                echo "ERROR : unsupported shell : $s"
                ;;
        esac
    done
}


# see https://github.com/StudioEtrange/glibc-binary-compat.git
glibc_binary_compat() {
    local binary="${1}"
    local search_folder="${2}"
    local custom_glibc_runtime_path="${3}"
    
	"$STELLA_API" link_to_glibc_binary_compat "${binary}" "${search_folder}" "${custom_glibc_runtime_path}"

}