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

    export PIP_BUILD_CONSTRAINT="${PIP_CONSTRAINT}"
    export UV_BUILD_CONSTRAINT="${UV_CONSTRAINT}"


	# requirement - those will be installed and presence checked to run the current component
	# NOTE:	those search path will be injected in context file
    export AISTACK_RUNTIME_PYTHON_RUNTIME_REQUIRED=""
	export AISTACK_RUNTIME_PYTHON_MODULE_REQUIRED=""
	# remove from context any runtime or module any item already in generic aistack context
	export AISTACK_RUNTIME_PYTHON_RUNTIME_REQUIRED_IN_CONTEXT="$($STELLA_API filter_list_with_list "${AISTACK_RUNTIME_PYTHON_RUNTIME_REQUIRED}" "${AISTACK_GENERIC_CONTEXT_ADD_RUNTIME}")"
	export AISTACK_RUNTIME_PYTHON_MODULE_REQUIRED_IN_CONTEXT="$($STELLA_API filter_list_with_list "${AISTACK_RUNTIME_PYTHON_MODULE_REQUIRED}" "${AISTACK_GENERIC_CONTEXT_ADD_MODULE}")"


}


# return 0 : is installed
# return 1 : tool is not installed
# return 2 : missing runtime
python_is_installed() {
    local r m

    export AISTACK_RUNTIME_PYTHON_AVAILABLE="false"
	export AISTACK_RUNTIME_PYTHON_SEARCH_PATH=""
	export AISTACK_RUNTIME_PYTHON_PATH=""

    export AISTACK_MODULE_MAMBA_AVAILABLE="false"
	export AISTACK_MODULE_MAMBA_SEARCH_PATH=""
	export AISTACK_MODULE_MAMBA_PATH=""

	for r in ${AISTACK_RUNTIME_PYTHON_RUNTIME_REQUIRED}; do aistack_runtime_is_detected "${r}" || return 2; done
	for m in ${AISTACK_RUNTIME_PYTHON_MODULE_REQUIRED}; do aistack_module_is_detected "${m}" || return 2; done
    
    if aistack_component_is_installed "python"; then
        export AISTACK_RUNTIME_PYTHON_AVAILABLE="true"
        export AISTACK_RUNTIME_PYTHON_SEARCH_PATH="${AISTACK_ISOLATED_ROOT}/miniforge3/bin"
        export AISTACK_RUNTIME_PYTHON_PATH="${AISTACK_RUNTIME_PYTHON_SEARCH_PATH}/python"
        # mamba module is always included in miniforge3 installation
        export AISTACK_MODULE_MAMBA_AVAILABLE="true"
        export AISTACK_MODULE_MAMBA_SEARCH_PATH="${AISTACK_RUNTIME_PYTHON_SEARCH_PATH}"
        export AISTACK_MODULE_MAMBA_PATH="${AISTACK_MODULE_MAMBA_SEARCH_PATH}/mamba"
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
	local reinstall="${1:-false}"
    local r m
    for r in $AISTACK_RUNTIME_PYTHON_RUNTIME_REQUIRED; do 
		echo "INFO: python require needed ${r} managed runtime"
		aistack_runtime_require "${r}"
	done

	for m in $AISTACK_RUNTIME_PYTHON_MODULE_REQUIRED; do 
		echo "INFO: python require needed ${m} managed module"
		aistack_module_require "${m}"
	done

    #stella_feature_install "miniforge3" "NOT_LOADED_IN_PATH"
    aistack_component_install "miniforge3" "${reinstall}"

    # NOTE : Here $AISTACK_RUNTIME_PYTHON_SEARCH_PATH is empty so we launch aistack_runtime_detect
    # to set it to be able to install pipx and uv with mamba
    #aistack_runtime_detect
	python_is_installed || return 1


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


# ----------- packages management -----------

# NOTE: about uv tool install and uv pip install:
# 	uv tool install will put into bin folder only the tools scripts, not python binary
#	uv pip install will put the executable scripts AND the venv python binary 
#				=> it might be a problem when adding bin path to search path

# NOTES: uv functions abstract:
# - python_uv_package_install:
#     Installs packages using `uv pip install` in the current Python environment.
#
# - python_uv_isolated_package_clean_install:
#     Removes the target directory, creates a virtual environment with `uv venv`,
#     and installs packages using `uv pip install --prefix` in the target directory.
#
# - python_uv_isolated_package_install:
#     Creates a virtual environment with `uv venv` and installs packages
#     using `uv pip install --prefix` in the target directory, without prior cleanup.
#
# - python_uv_tool_install:
#     Uninstalls and reinstalls a tool using `uv tool uninstall` and `uv tool install`.
#
# - python_uv_isolated_tool_clean_install:
#     Removes the target directory and installs a tool using `uv tool install`
#     with custom `UV_TOOL_DIR` and `UV_TOOL_BIN_DIR` environment variables.
#
# - python_uv_isolated_tool_install:
#     Installs a tool using `uv tool install` with custom `UV_TOOL_DIR`
#     and `UV_TOOL_BIN_DIR` environment variables, without prior cleanup.


# install or reinstall/complete packages in current python env (default mamba env)
python_pip_package_install() {
    PATH="${AISTACK_RUNTIME_PYTHON_SEARCH_PATH}:${PATH}" pip install --no-cache-dir --no-binary=yara-x --force-reinstall --verbose "${@}"
}
python_pip_package_uninstall() {
	PATH="${AISTACK_RUNTIME_PYTHON_SEARCH_PATH}:${PATH}" pip uninstall --yes --verbose "${@}"
}


# install or reinstall/complete packages in current python env (default mamba env)
python_mamba_package_install() {
    PATH="${AISTACK_RUNTIME_PYTHON_SEARCH_PATH}:${PATH}" mamba install -y "${@}"
}
python_mamba_package_uninstall() {
    PATH="${AISTACK_RUNTIME_PYTHON_SEARCH_PATH}:${PATH}" mamba remove -y "${@}"
}

# install or reinstall/complete packages in current python env (default mamba env)
python_uv_package_install() {
	# NOTE : --python "${AISTACK_RUNTIME_PYTHON_PATH}" replace --system 
    PATH="${AISTACK_RUNTIME_PYTHON_SEARCH_PATH}:${PATH}" uv pip install --python "${AISTACK_RUNTIME_PYTHON_PATH}" --reinstall --verbose "${@}"
}
python_uv_package_uninstall() {
	# NOTE : --python "${AISTACK_RUNTIME_PYTHON_PATH}" replace --system
	PATH="${AISTACK_RUNTIME_PYTHON_SEARCH_PATH}:${PATH}" uv pip uninstall --python "${AISTACK_RUNTIME_PYTHON_PATH}" --verbose "${@}"
}

# install packages in a new created (and deleted before) dedicated isolated python venv
# install multiple packages sample :
# python_uv_isolated_package_clean_install \
#     "/foo/bar" \
#     black \
#     ruff
#
# tree folder created :
# /foo/bar/
# ├── bin/
# │   ├── python
# │   ├── black                  # Black CLI
# │   ├── blackd                 # Black daemon CLI
# │   ├── ruff                   # Ruff CLI
# │   ├── activate
# │   └── ...
# ├── lib/
# │   └── python3.12/
# │       └── site-packages/
# │           ├── black/                # Black package
# │           ├── black-*.dist-info/
# │           ├── ruff/                 # Ruff package
# │           ├── ruff-*.dist-info/
# │           ├── click/                # Black dependency
# │           ├── click-*.dist-info/
# │           └── ...
# ├── pyvenv.cfg
python_uv_isolated_package_clean_install() {
	local isolated_path="${1}"
	[ -n "${isolated_path}" ] || return 1
	shift
	
	[ "${#}" -gt 0 ] || {
		echo "ERROR: at least one package or tool is required" >&2
		return 1
	}

	# NOTE : delete and recreate venv - we do not use uv venv --clear option because it cannot delete non empty folder which might be an incomplete venv
	rm -Rf "${isolated_path}"
	# NOTE: --python "${AISTACK_RUNTIME_PYTHON_PATH}" force uv to use mamba default env as model to create a venv
	PATH="${AISTACK_RUNTIME_PYTHON_SEARCH_PATH}:${PATH}" uv venv --python "${AISTACK_RUNTIME_PYTHON_PATH}" "${isolated_path}" || return 1

	PATH="${AISTACK_RUNTIME_PYTHON_SEARCH_PATH}:${PATH}" uv pip install --python "${isolated_path}/bin/python" --reinstall --verbose "${@}"
}
# install packages in a new created if not exist dedicated isolated python venv
python_uv_isolated_package_install() {
	local isolated_path="${1}"
	[ -n "${isolated_path}" ] || return 1
	shift
	
	[ "${#}" -gt 0 ] || {
		echo "ERROR: at least one package or tool is required" >&2
		return 1
	}
	
	if [ ! -f "${isolated_path}/pyvenv.cfg" ]; then
		# NOTE: --python "${AISTACK_RUNTIME_PYTHON_PATH}" force uv to use mamba default env as model to create a venv
		PATH="${AISTACK_RUNTIME_PYTHON_SEARCH_PATH}:${PATH}" uv venv --python "${AISTACK_RUNTIME_PYTHON_PATH}" "${isolated_path}" || return 1
	fi
	if [ ! -x "${isolated_path}/bin/python" ]; then
		echo "ERROR: invalid Python venv: ${isolated_path}" >&2
		return 1
	fi

	PATH="${AISTACK_RUNTIME_PYTHON_SEARCH_PATH}:${PATH}" uv pip install --python "${isolated_path}/bin/python" --reinstall --verbose "${@}"
}


# uninstall packages from an isolated python venv
python_uv_isolated_package_uninstall() {
	local isolated_path="${1}"
	[ -n "${isolated_path}" ] || return 1
	shift

    if [ ! -f "${isolated_path}/pyvenv.cfg" ]; then
    	return 0
    fi

	PATH="${AISTACK_RUNTIME_PYTHON_SEARCH_PATH}:${PATH}" \
        uv pip uninstall \
            --python "${isolated_path}/bin/python" \
            --verbose \
            "$@"
}


# install or reinstall tools in tool root and in default mamba env
# python_uv_tool_install "<tools list>" "<options for uv install>"
#
# NOTE: argument 1 "<tools list>" do not suppoert tool name with space 
#			"black 'skillspector[mcp] @ git+https://github.com/NVIDIA/skillspector.git'" DO NOT WORK
#		argument 2 spaces within "<options for uv install>" are OK
#			"--with=/chemin avec espaces/dependency.whl" OR
#			--with '/chemin avec espaces/dependency.whl'
#
# Example:
# python_uv_tool_install "ruff black" "--verbose"
#
# /mamba/defaultenv/
# └── bin/
#     ├── python
#     └── uv
# ~/.local/ (default folder for uv tool install)
# ├── bin/
# │   ├── ruff
# │   └── black
# └── share/
#     └── uv/
#         └── tools/
#             ├── ruff/
#             │   ├── bin/python
#             │   ├── bin/ruff
#             │   ├── lib/python3.x/site-packages/
#             │   └── pyvenv.cfg
#             └── black/
#                 ├── bin/python
#                 ├── bin/black
#                 ├── lib/python3.x/site-packages/
#                 └── pyvenv.cfg
python_uv_tool_install() {
	local tool_list="${1}"
	[ -n "${tool_list}" ] || return 1
	shift 1

	local tool
	local tools=()

	IFS=' ' read -r -a tools <<< "${tool_list}"
	[ "${#tools[@]}" -gt 0 ] || {
		echo "ERROR: at least one tool is required" >&2
		return 1
	}

	# NOTE : do not pass to python_uv_tool_uninstall "$@" because some options could be not compatible with uv tool uninstall
	python_uv_tool_uninstall "${tool_list}" 2>/dev/null || true


	# NOTE: --python "${AISTACK_RUNTIME_PYTHON_PATH}" force uv to use mamba default env as model to create a venv
	for tool in "${tools[@]}"; do

		PATH="${AISTACK_RUNTIME_PYTHON_SEARCH_PATH}:${PATH}" \
				uv tool install \
					--python "${AISTACK_RUNTIME_PYTHON_PATH}" \
					--reinstall \
					--verbose \
					"$@" "${tool}" || return 1
	done
}
# Uninstall Python CLI tools from their isolated virtual environments and from tools root
# python_uv_tool_uninstall "<tools list>" "<options for uv tool uninstall>"
python_uv_tool_uninstall() {
	local tool_list="${1}"
	[ -n "${tool_list}" ] || return 1
	shift 1

	local tool
	local tool_name
	local tools=()

	IFS=' ' read -r -a tools <<< "${tool_list}"
	[ "${#tools[@]}" -gt 0 ] || {
		echo "ERROR: at least one tool is required" >&2
		return 1
	}

	for tool in "${tools[@]}"; do
		# NOTE: 'tool uninstall' command do not support format "black==25.1.0"
		tool_name="${tool%%[<>=!~\[]*}"

        PATH="${AISTACK_RUNTIME_PYTHON_SEARCH_PATH}:${PATH}" \
            uv tool uninstall \
                --verbose \
                "$@" "${tool_name}" || return 1
    done
}

# install tools in a NEW dedicated isolated python venv, delete it before if it exists
# python_uv_isolated_tool_clean_install "<isolated path>" "<tools list>" "<options for uv tool install>"
# Example:
# python_uv_isolated_tool_clean_install \
#     "/foo/bar" \
#     "black ruff" "--verbose"
#
# NOTE: argument 2 "<tools list>" do not suppoert tool name with space 
#			"black 'skillspector[mcp] @ git+https://github.com/NVIDIA/skillspector.git'" DO NOT WORK
#		argument 3 spaces within "<options for uv install>" are OK
#			"--with=/chemin avec espaces/dependency.whl" OR
#			--with '/chemin avec espaces/dependency.whl'
#
# /foo/bar/
# ├── bin/
# │   ├── black -> ../tools/black/bin/black
# │   └── ruff  -> ../tools/ruff/bin/ruff
# └── tools/
#     ├── black/
#     │   ├── bin/
#     │   │   ├── python
#     │   │   ├── black
#     │   │   └── activate
#     │   ├── lib/
#     │   │   └── python3.12/
#     │   │       └── site-packages/
#     │   │           ├── black/
#     │   │           ├── click/
#     │   │           ├── packaging/
#     │   │           └── ...
#     │   └── pyvenv.cfg
#     └── ruff/
#         ├── bin/
#         │   ├── python
#         │   ├── ruff
#         │   └── activate
#         ├── lib/
#         │   └── python3.12/
#         │       └── site-packages/
#         │           ├── ruff/
#         │           └── ...
#         └── pyvenv.cfg
python_uv_isolated_tool_clean_install() {
	local isolated_path="${1}"
	local tool_list="${2}"
	[ -n "${isolated_path}" ] || return 1
	[ -n "${tool_list}" ] || return 1
	shift 2

	rm -Rf "${isolated_path}"
	python_uv_isolated_tool_install "${isolated_path}" "${tool_list}" "${@}"
}
# add tools in a dedicated isolated python venv, creating it if not exists
# NOTE: argument 2 "<tools list>" do not suppoert tool name with space 
#			"black 'skillspector[mcp] @ git+https://github.com/NVIDIA/skillspector.git'" DO NOT WORK
#		argument 3 spaces within "<options for uv install>" are OK
#			"--with=/chemin avec espaces/dependency.whl" OR
#			--with '/chemin avec espaces/dependency.whl'
python_uv_isolated_tool_install() {
	local isolated_path="${1}"
	local tool_list="${2}"
	[ -n "${isolated_path}" ] || return 1
	[ -n "${tool_list}" ] || return 1
	shift 2
	
	local tool
	local tools=()

	IFS=' ' read -r -a tools <<< "${tool_list}"
	[ "${#tools[@]}" -gt 0 ] || {
		echo "ERROR: at least one tool is required" >&2
		return 1
	}

	# NOTE: --python "${AISTACK_RUNTIME_PYTHON_PATH}" force uv to use mamba default env as model to create a venv
	for tool in "${tools[@]}"; do

		# NOTE: adding UV_TOOL_BIN_DIR temporarly to PATH avoid an uv tool install warning about PATH
        UV_TOOL_DIR="${isolated_path}/tools" \
		UV_TOOL_BIN_DIR="${isolated_path}/bin" \
		PATH="${isolated_path}/bin:${AISTACK_RUNTIME_PYTHON_SEARCH_PATH}:${PATH}" \
				uv tool install \
					--python "${AISTACK_RUNTIME_PYTHON_PATH}" \
					--reinstall \
					--verbose \
					"$@" "${tool}" || return $?
	done

}
# uninstall list of tools from an isolated python venv and from tools root
# example
# python_uv_isolated_tool_uninstall \
# 	"/foo/bar" \
# 	"black ruff" \
# 	--offline

python_uv_isolated_tool_uninstall() {
    local isolated_path="${1}"
	local tool_list="${2}"
	[ -n "${isolated_path}" ] || return 1
	[ -n "${tool_list}" ] || return 1
	shift 2

	local tool
	local tool_name
	local tools=()

	IFS=' ' read -r -a tools <<< "${tool_list}"
	[ "${#tools[@]}" -gt 0 ] || {
		echo "ERROR: at least one tool is required" >&2
		return 1
	}

	for tool in "${tools[@]}"; do
		# NOTE: 'tool uninstall' command do not support format with special character "black==25.1.0"
		tool_name="${tool%%[<>=!~\[]*}"

        UV_TOOL_DIR="${isolated_path}/tools" \
		UV_TOOL_BIN_DIR="${isolated_path}/bin" \
		PATH="${AISTACK_RUNTIME_PYTHON_SEARCH_PATH}:${PATH}" \
            uv tool uninstall \
				--verbose \
                "${@}" "${tool_name}" || return 1
    done
}


# ---------------- special case -----------------------

# build yara-x wheel package
python_yara_x_package_build_wheel() {
	local version="${1:-v1.19.0}"
	local output_dir="${2}"
	local download_url
	local tmp_dir
	local target_python
	
	target_python="${AISTACK_RUNTIME_PYTHON_PATH}"

    aistack_runtime_require "rust"

	tmp_dir="$(mktemp -d)" || return 1
	download_url="https://github.com/VirusTotal/yara-x/archive/refs/tags/${version}.tar.gz"
	${STELLA_API} get_resource "yara-x" "${download_url}" "HTTP_ZIP" "${tmp_dir}" "DEST_ERASE STRIP"
	
	mkdir -p "${output_dir}"
	
	local build_status

	(
		cd "${tmp_dir}"

		aistack_context_load_runtime_path "rust"

		export MATURIN_NO_INSTALL_RUST=1
		python_pip_package_install "maturin" || return $?

		# cache cargo is in a subfolder of CARGO_HOME, which is by default ${HOME}/.cargo
		"${AISTACK_RUNTIME_PYTHON_SEARCH_PATH}/maturin" build \
				-vv \
				--release \
				--locked \
				--manifest-path "${tmp_dir}/py/Cargo.toml" \
				--out "${output_dir}" \
				--interpreter "${target_python}" || return $?

		local wheel wheel_built
		local wheel_found="false"

		# NOTE; build produce only one wheel
		for wheel in "${output_dir}"/yara_x-*.whl; do
			[ -f "${wheel}" ] || continue && wheel_built="${wheel}"
			wheel_found="true"
		done

		if [ "${wheel_found}" != "true" ]; then
			echo "ERROR: no yara-x wheel found after compilation" >&2
			return 1
		else
			echo -n "${wheel_built}"
		fi
	)
	build_status=$?

	rm -Rf "${tmp_dir}"

	return "${build_status}"
}

# buils and install yara-x package in default mamba python environment or in an isolated python venv
python_yara_x_package_build_install() {
	local version="${1:-v1.19.0}"
	local isolated_path="${2}"
	local tmp_dir
	local install_status

	tmp_dir="$(mktemp -d)" || return 1

	(
		python_yara_x_package_build_wheel "${version}" "${tmp_dir}" || return $?

		local wheel
		local wheel_found="false"

		for wheel in "${tmp_dir}"/yara_x-*.whl; do
			[ -f "${wheel}" ] || continue
			wheel_found="true"

			if [ -z "${isolated_path}" ]; then
				python_pip_package_install "${wheel}" || return $?
			else
				python_uv_isolated_package_install \
					"${isolated_path}" "${wheel}" || return $?
			fi
		done

		if [ "${wheel_found}" != "true" ]; then
			echo "ERROR: no yara-x wheel found after compilation" >&2
			return 1
		fi
	)
	install_status=$?

	rm -Rf "${tmp_dir}" || {
		[ "${install_status}" -ne 0 ] || return 1
	}

	return "${install_status}"
}

# TODO review this
# python_yara_x_package_uninstall() {
# 	python_pip_package_uninstall "yara-x"
# }
