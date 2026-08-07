bats_load_library 'bats-assert'
bats_load_library 'bats-support'

setup() {
	load 'stella_bats_helper.bash'
	OPENCHAMBER_TEST_TMP="$(mktemp -d)"
	HOME="${OPENCHAMBER_TEST_TMP}/home"
	AISTACK_LAUNCHER_HOME="${OPENCHAMBER_TEST_TMP}/launcher"
	AISTACK_RUNTIME_NODEJS_SEARCH_PATH="${OPENCHAMBER_TEST_TMP}/node/bin"
	AISTACK_TOOL_CONTEXT_FILE="${OPENCHAMBER_TEST_TMP}/tool_context.sh"
	AISTACK_OPENCODE_TOOL_PATH="${OPENCHAMBER_TEST_TMP}/opencode"
	mkdir -p "${HOME}" "${AISTACK_RUNTIME_NODEJS_SEARCH_PATH}"
	printf '%s\n' '#!/bin/sh' > "${AISTACK_TOOL_CONTEXT_FILE}"
	openchamber_init
}

teardown() {
	rm -rf "${OPENCHAMBER_TEST_TMP}"
}

create_openchamber() {
	cat > "${AISTACK_RUNTIME_NODEJS_SEARCH_PATH}/openchamber" <<'EOF'
#!/bin/sh
printf 'PASSWORD=%s\n' "${OPENCHAMBER_UI_PASSWORD}"
printf '%s\n' "$@"
EOF
	chmod +x "${AISTACK_RUNTIME_NODEJS_SEARCH_PATH}/openchamber"
	AISTACK_OPENCHAMBER_TOOL_PATH="${AISTACK_RUNTIME_NODEJS_SEARCH_PATH}/openchamber"
}

create_password_generator() {
	STELLA_API="${OPENCHAMBER_TEST_TMP}/stella-api"
	cat > "${STELLA_API}" <<'EOF'
#!/bin/sh
if [ "$1" = "generate_password" ]; then
	printf '%s\n' 'Generated123'
	exit 0
fi
exit 1
EOF
	chmod +x "${STELLA_API}"
}

@test "openchamber_init defines the UI password file in the data directory" {
	assert_equal "${AISTACK_OPENCHAMBER_UI_PASSWORD_FILE}" "${HOME}/.config/openchamber/ui-password"
}

@test "openchamber_settings_ui_password_create writes the generated password" {
	create_password_generator

	run openchamber_settings_ui_password_create
	assert_success
	assert_equal "$(openchamber_settings_ui_password_get)" "Generated123"
	[ -f "${AISTACK_OPENCHAMBER_UI_PASSWORD_FILE}" ]
}

@test "openchamber_settings_ui_password_reset empties the password file" {
	openchamber_settings_ui_password_set "Existing123"

	openchamber_settings_ui_password_reset

	[ -f "${AISTACK_OPENCHAMBER_UI_PASSWORD_FILE}" ]
	[ ! -s "${AISTACK_OPENCHAMBER_UI_PASSWORD_FILE}" ]
}

@test "openchamber_daemon_up uses native serve and the managed password" {
	create_openchamber
	openchamber_settings_ui_password_set "Managed123"
	opencode_is_installed() {
		return 0
	}

	run openchamber_daemon_up --port 3000 --host 127.0.0.1
	assert_success
	assert_line --index 0 "PASSWORD=Managed123"
	assert_line --index 1 "serve"
	assert_line --index 2 "--port"
	assert_line --index 3 "3000"
	assert_line --index 4 "--host"
	assert_line --index 5 "127.0.0.1"
}

@test "openchamber_daemon_up creates a missing password" {
	create_openchamber
	create_password_generator
	opencode_is_installed() {
		return 0
	}

	run openchamber_daemon_up --port 3000
	assert_success
	assert_output --partial "New OpenChamber UI password created : Generated123"
	assert_output --partial "PASSWORD=Generated123"
}

@test "openchamber_daemon_up rejects a manual UI password" {
	create_openchamber
	openchamber_settings_ui_password_set "Managed123"
	opencode_is_installed() {
		return 0
	}

	run openchamber_daemon_up --ui-password manual
	assert_failure
	assert_output --partial "UI password is managed in"
}

@test "openchamber native lifecycle commands forward arguments" {
	create_openchamber

	run openchamber_daemon_down --port 3000
	assert_success
	assert_line --index 1 "stop"
	assert_line --index 2 "--port"
	assert_line --index 3 "3000"

	run openchamber_daemon_status --json
	assert_success
	assert_line --index 1 "status"
	assert_line --index 2 "--json"

	run openchamber_daemon_logs --no-follow
	assert_success
	assert_line --index 1 "logs"
	assert_line --index 2 "--no-follow"
}

@test "openchamber_daemon_restart uses native restart and managed password" {
	create_openchamber
	openchamber_settings_ui_password_set "Managed123"

	run openchamber_daemon_restart --port 3000
	assert_success
	assert_line --index 0 "PASSWORD=Managed123"
	assert_line --index 1 "restart"
	assert_line --index 2 "--port"
	assert_line --index 3 "3000"
}
