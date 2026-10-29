#!/usr/bin/env bats

bats_load_library 'bats-assert'
bats_load_library 'bats-support'

setup() {
	load 'stella_bats_helper.bash'
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

@test "aistack_init rejects invalid Node.js versions before refresh or purge" {
	AISTACK_INIT_FORCE_NODE_VERSION="--lts"
	aistack_install_refresh() { fail "must not refresh"; }
	aistack_install_purge() { fail "must not purge"; }
	local mode
	for mode in refresh reinstall; do
		run aistack_init "${mode}"
		assert_failure
		assert_output --partial "ERROR: invalid Node.js version:"
	done
}

@test "aistack_runtime_install propagates Node.js installation failure" {
	aistack_component_install() { return 3; }
	aistack_runtime_detect() { fail "must not detect an old runtime"; }
	run aistack_runtime_install nodejs
	assert_equal "${status}" 3
}

@test "aistack_runtime_install forwards an explicit Node.js version even when installed" {
	AISTACK_INIT_FORCE_NODE_VERSION="22"
	aistack_runtime_is_detected() { return 0; }
	aistack_component_install() { printf '%s:%s' "${1}" "${3}"; }
	aistack_runtime_detect() { :; }
	aistack_module_detect() { :; }
	aistack_tool_detect() { :; }
	aistack_generic_context_file_generate() { :; }
	aistack_launcher_and_context_files_regenerate() { :; }
	local version
	for version in 24 24.1 24.1.0 v24.1.0; do
		run aistack_runtime_install nodejs "${version}"
		assert_success
		assert_output "nodejs:${version}"
	done
	aistack_runtime_install nodejs 24.1 >/dev/null
	assert_equal "${AISTACK_INIT_FORCE_NODE_VERSION}" "22"
}

@test "aistack_runtime_install runs installers for existing runtimes without a version" {
	AISTACK_INIT_FORCE_NODE_VERSION=""
	aistack_runtime_is_detected() { return 0; }
	aistack_component_install() { echo "install ${1}"; }
	aistack_runtime_detect() { :; }
	aistack_module_detect() { :; }
	aistack_tool_detect() { :; }
	aistack_generic_context_file_generate() { :; }
	aistack_launcher_and_context_files_regenerate() { :; }
	local runtime
	for runtime in nodejs python rust bun; do
		run aistack_runtime_install "${runtime}"
		assert_success
		assert_output "install ${runtime}"
	done
}

@test "aistack_runtime_install rejects missing extra and invalid arguments before installing" {
	aistack_component_install() { echo "unexpected installation"; return 0; }
	run aistack_runtime_install
	assert_failure
	assert_output --partial "ERROR: usage:"
	refute_output --partial "unexpected installation"
	run aistack_runtime_install nodejs 24.1 extra
	assert_failure
	assert_output --partial "ERROR: usage:"
	refute_output --partial "unexpected installation"
	local runtime
	for runtime in python rust bun; do
		run aistack_runtime_install "${runtime}" 24.1
		assert_failure
		assert_output --partial "ERROR: version selection is only supported"
		refute_output --partial "unexpected installation"
	done
	run aistack_runtime_install unknown
	assert_failure
	assert_output "ERROR: Unknown runtime unknown"
	local version
	for version in '' --lts invalid 24.1.0.1; do
		run aistack_runtime_install nodejs "${version}"
		assert_failure
		assert_output --partial "ERROR: invalid Node.js version:"
		refute_output --partial "unexpected installation"
	done
}

@test "aistack_runtime_install validates the Node.js environment version before installing" {
	AISTACK_INIT_FORCE_NODE_VERSION="invalid"
	aistack_component_install() { echo "unexpected installation"; }
	run aistack_runtime_install nodejs
	assert_failure
	assert_output --partial "ERROR: invalid Node.js version:"
	refute_output --partial "unexpected installation"
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

@test "unregister_named_bloc_for_shell removes one exact block" {
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

	HOME="${test_home}" run unregister_named_bloc_for_shell "aistack-gemini-path" "bash"

	assert_success
	run grep -F "aistack-gemini-path" "${test_home}/.bashrc"
	assert_failure
	run grep -F "aistack-opencode-path" "${test_home}/.bashrc"
	assert_success
}

@test "unregister_named_bloc_for_shell removes all matching wildcard blocks" {
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

	HOME="${test_home}" run unregister_named_bloc_for_shell "aistack-*-path" "bash"

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

@test "unregister_named_bloc_for_shell does not rewrite a file without matching blocks" {
	local test_home="${BATS_TEST_TMPDIR}/home"
	local modified_before modified_after
	mkdir -p "${test_home}"
	printf '%s\n' "unchanged" > "${test_home}/.bashrc"
	touch -t 202001010101 "${test_home}/.bashrc"
	case "$(uname -s)" in
		Darwin)
			modified_before="$(stat -f '%m' "${test_home}/.bashrc")"
			;;
		*)
			modified_before="$(stat -c '%Y' "${test_home}/.bashrc")"
			;;
	esac

	HOME="${test_home}" run unregister_named_bloc_for_shell "aistack-*-path" "bash"
	assert_success

	case "$(uname -s)" in
		Darwin)
			modified_after="$(stat -f '%m' "${test_home}/.bashrc")"
			;;
		*)
			modified_after="$(stat -c '%Y' "${test_home}/.bashrc")"
			;;
	esac
	assert_equal "${modified_after}" "${modified_before}"
	
	run grep -Fx "unchanged" "${test_home}/.bashrc"
	assert_success
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
