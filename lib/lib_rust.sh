rust_init() {
	export RUST_FEAT_INSTALL_ROOT="${AISTACK_ISOLATED_ROOT}/rust"
	mkdir -p "${RUST_FEAT_INSTALL_ROOT}"
	export AISTACK_RUNTIME_RUST_RUNTIME_REQUIRED=""
}

# return 0 : is installed
# return 1 : runtime is not installed
# return 2 : missing runtime
rust_is_installed() {
	local r

	export AISTACK_RUNTIME_RUST_AVAILABLE="false"
    export AISTACK_MODULE_CARGO_AVAILABLE="false"

	for r in ${AISTACK_RUNTIME_RUST_RUNTIME_REQUIRED}; do
		aistack_runtime_is_detected "${r}" || return 2
	done

	if aistack_component_is_installed "rust"; then
		export AISTACK_RUNTIME_RUST_AVAILABLE="true"
		export AISTACK_RUNTIME_RUST_PATH="${RUST_FEAT_INSTALL_ROOT}/bin/rustc"
		export AISTACK_RUNTIME_RUST_SEARCH_PATH="${RUST_FEAT_INSTALL_ROOT}/bin"
		
		# cargo module is always included in rust installation
        export AISTACK_MODULE_CARGO_AVAILABLE="true"
        export AISTACK_MODULE_CARGO_PATH="${RUST_FEAT_INSTALL_ROOT}/bin/cargo"
        export AISTACK_MODULE_CARGO_SEARCH_PATH="${RUST_FEAT_INSTALL_ROOT}/bin"
        
		return 0
	fi

	return 1
}

# Download and install an official Rust standalone installer.
# See https://forge.rust-lang.org/infra/other-installation-methods.html
rust_install() {
	local version="$1"
	local target=""
	local filename
	local download_url
	local tmp_dir

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

	filename="rust-${version}-${target}.tar.xz"
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
	if ! "${tmp_dir}/install.sh" --prefix="${RUST_FEAT_INSTALL_ROOT}" --disable-ldconfig; then
		rm -Rf "${tmp_dir}"
		return 1
	fi

	rm -Rf "${tmp_dir}"
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
