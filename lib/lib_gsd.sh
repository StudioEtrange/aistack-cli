gsd_init() {
	# GSD is a one shot installer/uninstaller and does not have a launcher or context
	export AISTACK_GSD_LAUNCHER_HOME=""
	export AISTACK_GSD_RUNTIME_REQUIRED="nodejs"
	export AISTACK_GSD_MODULE_REQUIRED=""
}

# test if GSD can be run
# return 0 : is installed
# return 1 : tool is not installed
# return 2 : missing runtime
gsd_is_installed() {
	local r m
	export AISTACK_GSD_TOOL_AVAILABLE="false"
	for r in ${AISTACK_GSD_RUNTIME_REQUIRED}; do aistack_runtime_is_detected "${r}" || return 2; done
	for m in ${AISTACK_GSD_MODULE_REQUIRED}; do aistack_module_is_detected "${m}" || return 2; done
	export AISTACK_GSD_TOOL_PATH=""
	# GSD is considered always installable because it is a one shot installer/uninstaller
	export AISTACK_GSD_TOOL_AVAILABLE="true"
	return 0
}


gsd_install() {
	local r m
	local version="@latest"
    # available versions : https://www.npmjs.com/package/@opengsd/gsd-core

	for r in ${AISTACK_GSD_RUNTIME_REQUIRED}; do
		echo "INFO: GSD require ${r} managed runtime"
		aistack_runtime_require "${r}"
	done
	for m in ${AISTACK_GSD_MODULE_REQUIRED}; do
		echo "INFO: GSD require ${m} managed module"
		aistack_module_require "${m}"
	done

    echo "Installing GSD"
	echo "Launching command : npx --yes @opengsd/gsd-core${version} --install ${@}"
	PATH="${AISTACK_RUNTIME_NODEJS_SEARCH_PATH}:${STELLA_ORIGINAL_SYSTEM_PATH}" npx --yes "@opengsd/gsd-core${version}" --install "${@}" || return $?

	gsd_is_installed
	return $?
}

gsd_uninstall() {
	local r m
	local version="@latest"

	if aistack_runtime_is_detected "nodejs"; then

		echo "Uninstalling GSD"
		echo "Launching command : npx @opengsd/gsd-core${version} ${@}"
		PATH="${AISTACK_RUNTIME_NODEJS_SEARCH_PATH}:${STELLA_ORIGINAL_SYSTEM_PATH}" npx "@opengsd/gsd-core${version}" --uninstall "${@}" || return $?
		return 0
	else
		echo "WARN : missing a required managed runtime ${AISTACK_GSD_RUNTIME_REQUIRED}"
		return 1
	fi
}

# GSD do not have a launcher
gsd_launcher_and_context_files_manage() {
	:
}


gsd_help() {
	local r m
	local version="@latest"

	for r in ${AISTACK_GSD_RUNTIME_REQUIRED}; do
		echo "INFO: GSD require ${r} managed runtime"
		aistack_runtime_require "${r}"
	done
	for m in ${AISTACK_GSD_MODULE_REQUIRED}; do
		echo "INFO: GSD require ${m} managed module"
		aistack_module_require "${m}"
	done

	PATH="${AISTACK_RUNTIME_NODEJS_SEARCH_PATH}:${STELLA_ORIGINAL_SYSTEM_PATH}" npx "@opengsd/gsd-core${version}" -h

}
