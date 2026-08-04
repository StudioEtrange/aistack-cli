bats_load_library 'bats-assert'
bats_load_library 'bats-support'

setup() {
	load 'stella_bats_helper.bash'
	PLAYWRIGHT_TEST_TMP="$(mktemp -d)"
	AISTACK_LAUNCHER_HOME="${PLAYWRIGHT_TEST_TMP}/launcher"
	AISTACK_RUNTIME_NODEJS_SEARCH_PATH="${PLAYWRIGHT_TEST_TMP}/node/bin"
	AISTACK_TOOL_CONTEXT_FILE="${PLAYWRIGHT_TEST_TMP}/tool_context.sh"
	mkdir -p "${AISTACK_RUNTIME_NODEJS_SEARCH_PATH}"
	printf '%s\n' '#!/bin/sh' > "${AISTACK_TOOL_CONTEXT_FILE}"
	playwright_init
}

teardown() {
	rm -rf "${PLAYWRIGHT_TEST_TMP}"
}

@test "playwright_is_installed reports a missing runtime" {
	aistack_runtime_is_detected() {
		return 1
	}

	run playwright_is_installed
	assert_failure 2
}

@test "playwright_is_installed detects the managed binary" {
	aistack_runtime_is_detected() {
		return 0
	}
	printf '%s\n' '#!/bin/sh' > "${AISTACK_RUNTIME_NODEJS_SEARCH_PATH}/playwright-cli"
	chmod +x "${AISTACK_RUNTIME_NODEJS_SEARCH_PATH}/playwright-cli"

	playwright_is_installed

	assert_equal "${AISTACK_PLAYWRIGHT_TOOL_AVAILABLE}" "true"
	assert_equal "${AISTACK_PLAYWRIGHT_TOOL_PATH}" "${AISTACK_RUNTIME_NODEJS_SEARCH_PATH}/playwright-cli"
}

@test "playwright_install installs latest by default" {
	aistack_runtime_require() {
		return 0
	}
	node_package_install() {
		printf '%s' "$1" > "${PLAYWRIGHT_TEST_TMP}/installed-package"
		printf '%s\n' '#!/bin/sh' > "${AISTACK_RUNTIME_NODEJS_SEARCH_PATH}/playwright-cli"
		chmod +x "${AISTACK_RUNTIME_NODEJS_SEARCH_PATH}/playwright-cli"
	}
	aistack_runtime_is_detected() {
		return 0
	}

	run playwright_install
	assert_success
	assert_equal "$(cat "${PLAYWRIGHT_TEST_TMP}/installed-package")" "@playwright/cli@latest"
}

@test "playwright_install accepts an explicit npm version" {
	aistack_runtime_require() {
		return 0
	}
	node_package_install() {
		printf '%s' "$1" > "${PLAYWRIGHT_TEST_TMP}/installed-package"
		printf '%s\n' '#!/bin/sh' > "${AISTACK_RUNTIME_NODEJS_SEARCH_PATH}/playwright-cli"
		chmod +x "${AISTACK_RUNTIME_NODEJS_SEARCH_PATH}/playwright-cli"
	}
	aistack_runtime_is_detected() {
		return 0
	}

	run playwright_install "@1.2.3"
	assert_success
	assert_equal "$(cat "${PLAYWRIGHT_TEST_TMP}/installed-package")" "@playwright/cli@1.2.3"
}

@test "playwright_launch forwards arguments to the managed binary" {
	cat > "${AISTACK_RUNTIME_NODEJS_SEARCH_PATH}/playwright-cli" <<'EOF'
#!/bin/sh
printf '%s\n' "$@"
EOF
	chmod +x "${AISTACK_RUNTIME_NODEJS_SEARCH_PATH}/playwright-cli"

	run playwright_launch open https://example.com --headed
	assert_success
	assert_line --index 0 "open"
	assert_line --index 1 "https://example.com"
	assert_line --index 2 "--headed"
}


@test "playwright_launcher_manage creates an executable wrapper" {
	aistack_runtime_is_detected() {
		return 0
	}
	shell_quote_posix() {
		printf "'%s'" "$1"
	}
	printf '%s\n' '#!/bin/sh' > "${AISTACK_RUNTIME_NODEJS_SEARCH_PATH}/playwright-cli"
	chmod +x "${AISTACK_RUNTIME_NODEJS_SEARCH_PATH}/playwright-cli"

	playwright_launcher_manage create

	[ -x "${AISTACK_PLAYWRIGHT_LAUNCHER_HOME}/playwright-cli" ]
}
