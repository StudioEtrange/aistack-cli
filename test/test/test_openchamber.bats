bats_load_library 'bats-assert'
bats_load_library 'bats-support'

setup() {
	load 'stella_bats_helper.bash'
	OCH_TEST_TMP="$(mktemp -d)"
	AISTACK_ISOLATED_ROOT="${OCH_TEST_TMP}/isolated dependencies"
	AISTACK_LAUNCHER_HOME="${OCH_TEST_TMP}/launchers"
	AISTACK_CONTEXT_HOME="${OCH_TEST_TMP}/contexts"
	AISTACK_GENERIC_CONTEXT_FILE="${OCH_TEST_TMP}/generic context.sh"
	AISTACK_GENERIC_CONTEXT_ADD_RUNTIME="nodejs"
	AISTACK_OPENCODE_LAUNCHER_HOME="${OCH_TEST_TMP}/opencode launcher"
	AISTACK_OPENCODE_LAUNCHER_FILE="${AISTACK_OPENCODE_LAUNCHER_HOME}/opencode"
	export OPENCHAMBER_DATA_DIR="${OCH_TEST_TMP}/config with spaces"
	unset AISTACK_OPENCHAMBER_UI_PASSWORD AISTACK_OPENCHAMBER_TOOL_PATH OCH_TEST_EXIT
	mkdir -p "${AISTACK_OPENCODE_LAUNCHER_HOME}"
	printf '%s\n' '#!/bin/sh' 'exit 0' > "${AISTACK_OPENCODE_LAUNCHER_FILE}"
	chmod +x "${AISTACK_OPENCODE_LAUNCHER_FILE}"
	printf '%s\n' '#!/bin/sh' 'export OCH_GENERIC_LOADED=yes' > "${AISTACK_GENERIC_CONTEXT_FILE}"
	openchamber_init
	aistack_runtime_is_detected() { return 0; }
	aistack_runtime_require() { printf '%s\n' "${@}" >> "${OCH_TEST_TMP}/required-runtime"; }
	node_isolated_package_install() {
		printf '%s\n' "${@}" > "${OCH_TEST_TMP}/package"
		mkdir -p "${1}/bin"
		printf '%s\n' '#!/bin/sh' 'printf "%s\n" "$PWD" "$OPENCHAMBER_UI_PASSWORD" "$OPENCHAMBER_DATA_DIR" "$OCH_GENERIC_LOADED"' 'command -v opencode || :' 'printf "arg:%s\n" "$@"' 'exit "${OCH_TEST_EXIT:-0}"' > "${1}/bin/openchamber"
		chmod +x "${1}/bin/openchamber"
	}
	node_isolated_package_uninstall() { printf '%s\n' "${@}" > "${OCH_TEST_TMP}/uninstalled"; }
}

teardown() {
	rm -rf "${OCH_TEST_TMP}"
}

och_test_main() {
	. "${AISTACK_CURRENT_FILE_DIR}/lib/main_och.sh"
}

och_test_prepare() {
	openchamber_install
	openchamber_settings_configure
	openchamber_launcher_and_context_files_manage create
}

@test "openchamber install uses an isolated package root and defaults to latest" {
	openchamber_install
	assert_equal "$(cat "${OCH_TEST_TMP}/package")" "$(printf '%s\n' "${OPENCHAMBER_FEAT_INSTALL_ROOT}" --allow-scripts=@openchamber/web @openchamber/web@latest)"
	assert_equal "$(cat "${OCH_TEST_TMP}/required-runtime")" nodejs
	assert_equal "${AISTACK_OPENCHAMBER_TOOL_AVAILABLE}" true
	assert_equal "${AISTACK_OPENCHAMBER_TOOL_PATH}" "${OPENCHAMBER_FEAT_INSTALL_ROOT}/bin/openchamber"
	[ ! -f "${AISTACK_OPENCHAMBER_UI_PASSWORD_FILE}" ]
}

@test "openchamber install accepts an explicit npm version and propagates npm failures" {
	openchamber_install @1.18.0
	assert_equal "$(tail -n 1 "${OCH_TEST_TMP}/package")" @openchamber/web@1.18.0
	node_isolated_package_install() { return 4; }
	run openchamber_install
	assert_failure 4
}

@test "openchamber detection clears stale state for a missing binary or runtime" {
	AISTACK_OPENCHAMBER_TOOL_AVAILABLE=true
	AISTACK_OPENCHAMBER_TOOL_PATH=stale
	openchamber_is_installed || :
	assert_equal "${AISTACK_OPENCHAMBER_TOOL_AVAILABLE}" false
	assert_equal "${AISTACK_OPENCHAMBER_TOOL_PATH}" ''
	run openchamber_is_installed
	assert_failure 1
	aistack_runtime_is_detected() { return 1; }
	run openchamber_is_installed
	assert_failure 2
}

@test "openchamber password creation generates twelve alphanumeric characters and refreshes context" {
	och_test_prepare
	local password="$(openchamber_settings_ui_password_get)"
	[ "${#password}" -eq 12 ]
	[[ "${password}" =~ ^[a-zA-Z0-9]+$ ]]
	assert_equal "${AISTACK_OPENCHAMBER_UI_PASSWORD}" "${password}"
	openchamber_settings_ui_password_create
	[ "${password}" != "$(openchamber_settings_ui_password_get)" ]
	run env -i PATH=/usr/bin:/bin /bin/sh "${AISTACK_OPENCHAMBER_LAUNCHER_FILE}" --help
	assert_success
	assert_line --index 1 "${AISTACK_OPENCHAMBER_UI_PASSWORD}"
}

@test "openchamber password setter getter and reset synchronize the file and environment" {
	openchamber_settings_ui_password_set abc123ABC789
	assert_equal "$(openchamber_settings_ui_password_get)" abc123ABC789
	assert_equal "${AISTACK_OPENCHAMBER_UI_PASSWORD}" abc123ABC789
	openchamber_settings_ui_password_reset
	assert_equal "$(openchamber_settings_ui_password_get)" ''
	assert_equal "${AISTACK_OPENCHAMBER_UI_PASSWORD}" ''
}

@test "openchamber CLI install configures password and creates launcher" {
	run och_test_main install @1.18.0
	assert_success
	[ -s "${AISTACK_OPENCHAMBER_UI_PASSWORD_FILE}" ]
	[ -x "${AISTACK_OPENCHAMBER_LAUNCHER_FILE}" ]
	assert_equal "$(tail -n 1 "${OCH_TEST_TMP}/package")" @openchamber/web@1.18.0
}

@test "openchamber standalone launcher restores context without inherited AIStack variables" {
	och_test_prepare
	export OCH_TEST_EXIT=7
	run env -i PATH=/usr/bin:/bin OCH_TEST_EXIT=7 /bin/sh "${AISTACK_OPENCHAMBER_LAUNCHER_FILE}" tunnel 'argument with spaces'
	assert_failure 7
	assert_line --index 0 "${PWD}"
	assert_line --index 1 "${AISTACK_OPENCHAMBER_UI_PASSWORD}"
	assert_line --index 2 "${AISTACK_OPENCHAMBER_CONFIG_HOME}"
	assert_line --index 3 yes
	assert_line --index 4 "${AISTACK_OPENCODE_LAUNCHER_FILE}"
	assert_line --index 5 arg:tunnel
	assert_line --index 6 'arg:argument with spaces'
}

@test "openchamber up forwards a project folder and native options" {
	och_test_prepare
	mkdir -p "${OCH_TEST_TMP}/project with spaces"
	run och_test_main up "${OCH_TEST_TMP}/project with spaces" -- --host 127.0.0.1 --port 3000
	assert_success
	assert_line "${OCH_TEST_TMP}/project with spaces"
	assert_line arg:serve
	assert_line arg:--host
	assert_line arg:127.0.0.1
	assert_line arg:3000
}

@test "openchamber lifecycle wrappers forward native options and exit status" {
	och_test_prepare
	local command native
	for command in up down restart status logs; do
		native="${command}"
		case "${command}" in up) native=serve ;; down) native=stop ;; esac
		run "openchamber_server_${command}" --port 3000
		assert_success
		assert_line "arg:${native}"
		assert_line arg:--port
		assert_line arg:3000
	done
	export OCH_TEST_EXIT=7
	run och_test_main launch -- tunnel providers --json
	assert_failure 7
	assert_line arg:tunnel
	assert_line arg:providers
}

@test "openchamber CLI rejects missing installation project and subcommand" {
	run och_test_main launch -- --help
	assert_failure
	assert_output --partial 'not installed'
	openchamber_install
	run och_test_main up "${OCH_TEST_TMP}/missing" -- --port 3000
	assert_failure
	assert_output --partial 'not found'
	usage() { :; }
	run och_test_main
	assert_failure
	assert_output --partial 'Unknown command'
}

@test "openchamber uninstall stops the server before removing its isolated package and preserves config" {
	och_test_prepare
	printf '%s\n' '{}' > "${AISTACK_OPENCHAMBER_CONFIG_FILE}"
	openchamber_server_down() { [ -x "${AISTACK_OPENCHAMBER_TOOL_PATH}" ]; echo stop > "${OCH_TEST_TMP}/stopped"; }
	openchamber_uninstall
	[ -f "${OCH_TEST_TMP}/stopped" ]
	assert_equal "$(cat "${OCH_TEST_TMP}/uninstalled")" "$(printf '%s\n' "${OPENCHAMBER_FEAT_INSTALL_ROOT}" --allow-scripts=@openchamber/web @openchamber/web)"
	[ ! -d "${OPENCHAMBER_FEAT_INSTALL_ROOT}" ]
	[ -s "${AISTACK_OPENCHAMBER_UI_PASSWORD_FILE}" ]
	[ -f "${AISTACK_OPENCHAMBER_CONFIG_FILE}" ]
}

@test "openchamber uninstall propagates package manager errors" {
	och_test_prepare
	openchamber_server_down() { return 1; }
	node_isolated_package_uninstall() { return 5; }
	run openchamber_uninstall
	assert_failure 5
	[ -d "${OPENCHAMBER_FEAT_INSTALL_ROOT}" ]
}

@test "openchamber info shows detection installation paths and the managed password" {
	och_test_prepare
	run och_test_main info
	assert_success
	assert_output --partial 'OpenChamber available : true'
	assert_output --partial "OpenChamber CLI path : ${AISTACK_OPENCHAMBER_TOOL_PATH}"
	assert_output --partial "OpenChamber UI password : ${AISTACK_OPENCHAMBER_UI_PASSWORD}"
}

@test "openchamber refresh preserves a desktop-only context without a CLI launcher" {
	openchamber_context_file_generate
	openchamber_launcher_and_context_files_manage refresh_if_exists || :
	[ -f "${AISTACK_OPENCHAMBER_CONTEXT_FILE}" ]
	[ ! -f "${AISTACK_OPENCHAMBER_LAUNCHER_FILE}" ]
}

@test "openchamber_server_instance_reachable accepts default and custom HTTP 200 addresses" {
	curl() { printf '%s\n' "${@}" > "${OCH_TEST_TMP}/curl-arguments"; printf '200'; }
	run openchamber_server_instance_reachable
	assert_success
	assert_output ''
	grep -Fx 'http://127.0.0.1:3000' "${OCH_TEST_TMP}/curl-arguments"
	run openchamber_server_instance_reachable https://localhost:3443/
	assert_success
	assert_output ''
	grep -Fx 'https://localhost:3443/' "${OCH_TEST_TMP}/curl-arguments"
}

@test "openchamber_server_instance_reachable reports HTTP errors only on stderr" {
	curl() { printf '401'; }
	run openchamber_server_instance_reachable http://localhost:3001
	assert_failure 1
	assert_output 'ERROR: server returned HTTP 401 for http://localhost:3001'
	openchamber_server_instance_reachable > "${OCH_TEST_TMP}/stdout" 2> "${OCH_TEST_TMP}/stderr" || :
	[ ! -s "${OCH_TEST_TMP}/stdout" ]
	[ -s "${OCH_TEST_TMP}/stderr" ]
}

@test "openchamber_server_instance_reachable reports connection failures and missing curl" {
	curl() { printf '000'; return 7; }
	run openchamber_server_instance_reachable
	assert_failure 1
	assert_output 'ERROR: unable to reach server: http://127.0.0.1:3000'
	curl() { return 127; }
	run openchamber_server_instance_reachable
	assert_failure 1
	assert_output 'ERROR: unable to reach server: http://127.0.0.1:3000'
}
