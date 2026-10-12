bats_load_library 'bats-assert'
bats_load_library 'bats-support'


setup() {
	load 'stella_bats_helper.bash'
}

teardown() {
    true
}


@test "vscode_get_config reads escaped flat keys and typed values" {
	AISTACK_VSCODE_CONFIG_FILE="${BATS_TEST_TMPDIR}/settings.json"
	printf '%s\n' '{"editor.fontSize":14,"editor":{"fontSize":99},"enabled":false,"items":[1,2]}' > "${AISTACK_VSCODE_CONFIG_FILE}"
	run vscode_get_config 'editor\.fontSize'
	assert_success
	assert_output '14'
	run vscode_get_config 'editor.fontSize'
	assert_success
	assert_output '99'
	run vscode_get_config 'enabled'
	assert_success
	assert_output 'false'
	run vscode_get_config 'items'
	assert_success
	assert_output '[1,2]'
}

@test "vscode_get_config returns empty output for absent and null keys" {
	AISTACK_VSCODE_CONFIG_FILE="${BATS_TEST_TMPDIR}/settings.json"
	printf '%s\n' '{"nullable":null}' > "${AISTACK_VSCODE_CONFIG_FILE}"
	for key in missing nullable; do
		run vscode_get_config "${key}"
		assert_success
		assert_output ''
	done
}

@test "vscode_get_config rejects missing files empty configuration and empty keys" {
	AISTACK_VSCODE_CONFIG_FILE="${BATS_TEST_TMPDIR}/missing.json"
	run vscode_get_config 'editor\.fontSize'
	assert_failure
	[ ! -e "${AISTACK_VSCODE_CONFIG_FILE}" ]
	AISTACK_VSCODE_CONFIG_FILE=''
	run vscode_get_config 'editor\.fontSize'
	assert_failure
	AISTACK_VSCODE_CONFIG_FILE="${BATS_TEST_TMPDIR}/settings.json"
	printf '%s\n' '{}' > "${AISTACK_VSCODE_CONFIG_FILE}"
	run vscode_get_config
	assert_failure
}

@test "vscode_set_config updates escaped flat keys and preserves other settings" {
	AISTACK_VSCODE_CONFIG_FILE="${BATS_TEST_TMPDIR}/settings.json"
	printf '%s\n' '{"editor.fontSize":14,"editor":{"fontSize":99},"keep":true}' > "${AISTACK_VSCODE_CONFIG_FILE}"
	run vscode_set_config 'editor\.fontSize' '18'
	assert_success
	assert_equal "$(jq -cS . "${AISTACK_VSCODE_CONFIG_FILE}")" '{"editor":{"fontSize":99},"editor.fontSize":18,"keep":true}'
	run vscode_set_config 'http\.proxy' '"http://proxy.test:3128"'
	assert_success
	assert_equal "$(jq -r '.["http.proxy"]' "${AISTACK_VSCODE_CONFIG_FILE}")" 'http://proxy.test:3128'
}

@test "vscode_set_config creates a missing target and parent directory" {
	AISTACK_VSCODE_CONFIG_FILE="${BATS_TEST_TMPDIR}/new/settings.json"
	run vscode_set_config 'terminal\.integrated\.env\.linux' '{"PATH":"/tools"}'
	assert_success
	assert_equal "$(jq -c . "${AISTACK_VSCODE_CONFIG_FILE}")" '{"terminal.integrated.env.linux":{"PATH":"/tools"}}'
}

@test "vscode_set_config rejects empty configuration keys and invalid JSON values" {
	AISTACK_VSCODE_CONFIG_FILE=''
	run vscode_set_config 'key' 'true'
	assert_failure
	AISTACK_VSCODE_CONFIG_FILE="${BATS_TEST_TMPDIR}/settings.json"
	printf '%s\n' '{"keep":true}' > "${AISTACK_VSCODE_CONFIG_FILE}"
	run vscode_set_config '' 'true'
	assert_failure
	run vscode_set_config 'key' 'not-json'
	assert_failure
	assert_equal "$(jq -c . "${AISTACK_VSCODE_CONFIG_FILE}")" '{"keep":true}'
}

@test "vscode_remove_config deletes only the escaped flat key" {
	AISTACK_VSCODE_CONFIG_FILE="${BATS_TEST_TMPDIR}/settings.json"
	printf '%s\n' '{"http.proxy":"proxy","http":{"proxy":"keep"},"keep":true}' > "${AISTACK_VSCODE_CONFIG_FILE}"
	run vscode_remove_config 'http\.proxy'
	assert_success
	assert_equal "$(jq -c . "${AISTACK_VSCODE_CONFIG_FILE}")" '{"http":{"proxy":"keep"},"keep":true}'
	run vscode_remove_config 'http\.proxy'
	assert_success
	assert_equal "$(jq -c . "${AISTACK_VSCODE_CONFIG_FILE}")" '{"http":{"proxy":"keep"},"keep":true}'
}

@test "vscode_remove_config skips unset and missing targets but rejects empty keys" {
	AISTACK_VSCODE_CONFIG_FILE=''
	run vscode_remove_config 'http\.proxy'
	assert_success
	AISTACK_VSCODE_CONFIG_FILE="${BATS_TEST_TMPDIR}/missing.json"
	run vscode_remove_config 'http\.proxy'
	assert_success
	[ ! -e "${AISTACK_VSCODE_CONFIG_FILE}" ]
	printf '%s\n' '{"keep":true}' > "${AISTACK_VSCODE_CONFIG_FILE}"
	run vscode_remove_config
	assert_failure
	assert_equal "$(jq -c . "${AISTACK_VSCODE_CONFIG_FILE}")" '{"keep":true}'
}

@test "vscode_settings_tweak_path_for_vs_terminal selects linux and osx env keys" {
	AISTACK_VSCODE_CONFIG_FILE="${BATS_TEST_TMPDIR}/settings.json"
	printf '%s\n' '{"terminal.integrated.env.linux":{"PATH":"/linux","KEEP":"yes"},"terminal.integrated.env.osx":{"PATH":"/mac"},"keep":true}' > "${AISTACK_VSCODE_CONFIG_FILE}"
	STELLA_CURRENT_PLATFORM='linux'
	run vscode_settings_tweak_path_for_vs_terminal '/tools' 'ALWAYS_POSTPEND'
	assert_success
	STELLA_CURRENT_PLATFORM='darwin'
	run vscode_settings_tweak_path_for_vs_terminal '/tools' 'ALWAYS_PREPEND'
	assert_success
	assert_equal "$(jq -cS . "${AISTACK_VSCODE_CONFIG_FILE}")" '{"keep":true,"terminal.integrated.env.linux":{"KEEP":"yes","PATH":"/linux:/tools"},"terminal.integrated.env.osx":{"PATH":"/tools:/mac"}}'
}

@test "vscode_settings_tweak_path_for_vs_terminal rejects invalid regex without changing settings" {
	STELLA_CURRENT_PLATFORM='linux'
	AISTACK_VSCODE_CONFIG_FILE="${BATS_TEST_TMPDIR}/settings.json"
	printf '%s\n' '{"terminal.integrated.env.linux":{"PATH":"/one:/two"}}' > "${AISTACK_VSCODE_CONFIG_FILE}"
	run vscode_settings_tweak_path_for_vs_terminal '[' 'REMOVE_REGEXP'
	assert_failure
	assert_equal "$(jq -c . "${AISTACK_VSCODE_CONFIG_FILE}")" '{"terminal.integrated.env.linux":{"PATH":"/one:/two"}}'
}

@test "vscode_settings_add_path_for_vs_terminal creates settings and defaults to prepend" {
	STELLA_CURRENT_PLATFORM='darwin'
	AISTACK_VSCODE_CONFIG_FILE="${BATS_TEST_TMPDIR}/new/settings.json"
	run vscode_settings_add_path_for_vs_terminal '${env:PATH}'
	assert_success
	run vscode_settings_add_path_for_vs_terminal '/tools with spaces'
	assert_success
	assert_equal "$(jq -c . "${AISTACK_VSCODE_CONFIG_FILE}")" '{"terminal.integrated.env.osx":{"PATH":"/tools with spaces:${env:PATH}"}}'
}

@test "vscode_settings_add_path_for_vs_terminal moves paths and removes duplicate occurrences" {
	STELLA_CURRENT_PLATFORM='linux'
	AISTACK_VSCODE_CONFIG_FILE="${BATS_TEST_TMPDIR}/settings.json"
	printf '%s\n' '{"terminal.integrated.env.linux":{"PATH":"/one:/tools:/two:/tools"}}' > "${AISTACK_VSCODE_CONFIG_FILE}"
	run vscode_settings_add_path_for_vs_terminal '/tools'
	assert_success
	assert_equal "$(jq -r '.["terminal.integrated.env.linux"].PATH' "${AISTACK_VSCODE_CONFIG_FILE}")" '/tools:/one:/two'
	run vscode_settings_add_path_for_vs_terminal '/tools' 'ALWAYS_POSTPEND'
	assert_success
	assert_equal "$(jq -r '.["terminal.integrated.env.linux"].PATH' "${AISTACK_VSCODE_CONFIG_FILE}")" '/one:/two:/tools'
}

@test "vscode_settings_add_path_for_vs_terminal conditional modes preserve existing ordering" {
	STELLA_CURRENT_PLATFORM='linux'
	AISTACK_VSCODE_CONFIG_FILE="${BATS_TEST_TMPDIR}/settings.json"
	printf '%s\n' '{"terminal.integrated.env.linux":{"PATH":"/one:/tools:/two"}}' > "${AISTACK_VSCODE_CONFIG_FILE}"
	for mode in PREPEND_IF_NOT_EXISTS POSTPEND_IF_NOT_EXISTS; do
		run vscode_settings_add_path_for_vs_terminal '/tools' "${mode}"
		assert_success
		assert_equal "$(jq -r '.["terminal.integrated.env.linux"].PATH' "${AISTACK_VSCODE_CONFIG_FILE}")" '/one:/tools:/two'
	done
	run vscode_settings_add_path_for_vs_terminal '/first' 'PREPEND_IF_NOT_EXISTS'
	assert_success
	run vscode_settings_add_path_for_vs_terminal '/last' 'POSTPEND_IF_NOT_EXISTS'
	assert_success
	assert_equal "$(jq -r '.["terminal.integrated.env.linux"].PATH' "${AISTACK_VSCODE_CONFIG_FILE}")" '/first:/one:/tools:/two:/last'
}

@test "vscode_settings_add_path_for_vs_terminal rejects unset configuration and ignores empty paths" {
	STELLA_CURRENT_PLATFORM='linux'
	AISTACK_VSCODE_CONFIG_FILE=''
	run vscode_settings_add_path_for_vs_terminal '/tools'
	assert_failure
	AISTACK_VSCODE_CONFIG_FILE="${BATS_TEST_TMPDIR}/settings.json"
	printf '%s\n' '{"keep":true}' > "${AISTACK_VSCODE_CONFIG_FILE}"
	run vscode_settings_add_path_for_vs_terminal ''
	assert_success
	assert_equal "$(jq -c . "${AISTACK_VSCODE_CONFIG_FILE}")" '{"keep":true}'
}

@test "vscode_settings_remove_path_for_vs_terminal removes exact duplicates not similar paths" {
	STELLA_CURRENT_PLATFORM='linux'
	AISTACK_VSCODE_CONFIG_FILE="${BATS_TEST_TMPDIR}/settings.json"
	printf '%s\n' '{"terminal.integrated.env.linux":{"PATH":"/tools:/tools-extra:/keep:/tools"}}' > "${AISTACK_VSCODE_CONFIG_FILE}"
	run vscode_settings_remove_path_for_vs_terminal '/tools'
	assert_success
	assert_equal "$(jq -r '.["terminal.integrated.env.linux"].PATH' "${AISTACK_VSCODE_CONFIG_FILE}")" '/tools-extra:/keep'
}

@test "vscode_settings_remove_path_for_vs_terminal supports selective regexp removal" {
	STELLA_CURRENT_PLATFORM='darwin'
	AISTACK_VSCODE_CONFIG_FILE="${BATS_TEST_TMPDIR}/settings.json"
	printf '%s\n' '{"terminal.integrated.env.osx":{"PATH":"/old/v1/bin:/keep:/old/v2/bin:${env:PATH}"}}' > "${AISTACK_VSCODE_CONFIG_FILE}"
	run vscode_settings_remove_path_for_vs_terminal '^/old/' 'REMOVE_REGEXP'
	assert_success
	assert_equal "$(jq -r '.["terminal.integrated.env.osx"].PATH' "${AISTACK_VSCODE_CONFIG_FILE}")" '/keep:${env:PATH}'
}

@test "vscode_settings_remove_path_for_vs_terminal cleans up PATH but retains env keys and other OS" {
	STELLA_CURRENT_PLATFORM='linux'
	AISTACK_VSCODE_CONFIG_FILE="${BATS_TEST_TMPDIR}/settings.json"
	printf '%s\n' '{"terminal.integrated.env.linux":{"PATH":"/tools","KEEP":"yes"},"terminal.integrated.env.osx":{"PATH":"/mac"}}' > "${AISTACK_VSCODE_CONFIG_FILE}"
	run vscode_settings_remove_path_for_vs_terminal '/tools'
	assert_success
	assert_equal "$(jq -c . "${AISTACK_VSCODE_CONFIG_FILE}")" '{"terminal.integrated.env.linux":{"KEEP":"yes"},"terminal.integrated.env.osx":{"PATH":"/mac"}}'
	printf '%s\n' '{"terminal.integrated.env.linux":{"PATH":"/tools"}}' > "${AISTACK_VSCODE_CONFIG_FILE}"
	run vscode_settings_remove_path_for_vs_terminal '/tools'
	assert_success
	assert_equal "$(jq -c . "${AISTACK_VSCODE_CONFIG_FILE}")" '{"terminal.integrated.env.linux":{}}'
}

@test "vscode_settings_remove_path_for_vs_terminal skips missing targets and absent PATH" {
	STELLA_CURRENT_PLATFORM='linux'
	AISTACK_VSCODE_CONFIG_FILE="${BATS_TEST_TMPDIR}/missing.json"
	run vscode_settings_remove_path_for_vs_terminal '/tools'
	assert_success
	[ ! -e "${AISTACK_VSCODE_CONFIG_FILE}" ]
	AISTACK_VSCODE_CONFIG_FILE=''
	run vscode_settings_remove_path_for_vs_terminal '/tools'
	assert_success
	AISTACK_VSCODE_CONFIG_FILE="${BATS_TEST_TMPDIR}/settings.json"
	printf '%s\n' '{"keep":true}' > "${AISTACK_VSCODE_CONFIG_FILE}"
	run vscode_settings_remove_path_for_vs_terminal '/tools'
	assert_success
	assert_equal "$(jq -c . "${AISTACK_VSCODE_CONFIG_FILE}")" '{"keep":true,"terminal.integrated.env.linux":{}}'
}

@test "vscode_merge_config accepts JSON5 without modifying its source file" {
	AISTACK_VSCODE_CONFIG_FILE="${BATS_TEST_TMPDIR}/settings.json"
	source_file="${BATS_TEST_TMPDIR}/source.json5"
	source_json="{ /* comment */ 'editor.fontSize': 18, nested: { replace: 'new', }, }"
	printf '%s\n' "${source_json}" > "${source_file}"
	printf '%s\n' '{"editor.fontSize":14,"nested":{"replace":"old","keep":true}}' > "${AISTACK_VSCODE_CONFIG_FILE}"
	run vscode_merge_config "${source_file}"
	assert_success
	assert_equal "$(jq -cS . "${AISTACK_VSCODE_CONFIG_FILE}")" '{"editor.fontSize":18,"nested":{"keep":true,"replace":"new"}}'
	assert_equal "$(< "${source_file}")" "${source_json}"
}

@test "vscode_merge_config expands defined and empty env variables but preserves undefined and VS Code placeholders" {
	AISTACK_VSCODE_CONFIG_FILE="${BATS_TEST_TMPDIR}/new/settings.json"
	export VS_TEST_VALUE='/tools with spaces'
	export VS_TEST_EMPTY=''
	unset VS_TEST_UNDEFINED
	run vscode_merge_config '{"path":"${VS_TEST_VALUE}","empty":"${VS_TEST_EMPTY}","missing":"${VS_TEST_UNDEFINED}","terminal":"${env:PATH}","bare":"$VS_TEST_VALUE"}'
	assert_success
	assert_equal "$(jq -cS . "${AISTACK_VSCODE_CONFIG_FILE}")" '{"bare":"$VS_TEST_VALUE","empty":"","missing":"${VS_TEST_UNDEFINED}","path":"/tools with spaces","terminal":"${env:PATH}"}'
}

@test "vscode_merge_config rejects empty configuration empty input and malformed input" {
	AISTACK_VSCODE_CONFIG_FILE=''
	run vscode_merge_config '{"new":true}'
	assert_failure
	AISTACK_VSCODE_CONFIG_FILE="${BATS_TEST_TMPDIR}/settings.json"
	printf '%s\n' '{"keep":true}' > "${AISTACK_VSCODE_CONFIG_FILE}"
	for input in '' '{invalid' "${BATS_TEST_TMPDIR}/nonexistent.json"; do
		run vscode_merge_config "${input}"
		assert_failure
		assert_equal "$(jq -c . "${AISTACK_VSCODE_CONFIG_FILE}")" '{"keep":true}'
	done
}

@test "vscode_merge_config preserves settings on incompatible merge types" {
	AISTACK_VSCODE_CONFIG_FILE="${BATS_TEST_TMPDIR}/settings.json"
	printf '%s\n' '{"keep":true}' > "${AISTACK_VSCODE_CONFIG_FILE}"
	run vscode_merge_config '[1,2]'
	assert_failure
	assert_equal "$(jq -c . "${AISTACK_VSCODE_CONFIG_FILE}")" '{"keep":true}'
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

