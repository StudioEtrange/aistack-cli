bats_load_library 'bats-assert'
bats_load_library 'bats-support'

setup() {
	load 'stella_bats_helper.bash'
	GEIGER_TEST_TMP="$(mktemp -d)"
	AISTACK_LAUNCHER_HOME="${GEIGER_TEST_TMP}/launcher"
	AISTACK_ISOLATED_ROOT="${GEIGER_TEST_TMP}/isolated dependencies"
	AISTACK_CONTEXT_HOME="${GEIGER_TEST_TMP}/context"
	AISTACK_GENERIC_CONTEXT_FILE="${GEIGER_TEST_TMP}/generic context.sh"
	AISTACK_RUNTIME_NODEJS_SEARCH_PATH="${GEIGER_TEST_TMP}/node/bin"
	mkdir -p "${AISTACK_RUNTIME_NODEJS_SEARCH_PATH}"
	printf '%s\n' '#!/bin/sh' > "${AISTACK_GENERIC_CONTEXT_FILE}"
	geiger_init
	mkdir -p "${GEIGER_FEAT_INSTALL_ROOT}/bin"
	aistack_runtime_is_detected() { return 0; }
	aistack_runtime_require() { return 0; }
	node_isolated_package_install() {
		printf '%s\n' "${@}" > "${GEIGER_TEST_TMP}/installed-package"
		printf '%s\n' '#!/bin/sh' 'printf "%s\n" "$PWD" "$@"' 'exit "${GEIGER_TEST_EXIT:-0}"' > "${1}/bin/geiger"
		chmod +x "${1}/bin/geiger"
	}
}

teardown() {
	rm -rf "${GEIGER_TEST_TMP}"
}

# Run the sourced CLI wiring inside a function, like aistack's main.
geiger_test_main() {
	. "${AISTACK_CURRENT_FILE_DIR}/lib/main_geiger.sh"
}

@test "geiger_is_installed reports a missing runtime and clears stale detection" {
	AISTACK_GEIGER_TOOL_PATH="stale"
	aistack_runtime_is_detected() { return 1; }
	run geiger_is_installed
	assert_failure 2
	geiger_is_installed || :
	assert_equal "${AISTACK_GEIGER_TOOL_PATH}" ""
	assert_equal "${AISTACK_GEIGER_TOOL_AVAILABLE}" false
}

@test "geiger_is_installed reports a missing binary" {
	run geiger_is_installed
	assert_failure 1
}

@test "geiger_install defaults to latest and detects the isolated binary" {
	geiger_install
	assert_equal "$(cat "${GEIGER_TEST_TMP}/installed-package")" "$(printf '%s\n' "${GEIGER_FEAT_INSTALL_ROOT}" --ignore-scripts geiger-scan@latest)"
	assert_equal "${AISTACK_GEIGER_TOOL_PATH}" "${GEIGER_FEAT_INSTALL_ROOT}/bin/geiger"
	assert_equal "${AISTACK_GEIGER_TOOL_AVAILABLE}" true
}

@test "geiger_install accepts an explicit npm version" {
	run geiger_install @0.4.0
	assert_success
	assert_equal "$(tail -n 1 "${GEIGER_TEST_TMP}/installed-package")" geiger-scan@0.4.0
}

@test "geiger_install rejects invalid versions and extra arguments before installation" {
	local version
	for version in 0.4.0 @ --prefix=/elsewhere '@latest/other'; do
		run geiger_install "${version}"
		assert_failure 1
	done
	run geiger_test_main install @latest extra
	assert_failure 1
	[ ! -f "${GEIGER_TEST_TMP}/installed-package" ]
}

@test "geiger_install propagates runtime and npm errors" {
	aistack_runtime_require() { return 3; }
	run geiger_install
	assert_failure 3
	[ ! -f "${GEIGER_TEST_TMP}/installed-package" ]
	aistack_runtime_require() { return 0; }
	node_isolated_package_install() { return 4; }
	run geiger_install
	assert_failure 4
}

@test "geiger launcher forwards quoted arguments and strict exit codes under sh" {
	geiger_install
	geiger_launcher_and_context_files_manage create
	[ -x "${AISTACK_GEIGER_LAUNCHER_FILE}" ]
	export GEIGER_TEST_EXIT=2
	run /bin/sh "${AISTACK_GEIGER_LAUNCHER_FILE}" --path 'project with spaces' --strict
	assert_failure 2
	assert_line --index 1 -- --path
	assert_line --index 2 'project with spaces'
	assert_line --index 3 -- --strict
}

@test "geiger launch preserves HOME and caller directory without arguments" {
	geiger_install
	printf '%s\n' '#!/bin/sh' 'printf "%s\n" "$HOME" "$PWD" "$#"' > "${GEIGER_FEAT_INSTALL_ROOT}/bin/geiger"
	run geiger_test_main launch
	assert_success
	assert_line --index 0 "${HOME}"
	assert_line --index 1 "${PWD}"
	assert_line --index 2 0
}

@test "geiger launch changes context directory and forwards native options" {
	geiger_install
	mkdir -p "${GEIGER_TEST_TMP}/project with spaces"
	run geiger_test_main launch "${GEIGER_TEST_TMP}/project with spaces" -- --json 'report file.json'
	assert_success
	assert_line --index 0 "$(cd "${GEIGER_TEST_TMP}/project with spaces" && pwd)"
	assert_line --index 1 -- --json
	assert_line --index 2 'report file.json'
}

@test "geiger CLI rejects missing commands, unknown commands and invalid folders" {
	run geiger_test_main
	assert_failure 1
	run geiger_test_main unknown
	assert_failure 1
	run geiger_test_main launch
	assert_failure 1
	geiger_install
	run geiger_test_main launch "${GEIGER_TEST_TMP}/missing"
	assert_failure 1
}

@test "geiger register refuses a missing installation" {
	run geiger_path_register_for_shell
	assert_failure 1
	run geiger_path_register_for_vs_terminal
	assert_failure 1
}

@test "geiger registration routes shell and VS Code targets" {
	geiger_install
	register_path_named_bloc_for_shell() { printf '%s\n' "${@}"; }
	vscode_path_register_for_vs_terminal() { printf '%s\n' "${@}"; }
	unregister_path_named_bloc_for_shell() { printf 'shell:%s\n' "${2}"; }
	vscode_path_unregister_for_vs_terminal() { printf 'vs:%s\n' "${1}"; }
	run geiger_test_main register bash
	assert_success
	assert_line --index 2 bash
	run geiger_test_main register vs
	assert_success
	assert_line --index 1 "${AISTACK_GEIGER_LAUNCHER_HOME}"
	run geiger_test_main unregister
	assert_success
	assert_line 'shell:all'
	assert_line 'vs:geiger'
}

@test "geiger uninstall uses the isolated prefix and preserves reports" {
	geiger_install
	geiger_launcher_and_context_files_manage create
	touch "${GEIGER_TEST_TMP}/report.json"
	node_isolated_package_uninstall() {
		printf '%s\n' "${@}" > "${GEIGER_TEST_TMP}/uninstalled-package"
		rm -f "${1}/bin/geiger"
	}
	unregister_path_named_bloc_for_shell() { return 0; }
	vscode_path_unregister_for_vs_terminal() { return 0; }
	run geiger_test_main uninstall
	assert_success
	assert_equal "$(cat "${GEIGER_TEST_TMP}/uninstalled-package")" "$(printf '%s\n' "${GEIGER_FEAT_INSTALL_ROOT}" --ignore-scripts geiger-scan)"
	[ ! -f "${AISTACK_GEIGER_LAUNCHER_FILE}" ]
	[ ! -f "${AISTACK_GEIGER_CONTEXT_FILE}" ]
	[ -f "${GEIGER_TEST_TMP}/report.json" ]
}

@test "geiger uninstall preserves launcher on package manager failure" {
	geiger_install
	geiger_launcher_and_context_files_manage create
	node_isolated_package_uninstall() { return 5; }
	run geiger_test_main uninstall
	assert_failure 5
	[ -x "${AISTACK_GEIGER_LAUNCHER_FILE}" ]
}

@test "geiger uninstall fails without its runtime and is harmless when absent" {
	run geiger_uninstall
	assert_success
	geiger_install
	aistack_runtime_is_detected() { return 1; }
	run geiger_uninstall
	assert_failure 2
	[ -x "${GEIGER_FEAT_INSTALL_ROOT}/bin/geiger" ]
}

@test "geiger launcher refresh and deletion follow the shared lifecycle" {
	geiger_launcher_and_context_files_manage refresh_if_exists
	[ ! -f "${AISTACK_GEIGER_LAUNCHER_FILE}" ]
	geiger_install
	geiger_launcher_and_context_files_manage create
	printf '%s\n' stale > "${AISTACK_GEIGER_CONTEXT_FILE}"
	geiger_launcher_and_context_files_manage refresh_if_exists
	run grep stale "${AISTACK_GEIGER_CONTEXT_FILE}"
	assert_failure
	geiger_launcher_and_context_files_manage delete
	[ ! -f "${AISTACK_GEIGER_LAUNCHER_FILE}" ]
	[ ! -f "${AISTACK_GEIGER_CONTEXT_FILE}" ]
}
