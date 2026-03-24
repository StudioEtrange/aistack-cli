# node and nvm paths
node_path() {
    export AISTACK_NVM_HOME="${AISTACK_ISOLATED_DEPENDENCIES_ROOT}/nvm"
    mkdir -p "$AISTACK_NVM_HOME"
    export NVM_DIR="${AISTACK_NVM_HOME}"

    nvm_load
    node_activate
}


node_install() {
    nvm_install
    nvm_load

    nvm install --lts
    nvm alias default lts/*
}

node_uninstall() {
    node_deactivate
    nvm_uninstall
}

node_activate() {
    if check_requirements "nvm"; then
        nvm use default >/dev/null
    fi
}

node_deactivate() {
    if check_requirements "nvm"; then
        # will remove node from path
        nvm deactivate
    fi
}


nvm_install() {
    local version="$1"

    if [ -z "$version" ] || [ "$version" = "latest" ]; then
        echo "No version provided, fetching the latest version..."
        version=$(github_get_latest_release "nvm-sh/nvm")
       
        echo "latest version is ${version}"
    fi

    # PROFILE=/dev/null : do not edit shell config
    #NVM_DIR="${AISTACK_NVM_HOME}" PROFILE=/dev/null curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/${version}/install.sh | bash
    
    (
        git clone https://github.com/nvm-sh/nvm.git "$NVM_DIR"
        cd "$NVM_DIR"
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

    # --no-use This loads nvm, without auto-using the default version
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