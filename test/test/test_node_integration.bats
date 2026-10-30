bats_load_library 'bats-assert'
bats_load_library 'bats-support'

setup() {
	load 'stella_bats_helper.bash'
	[ -x "${AISTACK_RUNTIME_NODEJS_PATH}" ] || {
		echo "ERROR: run with ./test/launch_test.sh node_integration" >&2
		return 1
	}
	[ -x "${AISTACK_MODULE_NPM_SEARCH_PATH}/npm" ] || return 1
	NODE_INTEGRATION_TMP="$(mktemp -d "${BATS_TEST_TMPDIR}/node-integration.XXXXXX")"
	NODE_INTEGRATION_PREFIX="${NODE_INTEGRATION_TMP}/isolated prefix"
	# Redirect even the global helpers away from the managed Node installation.
	export npm_config_prefix="${NODE_INTEGRATION_TMP}/global prefix"
	export npm_config_cache="${NODE_INTEGRATION_TMP}/npm cache"
	export npm_config_update_notifier=false
	export npm_config_audit=false
	export npm_config_fund=false
	# These fixtures do not need lifecycle scripts.
	export npm_config_ignore_scripts=true
	export PATH="${AISTACK_RUNTIME_NODEJS_SEARCH_PATH}:${PATH}"
}

teardown() {
	if [ -n "${NODE_INTEGRATION_TMP:-}" ]; then
		command rm -rf -- "${NODE_INTEGRATION_TMP}"
	fi
}

node_integration_assert_version() {
	local prefix="${1}"
	local package="${2}"
	local version="${3}"
	run "${AISTACK_RUNTIME_NODEJS_PATH}" -p "require(process.argv[1]).version" "${prefix}/lib/node_modules/${package}/package.json"
	assert_success
	assert_output "${version}"
}

# Exercise the real npm entrypoint without downloading or installing packages.
node_integration_with_path() (
	export PATH="${1}"
	shift
	"${@}"
)

node_integration_assert_npm_helpers() {
	local initial_path="${1}"
	local helper
	for helper in node_package_install node_package_uninstall node_isolated_package_install node_isolated_package_uninstall; do
		case "${helper}" in
			node_isolated_*)
				run node_integration_with_path "${initial_path}" "${helper}" "${NODE_INTEGRATION_PREFIX}" --version
				;;
			*)
				run node_integration_with_path "${initial_path}" "${helper}" --version
				;;
		esac
		assert_success
		assert_line --regexp '^[0-9]+\.[0-9]+\.[0-9]+$'
	done
}

@test "node integration npm helpers work without Node in the initial PATH" {
	local empty_path="${NODE_INTEGRATION_TMP}/empty path"
	mkdir -p "${empty_path}"
	# Scope PATH to the helper so Bats and teardown retain their normal tools.
	node_integration_assert_npm_helpers "${empty_path}"
}

@test "node integration isolated helpers preserve the configured registry without network access" {
	local real_npm="${AISTACK_MODULE_NPM_SEARCH_PATH}/npm"
	local helper
	unset npm_config_registry NPM_CONFIG_REGISTRY npm_config_globalconfig NPM_CONFIG_GLOBALCONFIG
	export npm_config_userconfig="${NODE_INTEGRATION_TMP}/user npmrc"
	export NPM_CONFIG_USERCONFIG="${npm_config_userconfig}"
	printf '' > "${npm_config_userconfig}"
	mkdir -p "${npm_config_prefix}/etc" "${NODE_INTEGRATION_TMP}/npm wrapper"
	printf '%s\n' 'registry=https://registry.local.org/' > "${npm_config_prefix}/etc/npmrc"

	# Demonstrate the original issue: --prefix changes the global config lookup.
	run "${real_npm}" config get registry --prefix "${NODE_INTEGRATION_PREFIX}" -g
	assert_success
	assert_output 'https://registry.npmjs.org/'

	# Replace only the package operation with a read-only query using real npm.
	export NODE_REGISTRY_TEST_NPM="${real_npm}"
	AISTACK_MODULE_NPM_SEARCH_PATH="${NODE_INTEGRATION_TMP}/npm wrapper"
	cat > "${AISTACK_MODULE_NPM_SEARCH_PATH}/npm" <<'EOF'
#!/bin/sh
case "${1}" in
	install|uninstall)
		shift
		[ "${1}" != --verbose ] || shift
		exec "${NODE_REGISTRY_TEST_NPM}" config get registry "${@}"
		;;
	*) exec "${NODE_REGISTRY_TEST_NPM}" "${@}" ;;
esac
EOF
	chmod +x "${AISTACK_MODULE_NPM_SEARCH_PATH}/npm"
	for helper in node_isolated_package_install node_isolated_package_uninstall; do
		run "${helper}" "${NODE_INTEGRATION_PREFIX}"
		assert_success
		assert_output 'https://registry.local.org/'
		npm_config_registry="https://override.local.org/" run "${helper}" "${NODE_INTEGRATION_PREFIX}"
		assert_success
		assert_output 'https://override.local.org/'
		printf '%s\n' 'registry=https://user.local.org/' > "${npm_config_userconfig}"
		run "${helper}" "${NODE_INTEGRATION_PREFIX}"
		assert_success
		assert_output 'https://user.local.org/'
		printf '' > "${npm_config_userconfig}"
		run "${helper}" "${NODE_INTEGRATION_PREFIX}" --registry=https://option.local.org/
		assert_success
		assert_output 'https://option.local.org/'
		printf '%s\n' 'registry=https://custom-config.local.org/' > "${NODE_INTEGRATION_TMP}/custom npmrc"
		npm_config_globalconfig="${NODE_INTEGRATION_TMP}/custom npmrc" run "${helper}" "${NODE_INTEGRATION_PREFIX}"
		assert_success
		assert_output 'https://custom-config.local.org/'
	done
}

@test "node integration npm helpers prefer managed Node over a system Node" {
	local fake_bin="${NODE_INTEGRATION_TMP}/fake system bin"
	mkdir -p "${fake_bin}"
	cat > "${fake_bin}/node" <<'EOF'
#!/bin/sh
echo 'ERROR: unexpected system Node' >&2
exit 42
EOF
	chmod +x "${fake_bin}/node"
	node_integration_assert_npm_helpers "${fake_bin}"
}

@test "node integration npm helpers preserve the caller PATH" {
	local original_path="${PATH}"
	# Do not use run: inspect the calling shell rather than a subshell.
	node_package_install --version >/dev/null
	assert_equal "${PATH}" "${original_path}"
	node_package_uninstall --version >/dev/null
	assert_equal "${PATH}" "${original_path}"
	node_isolated_package_install "${NODE_INTEGRATION_PREFIX}" --version >/dev/null
	assert_equal "${PATH}" "${original_path}"
	node_isolated_package_uninstall "${NODE_INTEGRATION_PREFIX}" --version >/dev/null
	assert_equal "${PATH}" "${original_path}"
}

@test "node integration installs and uninstalls a real global package in a temporary prefix" {
	run node_package_install 'semver@7.7.2'
	assert_success
	node_integration_assert_version "${npm_config_prefix}" semver 7.7.2
	[ -x "${npm_config_prefix}/bin/semver" ]
	run "${npm_config_prefix}/bin/semver" 1.2.3 -r '^1.0.0'
	assert_success
	assert_output '1.2.3'
	run node_package_uninstall semver
	assert_success
	[ ! -e "${npm_config_prefix}/lib/node_modules/semver" ]
	[ ! -e "${npm_config_prefix}/bin/semver" ]
	[ ! -L "${npm_config_prefix}/bin/semver" ]
}

@test "node integration installs and uninstalls a real isolated package with multiple scripts" {
	run node_isolated_package_install "${NODE_INTEGRATION_PREFIX}" 'cowsay@1.6.0'
	assert_success
	node_integration_assert_version "${NODE_INTEGRATION_PREFIX}" cowsay 1.6.0
	[ ! -e "${npm_config_prefix}/lib/node_modules/cowsay" ]
	run "${NODE_INTEGRATION_PREFIX}/bin/cowsay" 'aistack integration'
	assert_success
	assert_output --partial 'aistack integration'
	run "${NODE_INTEGRATION_PREFIX}/bin/cowthink" 'aistack integration'
	assert_success
	assert_output --partial 'aistack integration'
	run node_isolated_package_uninstall "${NODE_INTEGRATION_PREFIX}" cowsay
	assert_success
	[ ! -e "${NODE_INTEGRATION_PREFIX}/lib/node_modules/cowsay" ]
	[ ! -e "${NODE_INTEGRATION_PREFIX}/bin/cowsay" ]
	[ ! -L "${NODE_INTEGRATION_PREFIX}/bin/cowsay" ]
	[ ! -e "${NODE_INTEGRATION_PREFIX}/bin/cowthink" ]
	[ ! -L "${NODE_INTEGRATION_PREFIX}/bin/cowthink" ]
}

@test "node integration installs multiple isolated packages and preserves the remaining package on uninstall" {
	run node_isolated_package_install "${NODE_INTEGRATION_PREFIX}" 'semver@7.7.2' 'cowsay@1.6.0'
	assert_success
	node_integration_assert_version "${NODE_INTEGRATION_PREFIX}" semver 7.7.2
	node_integration_assert_version "${NODE_INTEGRATION_PREFIX}" cowsay 1.6.0
	run node_isolated_package_uninstall "${NODE_INTEGRATION_PREFIX}" cowsay
	assert_success
	[ ! -e "${NODE_INTEGRATION_PREFIX}/bin/cowsay" ]
	run "${NODE_INTEGRATION_PREFIX}/bin/semver" 2.3.4 -r '^2.0.0'
	assert_success
	assert_output '2.3.4'
	run node_isolated_package_uninstall "${NODE_INTEGRATION_PREFIX}" semver
	assert_success
	[ ! -e "${NODE_INTEGRATION_PREFIX}/lib/node_modules/semver" ]
}

@test "node integration reinstalls a global package at a requested version without affecting another prefix" {
	run node_isolated_package_install "${NODE_INTEGRATION_PREFIX}" 'semver@7.7.2'
	assert_success
	run node_package_install 'semver@7.7.1'
	assert_success
	node_integration_assert_version "${npm_config_prefix}" semver 7.7.1
	run node_package_install 'semver@7.7.2'
	assert_success
	node_integration_assert_version "${npm_config_prefix}" semver 7.7.2
	run node_package_uninstall semver
	assert_success
	[ ! -e "${npm_config_prefix}/bin/semver" ]
	node_integration_assert_version "${NODE_INTEGRATION_PREFIX}" semver 7.7.2
	run "${NODE_INTEGRATION_PREFIX}/bin/semver" 3.2.1
	assert_success
	assert_output '3.2.1'
	run node_isolated_package_uninstall "${NODE_INTEGRATION_PREFIX}" semver
	assert_success
}
