bats_load_library 'bats-assert'
bats_load_library 'bats-support'


setup() {
	load 'stella_bats_helper.bash'
}

teardown() {
    true
}

@test "node isolated helpers reject a missing prefix before invoking npm" {
	AISTACK_MODULE_NPM_SEARCH_PATH="${BATS_TEST_TMPDIR}/missing npm"
	local helper
	for helper in node_isolated_package_install node_isolated_package_uninstall; do
		run "${helper}"
		assert_failure
		assert_output ''
	done
}

@test "node isolated helpers propagate configuration lookup failure without installing" {
	AISTACK_MODULE_NPM_SEARCH_PATH="${BATS_TEST_TMPDIR}/npm wrapper"
	mkdir -p "${AISTACK_MODULE_NPM_SEARCH_PATH}"
	cat > "${AISTACK_MODULE_NPM_SEARCH_PATH}/npm" <<'EOF'
#!/bin/sh
if [ "${1}" = config ]; then
	exit 42
fi
echo 'unexpected package operation'
exit 1
EOF
	chmod +x "${AISTACK_MODULE_NPM_SEARCH_PATH}/npm"
	local helper
	for helper in node_isolated_package_install node_isolated_package_uninstall; do
		run "${helper}" "${BATS_TEST_TMPDIR}/isolated prefix" test-package
		assert_equal "${status}" 42
		assert_output ''
	done
}

@test "node_install_version uses latest LTS when no version is provided" {
	AISTACK_MODULE_NVM_LOADED="true"
	AISTACK_INIT_FORCE_NODE_GBC=""
	nvm() { printf 'nvm %s\n' "$*"; }
	nvm_default_node_cache_remove() { echo "cache removed"; }
	nvm_default_node_activate() { echo "default activated"; }

	run node_install_version
	assert_success
	assert_output "$(printf '%s\n' 'nvm install --lts' 'nvm alias default lts/*' 'cache removed' 'default activated')"
}

@test "node_install_version selects supported explicit versions" {
	AISTACK_MODULE_NVM_LOADED="true"
	AISTACK_INIT_FORCE_NODE_GBC=""
	nvm() { printf 'nvm %s\n' "$*"; }
	nvm_default_node_cache_remove() { echo "cache removed"; }
	nvm_default_node_activate() { echo "default activated"; }
	local version
	for version in 22 22.14 22.14.0 v22.14.0; do
		run node_install_version "${version}"
		assert_success
		assert_output "$(printf '%s\n' "nvm install ${version}" "nvm alias default ${version}" 'cache removed' 'default activated')"
	done
}

@test "node_install_version rejects invalid versions before calling nvm" {
	AISTACK_MODULE_NVM_LOADED="true"
	nvm() { fail "nvm must not be called"; }
	local version
	for version in latest --lts '22 bad' '22;echo bad' 22. 22.14.0.1; do
		run node_install_version "${version}"
		assert_failure
		assert_output --partial "ERROR: invalid Node.js version:"
	done
}

@test "node_install_version fails when nvm is not loaded" {
	AISTACK_MODULE_NVM_LOADED="false"
	run node_install_version 22
	assert_failure
}

@test "node_install_version preserves default and cache on installation failure" {
	AISTACK_MODULE_NVM_LOADED="true"
	nvm() {
		[ "${1}" = "install" ] || fail "default must not change"
		return 3
	}
	nvm_default_node_cache_remove() { fail "cache must not change"; }
	run node_install_version 99999
	assert_equal "${status}" 3
}

@test "node_install honors the version environment variable" {
	AISTACK_RUNTIME_NODEJS_RUNTIME_REQUIRED=""
	AISTACK_RUNTIME_NODEJS_MODULE_REQUIRED=""
	AISTACK_INIT_FORCE_NPM_REGISTRY=""
	node_install_version() { echo "version ${1}"; }
	node_install_lts() { echo "latest LTS"; }
	node_is_installed() { return 0; }
	aistack_module_install() { return 0; }

	AISTACK_INIT_FORCE_NODE_VERSION=22 run node_install
	assert_success
	assert_output --partial "version 22"
	AISTACK_INIT_FORCE_NODE_VERSION="" run node_install
	assert_success
	assert_output --partial "latest LTS"
}

@test "node_install stops before installing packages when version installation fails" {
	AISTACK_RUNTIME_NODEJS_RUNTIME_REQUIRED=""
	AISTACK_RUNTIME_NODEJS_MODULE_REQUIRED=""
	AISTACK_INIT_FORCE_NODE_VERSION=99999
	node_install_version() { return 3; }
	node_is_installed() { fail "must not reuse the previous runtime"; }
	aistack_module_install() { fail "must not install packages"; }
	run node_install
	assert_equal "${status}" 3
}


@test "nvm_install replaces an incomplete installation after a successful clone" {
	tmp="$(mktemp -d)"
	NVM_DIR="${tmp}/nvm"
	AISTACK_NVM_BIN_CACHE="${tmp}/nvm-bin-cache"
	mkdir -p "${NVM_DIR}" "${AISTACK_NVM_BIN_CACHE}"
	printf '%s\n' 'partial installation' > "${NVM_DIR}/partial"

	git() {
		case "${1}" in
			clone)
				mkdir -p "${3}/.git"
				printf '%s\n' '# nvm test fixture' > "${3}/nvm.sh"
				;;
			checkout)
				return 0
				;;
		esac
	}

	run nvm_install "v-test"
	assert_success
	[ -s "${NVM_DIR}/nvm.sh" ]
	[ ! -e "${NVM_DIR}/partial" ]
	[ -L "${NVM_DIR}/.cache" ]
	assert_equal "$(readlink "${NVM_DIR}/.cache")" "${AISTACK_NVM_BIN_CACHE}"

	rm -rf "${tmp}"
}
