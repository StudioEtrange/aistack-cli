bats_load_library 'bats-assert'
bats_load_library 'bats-support'


setup() {
	load 'stella_bats_helper.bash'
}

teardown() {
    true
}



@test "vscode_merge_config accepts a JSON file" {
	tmp1="$(mktemp)"
	tmp2="$(mktemp)"
	AISTACK_VSCODE_CONFIG_FILE="${tmp2}"

	printf '%s\n' '{"new_setting":"value"}' > "${tmp1}"
	printf '%s\n' '{"existing_setting":true}' > "${tmp2}"

	run vscode_merge_config "${tmp1}"
	assert_success
	assert_equal "$(jq -c . "${tmp2}")" '{"existing_setting":true,"new_setting":"value"}'

	rm -f "${tmp1}" "${tmp2}"
}


@test "vscode_merge_config accepts a JSON string" {
	tmp="$(mktemp)"
	AISTACK_VSCODE_CONFIG_FILE="${tmp}"
	printf '%s\n' '{"existing_setting":true}' > "${tmp}"

	run vscode_merge_config '{"new_setting":"value"}'
	assert_success
	assert_equal "$(jq -c . "${tmp}")" '{"existing_setting":true,"new_setting":"value"}'

	rm -f "${tmp}"
}


