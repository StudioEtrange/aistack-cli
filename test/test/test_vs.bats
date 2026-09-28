bats_load_library 'bats-assert'
bats_load_library 'bats-support'


setup() {
	load 'stella_bats_helper.bash'
}

teardown() {
    true
}

@test "vscode_init uses SUDO_USER home" {
	local test_bin="${BATS_TEST_TMPDIR}/bin"
	local target_home="${BATS_TEST_TMPDIR}/sudo user home"
	local target_user="$(id -un)"
	mkdir -p "${test_bin}"
	mkdir -p "${target_home}/Library/Application Support/Code/User"
	cat > "${test_bin}/sudo" <<EOF
#!/bin/sh
printf '%s\n' '${target_home}'
EOF
	chmod +x "${test_bin}/sudo"
	STELLA_CURRENT_PLATFORM="darwin"
	export SUDO_USER="${target_user}"
	export PATH="${test_bin}:${PATH}"

	user_init
	vscode_init "local"

	assert_equal "${AISTACK_USER}" "${target_user}"
	assert_equal "${AISTACK_USER_HOME}" "${target_home}"
	assert_equal "${HOME}" "${target_home}"
	assert_equal "${AISTACK_VSCODE_CONFIG_FILE}" "${target_home}/Library/Application Support/Code/User/settings.json"
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


@test "vscode_merge_config merges VS Code proxy settings in one call" {
	tmp="$(mktemp)"
	AISTACK_VSCODE_CONFIG_FILE="${tmp}"
	export HTTP_PROXY="http://proxy.example.test:3128"
	export HTTPS_PROXY="http://proxy.example.test:3128"
	export http_proxy="http://proxy.example.test:3128"
	export https_proxy="http://proxy.example.test:3128"
	printf '%s\n' '{}' > "${tmp}"

	run vscode_merge_config '{
		"http.proxy": "http://proxy.example.test:3128",
		"http.noProxy": ["*.foo.com", "localhost", "127.0.0.1"],
		"http.proxyStrictSSL": false,
		"terminal.integrated.env.linux.HTTP_PROXY": "${HTTP_PROXY}",
		"terminal.integrated.env.linux.HTTPS_PROXY": "${HTTPS_PROXY}",
		"terminal.integrated.env.linux.http_proxy": "${http_proxy}",
		"terminal.integrated.env.linux.https_proxy": "${https_proxy}"
	}'
	assert_success

	run jq -e '
		.["http.proxy"] == "http://proxy.example.test:3128" and
		.["http.noProxy"] == ["*.foo.com", "localhost", "127.0.0.1"] and
		.["http.proxyStrictSSL"] == false and
		.["terminal.integrated.env.linux.HTTP_PROXY"] == "http://proxy.example.test:3128" and
		.["terminal.integrated.env.linux.HTTPS_PROXY"] == "http://proxy.example.test:3128" and
		.["terminal.integrated.env.linux.http_proxy"] == "http://proxy.example.test:3128" and
		.["terminal.integrated.env.linux.https_proxy"] == "http://proxy.example.test:3128"
	' "${tmp}"
	assert_success

	rm -f "${tmp}"
}
