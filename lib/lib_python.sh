python_init() {

    # a constraints do not install package bug constraint version if something wants to install the package
    # constraints for  quarantine
    export PIP_CONSTRAINT="${PIP_CONSTRAINT} ${AISTACK_POOL}/settings/python/constraint_quarantine.txt"
    export UV_CONSTRAINT="${UV_CONSTRAINT} ${AISTACK_POOL}/settings/python/constraint_quarantine.txt"

    # constraints for glibc 2.17
    case "${AISTACK_GLIBC_CURRENT_VERSION}" in
        "2.17") 
            # https://docs.astral.sh/uv/reference/environment/#uv_constraint
            export PIP_CONSTRAINT="${PIP_CONSTRAINT} ${AISTACK_POOL}/settings/python/constraint_glibc217.txt"
            export UV_CONSTRAINT="${UV_CONSTRAINT} ${AISTACK_POOL}/settings/python/constraint_glibc217.txt"
        ;;
    esac
}


# return 0 : is installed
# return 1 : tool is not installed
# return 2 : missing runtime
python_is_installed() {
    export AISTACK_RUNTIME_PYTHON_AVAILABLE="false"
    export AISTACK_MODULE_MAMBA_AVAILABLE="false"

	for r in ${AISTACK_RUNTIME_PYTHON_RUNTIME_REQUIRED}; do aistack_runtime_is_detected "${r}" || return 2; done
    
    if aistack_component_is_installed "python"; then
        export AISTACK_RUNTIME_PYTHON_AVAILABLE="true"
        export AISTACK_RUNTIME_PYTHON_PATH="${AISTACK_ISOLATED_ROOT}/miniforge3/bin/python"
        # bin folder which contains python
        export AISTACK_RUNTIME_PYTHON_SEARCH_PATH="$(dirname ${AISTACK_RUNTIME_PYTHON_PATH})"
        # mamba module is always included in miniforge3 installation
        export AISTACK_MODULE_MAMBA_AVAILABLE="true"
        export AISTACK_MODULE_MAMBA_PATH="${AISTACK_RUNTIME_PYTHON_SEARCH_PATH}/mamba"
        export AISTACK_MODULE_MAMBA_SEARCH_PATH="${AISTACK_RUNTIME_PYTHON_SEARCH_PATH}"
        # # modules that are installed at the same time as python runtime
        # for ingredient in "uv pipx"; do
        #     va="AISTACK_MODULE_${ingredient}_AVAILABLE"; vp="AISTACK_MODULE_${ingredient}_PATH";
        #     if aistack_component_is_installed "${ingredient}"; then
        #         printf -v "${va}" '%s' "true"; export ${va};
        #         printf -v "${vp}" '%s' "${AISTACK_RUNTIME_PYTHON_SEARCH_PATH}/${ingredient}"; export ${vp};
        #     fi
        # fi
        return 0
    else
        return 1
    fi
}

python_install() {
    #stella_feature_install "miniforge3" "NOT_LOADED_IN_PATH"
    aistack_component_install "miniforge3"

    # NOTE : Here $AISTACK_RUNTIME_PYTHON_SEARCH_PATH is empty so we launch aistack_runtime_detect
    # to set it to be able to install pipx and uv with mamba
    aistack_runtime_detect

    echo "-- upgrade pip"
    # TODO : not really usefull ?
    python_pip_package_install "pip"

    echo "-- install python pipx and uv package/project manager"
    aistack_module_install "pipx"
    aistack_module_install "uv"
}

python_uninstall() {
    echo "Uninstalling python"
    rm -Rf "${AISTACK_ISOLATED_ROOT}/miniforge3"
}