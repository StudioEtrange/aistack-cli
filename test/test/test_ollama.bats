bats_load_library 'bats-assert'
bats_load_library 'bats-support'

setup() {
	load 'stella_bats_helper.bash'
	OLLAMA_TEST_TMP="$(mktemp -d)"
	STELLA_APP_WORK_ROOT="${OLLAMA_TEST_TMP}/work space"
	AISTACK_ISOLATED_ROOT="${STELLA_APP_WORK_ROOT}/isolated_dependencies"
	AISTACK_LAUNCHER_HOME="${STELLA_APP_WORK_ROOT}/launcher"
	AISTACK_CONTEXT_HOME="${STELLA_APP_WORK_ROOT}/context"
	AISTACK_GENERIC_CONTEXT_FILE="${AISTACK_CONTEXT_HOME}/generic_context.sh"
	STELLA_CURRENT_PLATFORM="darwin"
	STELLA_CURRENT_CPU_FAMILY="intel"
	ollama_init
}

teardown() {
	rm -rf "${OLLAMA_TEST_TMP}"
}

make_ollama_binary() {
	mkdir -p "${OLLAMA_FEAT_INSTALL_ROOT}/bin"
	printf '%s\n' '#!/bin/sh' 'printf "%s\n" "$HOME" "$OLLAMA_MODELS" "$OLLAMA_HOST" "$@"' > "${OLLAMA_FEAT_INSTALL_ROOT}/bin/ollama"
	chmod +x "${OLLAMA_FEAT_INSTALL_ROOT}/bin/ollama"
}

make_ollama_archive() {
	mkdir -p "${OLLAMA_TEST_TMP}/fixture"
	printf '%s\n' '#!/bin/sh' 'exit 0' > "${OLLAMA_TEST_TMP}/fixture/ollama"
	chmod +x "${OLLAMA_TEST_TMP}/fixture/ollama"
	printf '%s\n' 'companion library' > "${OLLAMA_TEST_TMP}/fixture/libollama.dylib"
	tar -czf "${OLLAMA_TEST_TMP}/fixture.tgz" -C "${OLLAMA_TEST_TMP}/fixture" .
	curl() {
		printf '%s\n' "${6}" > "${OLLAMA_TEST_TMP}/url"
		cp "${OLLAMA_TEST_TMP}/fixture.tgz" "${5}"
	}
}

@test "ollama detects missing and installed executable" {
	run ollama_is_installed
	assert_failure
	make_ollama_binary
	ollama_is_installed
	assert_equal "${AISTACK_OLLAMA_TOOL_AVAILABLE}" true
	assert_equal "${AISTACK_OLLAMA_TOOL_PATH}" "${OLLAMA_FEAT_INSTALL_ROOT}/bin/ollama"
}

@test "ollama launch isolates data and preserves arguments and caller HOME" {
	make_ollama_binary
	local original_home="${HOME}"
	OLLAMA_HOST="127.0.0.1:11435"
	run ollama_launch run llama3.2 'hello world'
	assert_success
	assert_line --index 0 "${AISTACK_OLLAMA_DATA_HOME}"
	assert_line --index 1 "${AISTACK_OLLAMA_MODELS_HOME}"
	assert_line --index 2 '127.0.0.1:11435'
	assert_line --index 5 'hello world'
	assert_equal "${HOME}" "${original_home}"
}

@test "ollama launch reports a missing binary" {
	run ollama_launch list
	assert_failure
	assert_output --partial 'ERROR: Ollama is not installed'
}

@test "ollama generated launcher works with paths containing spaces" {
	make_ollama_binary
	ollama_launcher_and_context_files_manage create
	run "${AISTACK_OLLAMA_LAUNCHER_FILE}" run llama3.2 'hello world'
	assert_success
	assert_line --index 0 "${AISTACK_OLLAMA_DATA_HOME}"
	assert_line --index 5 'hello world'
}

@test "ollama install normalizes version and preserves macOS companion libraries" {
	make_ollama_archive
	run ollama_install 0.40.3
	assert_success
	assert_equal "$(cat "${OLLAMA_TEST_TMP}/url")" 'https://github.com/ollama/ollama/releases/download/v0.40.3/ollama-darwin.tgz'
	[ -x "${OLLAMA_FEAT_INSTALL_ROOT}/bin/ollama" ]
	[ -f "${OLLAMA_FEAT_INSTALL_ROOT}/libollama.dylib" ]
}

@test "ollama install resolves latest release" {
	make_ollama_archive
	github_get_latest_release() { printf '%s\n' v0.40.3; }
	run ollama_install
	assert_success
	assert_output --partial 'Installing Ollama v0.40.3'
}

@test "ollama install rejects invalid versions and unsupported platforms" {
	run ollama_install '../bad'
	assert_failure
	assert_output --partial 'Invalid Ollama version'
	STELLA_CURRENT_PLATFORM="windows"
	run ollama_install v0.40.3
	assert_failure
	assert_output --partial 'Unsupported platform'
	STELLA_CURRENT_CPU_FAMILY="unknown"
	run ollama_install v0.40.3
	assert_failure
	assert_output --partial 'Unsupported CPU family'
}

@test "ollama Linux installer reports missing zstd without downloading" {
	STELLA_CURRENT_PLATFORM="linux"
	command() { return 1; }
	run ollama_install v0.40.3
	assert_failure
	assert_output --partial 'zstd is required'
}

@test "ollama failed download preserves existing binaries and models" {
	make_ollama_binary
	printf '%s\n' model > "${AISTACK_OLLAMA_MODELS_HOME}/keep"
	curl() { return 22; }
	run ollama_install v0.40.3
	assert_failure 22
	[ -x "${OLLAMA_FEAT_INSTALL_ROOT}/bin/ollama" ]
	[ -f "${AISTACK_OLLAMA_MODELS_HOME}/keep" ]
}

@test "ollama uninstall and launcher removal preserve data" {
	make_ollama_binary
	ollama_launcher_and_context_files_manage create
	printf '%s\n' model > "${AISTACK_OLLAMA_MODELS_HOME}/keep"
	ollama_uninstall
	ollama_launcher_and_context_files_manage delete
	[ ! -e "${OLLAMA_FEAT_INSTALL_ROOT}" ]
	[ ! -e "${AISTACK_OLLAMA_LAUNCHER_FILE}" ]
	[ -f "${AISTACK_OLLAMA_MODELS_HOME}/keep" ]
}

@test "ollama CLI rejects missing model arguments" {
	run bash -c 'script="$1"; cli() { source "${script}"; }; cli run' _ "${BATS_TEST_DIRNAME}/../../lib/main_ollama.sh"
	assert_failure
	assert_output --partial 'Missing arguments'
}

@test "ollama CLI rejects missing and unknown subcommands" {
	run bash -c 'script="$1"; cli() { source "${script}"; }; cli' _ "${BATS_TEST_DIRNAME}/../../lib/main_ollama.sh"
	assert_failure
	assert_output --partial 'Unknown or missing command'
	run bash -c 'script="$1"; cli() { source "${script}"; }; cli invalid' _ "${BATS_TEST_DIRNAME}/../../lib/main_ollama.sh"
	assert_failure
}

@test "ollama Linux installer selects the architecture and preserves library layout" {
	STELLA_CURRENT_PLATFORM="linux"
	STELLA_CURRENT_CPU_FAMILY="arm"
	mkdir -p "${OLLAMA_TEST_TMP}/linux/bin" "${OLLAMA_TEST_TMP}/linux/lib/ollama"
	printf '%s\n' '#!/bin/sh' 'exit 0' > "${OLLAMA_TEST_TMP}/linux/bin/ollama"
	chmod +x "${OLLAMA_TEST_TMP}/linux/bin/ollama"
	printf '%s\n' library > "${OLLAMA_TEST_TMP}/linux/lib/ollama/keep"
	tar -cf "${OLLAMA_TEST_TMP}/linux.tar" -C "${OLLAMA_TEST_TMP}/linux" .
	command() { return 0; }
	curl() {
		printf '%s\n' "${6}" > "${OLLAMA_TEST_TMP}/url"
		cp "${OLLAMA_TEST_TMP}/linux.tar" "${5}"
	}
	zstd() { cp "${3}" "${5}"; }
	run ollama_install v0.40.3
	assert_success
	assert_equal "$(cat "${OLLAMA_TEST_TMP}/url")" 'https://github.com/ollama/ollama/releases/download/v0.40.3/ollama-linux-arm64.tar.zst'
	[ -x "${OLLAMA_FEAT_INSTALL_ROOT}/bin/ollama" ]
	[ -f "${OLLAMA_FEAT_INSTALL_ROOT}/lib/ollama/keep" ]
}

@test "ollama corrupt archive preserves an existing installation" {
	make_ollama_binary
	curl() { printf '%s\n' corrupt > "${5}"; }
	run ollama_install v0.40.3
	assert_failure
	[ -x "${OLLAMA_FEAT_INSTALL_ROOT}/bin/ollama" ]
}
