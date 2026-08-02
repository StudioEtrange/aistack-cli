# node and nvm paths
node_init() {
    export AISTACK_NVM_HOME="${AISTACK_ISOLATED_ROOT}/nvm"
    mkdir -p "${AISTACK_NVM_HOME}"
    export NVM_DIR="${AISTACK_NVM_HOME}"

    # cache folder for NVM
    export AISTACK_NVM_CACHE="${STELLA_APP_CACHE_DIR}/nvm-cache"
    mkdir -p "${AISTACK_NVM_CACHE}"
	export AISTACK_NVM_DEFAULT_BIN_CACHE="${AISTACK_NVM_HOME}/aistack-default-bin"

    export AISTACK_RUNTIME_NODEJS_RUNTIME_REQUIRED=""
	export AISTACK_RUNTIME_NODEJS_MODULE_REQUIRED="nvm"

	if aistack_component_is_installed "nvm"; then
		export AISTACK_MODULE_NVM_AVAILABLE="true"

		# load nvm
		nvm_load
	
		# activate default node
		# only if a nodejs version was previously installed
		nvm_default_node_activate
	fi
}

# return 0 : is installed
# return 1 : tool is not installed
# return 2 : missing runtime
node_is_installed() {
    local r m

    export AISTACK_RUNTIME_NODEJS_AVAILABLE="false"
    export AISTACK_MODULE_NPM_AVAILABLE="false"

	for r in ${AISTACK_RUNTIME_NODEJS_RUNTIME_REQUIRED}; do aistack_runtime_is_detected "${r}" || return 2; done
	for m in ${AISTACK_RUNTIME_NODEJS_MODULE_REQUIRED}; do aistack_module_is_detected "${m}" || return 2; done

	if aistack_component_is_installed "nodejs"; then
		export AISTACK_RUNTIME_NODEJS_AVAILABLE="true"
		[ -n "${NVM_BIN}" ] && export AISTACK_RUNTIME_NODEJS_PATH="${NVM_BIN}/node"
		# bin folder which contains node
		[ -n "${NVM_BIN}" ] && export AISTACK_RUNTIME_NODEJS_SEARCH_PATH="${NVM_BIN}"
		# npm module is always included in nodejs installation
		export AISTACK_MODULE_NPM_AVAILABLE="true"
		export AISTACK_MODULE_NPM_PATH="${AISTACK_RUNTIME_NODEJS_SEARCH_PATH}/npm"
		export AISTACK_MODULE_NPM_SEARCH_PATH="${AISTACK_RUNTIME_NODEJS_SEARCH_PATH}"
		return 0
	fi
    return 1

}

node_install() {
    local r
    for r in $AISTACK_RUNTIME_NODEJS_RUNTIME_REQUIRED; do 
		echo "INFO: Nodejs require ${r} managed runtime"
		aistack_runtime_require "${r}"
	done

	for m in $AISTACK_RUNTIME_NODEJS_MODULE_REQUIRED; do 
		echo "INFO: Nodejs require ${m} managed module"
		aistack_module_require "${m}"
	done

	
    node_install_lts

    # NOTE : Here $AISTACK_RUNTIME_NODEJS_SEARCH_PATH is empty so we launch aistack_runtime_detect
    # to set it to be able to install node package with npm
    aistack_runtime_detect

    if [ -n "${AISTACK_INIT_FORCE_NPM_REGISTRY}" ]; then
        if [ "$AISTACK_MODULE_NPM_AVAILABLE" = "true" ]; then
            "${AISTACK_MODULE_NPM_SEARCH_PATH}/npm" config set registry "${AISTACK_INIT_FORCE_NPM_REGISTRY}" -g
        else
            echo "WARN : can not set npm registry, npm is not available"
        fi
    fi

    echo "-- install pnpm"
    aistack_module_install "pnpm"
}


node_install_lts() {
	[ "${AISTACK_MODULE_NVM_LOADED}" = "true" ] || return 1

	# Install Node.js, update the default alias, then refresh the cached binary path.
	nvm install --lts || return $?
	nvm alias default 'lts/*' || return $?
	nvm_default_node_cache_remove
	nvm_default_node_activate || return $?

    [ -n "${AISTACK_INIT_FORCE_NODE_GBC}" ] && glibc_binary_compat "node" "${AISTACK_NVM_HOME}" "${AISTACK_INIT_FORCE_NODE_GBC}"
}

node_uninstall() {
    nvm_uninstall
}

# select a nodejs version
nvm_default_node_activate() {
	local cached_nvm_bin=""

	[ "${AISTACK_MODULE_NVM_LOADED}" = "true" ] || return 1

	if [ -f "${AISTACK_NVM_DEFAULT_BIN_CACHE}" ]; then
		IFS= read -r cached_nvm_bin < "${AISTACK_NVM_DEFAULT_BIN_CACHE}"
		case "${cached_nvm_bin}" in
			"${AISTACK_NVM_HOME}"/versions/node/*/bin)
				if [ -x "${cached_nvm_bin}/node" ]; then
					export NVM_BIN="${cached_nvm_bin}"
					export NVM_INC="${cached_nvm_bin%/bin}"
					export NVM_INC="${NVM_INC}/include/node"
					case ":${PATH}:" in
						*":${NVM_BIN}:"*) ;;
						*) export PATH="${NVM_BIN}:${PATH}" ;;
					esac
					return 0
				fi
				;;
		esac
	fi

	# Resolve the default alias only when the cache is missing or stale.
	nvm use default >/dev/null || return $?
	nvm_default_node_cache_write || :
	return 0
}

nvm_default_node_cache_write() {
	local tmp_file

	[ -n "${NVM_BIN}" ] || return 1
	[ -x "${NVM_BIN}/node" ] || return 1

	tmp_file="${AISTACK_NVM_DEFAULT_BIN_CACHE}.tmp.$$"
	printf '%s\n' "${NVM_BIN}" > "${tmp_file}" || return 1
	mv "${tmp_file}" "${AISTACK_NVM_DEFAULT_BIN_CACHE}"
}

nvm_default_node_cache_remove() {
	rm -f "${AISTACK_NVM_DEFAULT_BIN_CACHE}"
}


nvm_deactivate() {
    if [ "${AISTACK_MODULE_NVM_LOADED}" = "true" ]; then
        # will remove node from path
        nvm deactivate
    fi
}


nvm_install() {
    local version="$1"

    if [ -z "${version}" ] || [ "${version}" = "latest" ]; then
        echo "No version provided, fetching the latest version..."
        version=$(github_get_latest_release "nvm-sh/nvm")
       
        echo "latest version is ${version}"
    fi

    # PROFILE=/dev/null : do not edit shell config
    #NVM_DIR="${AISTACK_NVM_HOME}" PROFILE=/dev/null curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/${version}/install.sh | bash
    
    (
        git clone https://github.com/nvm-sh/nvm.git "${NVM_DIR}"
        cd "${NVM_DIR}"
        git checkout "${version}"
    ) >/dev/null

    # special case to manage NVM cache outside of NVM install dir
    mkdir -p "${NVM_DIR}"
    if [ -d "${AISTACK_NVM_CACHE}" ]; then
        ln -s "${AISTACK_NVM_CACHE}" "${NVM_DIR}/.cache"
    fi


}

nvm_uninstall() {
    nvm_deactivate
    nvm_unload
	nvm_default_node_cache_remove
    rm -rf "${AISTACK_NVM_HOME}"
}

nvm_is_loaded() {
    # check if nvm alias command is loaded
	if type nvm >/dev/null 2>&1; then
		export AISTACK_MODULE_NVM_LOADED="true"
		return 0
	fi
	export AISTACK_MODULE_NVM_LOADED="false"
    return 1

}

nvm_load() {
    # undefined other nvm function installed outside of aistack
    nvm_unload

    # --no-use This loads nvm, without auto-using the default nodejs version
    if [ -f "$AISTACK_NVM_HOME/nvm.sh" ]; then
        . "$AISTACK_NVM_HOME/nvm.sh" --no-use
        export AISTACK_MODULE_NVM_LOADED="true"
    fi

	nvm_is_loaded
}


nvm_unload() {
    # if aistack_module_is_detected "nvm"; then
    #     # will remove node from path # TODO : NOT SURE !
    #     nvm unload
    # fi
    export AISTACK_MODULE_NVM_LOADED="false"
    unset -f nvm
}







# note : install or reinstall/complete package
node_package_install() {
	PATH="${AISTACK_RUNTIME_NODEJS_SEARCH_PATH}:${PATH}" npm install --verbose -g "${@}"
	#PATH="${AISTACK_RUNTIME_NODEJS_SEARCH_PATH}:${STELLA_ORIGINAL_SYSTEM_PATH}" npm install --verbose -g "${@}"
}
node_package_uninstall() {
	PATH="${AISTACK_RUNTIME_NODEJS_SEARCH_PATH}:${PATH}" npm uninstall -g "${@}"
	#PATH="${AISTACK_RUNTIME_NODEJS_SEARCH_PATH}:${STELLA_ORIGINAL_SYSTEM_PATH}" npm uninstall -g "${@}"
}
