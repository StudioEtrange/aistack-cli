bats_load_library 'bats-assert'
bats_load_library 'bats-support'

setup() {
	load 'stella_bats_helper.bash'
	CLAUDE_CODE_TEST_TMP="$(mktemp -d)"
	export CLAUDE_CODE_TEST_TMP
	AISTACK_ISOLATED_ROOT="${CLAUDE_CODE_TEST_TMP}/isolated dependencies"
	AISTACK_LAUNCHER_HOME="${CLAUDE_CODE_TEST_TMP}/launcher"
	AISTACK_CONTEXT_HOME="${CLAUDE_CODE_TEST_TMP}/context"
	AISTACK_GENERIC_CONTEXT_FILE="${CLAUDE_CODE_TEST_TMP}/generic context.sh"
	printf '%s\n' '#!/bin/sh' > "${AISTACK_GENERIC_CONTEXT_FILE}"
	claude_init
	cat > "${CLAUDE_CODE_TEST_TMP}/bootstrap.sh" <<'EOF'
#!/bin/bash
set -e
TARGET="$1"
DOWNLOAD_DIR="$HOME/.claude/downloads"
mkdir -p "$DOWNLOAD_DIR"
binary_path="$DOWNLOAD_DIR/claude-1.2.3-darwin-arm64"
printf '%s\n' '#!/bin/sh' 'printf "%s\n" "$HOME" "$PWD" "$@"' 'exit "${CLAUDE_CODE_TEST_EXIT:-0}"' > "$binary_path"
if [ "${CLAUDE_CODE_TEST_FAILURE:-0}" != 0 ]; then
    rm -f "$binary_path"
    exit "$CLAUDE_CODE_TEST_FAILURE"
fi
chmod +x "$binary_path"

# Run claude install to set up launcher and shell integration
touch "$CLAUDE_CODE_TEST_TMP/setup-executed"
install_code=0
"$binary_path" install ${TARGET:+"$TARGET"} || install_code=$?

# Clean up downloaded file
rm -f "$binary_path"
EOF
	claude_bootstrap_download() { cp "${CLAUDE_CODE_TEST_TMP}/bootstrap.sh" "${1}"; }
}

teardown() {
	rm -rf "${CLAUDE_CODE_TEST_TMP}"
}

claude_test_main() {
	. "${AISTACK_CURRENT_FILE_DIR}/lib/main_cc.sh"
}

@test "claude installs verified executable without setup and cleans staging" {
	claude_install
	assert_equal "${AISTACK_CLAUDE_CODE_TOOL_PATH}" "${CLAUDE_CODE_FEAT_INSTALL_ROOT}/claude"
	assert_equal "${AISTACK_CLAUDE_CODE_TOOL_SEARCH_PATH}" "${CLAUDE_CODE_FEAT_INSTALL_ROOT}"
	[ -x "${AISTACK_CLAUDE_CODE_TOOL_PATH}" ]
	[ ! -e "${CLAUDE_CODE_TEST_TMP}/setup-executed" ]
	assert_equal "$(find "${CLAUDE_CODE_FEAT_INSTALL_ROOT}" -name '.download.*' -print)" ""
}

@test "claude adapter redirects downloads and preserves binary after bootstrap" {
	claude_bootstrap_prepare "${CLAUDE_CODE_TEST_TMP}/bootstrap.sh" "${CLAUDE_CODE_TEST_TMP}/adapted.sh"
	run env AISTACK_CLAUDE_CODE_DOWNLOAD_DIR="${CLAUDE_CODE_TEST_TMP}/custom downloads" AISTACK_CLAUDE_CODE_DOWNLOAD_RESULT="${CLAUDE_CODE_TEST_TMP}/result" bash "${CLAUDE_CODE_TEST_TMP}/adapted.sh"
	assert_success
	[ -x "$(cat "${CLAUDE_CODE_TEST_TMP}/result")" ]
	[ ! -e "${CLAUDE_CODE_TEST_TMP}/setup-executed" ]
}

@test "claude rejects unknown or duplicate bootstrap boundaries before execution" {
	sed 's/chmod +x/chmod u+x/' "${CLAUDE_CODE_TEST_TMP}/bootstrap.sh" > "${CLAUDE_CODE_TEST_TMP}/changed.sh"
	run claude_bootstrap_prepare "${CLAUDE_CODE_TEST_TMP}/changed.sh" "${CLAUDE_CODE_TEST_TMP}/adapted.sh"
	assert_failure
	[ ! -e "${CLAUDE_CODE_TEST_TMP}/adapted.sh" ]
	printf '%s\n' 'chmod +x "$binary_path"' >> "${CLAUDE_CODE_TEST_TMP}/bootstrap.sh"
	run claude_install
	assert_failure
	[ ! -e "${CLAUDE_CODE_TEST_TMP}/setup-executed" ]
	[ ! -e "${CLAUDE_CODE_FEAT_INSTALL_ROOT}/claude" ]
}

@test "claude download and verification errors preserve previous executable" {
	printf '%s\n' 'previous executable' > "${CLAUDE_CODE_FEAT_INSTALL_ROOT}/claude"
	export CLAUDE_CODE_TEST_FAILURE=7
	run claude_install
	assert_failure 7
	assert_equal "$(cat "${CLAUDE_CODE_FEAT_INSTALL_ROOT}/claude")" 'previous executable'
	claude_bootstrap_download() { return 22; }
	run claude_install
	assert_failure 22
	assert_equal "$(cat "${CLAUDE_CODE_FEAT_INSTALL_ROOT}/claude")" 'previous executable'
	assert_equal "$(find "${CLAUDE_CODE_FEAT_INSTALL_ROOT}" -name '.download.*' -print)" ""
}

@test "claude missing downloader produces a clear error" {
	# Use the real download function with command lookup simulated as unavailable.
	. "${AISTACK_CURRENT_FILE_DIR}/lib/lib_claude.sh"
	command() { return 1; }
	run claude_bootstrap_download "${CLAUDE_CODE_TEST_TMP}/download"
	assert_failure
	assert_output --partial 'curl or wget is required'
}

@test "claude rejects version arguments and missing or unknown commands" {
	run claude_test_main install stable
	assert_failure
	assert_output --partial 'accepts no arguments'
	run claude_test_main
	assert_failure
	run claude_test_main unknown
	assert_failure
	[ ! -e "${CLAUDE_CODE_FEAT_INSTALL_ROOT}/claude" ]
}

@test "claude detection clears stale paths when binary is missing" {
	AISTACK_CLAUDE_CODE_TOOL_PATH=stale
	AISTACK_CLAUDE_CODE_TOOL_SEARCH_PATH=stale
	claude_is_installed || :
	assert_equal "${AISTACK_CLAUDE_CODE_TOOL_AVAILABLE}" false
	assert_equal "${AISTACK_CLAUDE_CODE_TOOL_PATH}" ""
	assert_equal "${AISTACK_CLAUDE_CODE_TOOL_SEARCH_PATH}" ""
	run claude_test_main launch
	assert_failure
}

@test "claude launcher forwards arguments and exit status while preserving HOME and cwd" {
	claude_install
	claude_launcher_and_context_files_manage create
	export CLAUDE_CODE_TEST_EXIT=9
	run /bin/sh "${AISTACK_CLAUDE_CODE_LAUNCHER_FILE}" -p 'two words'
	assert_failure 9
	assert_line --index 0 "${HOME}"
	assert_line --index 1 "${PWD}"
	assert_line --index 2 '-p'
	assert_line --index 3 'two words'
}

@test "claude CLI changes context directory and rejects invalid directories" {
	claude_install
	claude_launcher_and_context_files_manage create
	mkdir -p "${CLAUDE_CODE_TEST_TMP}/project folder"
	run claude_test_main launch "${CLAUDE_CODE_TEST_TMP}/project folder" -- --version
	assert_success
	assert_line --index 1 "${CLAUDE_CODE_TEST_TMP}/project folder"
	assert_line --index 2 '--version'
	run claude_test_main launch "${CLAUDE_CODE_TEST_TMP}/missing"
	assert_failure
}

@test "claude uninstallation removes managed files and unregisters both targets" {
	claude_install
	claude_launcher_and_context_files_manage create
	claude_path_unregister_for_shell() { echo "shell:${1}"; }
	claude_path_unregister_for_vs_terminal() { echo 'vs'; }
	run claude_test_main uninstall
	assert_success
	assert_line 'shell:all'
	assert_line 'vs'
	[ ! -e "${CLAUDE_CODE_FEAT_INSTALL_ROOT}/claude" ]
	[ ! -e "${AISTACK_CLAUDE_CODE_LAUNCHER_FILE}" ]
	[ ! -e "${AISTACK_CLAUDE_CODE_CONTEXT_FILE}" ]
}
