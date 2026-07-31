# node and nvm paths
node_init() {
    export AISTACK_NVM_HOME="${AISTACK_ISOLATED_ROOT}/nvm"
    mkdir -p "${AISTACK_NVM_HOME}"
    export NVM_DIR="${AISTACK_NVM_HOME}"

    # cache folder for NVM
    export AISTACK_NVM_CACHE="${STELLA_APP_CACHE_DIR}/nvm-cache"
    mkdir -p "${AISTACK_NVM_CACHE}"

    export AISTACK_RUNTIME_NODEJS_RUNTIME_REQUIRED=""

	# those functions are invoqued before runtime_detect
	# so we cannot use variable AISTACK_MODULE_NVM_AVAILABLE inside them
    nvm_load
    node_activate
}

# return 0 : is installed
# return 1 : tool is not installed
# return 2 : missing runtime
node_is_installed() {
    local r
    
    export AISTACK_RUNTIME_NODEJS_AVAILABLE="false"
    export AISTACK_MODULE_NPM_AVAILABLE="false"
    export AISTACK_MODULE_NVM_AVAILABLE="false"
	for r in ${AISTACK_RUNTIME_NODEJS_RUNTIME_REQUIRED}; do aistack_runtime_is_detected "${r}" || return 2; done


    if aistack_component_is_installed "nvm"; then
        export AISTACK_MODULE_NVM_AVAILABLE="true"
        if aistack_component_is_installed "nodejs"; then
            export AISTACK_RUNTIME_NODEJS_AVAILABLE="true"
            export AISTACK_RUNTIME_NODEJS_PATH="$(nvm which default)"
            # bin folder which contains node
            export AISTACK_RUNTIME_NODEJS_SEARCH_PATH="$(dirname ${AISTACK_RUNTIME_NODEJS_PATH})"
            # npm module is always included in nodejs installation
            export AISTACK_MODULE_NPM_AVAILABLE="true"
            export AISTACK_MODULE_NPM_PATH="${AISTACK_RUNTIME_NODEJS_SEARCH_PATH}/npm"
            export AISTACK_MODULE_NPM_SEARCH_PATH="${AISTACK_RUNTIME_NODEJS_SEARCH_PATH}"
            return 0
        fi
    fi
    return 1

}

node_install() {
    local r
    for r in $AISTACK_RUNTIME_NODEJS_RUNTIME_REQUIRED; do 
		echo "Require needed ${r} managed runtime"
		aistack_runtime_require "${r}"
	done
	
    node_nvm_install

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


node_nvm_install() {
    
    nvm_install
    nvm_load

    # install node LTS version
    if type nvm >/dev/null 2>&1; then
        nvm install --lts
        nvm alias default lts/*
    fi

    [ -n "${AISTACK_INIT_FORCE_NODE_GBC}" ] && glibc_binary_compat "node" "${AISTACK_NVM_HOME}" "${AISTACK_INIT_FORCE_NODE_GBC}"

}

node_uninstall() {
    node_deactivate
    nvm_uninstall
}

node_activate() {
    if type nvm >/dev/null 2>&1; then
        nvm use default >/dev/null
    fi
}

node_deactivate() {
    if type nvm >/dev/null 2>&1; then
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
    node_deactivate
    nvm_unload
    rm -rf "${AISTACK_NVM_HOME}"
}


nvm_load() {
    # undefined other nvm function installed outside of aistack
    nvm_unload

    # --no-use This loads nvm, without auto-using the default nodejs version
    if [ -f "$AISTACK_NVM_HOME/nvm.sh" ]; then
        . "$AISTACK_NVM_HOME/nvm.sh" --no-use
        export AISTACK_INTERNAL_NVM_LOADED="true"
    fi
}


nvm_unload() {

    
    # if type nvm >/dev/null 2>&1; then
    #     # will remove node from path # TODO : NOT SURE !
    #     nvm unload
    # fi
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
