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