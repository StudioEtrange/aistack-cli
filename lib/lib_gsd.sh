gsd_init() {
    export AISTACK_GSD_LAUNCHER_HOME=""

	export AISTACK_GSD_RUNTIME_REQUIRED="nodejs"
}

# return 0 : is installed
# return 1 : tool is not installed
# return 2 : missing runtime
gsd_is_installed() {
	local r
	export AISTACK_GSD_TOOL_AVAILABLE="false"
	for r in $AISTACK_GSD_RUNTIME_REQUIRED; do aistack_runtime_is_detected "${r}" || return 2; done
	export AISTACK_GSD_TOOL_PATH=""
	# GSD is considered always installable because it is a one shot installer/uninstaller
	export AISTACK_GSD_TOOL_AVAILABLE="true"
	return 0
}


gsd_install() {
    local version="@latest"
    # available versions : https://www.npmjs.com/package/@opengsd/gsd-core

	for r in ${AISTACK_GSD_RUNTIME_REQUIRED}; do 
		echo "Require needed ${r} managed runtime"
		aistack_runtime_require "${r}"
	done

    echo "Installing GSD"
	echo "Launching command : npx @opengsd/gsd-core${version} ${@}"
    PATH="${AISTACK_RUNTIME_NODEJS_SEARCH_PATH}:${STELLA_ORIGINAL_SYSTEM_PATH}" npx @opengsd/gsd-core${version} ${@}

	gsd_is_installed
}

gsd_uninstall() {
	local version="@latest"

	if aistack_runtime_is_detected "nodejs"; then
	    echo "Uinstalling GSD"
		echo "Launching command : npx @opengsd/gsd-core${version} ${@}"
		PATH="${AISTACK_RUNTIME_NODEJS_SEARCH_PATH}:${STELLA_ORIGINAL_SYSTEM_PATH}" npx @opengsd/gsd-core${version} ${@}
		gsd_is_installed
	else
		echo "WARN : missing a required managed runtime ${AISTACK_GSD_RUNTIME_REQUIRED}"
	fi
}

# GSD do not have a launcher
gsd_launcher_manage() {
	:
}


gsd_help() {
    local version="@latest"

	for r in ${AISTACK_GSD_RUNTIME_REQUIRED}; do 
		echo "Require needed ${r} managed runtime"
		aistack_runtime_require "${r}"
	done

    PATH="${AISTACK_RUNTIME_NODEJS_SEARCH_PATH}:${STELLA_ORIGINAL_SYSTEM_PATH}" npx @opengsd/gsd-core${version} -h

}