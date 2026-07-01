# node and nvm paths
node_init() {
    export AISTACK_NVM_HOME="${AISTACK_ISOLATED_ROOT}/nvm"
    mkdir -p "${AISTACK_NVM_HOME}"
    export NVM_DIR="${AISTACK_NVM_HOME}"

	# those functions are invoqued before runtime_detect
	# so we cannot use variable AISTACK_MODULE_NVM_AVAILABLE inside them
    nvm_load
    node_activate
}


node_install() {
    nvm_install
    nvm_load

    # install node LTS version
    nvm install --lts
    nvm alias default lts/*

    [ -n "${AISTACK_INIT_FORCE_NODE_GBC}" ] && node_glibc_compat
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

# see https://github.com/StudioEtrange/glibc-binary-compat.git
node_glibc_compat() {
    export GBC_FEAT_INSTALL_ROOT="${AISTACK_ISOLATED_ROOT}/glibc-binay-compat"
    mkdir -p "${GBC_FEAT_INSTALL_ROOT}"
    git clone "https://github.com/StudioEtrange/glibc-binary-compat.git" "${GBC_FEAT_INSTALL_ROOT}" 2>/dev/null
    echo "INFO: link Node.js binary with custom glibc in ${AISTACK_INIT_FORCE_NODE_GBC} built with GBC (https://github.com/StudioEtrange/glibc-binary-compat)"

    export CUSTOM_GLIBC_LINKER="${AISTACK_INIT_FORCE_NODE_GBC}/lib/ld-linux-x86-64.so.2"
    export CUSTOM_GLIBC_PATH="${AISTACK_INIT_FORCE_NODE_GBC}/lib:${AISTACK_INIT_FORCE_NODE_GBC}/rtlib}"

    "${GBC_FEAT_INSTALL_ROOT}/patch-with-custom-glibc.sh" "node" "${AISTACK_NVM_HOME}/" ${AISTACK_INIT_FORCE_NODE_GLIBC}
}

