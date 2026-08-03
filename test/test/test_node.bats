bats_load_library 'bats-assert'
bats_load_library 'bats-support'


setup() {
	load 'stella_bats_helper.bash'
}

teardown() {
    true
}


@test "nvm_install replaces an incomplete installation after a successful clone" {
	tmp="$(mktemp -d)"
	NVM_DIR="${tmp}/nvm"
	AISTACK_NVM_CACHE="${tmp}/nvm-cache"
	mkdir -p "${NVM_DIR}" "${AISTACK_NVM_CACHE}"
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
	assert_equal "$(readlink "${NVM_DIR}/.cache")" "${AISTACK_NVM_CACHE}"

	rm -rf "${tmp}"
}