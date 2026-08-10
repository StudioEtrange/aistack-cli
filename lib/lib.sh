

# initialize global variables and folders
aistack_initialize() {

	export AISTACK_MANAGED_ENV="1"

    # components ---
    # runtime lists
    export AISTACK_RUNTIME_TO_DETECT="python nodejs bun rust"
	# runtimes required for AIStack
    # note : json5 core module require nodejs and nodejs require module nvm
    export AISTACK_RUNTIME_CORE="nodejs"

    # modules lists
    export AISTACK_MODULE_TO_DETECT="yq jq json5 uv pipx mamba npm pnpm cargo nvm"
	# modules required for AIStack - installed before everything else at init - MUST not depends on any runtimes
    export AISTACK_MODULE_CORE_BOOTSTRAP="yq nvm"
	# modules required for AIStack - installed after required runtime
    export AISTACK_MODULE_CORE="jq json5"
    # NOTE : json5 is a nodejs package to correct invalid json
    # https://github.com/json5/json5

    # remove from AISTACK_MODULE_CORE any items from AISTACK_MODULE_CORE_BOOTSTRAP
    AISTACK_MODULE_CORE="$($STELLA_API filter_list_with_list "${AISTACK_MODULE_CORE}" "${AISTACK_MODULE_CORE_BOOTSTRAP}")"

	# export variables and theirs values to a generic context file used when a tool is launched
	AISTACK_GENERIC_CONTEXT_EXPORT_VARIABLES="AISTACK_MANAGED_ENV"

    # export search path of runtimes and modules, only if they are installed, to a generic context file used when a tool is launched
	# NOTE : there is no AISTACK_GENERIC_CONTEXT_ADD_TOOL because each tool can be registered in shell wight "register" command
    # WARN : the content of AISTACK_RUNTIME_CORE/MODULE_CORE is not AUTOMATICLY exported and added in AISTACK_GENERIC_CONTEXT_ADD_RUNTIME/ADD_MODULE
	#				AISTACK_RUNTIME_CORE/MODULE_CORE is what is required by aistack itself
	#				AISTACK_GENERIC_CONTEXT_ADD_RUNTIME/ADD_MODULE is what is made available to tools, only if they are installed
	#export AISTACK_GENERIC_CONTEXT_ADD_RUNTIME="nodejs bun python"
    #export AISTACK_GENERIC_CONTEXT_ADD_MODULE="yq jq"
    [ -n "${AISTACK_GENERIC_CONTEXT_ADD_RUNTIME}" ] || $STELLA_API get_app_property "AISTACK" "GENERIC_CONTEXT_ADD_RUNTIME"
    [ -n "${AISTACK_GENERIC_CONTEXT_ADD_MODULE}" ] || $STELLA_API get_app_property "AISTACK" "GENERIC_CONTEXT_ADD_MODULE"


    # paths ---
	# we can override this value (usefull for unit tests)
    [ -n "${AISTACK_POOL}" ] || export AISTACK_POOL="${STELLA_APP_ROOT}/pool"

    export AISTACK_LAUNCHER_HOME="${STELLA_APP_WORK_ROOT}/launcher"
    mkdir -p "${AISTACK_LAUNCHER_HOME}"

    export AISTACK_MCP_LAUNCHER_HOME="${STELLA_APP_WORK_ROOT}/launcher-mcp"
    mkdir -p "${AISTACK_MCP_LAUNCHER_HOME}"

    export AISTACK_ISOLATED_ROOT="${STELLA_APP_WORK_ROOT}/isolated_dependencies"
    mkdir -p "${AISTACK_ISOLATED_ROOT}"

    export AISTACK_CONTEXT_HOME="${STELLA_APP_WORK_ROOT}/context"
    mkdir -p "${AISTACK_CONTEXT_HOME}"
    export AISTACK_GENERIC_CONTEXT_FILE="${AISTACK_CONTEXT_HOME}/generic_context.sh"

    export AISTACK_GLIBC_CURRENT_VERSION="$(glibc_version)"
	glibc_alternative_system

    # init variables ---
	node_init
    bun_init
	rust_init
    python_init

    # AISTACK_INIT_FORCE_VSCODE_MODE could be "remote" : means using vscode remote extension
    # AISTACK_INIT_FORCE_VSCODE_MODE could be empty "" : try to guess
	vscode_init "${AISTACK_INIT_FORCE_VSCODE_MODE}"

	gemini_init
	agy_init
    opencode_init
	openchamber_init
    cpa_init
    orla_init
    kilo_init
    bmad_init
	gsd_init
    adk_init
    asm_init
	playwright_init
	llmfit_init
    sktor_init
	ciss_init
}

aistack_info() {
    echo "--*== AIStack Informations ==*--"
    echo
	( aistack_component_core_is_detected >/dev/null 2>&1) \
		&& echo "AIStack core components are installed." \
		|| echo "AIStack core components are NOT installed. Please initialize AIStack."
    echo
	echo "CURRENT PLATFORM DETECTED: $STELLA_CURRENT_PLATFORM"
    echo "AISTACK_LAUNCHER_HOME: $AISTACK_LAUNCHER_HOME"
    echo "AISTACK_MCP_LAUNCHER_HOME: $AISTACK_MCP_LAUNCHER_HOME"
    echo "AISTACK_ISOLATED_ROOT: $AISTACK_ISOLATED_ROOT"
    echo "AISTACK_GENERIC_CONTEXT_FILE: $AISTACK_GENERIC_CONTEXT_FILE"
    echo 
	
    echo "--JavaScript ecosystem--"
    echo "AISTACK_NVM_HOME : $AISTACK_NVM_HOME"
    echo "NVM_DIR : $NVM_DIR"
    echo "NVM_BIN : $NVM_BIN"
    echo "NVM_INC : $NVM_INC"
    echo "AISTACK_NVM_CACHE (npm/npx): $AISTACK_NVM_CACHE"
    echo "AISTACK_NVM_DEFAULT_BIN_CACHE : $AISTACK_NVM_DEFAULT_BIN_CACHE"

    echo "AISTACK_MODULE_NVM_AVAILABLE : $AISTACK_MODULE_NVM_AVAILABLE"
    echo "AISTACK_MODULE_NVM_LOADED : $AISTACK_MODULE_NVM_LOADED"
   
    echo "AISTACK_RUNTIME_NODEJS_AVAILABLE: $AISTACK_RUNTIME_NODEJS_AVAILABLE"
    if [ "$AISTACK_RUNTIME_NODEJS_AVAILABLE" = "true" ]; then
        echo "AISTACK_RUNTIME_NODEJS_SEARCH_PATH: $AISTACK_RUNTIME_NODEJS_SEARCH_PATH"
        echo "AISTACK_RUNTIME_NODEJS_PATH: $AISTACK_RUNTIME_NODEJS_PATH"
        echo "AISTACK_MODULE_NPM_AVAILABLE: $AISTACK_MODULE_NPM_AVAILABLE"
        echo "NodeJS version: $($AISTACK_RUNTIME_NODEJS_PATH --version)"
        echo "NPM version: $(PATH="${AISTACK_RUNTIME_NODEJS_SEARCH_PATH}:${STELLA_ORIGINAL_SYSTEM_PATH}" npm --version)"
        echo "NPM cache dir: $(PATH="${AISTACK_RUNTIME_NODEJS_SEARCH_PATH}:${STELLA_ORIGINAL_SYSTEM_PATH}" npm --global config get cache)"
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
    echo "AISTACK_RUNTIME_BUN_AVAILABLE: $AISTACK_RUNTIME_BUN_AVAILABLE"
    if [ "$AISTACK_RUNTIME_BUN_AVAILABLE" = "true" ]; then
        echo "AISTACK_RUNTIME_BUN_SEARCH_PATH: $AISTACK_RUNTIME_BUN_SEARCH_PATH"
        echo "AISTACK_RUNTIME_BUN_PATH: $AISTACK_RUNTIME_BUN_PATH"
        echo "Bun version: $($AISTACK_RUNTIME_BUN_PATH --version)"
    fi

    echo
    echo "--python ecosystem--"
    echo "AISTACK_RUNTIME_PYTHON_AVAILABLE: $AISTACK_RUNTIME_PYTHON_AVAILABLE"
    if [ "$AISTACK_RUNTIME_PYTHON_AVAILABLE" = "true" ]; then
        echo "AISTACK_RUNTIME_PYTHON_SEARCH_PATH: $AISTACK_RUNTIME_PYTHON_SEARCH_PATH"
        echo "AISTACK_RUNTIME_PYTHON_PATH: $AISTACK_RUNTIME_PYTHON_PATH"
        echo "Python version: $($AISTACK_RUNTIME_PYTHON_PATH --version)"
    fi
    echo "AISTACK_MODULE_MAMBA_AVAILABLE: $AISTACK_MODULE_MAMBA_AVAILABLE"
    echo "Python packages constraints files - PIP_CONSTRAINT, PIP_BUILD_CONSTRAINT, UV_CONSTRAINT, UV_BUILD_CONSTRAINT: $UV_CONSTRAINT"
    echo
    echo "--rust ecosystem--"
    echo "AISTACK_RUNTIME_RUST_AVAILABLE: $AISTACK_RUNTIME_RUST_AVAILABLE"
    if [ "$AISTACK_RUNTIME_RUST_AVAILABLE" = "true" ]; then
        echo "AISTACK_RUNTIME_RUST_SEARCH_PATH: $AISTACK_RUNTIME_RUST_SEARCH_PATH"
        echo "AISTACK_RUNTIME_RUST_PATH: $AISTACK_RUNTIME_RUST_PATH"
        echo "Rust version: $($AISTACK_RUNTIME_RUST_PATH --version)"
    fi
    echo "AISTACK_MODULE_CARGO_AVAILABLE: $AISTACK_MODULE_CARGO_AVAILABLE"
    if [ "${AISTACK_MODULE_CARGO_AVAILABLE}" = "true" ]; then
		echo "Cargo version: $($AISTACK_MODULE_CARGO_PATH --version)"
    fi
    echo

    echo "--components management--"
	echo "AISTACK_RUNTIME_TO_DETECT: $AISTACK_RUNTIME_TO_DETECT"
	echo "AISTACK_RUNTIME_CORE: $AISTACK_RUNTIME_CORE"
    echo "AISTACK_MODULE_TO_DETECT: $AISTACK_MODULE_TO_DETECT"
	echo "AISTACK_MODULE_CORE: $AISTACK_MODULE_CORE"
	echo "AISTACK_MODULE_CORE_BOOTSTRAP: $AISTACK_MODULE_CORE_BOOTSTRAP"
    echo
    echo "AISTACK_GENERIC_CONTEXT_ADD_RUNTIME: $AISTACK_GENERIC_CONTEXT_ADD_RUNTIME"
    echo "AISTACK_GENERIC_CONTEXT_ADD_MODULE: $AISTACK_GENERIC_CONTEXT_ADD_MODULE"
    echo
	echo
    echo "--runtimes status--"
    local var name p
	while IFS= read -r var; do
		case "$var" in
			AISTACK_RUNTIME_*_AVAILABLE)
                name="${var#AISTACK_RUNTIME_}"
                name="${name%_AVAILABLE}"
                printf '%s available : %s\n' "$name" "${!var}"
                path_var="${var/_AVAILABLE/_PATH}"
                printf '%s path : %s\n' "$name" "${!path_var}"
                ;;
		esac
	done < <(compgen -v AISTACK_ | sort)
	echo
    echo "--modules status--"
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
	echo
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
    echo "--glibc runtime alternative system--"
    echo "Current glibc version AISTACK_GLIBC_CURRENT_VERSION: ${AISTACK_GLIBC_CURRENT_VERSION}"
	echo "Alternative glibc 2.17 path AISTACK_GLIBC_217_PATH: ${AISTACK_GLIBC_217_PATH}"
	echo "Alternative glibc 2.28 path AISTACK_GLIBC_228_PATH: ${AISTACK_GLIBC_228_PATH}"
	echo "Alternative glibc 2.39 path AISTACK_GLIBC_239_PATH: ${AISTACK_GLIBC_239_PATH}"
	echo "Node.js alternative glibc path AISTACK_INIT_FORCE_NODE_GBC: ${AISTACK_INIT_FORCE_NODE_GBC}"
	echo "Antigravity CLI alternative glibc path AISTACK_INIT_FORCE_AGY_GBC: ${AISTACK_INIT_FORCE_AGY_GBC}"
	echo "llmfit alternative glibc path AISTACK_INIT_FORCE_LLMFIT_GBC: ${AISTACK_INIT_FORCE_LLMFIT_GBC}"
    echo
	#echo "-- CURRENT SEARCH PATH --"
    #echo "PATH : $PATH"
}

aistack_init() {
	local mode="${1:-refresh}"

	case "${mode}" in
		"refresh")
			aistack_install_refresh
			;;
		"reinstall")
			aistack_install_purge
			;;
		*)
			echo "ERROR: unsupported init mode: ${mode}" >&2
			return 1
			;;
	esac
}

# only update/install mandatories components, keep installed tools and regenerate launcher and context files
aistack_install_refresh() {
	aistack_initialize

	aistack_component_core_install
	# NOTE: those calls are included in aistack_component_core_install
	#aistack_runtime_detect
	#aistack_module_detect

	aistack_tool_detect
	aistack_mcp_detect

	aistack_component_core_is_detected

	aistack_generic_context_file_generate
	aistack_launcher_and_context_files_regenerate

}

# uninstall everything to make a fresh install
aistack_install_purge() {
	aistack_uninstall 1>/dev/null

	aistack_initialize

	# after aistack_uninstall, we need to reset all runtime and modules variables (available, path, ...)
	aistack_runtime_detect
	aistack_module_detect
	aistack_tool_detect
	aistack_mcp_detect

	aistack_component_core_install
	# NOTE: those calls are included in aistack_component_core_install
	#aistack_runtime_detect
	#aistack_module_detect

	# NOTE: after aistack_uninstall, we do not have any tool or mcp installed yet
	#		unless in the future some tools will be considered as core and installed with aistack_component_core_install ?)
	#aistack_tool_detect
	#aistack_mcp_detect

	aistack_component_core_is_detected

	aistack_generic_context_file_generate
	aistack_launcher_and_context_files_regenerate

}

aistack_uninstall() {
	echo "INFO : clean various PATHs and values registered for shell"
	aistack_shell_purge

	echo "INFO : delete generated launcher and context files and folders"
	aistack_launcher_and_context_files_remove
	aistack_generic_context_file_remove
	rm -Rf "${AISTACK_MCP_LAUNCHER_HOME}"
    rm -Rf "${AISTACK_LAUNCHER_HOME}"
	rm -Rf "${AISTACK_CONTEXT_HOME}"

	echo "INFO : delete all components and runtimes"
     # remove isolated component (runtimes, tools)
    rm -Rf "${AISTACK_ISOLATED_ROOT}"
    # remove component from stella framework
    rm -Rf "${STELLA_APP_FEATURE_ROOT}"


    echo "INFO : delete AIStack working directory"
	rm -Rf "${STELLA_APP_WORK_ROOT}"

	# NOTE: we intentionnaly keep cache
	# TODO add an option to delete cache at install/uninstall
	#echo "INFO : delete NVM cache"
    #rm -Rf "${AISTACK_NVM_CACHE}"
	#echo "INFO : delete all cache"
	#rm -Rf "${STELLA_APP_CACHE_DIR}"
    
}

# --------------- CONTEXT MANAGEMENT -----------------------------
# inject into current aistack path, the search path of a list of runtimes
aistack_context_load_runtime_path() {
    local runtime_list="$1"
    local r va vp list_path

    for r in ${runtime_list}; do
        va="AISTACK_RUNTIME_$(printf '%s' "${r}" | tr '[:lower:]' '[:upper:]')_AVAILABLE"
        vp="AISTACK_RUNTIME_$(printf '%s' "${r}" | tr '[:lower:]' '[:upper:]')_SEARCH_PATH"
        [ "${!va}" = "true" ] && [ -n "${!vp}" ] && [ -d "${!vp}" ] && list_path="$($STELLA_API path_append_to_list "${list_path}" "${!vp}" "ALWAYS_PREPEND")"
    done
    [ -n "${list_path}" ] && export PATH="${list_path}:${PATH}"
}

# inject into current aistack path, the search path of a list of module
aistack_context_load_module_path() {
    local module_list="$1"
    local m va vp list_path

    for m in ${module_list}; do
        va="AISTACK_MODULE_$(printf '%s' "${m}" | tr '[:lower:]' '[:upper:]')_AVAILABLE"
        vp="AISTACK_MODULE_$(printf '%s' "${m}" | tr '[:lower:]' '[:upper:]')_SEARCH_PATH"
        [ "${!va}" = "true" ] && [ -n "${!vp}" ] && [ -d "${!vp}" ] && list_path="$($STELLA_API path_append_to_list "${list_path}" "${!vp}" "ALWAYS_PREPEND")"
    done
    [ -n "${list_path}" ] && export PATH="${list_path}:${PATH}"
}

# VARIABLE_LIST : consider list_path as variables names to append to path list PATH=${VAR}:$PATH
# VALUE_LIST : consider list_path as raw path to append to path list PATH=/foo/bar:$PATH
aistack_context_file_export_path() {
	local f="$1"
	local list_path="$2"
	local mode="${3:-VALUE_LIST}"

	local p list_path_to_export variable_list_to_export

	case "$mode" in
		"VARIABLE_LIST")
			for p in ${list_path}; do
				if [ -d "${!p}" ]; then
					variable_list_to_export="${p} ${variable_list_to_export}"
					list_path_to_export="$($STELLA_API path_append_to_list "${list_path_to_export}" "\${${p}}" "ALWAYS_PREPEND")"
				fi
			done
			;;
		"VALUE_LIST")
			for p in ${list_path}; do
				if [ -d "${p}" ]; then
					list_path_to_export="$($STELLA_API path_append_to_list "${list_path_to_export}" "${p}" "ALWAYS_PREPEND")"
				fi
			done
			;;
	esac

	# export variable used in VARIABLE_LIST
	[ -n "${variable_list_to_export}" ] && aistack_context_file_export_variables "${f}" "${variable_list_to_export}"

	# export PATH
	[ -n "${list_path_to_export}" ] && echo "export PATH=\"${list_path_to_export}:\${PATH}\"" >> "${f}"
}


# TODO : add type tool support ?
# add a runtime or module path into a context file
#		VARIABLE_LIST : add variable name to path list PATH=${VAR}:$PATH
# 		VALUE_LIST : add real path to path list PATH=/foo/bar:$PATH
aistack_context_path_add_component() {
	local type="$1"
	local name="$2"
	local mode="${3:-VALUE_LIST}"

	local path_to_add
	# NOTE : we do not check with if folder exists with, it will be checked later in aistack_context_file_export_path
	case "${type}" in
		"runtime")
			va="AISTACK_RUNTIME_$(printf '%s' "${name}" | tr '[:lower:]' '[:upper:]')_AVAILABLE"
        	vp="AISTACK_RUNTIME_$(printf '%s' "${name}" | tr '[:lower:]' '[:upper:]')_SEARCH_PATH"
		;;
		"module")
			va="AISTACK_MODULE_$(printf '%s' "${m}" | tr '[:lower:]' '[:upper:]')_AVAILABLE"
        	vp="AISTACK_MODULE_$(printf '%s' "${m}" | tr '[:lower:]' '[:upper:]')_SEARCH_PATH"
		;;
	esac

	case "$mode" in
		"VALUE_LIST")
			[ "${!va}" = "true" ] && [ -n "${!vp}" ] && path_to_add="${!vp}"
		;;
		"VARIABLE_LIST")
			[ "${!va}" = "true" ] && [ -n "${vp}" ] && path_to_add="${vp}"
		;;
	esac

	[ -n "${path_to_add}" ] && echo "${path_to_add}"
}

# add an export section of variable in a context file
aistack_context_file_export_variables() {
	local f="$1"
	local variable_list="$2"
	local v

	{
		for v in ${variable_list}; do
			printf '[ -n "$%s" ] || %s=%s; export %s\n' "$v" "$v" "$(shell_quote_posix "${!v}")" "$v"
		done
	} >> "${f}"
}


aistack_generic_context_file_generate() {
    local m r list_path

	# GENERATE CONTEXT FILE ----
    echo '#!/bin/sh' > "${AISTACK_GENERIC_CONTEXT_FILE}"
	chmod +x "${AISTACK_GENERIC_CONTEXT_FILE}"

	# VARIABLES
	aistack_context_file_export_variables "${AISTACK_GENERIC_CONTEXT_FILE}" "${AISTACK_GENERIC_CONTEXT_EXPORT_VARIABLES}"
	
	# PATH
    for r in ${AISTACK_GENERIC_CONTEXT_ADD_RUNTIME}; do
		list_path="$(aistack_context_path_add_component "runtime" "${r}" "VARIABLE_LIST") "${list_path}""
    done
    for m in ${AISTACK_GENERIC_CONTEXT_ADD_MODULE}; do
		list_path="$(aistack_context_path_add_component "module" "${m}" "VARIABLE_LIST") "${list_path}""
    done
	aistack_context_file_export_path "${AISTACK_GENERIC_CONTEXT_FILE}" "${list_path}" "VARIABLE_LIST"
}

aistack_generic_context_file_remove() {
    rm -f "${AISTACK_GENERIC_CONTEXT_FILE}"
}

aistack_launcher_and_context_files_remove() {
	aistack_tool_launcher_and_context_files_remove
	aistack_mcp_launcher_and_context_files_remove
}

aistack_launcher_and_context_files_regenerate() {
	aistack_tool_launcher_and_context_files_regenerate
	aistack_mcp_launcher_and_context_files_regenerate
}

# remove all injected value in shell rc files and vscide
aistack_shell_purge() {
	path_unregister_all_for_shell

	# NOTE: special case for openchamber to clean shell profile
	openchamber_disconnect_aistack "all"

    vscode_path_unregister_all_for_vs_terminal
}

# --------------- RUNTIME MANAGEMENT -----------------------------
# detect all installed managed runtimes
# equivalent to individual functions *_is_installed
aistack_runtime_detect() {
    local r e va vp

    for r in ${AISTACK_RUNTIME_TO_DETECT}; do
        
        case "${r}" in
            "python")
                python_is_installed
                ;;
            "nodejs")
                node_is_installed
                ;;
            "bun")
                bun_is_installed
                ;;
			"rust")
				rust_is_installed
				;;
        esac
    done

}


# check if a runtime have been detected as available
aistack_runtime_is_detected() {
    local r="${1}"
    local _var="AISTACK_RUNTIME_$(printf '%s' "${r}" | tr '[:lower:]' '[:upper:]')_AVAILABLE"

    [ "${!_var}" = "true" ] || return 1
    return 0
}

# check if a managed runtime is installed else install it
aistack_runtime_require() {
    local r="${1}"

    if ! aistack_runtime_is_detected "${r}"; then
        if ! aistack_runtime_install "${r}"; then
            echo "ERROR : error while requiring runtime ${r}"
            exit 1
        fi
        #aistack_runtime_detect
		#aistack_generic_context_file_generate
    fi

    # if ! aistack_runtime_is_detected "${r}"; then
    #     echo "ERROR : error while requiring runtime ${r}"
    #     exit 1
    # fi
}


# install managed runtime
aistack_runtime_install() {
    local r="$1"

    case "${r}" in
        "python")
            aistack_component_install "python"
            aistack_runtime_detect
			aistack_module_detect
			aistack_tool_detect
			aistack_generic_context_file_generate
			aistack_launcher_and_context_files_regenerate
            aistack_runtime_is_detected "python"
            return $?
            ;;
        "nodejs")
            aistack_component_install "nodejs"
            aistack_runtime_detect
			aistack_module_detect
			aistack_tool_detect
			aistack_generic_context_file_generate
			aistack_launcher_and_context_files_regenerate
            aistack_runtime_is_detected "nodejs"
            return $?
            ;;
        "bun")
            aistack_component_install "bun"
            aistack_runtime_detect
			aistack_module_detect
			aistack_tool_detect
			aistack_generic_context_file_generate
			aistack_launcher_and_context_files_regenerate
            aistack_runtime_is_detected "bun"
            return $?
            ;;
		"rust")
			aistack_component_install "rust"
            aistack_runtime_detect
			aistack_module_detect
			aistack_tool_detect
			aistack_generic_context_file_generate
			aistack_launcher_and_context_files_regenerate
            aistack_runtime_is_detected "rust"
            return $?
			;;
        *)
			echo "ERROR: Unknown runtime $r"
            return 1
            ;;
    esac
}

aistack_runtime_uninstall() {
    local r="$1"
	# NOTE: remove a runtime may remove some modules or tools instaleld INSIDE the runtime path
	#		thats why we need to redetect moodule and tool, and regenerate files because runtimes path may have changed
    case "${r}" in
        "python")
            python_uninstall
            aistack_runtime_detect
			aistack_module_detect
			aistack_tool_detect
			aistack_generic_context_file_generate
			aistack_launcher_and_context_files_regenerate
            ;;
        "nodejs")
            node_uninstall
            aistack_runtime_detect
			aistack_module_detect
			aistack_tool_detect
			aistack_generic_context_file_generate
			aistack_launcher_and_context_files_regenerate
            ;;
        "bun")
            bun_uninstall
            aistack_runtime_detect
			aistack_module_detect
			aistack_tool_detect
			aistack_generic_context_file_generate
			aistack_launcher_and_context_files_regenerate
            ;;
		"rust")
			rust_uninstall
            aistack_runtime_detect
			aistack_module_detect
			aistack_tool_detect
			aistack_generic_context_file_generate
			aistack_launcher_and_context_files_regenerate
			;;
         *)
			echo "ERROR: Unknown runtime $r"
            return 1
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
                export AISTACK_MODULE_JQ_AVAILABLE="false"
                if aistack_component_is_installed "${m}"; then
                    export AISTACK_MODULE_JQ_PATH="$(command -v jq)"
                    if [ -n "${AISTACK_MODULE_JQ_PATH}" ]; then
                        export AISTACK_MODULE_JQ_SEARCH_PATH="$(dirname ${AISTACK_MODULE_JQ_PATH})"
                        export AISTACK_MODULE_JQ_AVAILABLE="true"
                    fi
                fi
                ;;
            yq)
                export AISTACK_MODULE_YQ_AVAILABLE="false"
                if aistack_component_is_installed "${m}"; then
                    export AISTACK_MODULE_YQ_PATH="$(command -v yq)"
                    if [ -n "${AISTACK_MODULE_YQ_PATH}" ]; then
                        export AISTACK_MODULE_YQ_SEARCH_PATH="$(dirname ${AISTACK_MODULE_YQ_PATH})"
                        export AISTACK_MODULE_YQ_AVAILABLE="true"
                    fi
                fi
                ;;

            # nodejs modules -------
            json5)
                export AISTACK_MODULE_JSON5_AVAILABLE="false"
                if aistack_component_is_installed "${m}"; then
                    export AISTACK_MODULE_JSON5_AVAILABLE="true"
                    #export AISTACK_MODULE_JSON5_PATH="$(PATH="${AISTACK_RUNTIME_NODEJS_SEARCH_PATH}:${STELLA_ORIGINAL_SYSTEM_PATH}" command -v json5)"
                    export AISTACK_MODULE_JSON5_PATH="$AISTACK_RUNTIME_NODEJS_SEARCH_PATH/json5"
                    export AISTACK_MODULE_JSON5_SEARCH_PATH="$(dirname ${AISTACK_MODULE_JSON5_PATH})"

                fi
                ;;
            pnpm)
                export AISTACK_MODULE_PNPM_AVAILABLE="false"
                if aistack_component_is_installed "${m}"; then
                    export AISTACK_MODULE_PNPM_AVAILABLE="true"
                    export AISTACK_MODULE_PNPM_PATH="$AISTACK_RUNTIME_NODEJS_SEARCH_PATH/pnpm"
                    export AISTACK_MODULE_PNPM_SEARCH_PATH="$(dirname ${AISTACK_MODULE_PNPM_PATH})"

                fi
                ;;
            # python modules -------
            pipx)
                export AISTACK_MODULE_PIPX_AVAILABLE="false"
                if aistack_component_is_installed "${m}"; then
                    export AISTACK_MODULE_PIPX_AVAILABLE="true"
                    #export AISTACK_MODULE_PIPX_PATH="$(PATH="${AISTACK_RUNTIME_PYTHON_SEARCH_PATH}:${STELLA_ORIGINAL_SYSTEM_PATH}" command -v json5)"
                    export AISTACK_MODULE_PIPX_PATH="$AISTACK_RUNTIME_PYTHON_SEARCH_PATH/pipx"
                    export AISTACK_MODULE_PIPX_SEARCH_PATH="$(dirname ${AISTACK_MODULE_PIPX_PATH})"
                fi
                ;;
            uv)
                export AISTACK_MODULE_UV_AVAILABLE="false"
                if aistack_component_is_installed "${m}"; then
                    export AISTACK_MODULE_UV_AVAILABLE="true"
                    #export AISTACK_MODULE_UV_PATH="$(PATH="${AISTACK_RUNTIME_PYTHON_SEARCH_PATH}:${STELLA_ORIGINAL_SYSTEM_PATH}" command -v json5)"
                    export AISTACK_MODULE_UV_PATH="$AISTACK_RUNTIME_PYTHON_SEARCH_PATH/uv"
                    export AISTACK_MODULE_UV_SEARCH_PATH="$(dirname ${AISTACK_MODULE_UV_PATH})"
                fi
                ;;
            # various modules -------
            mamba|npm|cargo)
                # already detected at python/nodejs/rust runtime install
                ;;
			nvm)
                export AISTACK_MODULE_NVM_AVAILABLE="false"
				if aistack_component_is_installed "${m}"; then
					export AISTACK_MODULE_NVM_AVAILABLE="true"
				fi
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
        #aistack_module_detect
		#aistack_generic_context_file_generate
    fi

    if ! aistack_module_is_detected "${m}"; then
        echo "ERROR : error while requiring module ${m}"
        exit 1
    fi
}

aistack_module_install() {
    aistack_component_install "$@"
    aistack_module_detect
    aistack_generic_context_file_generate
}

# NOTE : we do not need to implements this function
# we never need to uninstall a specific module because all are mandatories and should not be removed
aistack_module_uninstall() {
    :
    # aistack_module_detect
    # aistack_generic_context_file_generate
}



# --------------- TOOL MANAGEMENT -----------------------------



aistack_tool_launcher_and_context_files_regenerate() (

	adk_launcher_and_context_files_manage "refresh_if_exists"
	agy_launcher_and_context_files_manage "refresh_if_exists"
	asm_launcher_and_context_files_manage "refresh_if_exists"
	playwright_launcher_and_context_files_manage "refresh_if_exists"
	bmad_launcher_and_context_files_manage "refresh_if_exists"
	cpa_launcher_and_context_files_manage "refresh_if_exists"
	gemini_launcher_and_context_files_manage "refresh_if_exists"
	gsd_launcher_and_context_files_manage "refresh_if_exists"
	kilo_launcher_and_context_files_manage "refresh_if_exists"
	opencode_launcher_and_context_files_manage "refresh_if_exists"
	openchamber_launcher_and_context_files_manage "refresh_if_exists"
	orla_launcher_and_context_files_manage "refresh_if_exists"
	llmfit_launcher_and_context_files_manage "refresh_if_exists"
	sktor_launcher_and_context_files_manage "refresh_if_exists"
	ciss_launcher_and_context_files_manage "refresh_if_exists"

)


aistack_tool_launcher_and_context_files_remove() (

	adk_launcher_and_context_files_manage "delete"
	agy_launcher_and_context_files_manage "delete"
	asm_launcher_and_context_files_manage "delete"
	playwright_launcher_and_context_files_manage "delete"
	bmad_launcher_and_context_files_manage "delete"
	cpa_launcher_and_context_files_manage "delete"
	gemini_launcher_and_context_files_manage "delete"
	gsd_launcher_and_context_files_manage "delete"
	kilo_launcher_and_context_files_manage "delete"
	opencode_launcher_and_context_files_manage "delete"
	openchamber_launcher_and_context_files_manage "delete"
	orla_launcher_and_context_files_manage "delete"
	llmfit_launcher_and_context_files_manage "delete"
	sktor_launcher_and_context_files_manage "delete"
	ciss_launcher_and_context_files_manage "delete"

)



# tools detect
aistack_tool_detect() {
	agy_is_installed
	asm_is_installed
	playwright_is_installed
	adk_is_installed
	bmad_is_installed
	cpa_is_installed
	gemini_is_installed
	gsd_is_installed
	kilo_is_installed
	opencode_is_installed
	orla_is_installed
	llmfit_is_installed
    sktor_is_installed
	ciss_is_installed
}


# --------------- MCP MANAGEMENT -----------------------------


aistack_mcp_detect() {
	:
}


aistack_mcp_launcher_and_context_files_regenerate() (
	# NOTE : for now, we do not use any launcher for mcp server
	:
)

aistack_mcp_launcher_and_context_files_remove() (
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

    echo "- Install some modules to bootstrap AIStack"
    for m in ${AISTACK_MODULE_CORE_BOOTSTRAP}; do
        aistack_component_install "${m}"
        aistack_module_detect
    done

    echo "- Install core mandatories runtimes managed by AIStack"
    for r in ${AISTACK_RUNTIME_CORE}; do
		# NOTE: aistack_runtime_install use each runtime installer which check themselves if we need to upgrade the already installed runtimes
        #aistack_runtime_require "${r}"
		aistack_runtime_install "${r}"
    done

	# NOTE: aistack_runtime_require include aistack_runtime_detect call
    #aistack_runtime_detect
	
	echo "- Install internal core mandatories modules for AIStack"
    for m in ${AISTACK_MODULE_CORE}; do
        aistack_component_install "${m}"
        aistack_module_detect
    done

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
               return 0
            fi
            return 1
            ;;
        # components NOT_LOADED_IN_PATH -----------
        miniforge3)
            [ -f "${AISTACK_ISOLATED_ROOT}/miniforge3/bin/python" ]
            return $?
            ;;
		llmfit)
            [ -f "${AISTACK_ISOLATED_ROOT}/llmfit/llmfit" ]
            return $?
            ;;
        # runtime --
        python)
            if aistack_component_is_installed "miniforge3"; then
                return 0
            fi
            return 1
            ;;
        nodejs)
            if [ "${AISTACK_MODULE_NVM_LOADED}" = "true" ]; then
                [ -n "${NVM_BIN}" ] && [ -x "${NVM_BIN}/node" ]
                return $?
            fi
            return 1
            ;;
        bun)
            [ -f "${AISTACK_ISOLATED_ROOT}/bun/bun" ]
            return $?
            ;;
		rust)
			[ -x "${RUST_FEAT_INSTALL_ROOT}/bin/rustc" ] && [ -x "${RUST_FEAT_INSTALL_ROOT}/bin/cargo" ]
			return $?
			;;
        # module -- runtime variables like AISTACK_RUNTIME_PYTHON_SEARCH_PATH are available
        mamba|pipx|uv)
            [ -f "${AISTACK_RUNTIME_PYTHON_SEARCH_PATH}/${c}" ]
            return $?
            ;;
        npm|json5|pnpm)
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
        miniforge3)
            stella_feature_install "miniforge3" "NOT_LOADED_IN_PATH"
            ;;
        # runtimes --
        python)
            python_install
            ;;
        nodejs)
            node_install
            ;;
        bun)
            bun_install
            ;;
		rust)
			rust_install
			;;
        # modules --
        nvm)
            nvm_install
            nvm_load
            ;;
        pipx|uv)
            aistack_runtime_require "python"
            PATH="${AISTACK_RUNTIME_PYTHON_SEARCH_PATH}:${STELLA_ORIGINAL_SYSTEM_PATH}" mamba install -y "${c}"
            ;;
        json5|pnpm) 
            aistack_runtime_require "nodejs"
            PATH="${AISTACK_RUNTIME_NODEJS_SEARCH_PATH}:${STELLA_ORIGINAL_SYSTEM_PATH}" npm install -g "${c}" 1>/dev/null
            [ $? -ne 0 ] && {
                echo "ERROR : installing module ${c}"
                return 1
            }
            ;;
        *)
            echo "ERROR : internal error in aistack_component_install : unknow omponent ${c}"
            exit 1
            ;;
    esac
}




# --------------- SPECIFIC INSTALLER -----------------------------


stella_feature_install() {
    local f="$1"
    local opt="$2"
    local o
    local loaded_in_path_during_aistack_run="ON"
	for o in $opt; do
		[ "$o" = "LOADED_IN_PATH" ] && loaded_in_path_during_aistack_run="ON"
		[ "$o" = "NOT_LOADED_IN_PATH" ] && loaded_in_path_during_aistack_run=""
	done

	# loaded_in_path_during_aistack_run
    if [ "${loaded_in_path_during_aistack_run}" = "ON" ]; then
        # PATH is injected in current and next aistack run context
        $STELLA_API get_feature "${f}"
    else
		# not_loaded_in_path_during_aistack_run
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

# f : stella feature schema
# return 0 : is installed
# return 1 : component is not installed
# return 2 : component do not support those options
stella_feature_installed() {
    local f="$1"
    local opt="$2"
    local o

    local loaded_in_path_during_aistack_run="ON"
	for o in $opt; do
		[ "$o" = "LOADED_IN_PATH" ] && loaded_in_path_during_aistack_run="ON"
		[ "$o" = "NOT_LOADED_IN_PATH" ] && loaded_in_path_during_aistack_run=""
	done

    if [ "${loaded_in_path_during_aistack_run}" = "ON" ]; then
		
		case "${f}" in
			# complex stella feature schema
			*'#'*|*'@'*|*':'*|*'/'*|*'\'*|*'!'*|*'%'*)
				;;
			# schema with name only
			*)
				case " ${FEATURE_LIST_ENABLED} " in
					*" ${f}#"*) return 0 ;;
					*) return 1 ;;
				esac
				;;
		esac

        local _feature_schema=""
        local _feature_name=""
        local _feature_ver=""
        $STELLA_API select_official_schema "${f}" "_feature_schema" "_feature_name" "_feature_ver"
		
		[ -n "${_feature_schema}" ] || return 1
		
		case " ${FEATURE_LIST_ENABLED} " in
			*" ${_feature_name}#${_feature_ver} "*) return 0 ;;
		esac

        return 1

	else
        # a component from stella framework NOT_LOADED_IN_PATH must be checked
        # with some special code checking binary presence in AISTACK_ISOLATED_ROOT 
        
        echo "WARN : this test mode for $f stella feature with path not loaded must be specificly coded in aistack_component_is_installed"
        return 2
    fi
}

# --------------- SHELL RC FILE MANAGEMENT -----------------------------


# add a PATH env variable by configuring shell rc files
path_register_for_shell() {
    local name="$1"
	local path_to_add="$2"
    local shell_name_list="${3:-all}"

    local rc_file
	local err=0

	if [ -z "$path_to_add" ]; then
        echo "ERROR: No path to add parameter provided."
        return 1
    fi

    local BEGIN_MARK="# >>> aistack-${name}-path >>>"
    local END_MARK="# <<< aistack-${name}-path <<<"

	[ "$shell_name_list" = "all" ] && shell_list="bash zsh fish" || shell_list="$shell_name_list"

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
    local shell_name_list="${2:-all}"

	if unregister_for_shell "aistack-${name}-path" "${shell_name_list}"; then
		echo "- unregister ${name} PATH for shell ${shell_name_list}"
	else
		return 1
	fi
}

path_unregister_all_for_shell() {
    local shell_name_list="${1:-all}"
	unregister_for_shell "aistack-*-path" "${shell_name_list}"
}

# remove a bloc from shell rc file
# bloc_name supports shell-style '*' and '?' wildcards
# use 'all' to unregister to all known shell
unregister_for_shell() {
	local bloc_name="${1}"
	local shell_name_list="${2:-all}"
	local shell_list
	local rc_file
	local tmp_file
	local s

	[ -n "${bloc_name}" ] || {
		echo "ERROR: block name is empty" >&2
		return 1
	}

	[ "${shell_name_list}" = "all" ] \
		&& shell_list="bash zsh fish" \
		|| shell_list="${shell_name_list}"

	for s in ${shell_list}; do
		case "${s}" in
			"bash")
				rc_file="${HOME}/.bashrc"
				;;
			"zsh")
				rc_file="${HOME}/.zshrc"
				;;
			"fish")
				rc_file="${HOME}/.config/fish/config.fish"
				;;
			*)
				echo "ERROR: unsupported shell: ${s}"
				return 1
				;;
		esac

		[ -f "${rc_file}" ] || continue

		if ! awk -v block_pattern="${bloc_name}" '
			function glob_matches(value, pattern, regex) {
				regex = pattern
				gsub(/[][\\.^$()+{}|]/, "\\\\&", regex)
				gsub(/[*]/, ".*", regex)
				gsub(/[?]/, ".", regex)
				return value ~ ("^" regex "$")
			}

			/^# >>> .* >>>$/ {
				block_name = $0
				sub(/^# >>> /, "", block_name)
				sub(/ >>>$/, "", block_name)
				if (glob_matches(block_name, block_pattern)) {
					found = 1
					exit
				}
			}

			END { exit found ? 0 : 1 }
		' "${rc_file}"; then
			continue
		fi

		tmp_file="$(mktemp "${rc_file}.aistack.XXXXXX")" || {
			echo "ERROR: unable to create temporary file for ${rc_file}" >&2
			return 1
		}

		if awk -v block_pattern="${bloc_name}" '
			function glob_matches(value, pattern, regex) {
				regex = pattern
				gsub(/[][\\.^$()+{}|]/, "\\\\&", regex)
				gsub(/[*]/, ".*", regex)
				gsub(/[?]/, ".", regex)
				return value ~ ("^" regex "$")
			}

			/^# >>> .* >>>$/ {
				block_name = $0
				sub(/^# >>> /, "", block_name)
				sub(/ >>>$/, "", block_name)
				if (glob_matches(block_name, block_pattern)) {
					skip = 1
					next
				}
			}

			skip && /^# <<< .* <<<$/ {
				block_name = $0
				sub(/^# <<< /, "", block_name)
				sub(/ <<<$/, "", block_name)
				if (glob_matches(block_name, block_pattern)) {
					skip = 0
					next
				}
			}

			!skip
		' "${rc_file}" > "${tmp_file}"; then
			mv "${tmp_file}" "${rc_file}" || {
				rm -f "${tmp_file}"
				return 1
			}
		else
			rm -f "${tmp_file}"
			return 1
		fi
	done
}


# --------------- GLIBC MANAGEMENT -----------------------------

glibc_version() {
	[ "${STELLA_CURRENT_PLATFORM}" = "darwin" ] && return 0

    ldd --version 2>/dev/null | awk '/ldd/{print $NF}' 2>/dev/null
}

# test if a glibc version fullfull the minimal required version
# by default, the glibc version tested is the current system glibc version
# glibc_version_require "2.17" # test if the glibc version on system match the minimal 2.17 requirement
# glibc_version_require "2.17" "3"  # test if a glibc version 3 match the minimal 2.17 requirement
# return 0 or 1
glibc_version_require() {
    local _minimal_ver="$1"
    local _tested_ver="$2"
    local _comparison
    
    [ -n "${_minimal_ver}" ] || return 1

    [ -z "${_tested_ver}" ] && _tested_ver="$(glibc_version)"
    [ -n "${_tested_ver}" ] || return 1

    _comparison="$(glibc_version_compare "${_tested_ver}" "${_minimal_ver}")"
    case "${_comparison}" in
        0|1) return 0;;
        *) return 1;;
    esac
}

# Usage :
#   glibc_version_compare "2.17" "2.28"
#
# print :
#   -1 if version1 < version2
#    0 if version1 = version2
#    1 if version1 > version2
glibc_version_compare() {
    local _version1="$1"
    local _version2="$2"
    local _part1
    local _part2

    while [ -n "$_version1" ] || [ -n "$_version2" ]; do
        _part1="${_version1%%.*}"
        _part2="${_version2%%.*}"

        [ "$_version1" = "$_part1" ] && _version1="" || _version1="${_version1#*.}"
        [ "$_version2" = "$_part2" ] && _version2="" || _version2="${_version2#*.}"

        [ -z "$_part1" ] && _part1=0
        [ -z "$_part2" ] && _part2=0

        # Le préfixe 10# évite l'interprétation octale, par exemple pour "08".
        _part1=$((10#$_part1))
        _part2=$((10#$_part2))

        if [ "$_part1" -lt "$_part2" ]; then
            printf '%s\n' '-1'
            return 0
        fi

        if [ "$_part1" -gt "$_part2" ]; then
            printf '%s\n' '1'
            return 0
        fi
    done

    printf '%s\n' '0'
}

# Print the first configured alternative glibc satisfying a minimum version.
glibc_alternative_path() {
	local _required_version="$1"
	local _version
	local _version_key
	local _path_var
	local _path

	[ -n "${_required_version}" ] || return 1

	for _version in 2.17 2.28 2.39; do
		if ! glibc_version_require "${_required_version}" "${_version}"; then
            continue
		fi

		_version_key="$(printf '%s' "${_version}" | tr -d '.')"
		_path_var="AISTACK_GLIBC_${_version_key}_PATH"
		_path="${!_path_var}"
		[ -n "${_path}" ] || continue

		if [ ! -d "${_path}" ]; then
			echo "WARN: ${_path_var} does not reference a directory: ${_path}" >&2
			continue
		fi

		printf '%s' "${_path}"
		return 0
	done

	return 1
}

# Configure each tool only when the system glibc does not meet its requirement.
# Explicit per-tool GBC paths always take precedence over automatic selection.
glibc_alternative_system() {
	local _path

	[ "${STELLA_CURRENT_PLATFORM}" = "darwin" ] && return 0

	[ -n "${AISTACK_GLIBC_CURRENT_VERSION}" ] || return 0

	if [ "$(glibc_version_compare "${AISTACK_GLIBC_CURRENT_VERSION}" "2.28")" = "-1" ]; then
		_path="$(glibc_alternative_path "2.28")"
		if [ -n "${_path}" ]; then
			[ -n "${AISTACK_INIT_FORCE_NODE_GBC}" ] || export AISTACK_INIT_FORCE_NODE_GBC="${_path}"
			[ -n "${AISTACK_INIT_FORCE_AGY_GBC}" ] || export AISTACK_INIT_FORCE_AGY_GBC="${_path}"
		fi
	fi

	if [ "$(glibc_version_compare "${AISTACK_GLIBC_CURRENT_VERSION}" "2.39")" = "-1" ]; then
		_path="$(glibc_alternative_path "2.39")"
		[ -n "${_path}" ] && [ -z "${AISTACK_INIT_FORCE_LLMFIT_GBC}" ] && export AISTACK_INIT_FORCE_LLMFIT_GBC="${_path}"
	fi
}

# see https://github.com/StudioEtrange/glibc-binary-compat.git
glibc_binary_compat() {
    local binary="${1}"
    local search_folder="${2}"
    local custom_glibc_runtime_path="${3}"
    
	"$STELLA_API" link_to_glibc_binary_compat "${binary}" "${search_folder}" "${custom_glibc_runtime_path}"

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

# TODO write unit test
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

