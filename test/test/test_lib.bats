#!/usr/bin/env bats

bats_load_library 'bats-assert'
bats_load_library 'bats-support'

setup() {
	load 'stella_bats_helper.bash'
}

@test "shell_quote_posix quotes an empty string" {
	run shell_quote_posix ""

	assert_success
	assert_output "''"
}

@test "shell_quote_posix quotes a simple string" {
	run shell_quote_posix "hello"

	assert_success
	assert_output "'hello'"
}

@test "shell_quote_posix preserves spaces" {
	run shell_quote_posix "hello world"

	assert_success
	assert_output "'hello world'"
}

@test "shell_quote_posix escapes single quotes" {
	run shell_quote_posix "it's quoted"

	assert_success
	assert_output "'it'\\''s quoted'"
}

@test "shell_quote_posix prevents shell expansion" {
	local value='${HOME}; $(printf injected); `printf injected`; * ? [abc]'
	local quoted

	quoted="$(shell_quote_posix "${value}")"
	run env QUOTED="${quoted}" sh -c 'eval "set -- ${QUOTED}"; printf "%s" "$1"'

	assert_success
	assert_output "${value}"
}

@test "shell_quote_posix round-trips embedded newlines" {
	local value
	local quoted
	value="$(printf 'first line\nsecond line')"

	quoted="$(shell_quote_posix "${value}")"
	run env QUOTED="${quoted}" sh -c 'eval "set -- ${QUOTED}"; printf "%s" "$1"'

	assert_success
	assert_output "${value}"
}

@test "unregister_for_shell removes one exact block" {
	local test_home="${BATS_TEST_TMPDIR}/home"
	mkdir -p "${test_home}"
	cat > "${test_home}/.bashrc" <<'EOF'
before
# >>> aistack-gemini-path >>>
export PATH="/gemini:$PATH"
# <<< aistack-gemini-path <<<
# >>> aistack-opencode-path >>>
export PATH="/opencode:$PATH"
# <<< aistack-opencode-path <<<
after
EOF

	HOME="${test_home}" run unregister_for_shell "aistack-gemini-path" "bash"

	assert_success
	run grep -F "aistack-gemini-path" "${test_home}/.bashrc"
	assert_failure
	run grep -F "aistack-opencode-path" "${test_home}/.bashrc"
	assert_success
}

@test "unregister_for_shell removes all matching wildcard blocks" {
	local test_home="${BATS_TEST_TMPDIR}/home"
	mkdir -p "${test_home}"
	cat > "${test_home}/.bashrc" <<'EOF'
before
# >>> aistack-gemini-path >>>
export PATH="/gemini:$PATH"
# <<< aistack-gemini-path <<<
# >>> aistack-opencode-path >>>
export PATH="/opencode:$PATH"
# <<< aistack-opencode-path <<<
# >>> aistack-openchamber-connect >>>
connect openchamber
# <<< aistack-openchamber-connect <<<
after
EOF

	HOME="${test_home}" run unregister_for_shell "aistack-*-path" "bash"

	assert_success
	run grep -F "aistack-gemini-path" "${test_home}/.bashrc"
	assert_failure
	run grep -F "aistack-opencode-path" "${test_home}/.bashrc"
	assert_failure
	run grep -F "aistack-openchamber-connect" "${test_home}/.bashrc"
	assert_success
	run grep -F "before" "${test_home}/.bashrc"
	assert_success
	run grep -F "after" "${test_home}/.bashrc"
	assert_success
}

@test "unregister_for_shell does not rewrite a file without matching blocks" {
	local test_home="${BATS_TEST_TMPDIR}/home"
	local modified_before
	mkdir -p "${test_home}"
	printf '%s\n' "unchanged" > "${test_home}/.bashrc"
	touch -t 202001010101 "${test_home}/.bashrc"
	modified_before="$(stat -f '%m' "${test_home}/.bashrc" 2>/dev/null || stat -c '%Y' "${test_home}/.bashrc")"

	HOME="${test_home}" run unregister_for_shell "aistack-*-path" "bash"

	assert_success
	assert_equal "$(stat -f '%m' "${test_home}/.bashrc" 2>/dev/null || stat -c '%Y' "${test_home}/.bashrc")" "${modified_before}"
	run grep -F "unchanged" "${test_home}/.bashrc"
	assert_success
}

@test "aistack_shell_rc_files_purge unregisters wildcard PATH blocks" {
	local test_home="${BATS_TEST_TMPDIR}/home"
	mkdir -p "${test_home}"
	cat > "${test_home}/.bashrc" <<'EOF'
# >>> aistack-gemini-path >>>
export PATH="/gemini:$PATH"
# <<< aistack-gemini-path <<<
# >>> aistack-opencode-path >>>
export PATH="/opencode:$PATH"
# <<< aistack-opencode-path <<<
# >>> aistack-openchamber-connect >>>
connect openchamber
# <<< aistack-openchamber-connect <<<
EOF
	aistack_module_is_detected() {
		return 1
	}

	HOME="${test_home}" run aistack_shell_rc_files_purge

	assert_success
	run grep -F "aistack-gemini-path" "${test_home}/.bashrc"
	assert_failure
	run grep -F "aistack-opencode-path" "${test_home}/.bashrc"
	assert_failure
	run grep -F "aistack-openchamber-connect" "${test_home}/.bashrc"
	assert_failure
}
