bun_path() {
    export BUN_FEAT_INSTALL_ROOT="$AISTACK_ISOLATED_DEPENDENCIES_ROOT/bun"
    mkdir -p "${BUN_FEAT_INSTALL_ROOT}"

    # when using bun install script, by default bun will install itself in $HOME/.bun
    #export BUN_INSTALL="${BUN_FEAT_INSTALL_ROOT}"
    #export BUN_INSTALL_CACHE_DIR="${BUN_FEAT_INSTALL_ROOT}/install/cache"
}


# Download and install bun from GitHub releases.
#   on https://github.com/oven-sh/bun/releases have several flavour
#   - bun-*-baseline - for older CPU without AVX2 support
#   - bun-*-profile - for debug purposes with more logging
#  see https://bun.sh/install for more details
# This function relies on the following environment variables to be set:
# - BUN_FEAT_INSTALL_ROOT: The directory where bun will be installed.
bun_install() {
    local version="$1"
    
    if [ -z "$version" ] || [ "$version" = "latest" ]; then
        echo "No version provided, fetching the latest version..."
        version=$(github_get_latest_release "oven-sh/bun")
        echo "latest version is ${version}"
    fi


    local os_arch
    case "$STELLA_CURRENT_PLATFORM" in
        "linux")
            [ "$STELLA_CURRENT_CPU_FAMILY" = "intel" ] && os_arch="linux-x64"
            [ "$STELLA_CURRENT_CPU_FAMILY" = "arm" ] && os_arch="linux-aarch64"
            ;;
        "darwin")
            [ "$STELLA_CURRENT_CPU_FAMILY" = "intel" ] && os_arch="darwin-x64"
            [ "$STELLA_CURRENT_CPU_FAMILY" = "arm" ] && os_arch="darwin-aarch64"
            ;;
    esac

    # If AVX2 isn't supported, use the -baseline build
    case "$STELLA_CURRENT_PLATFORM" in
        "darwin")
            if [[ $(sysctl -a | grep machdep.cpu | grep AVX2) == '' ]]; then
                os_arch="${os_arch}-baseline"
            fi
        ;;
        "linux")
            if [[ $(cat /proc/cpuinfo | grep avx2) = '' ]]; then
                os_arch="${os_arch}-baseline"
            fi
        ;;
    esac
    # TODO support muslc based linux distribution with bun-musl-*-*.zip releases
    local filename="bun-${os_arch}.zip"
    local download_url="https://github.com/oven-sh/bun/releases/download/${version}/${filename}"

    echo "Downloading and installing bun ${version} from ${download_url} to ${BUN_FEAT_INSTALL_ROOT}..."
    $STELLA_API get_resource "Bun" "${download_url}" "HTTP_ZIP" "$BUN_FEAT_INSTALL_ROOT" "DEST_ERASE STRIP"
    echo "Bun installed successfully."
}
 
bun_uninstall() {
    echo "Uninstalling Bun from ${BUN_FEAT_INSTALL_ROOT}..."
    rm -Rf "${BUN_FEAT_INSTALL_ROOT}"
    echo "Bun uninstalled successfully."
}
