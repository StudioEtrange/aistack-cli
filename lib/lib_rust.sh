rust_init() {
	export RUST_FEAT_INSTALL_ROOT="${AISTACK_ISOLATED_ROOT}/rust"
	mkdir -p "${RUST_FEAT_INSTALL_ROOT}"

	# requirement - those will be installed and presence checked to run the current component
	# NOTE:	those search path will be injected in context file
    export AISTACK_RUNTIME_RUST_RUNTIME_REQUIRED=""
	export AISTACK_RUNTIME_RUST_MODULE_REQUIRED=""
	# remove from context any runtime or module any item already in generic aistack context
	export AISTACK_RUNTIME_RUST_RUNTIME_REQUIRED_IN_CONTEXT="$($STELLA_API filter_list_with_list "${AISTACK_RUNTIME_RUST_RUNTIME_REQUIRED}" "${AISTACK_GENERIC_CONTEXT_ADD_RUNTIME}")"
	export AISTACK_RUNTIME_RUST_MODULE_REQUIRED_IN_CONTEXT="$($STELLA_API filter_list_with_list "${AISTACK_RUNTIME_RUST_MODULE_REQUIRED}" "${AISTACK_GENERIC_CONTEXT_ADD_MODULE}")"

}

# return 0 : is installed
# return 1 : runtime is not installed
# return 2 : missing runtime
rust_is_installed() {
	local r m

	export AISTACK_RUNTIME_RUST_AVAILABLE="false"
	export AISTACK_RUNTIME_RUST_SEARCH_PATH=""
	export AISTACK_RUNTIME_RUST_PATH=""

    export AISTACK_MODULE_CARGO_AVAILABLE="false"
	export AISTACK_MODULE_CARGO_SEARCH_PATH=""
	export AISTACK_MODULE_CARGO_PATH=""
	for r in ${AISTACK_RUNTIME_RUST_RUNTIME_REQUIRED}; do aistack_runtime_is_detected "${r}" || return 2; done
	for m in ${AISTACK_RUNTIME_RUST_MODULE_REQUIRED}; do aistack_module_is_detected "${m}" || return 2; done

	if aistack_component_is_installed "rust"; then
		export AISTACK_RUNTIME_RUST_AVAILABLE="true"
		export AISTACK_RUNTIME_RUST_SEARCH_PATH="${RUST_FEAT_INSTALL_ROOT}/bin"
		export AISTACK_RUNTIME_RUST_PATH="${AISTACK_RUNTIME_RUST_SEARCH_PATH}/rustc"
		
		# cargo module is always included in rust installation
        export AISTACK_MODULE_CARGO_AVAILABLE="true"
        export AISTACK_MODULE_CARGO_SEARCH_PATH="${RUST_FEAT_INSTALL_ROOT}/bin"
        export AISTACK_MODULE_CARGO_PATH="${AISTACK_MODULE_CARGO_SEARCH_PATH}/cargo"
        
		return 0
	fi

	return 1
}

# Download and install an official Rust standalone installer.
# See https://forge.rust-lang.org/infra/other-installation-methods.html
# NOTE: rust is always reinstalled in rust_install
rust_install() {
	local version="$1"
	local target=""
	local filename
	local ext
	local download_url
	local tmp_dir
	local install_status
	local r m

    for r in $AISTACK_RUNTIME_RUST_RUNTIME_REQUIRED; do 
		echo "INFO: rust require needed ${r} managed runtime"
		aistack_runtime_require "${r}"
	done

	for m in $AISTACK_RUNTIME_RUST_MODULE_REQUIRED; do 
		echo "INFO: rust require needed ${m} managed module"
		aistack_module_require "${m}"
	done

	if [ -z "${version}" ] || [ "${version}" = "latest" ]; then
		echo "No version provided, fetching the latest version..."
		version="$(github_get_latest_release "rust-lang/rust")" || return 1
		echo "latest version is ${version}"
	fi


	
	case "${STELLA_CURRENT_PLATFORM}:${STELLA_CURRENT_CPU_FAMILY}" in
		linux:intel)
			target="x86_64-unknown-linux-gnu"
			;;
		linux:arm)
			target="aarch64-unknown-linux-gnu"
			;;
		darwin:intel)
			target="x86_64-apple-darwin"
			;;
		darwin:arm)
			target="aarch64-apple-darwin"
			;;
		*)
			echo "ERROR: Unsupported Rust platform ${STELLA_CURRENT_PLATFORM}/${STELLA_CURRENT_CPU_FAMILY}"
			return 1
			;;
	esac

	#ext=".tar.xz"
	ext=".tar.gz"
	filename="rust-${version}-${target}${ext}"
	download_url="https://static.rust-lang.org/dist/${filename}"
	tmp_dir="$(mktemp -d)" || return 1

	echo "Downloading Rust ${version} from ${download_url}..."
	${STELLA_API} get_resource "Rust" "${download_url}" "HTTP_ZIP" "${tmp_dir}" "DEST_ERASE STRIP"

	if [ ! -x "${tmp_dir}/install.sh" ]; then
		echo "ERROR: Rust installer is missing from ${filename}"
		rm -Rf "${tmp_dir}"
		return 1
	fi

	rm -Rf "${RUST_FEAT_INSTALL_ROOT}"
	mkdir -p "${RUST_FEAT_INSTALL_ROOT}"

	# Exécution dans un sous-shell et depuis un répertoire stable.
	(
		cd / || exit 1
		"${tmp_dir}/install.sh" \
			--prefix="${RUST_FEAT_INSTALL_ROOT}" \
			--disable-ldconfig
	)
	install_status=$?

	rm -Rf "${tmp_dir}"

	if [ "${install_status}" -ne 0 ]; then
		echo "ERROR: Rust installation failed with status ${install_status}" >&2
		return 1
	fi
	
	if ! rust_is_installed; then
		echo "ERROR: Rust installation did not provide rustc and cargo"
		return 1
	fi

	echo "Rust installed successfully."
	return 0
}

rust_uninstall() {
	echo "Uninstalling Rust from ${RUST_FEAT_INSTALL_ROOT}..."
	rm -Rf "${RUST_FEAT_INSTALL_ROOT}"
	echo "Rust uninstalled successfully."
}
