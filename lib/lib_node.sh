# node and nvm paths
node_init() {
    export AISTACK_NVM_HOME="${AISTACK_ISOLATED_ROOT}/nvm"
    mkdir -p "${AISTACK_NVM_HOME}"
    export NVM_DIR="${AISTACK_NVM_HOME}"

    # cache folder for binaries downloaded by NVM
	export AISTACK_NVM_BIN_CACHE="${AISTACK_NVM_BIN_CACHE:-${STELLA_APP_CACHE_DIR}/nvm-bin-cache}"
    mkdir -p "${AISTACK_NVM_BIN_CACHE}"
	export AISTACK_NVM_DEFAULT_NODEJS_SEARCH_PATH="${AISTACK_NVM_HOME}/aistack-nvm-default-nodejs-search-path"

	# NVM lock parameters
	# allows recovery of a lock older than X minutes
	export NVM_INSTALL_LOCK_STALE=10
	# wait up to X seconds to acquire an installation lock before stop and fail
	export NVM_INSTALL_LOCK_TIMEOUT=60

	# requirement - those will be installed and presence checked to run the current component
	# NOTE:	those search path will be injected in context file
    export AISTACK_RUNTIME_NODEJS_RUNTIME_REQUIRED=""
	export AISTACK_RUNTIME_NODEJS_MODULE_REQUIRED="nvm"
	# remove from context any runtime or module any item already in generic aistack context
	export AISTACK_RUNTIME_NODEJS_RUNTIME_REQUIRED_IN_CONTEXT="$($STELLA_API filter_list_with_list "${AISTACK_RUNTIME_NODEJS_RUNTIME_REQUIRED}" "${AISTACK_GENERIC_CONTEXT_ADD_RUNTIME}")"
	export AISTACK_RUNTIME_NODEJS_MODULE_REQUIRED_IN_CONTEXT="$($STELLA_API filter_list_with_list "${AISTACK_RUNTIME_NODEJS_MODULE_REQUIRED}" "${AISTACK_GENERIC_CONTEXT_ADD_MODULE}")"


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
	export AISTACK_RUNTIME_NODEJS_SEARCH_PATH=""
	export AISTACK_RUNTIME_NODEJS_PATH=""
	export AISTACK_MODULE_NPM_SEARCH_PATH=""
	export AISTACK_MODULE_NPM_PATH=""

	for r in ${AISTACK_RUNTIME_NODEJS_RUNTIME_REQUIRED}; do aistack_runtime_is_detected "${r}" || return 2; done
	for m in ${AISTACK_RUNTIME_NODEJS_MODULE_REQUIRED}; do aistack_module_is_detected "${m}" || return 2; done

	if aistack_component_is_installed "nodejs"; then
		export AISTACK_RUNTIME_NODEJS_AVAILABLE="true"
		export AISTACK_RUNTIME_NODEJS_SEARCH_PATH="${NVM_BIN}"
		export AISTACK_RUNTIME_NODEJS_PATH="${AISTACK_RUNTIME_NODEJS_SEARCH_PATH}/node"
		# NOTE: module npm is considered always included in a nodejs installation, we do not call aistack_component_is_installed to test its existence
		export AISTACK_MODULE_NPM_AVAILABLE="true"
		export AISTACK_MODULE_NPM_SEARCH_PATH="${AISTACK_RUNTIME_NODEJS_SEARCH_PATH}"
		export AISTACK_MODULE_NPM_PATH="${AISTACK_MODULE_NPM_SEARCH_PATH}/npm"
		return 0
	fi
    return 1

}

node_install() {
	local version="${1:-${AISTACK_INIT_FORCE_NODE_VERSION:-}}"
	[ -z "${version}" ] || node_version_validate "${version}" || return $?

    local r m
    for r in $AISTACK_RUNTIME_NODEJS_RUNTIME_REQUIRED; do 
		echo "INFO: Nodejs require ${r} managed runtime"
		aistack_runtime_require "${r}"
	done

	for m in $AISTACK_RUNTIME_NODEJS_MODULE_REQUIRED; do 
		echo "INFO: Nodejs require ${m} managed module"
		aistack_module_require "${m}"
	done

	

	if [ -z "${version}" ]; then 
		node_install_lts || return $?
	else
		node_install_version "${version}" || return $? 
	fi

    # NOTE : Here $AISTACK_RUNTIME_NODEJS_SEARCH_PATH is empty so we launch aistack_runtime_detect
    # to set it to be able to install node package with npm
    #aistack_runtime_detect
	node_is_installed || return 1

    if [ -n "${AISTACK_INIT_FORCE_NPM_REGISTRY}" ]; then
        if [ "${AISTACK_MODULE_NPM_AVAILABLE}" = "true" ]; then
            "${AISTACK_MODULE_NPM_SEARCH_PATH}/npm" config set registry "${AISTACK_INIT_FORCE_NPM_REGISTRY}" -g
        else
            echo "WARN : can not set npm registry, npm is not available"
        fi
    fi

    echo "-- install pnpm"
    aistack_module_install "pnpm"
}


node_install_lts() {
	node_install_version
}

# Accept a major, major.minor or exact version, optionally prefixed with v.
node_version_validate() {
	if [[ ! "${1}" =~ ^v?[0-9]+(\.[0-9]+)?(\.[0-9]+)?$ ]]; then
		echo "ERROR: invalid Node.js version: ${1}; expected a version such as 22 or 22.14.0" >&2
		return 1
	fi
}

# install a version and set it as default version
node_install_version() {
	local version="${1}"

	[ "${AISTACK_MODULE_NVM_LOADED}" = "true" ] || return 1

	# Install Node.js, update the default alias, then refresh the cached binary path.
	if [ -n "${version}" ]; then
		nvm install "${version}" || return $?
		nvm alias default "${version}" || return $?
	else
		nvm install --lts || return $?
		nvm alias default 'lts/*' || return $?
	fi
	nvm_default_node_cache_remove
	nvm_default_node_activate || return $?

	if [ -n "${AISTACK_INIT_FORCE_NODE_GBC}" ]; then
		glibc_binary_compat "node" "${AISTACK_NVM_HOME}" "${AISTACK_INIT_FORCE_NODE_GBC}" || return $?
	fi
	return 0
}

node_uninstall() {
    nvm_uninstall
}

# select a nodejs version
# and fix NVM_BIN and NVM_INC variables
nvm_default_node_activate() {
	local cached_nvm_bin=""

	[ "${AISTACK_MODULE_NVM_LOADED}" = "true" ] || return 1

	if [ -f "${AISTACK_NVM_DEFAULT_NODEJS_SEARCH_PATH}" ]; then
		IFS= read -r cached_nvm_bin < "${AISTACK_NVM_DEFAULT_NODEJS_SEARCH_PATH}"
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

# generate file AISTACK_NVM_DEFAULT_NODEJS_SEARCH_PATH
nvm_default_node_cache_write() {
	local tmp_file

	[ -n "${NVM_BIN}" ] || return 1
	[ -x "${NVM_BIN}/node" ] || return 1

	tmp_file="${AISTACK_NVM_DEFAULT_NODEJS_SEARCH_PATH}.tmp.$$"
	printf '%s\n' "${NVM_BIN}" > "${tmp_file}" || return 1
	mv "${tmp_file}" "${AISTACK_NVM_DEFAULT_NODEJS_SEARCH_PATH}"
}

nvm_default_node_cache_remove() {
	rm -f "${AISTACK_NVM_DEFAULT_NODEJS_SEARCH_PATH}"
}


nvm_deactivate() {
    if [ "${AISTACK_MODULE_NVM_LOADED}" = "true" ]; then
        # will remove node from path
        nvm deactivate --silent
    fi
}


nvm_install() {
	local version="${1}"
	local install_dir

	if [ -z "${version}" ] || [ "${version}" = "latest" ]; then
		echo "No version provided, fetching the latest version..."
		version="$(github_get_latest_release "nvm-sh/nvm")"
		if [ -z "${version}" ]; then
			echo "ERROR: unable to determine latest NVM version" >&2
			return 1
		fi

		echo "latest version is ${version}"
	fi

	# PROFILE=/dev/null : do not edit shell config
    #NVM_DIR="${AISTACK_NVM_HOME}" PROFILE=/dev/null curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/${version}/install.sh | bash
    
	mkdir -p "$(dirname "${NVM_DIR}")" || return 1

	install_dir="$(mktemp -d "${NVM_DIR}.install.XXXXXX")" || return 1
	if ! git clone https://github.com/nvm-sh/nvm.git "${install_dir}" >/dev/null; then
		echo "ERROR: unable to clone NVM ${version}" >&2
		rm -rf "${install_dir}"
		return 1
	fi

	if ! (cd "${install_dir}" && git checkout "${version}" >/dev/null); then
		echo "ERROR: unable to checkout NVM ${version}" >&2
		rm -rf "${install_dir}"
		return 1
	fi

	if [ ! -s "${install_dir}/nvm.sh" ]; then
		echo "ERROR: invalid NVM installation for version ${version}" >&2
		rm -rf "${install_dir}"
		return 1
	fi

	rm -rf "${NVM_DIR}"
	if ! mv "${install_dir}" "${NVM_DIR}"; then
		echo "ERROR: unable to install NVM into ${NVM_DIR}" >&2
		rm -rf "${install_dir}"
		return 1
	fi

	# keep the NVM .cache/bin folder cache outside
	# but not .cache/locks and other folders
	if [ -d "${AISTACK_NVM_BIN_CACHE}" ] && [ ! -e "${NVM_DIR}/.cache/bin" ] && [ ! -L "${NVM_DIR}/.cache/bin" ]; then
		mkdir -p "${NVM_DIR}/.cache" || return 1
		ln -s "${AISTACK_NVM_BIN_CACHE}" "${NVM_DIR}/.cache/bin"
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
# npm install -g "@bar/foo"
# global prefix:
# /usr/local/
# .../nvm/versions/node/v24.x.x (sample in case of using nvm)
# ├── bin/
# │   └── foo -> ../lib/node_modules/@bar/foo/cli.js
# └── lib/
#     └── node_modules/
#         ├── @bar/
#         │   └── foo/
#         │       ├── cli.js
#         │       └── node_modules/   # Potential nested dependencies
#         └── ...                     # Shared dependencies
node_package_install() {
	PATH="${AISTACK_RUNTIME_NODEJS_SEARCH_PATH}:${PATH}" "${AISTACK_MODULE_NPM_SEARCH_PATH}/npm" install --verbose -g "${@}"
	#PATH="${AISTACK_RUNTIME_NODEJS_SEARCH_PATH}:${PATH}" npm install --verbose -g "${@}"
	#PATH="${AISTACK_RUNTIME_NODEJS_SEARCH_PATH}:${STELLA_ORIGINAL_SYSTEM_PATH}" npm install --verbose -g "${@}"
}
node_package_uninstall() {
	PATH="${AISTACK_RUNTIME_NODEJS_SEARCH_PATH}:${PATH}" "${AISTACK_MODULE_NPM_SEARCH_PATH}/npm" uninstall -g "${@}"
	#PATH="${AISTACK_RUNTIME_NODEJS_SEARCH_PATH}:${PATH}" npm uninstall -g "${@}"
	#PATH="${AISTACK_RUNTIME_NODEJS_SEARCH_PATH}:${STELLA_ORIGINAL_SYSTEM_PATH}" npm uninstall -g "${@}"
}

# NOTE : install or reinstall/complete package in its own tree
#
# npm install --prefix="/opt/prefix" -g "@bar/foo"
# /opt/prefix
# ├── bin/
# │   └── foo -> ../lib/node_modules/@bar/foo/cli.js
# └── lib/
#     └── node_modules/
#         ├── @bar/
#         │   └── foo/
#         │       ├── cli.js
#         │       └── node_modules/   # Potential nested dependencies
#         └── ...                     # Shared dependencies
node_isolated_package_install() {
	local prefix="${1}"
	local globalconfig
	[ -n "${prefix}" ] || return 1
	shift
	# Resolve configuration before --prefix changes npm's default globalconfig path.
	globalconfig="$(PATH="${AISTACK_RUNTIME_NODEJS_SEARCH_PATH}:${PATH}" "${AISTACK_MODULE_NPM_SEARCH_PATH}/npm" config get globalconfig)" || return $?
	PATH="${AISTACK_RUNTIME_NODEJS_SEARCH_PATH}:${PATH}" "${AISTACK_MODULE_NPM_SEARCH_PATH}/npm" install --verbose --globalconfig "${globalconfig}" --prefix "${prefix}" -g "${@}"
}
node_isolated_package_uninstall() {
	local prefix="${1}"
	local globalconfig
	[ -n "$prefix" ] || return 1
	shift
	globalconfig="$(PATH="${AISTACK_RUNTIME_NODEJS_SEARCH_PATH}:${PATH}" "${AISTACK_MODULE_NPM_SEARCH_PATH}/npm" config get globalconfig)" || return $?
	PATH="${AISTACK_RUNTIME_NODEJS_SEARCH_PATH}:${PATH}" "${AISTACK_MODULE_NPM_SEARCH_PATH}/npm" uninstall --globalconfig "${globalconfig}" --prefix "${prefix}"  -g "${@}"
}
