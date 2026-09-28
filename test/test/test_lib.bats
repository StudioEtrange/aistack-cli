#!/usr/bin/env bats

bats_load_library 'bats-assert'
bats_load_library 'bats-support'

setup() {
	load 'stella_bats_helper.bash'
}

@test "user_init uses the current user without sudo" {
	print_target_user() {
		unset SUDO_USER
		user_init || return $?
		printf '%s\n%s\n' "${AISTACK_USER}" "${AISTACK_USER_HOME}"
	}

	run print_target_user

	assert_success
	assert_line --index 0 "$(id -un)"
	assert_line --index 1 "${HOME}"
}

@test "user_init uses SUDO_USER and its login HOME" {
	local test_bin="${BATS_TEST_TMPDIR}/bin"
	local target_home="${BATS_TEST_TMPDIR}/target user home"
	mkdir -p "${test_bin}"
	cat > "${test_bin}/sudo" <<EOF
#!/bin/sh
printf '%s\n' '${target_home}'
EOF
	chmod +x "${test_bin}/sudo"
	print_target_user() {
		export SUDO_USER="test-user"
		user_init || return $?
		printf '%s\n%s\n' "${AISTACK_USER}" "${AISTACK_USER_HOME}"
	}

	PATH="${test_bin}:${PATH}" run print_target_user

	assert_success
	assert_line --index 0 "test-user"
	assert_line --index 1 "${target_home}"
}

@test "aistack_init refreshes by default" {
	aistack_install_refresh() {
		printf '%s' "refresh"
	}
	aistack_install_purge() {
		printf '%s' "purge"
	}

	run aistack_init

	assert_success
	assert_output "refresh"
}

@test "aistack_init reinstalls from scratch when requested" {
	aistack_install_refresh() {
		printf '%s' "refresh"
	}
	aistack_install_purge() {
		printf '%s' "purge"
	}

	run aistack_init "reinstall"

	assert_success
	assert_output "purge"
}

@test "aistack_init rejects an unsupported mode" {
	aistack_install_refresh() {
		printf '%s' "refresh"
	}
	aistack_install_purge() {
		printf '%s' "purge"
	}

	run aistack_init "force"

	assert_failure
	assert_output "ERROR: unsupported init mode: force"
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

@test "unregister_for_shell supports multiple rc files in HOME containing spaces" {
	local test_home="${BATS_TEST_TMPDIR}/home with spaces"
	mkdir -p "${test_home}"
	cat > "${test_home}/.bashrc" <<'EOF'
before
# >>> aistack-test-path >>>
export PATH="/test/bin:$PATH"
# <<< aistack-test-path <<<
after
EOF
	cp "${test_home}/.bashrc" "${test_home}/.zshrc"

	HOME="${test_home}" run unregister_for_shell "aistack-test-path" "bash zsh"

	assert_success
	run grep -F "aistack-test-path" "${test_home}/.bashrc"
	assert_failure
	run grep -F "aistack-test-path" "${test_home}/.zshrc"
	assert_failure
	run grep -F "before" "${test_home}/.bashrc"
	assert_success
	run grep -F "after" "${test_home}/.bashrc"
	assert_success
	run grep -F "before" "${test_home}/.zshrc"
	assert_success
	run grep -F "after" "${test_home}/.zshrc"
	assert_success
}

@test "call_sudo bypasses a sudo shell wrapper" {
	local test_bin="${BATS_TEST_TMPDIR}/bin"
	mkdir -p "${test_bin}"
	cat > "${test_bin}/sudo" <<'EOF'
#!/bin/sh
printf '%s\n' "$*"
EOF
	chmod +x "${test_bin}/sudo"
	sudo() {
		return 99
	}

	PATH="${test_bin}:${PATH}" run call_sudo -u "test-user" -- touch "/tmp/test-file"

	assert_success
	assert_output '-u test-user -- touch /tmp/test-file'
}

@test "path_register_for_shell writes as SUDO_USER" {
	local test_home="${BATS_TEST_TMPDIR}/home"
	local sudo_log="${BATS_TEST_TMPDIR}/sudo.log"
	mkdir -p "${test_home}"
	get_user_shell_config_files() {
		printf '%s\n' "${test_home}/.bashrc"
	}
	call_sudo() {
		printf '%s\n' "$*" >> "${sudo_log}"
		[ "$1" = "-u" ] || return 1
		shift 2
		[ "$1" = "--" ] && shift
		"$@"
	}

	SUDO_USER="test-user" run path_register_for_shell "test" "/test/bin" "bash"

	assert_success
	run grep -F 'export PATH="/test/bin:$PATH"' "${test_home}/.bashrc"
	assert_success
	run grep -F -- '-u test-user -- mkdir -p' "${sudo_log}"
	assert_success
	run grep -F -- '-u test-user -- touch' "${sudo_log}"
	assert_success
	run grep -F -- '-u test-user -- sh -c cat >> "$1"' "${sudo_log}"
	assert_success
}

@test "unregister_for_shell replaces the rc file as SUDO_USER" {
	local test_home="${BATS_TEST_TMPDIR}/home"
	local sudo_log="${BATS_TEST_TMPDIR}/sudo.log"
	mkdir -p "${test_home}"
	cat > "${test_home}/.bashrc" <<'EOF'
before
# >>> aistack-test-path >>>
export PATH="/test/bin:$PATH"
# <<< aistack-test-path <<<
after
EOF
	chmod 640 "${test_home}/.bashrc"
	get_user_shell_config_files() {
		printf '%s\n' "${test_home}/.bashrc"
	}
	call_sudo() {
		printf '%s\n' "$*" >> "${sudo_log}"
		[ "$1" = "-u" ] || return 1
		shift 2
		[ "$1" = "--" ] && shift
		"$@"
	}

	SUDO_USER="test-user" run unregister_for_shell "aistack-test-path" "bash"

	assert_success
	run grep -F "aistack-test-path" "${test_home}/.bashrc"
	assert_failure
	run grep -F -- '-u test-user -- mktemp' "${sudo_log}"
	assert_success
	run grep -F -- '-u test-user -- mv' "${sudo_log}"
	assert_success
	assert_equal "$(stat -f '%Lp' "${test_home}/.bashrc" 2>/dev/null || stat -c '%a' "${test_home}/.bashrc")" "640"
}

@test "unregister_for_shell uses mode 600 when stat fails" {
	local test_home="${BATS_TEST_TMPDIR}/home"
	mkdir -p "${test_home}"
	cat > "${test_home}/.bashrc" <<'EOF'
# >>> aistack-test-path >>>
export PATH="/test/bin:$PATH"
# <<< aistack-test-path <<<
EOF
	get_user_shell_config_files() {
		printf '%s\n' "${test_home}/.bashrc"
	}
	stat() {
		return 1
	}

	run unregister_for_shell "aistack-test-path" "bash"

	assert_success
	assert_output --partial "WARN: unable to determine permissions for ${test_home}/.bashrc; using mode 600"
	# stat compatible macos and fallback for linux
	assert_equal "$(command stat -f '%Lp' "${test_home}/.bashrc" 2>/dev/null || command stat -c '%a' "${test_home}/.bashrc")" "600"
}

@test "aistack_shell_purge unregisters wildcard PATH blocks" {
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

	HOME="${test_home}" run aistack_shell_purge

	assert_success
	run grep -F "aistack-gemini-path" "${test_home}/.bashrc"
	assert_failure
	run grep -F "aistack-opencode-path" "${test_home}/.bashrc"
	assert_failure
	run grep -F "aistack-openchamber-connect" "${test_home}/.bashrc"
	assert_failure
}
