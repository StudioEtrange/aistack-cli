bats_load_library 'bats-assert'
bats_load_library 'bats-support'
bats_require_minimum_version 1.5.0

setup() {
	# Source only the library: no real Python runtime or network is needed.
	source "${BATS_TEST_DIRNAME}/../../lib/lib_python.sh"
	PYTHON_TEST_TMP="$(mktemp -d "${BATS_TEST_TMPDIR}/python.XXXXXX")"
	PYTHON_TEST_CALLS=0
	PYTHON_TEST_FAIL_COMMAND=""
	PYTHON_TEST_FAIL_STATUS=23
	
	AISTACK_RUNTIME_PYTHON_SEARCH_PATH="${PYTHON_TEST_TMP}/managed python/bin"
	AISTACK_RUNTIME_PYTHON_PATH="${AISTACK_RUNTIME_PYTHON_SEARCH_PATH}/python"
	PYTHON_TEST_ISOLATED="${PYTHON_TEST_TMP}/isolated env"
	mkdir -p "${AISTACK_RUNTIME_PYTHON_SEARCH_PATH}"
	export UV_TOOL_DIR="${PYTHON_TEST_TMP}/original tools"
	export UV_TOOL_BIN_DIR="${PYTHON_TEST_TMP}/original bin"
	PYTHON_TEST_ORIGINAL_PATH="${PATH}"
	PYTHON_TEST_EXPECTED_PATH="${AISTACK_RUNTIME_PYTHON_SEARCH_PATH}:${PYTHON_TEST_ORIGINAL_PATH}"

	uv() {
		python_test_record uv "${@}" || return $?
		if [ "${1} ${2}" = 'venv --python' ]; then
			mkdir -p "${4}/bin"
			touch "${4}/pyvenv.cfg" "${4}/bin/python"
			chmod +x "${4}/bin/python"
		fi
	}
	pip() { python_test_record pip "${@}"; }
	mamba() { python_test_record mamba "${@}"; }
}

teardown() {
	command rm -rf "${PYTHON_TEST_TMP}"
}

python_test_record() {
	PYTHON_TEST_CALLS=$((PYTHON_TEST_CALLS + 1))
	printf '%s\n' "${@}" > "${PYTHON_TEST_TMP}/call-${PYTHON_TEST_CALLS}"
	printf '%s\n' "${PATH}" > "${PYTHON_TEST_TMP}/path-${PYTHON_TEST_CALLS}"
	printf '%s\n' "${UV_TOOL_DIR}" "${UV_TOOL_BIN_DIR}" > "${PYTHON_TEST_TMP}/dirs-${PYTHON_TEST_CALLS}"
	if [ "${1} ${2} ${3}" = "${PYTHON_TEST_FAIL_COMMAND}" ]; then
		return "${PYTHON_TEST_FAIL_STATUS}"
	fi
}

python_test_assert_call() {
	local index="${1}"
	shift
	assert_equal "$(cat "${PYTHON_TEST_TMP}/call-${index}")" "$(printf '%s\n' "${@}")"
	assert_equal "$(cat "${PYTHON_TEST_TMP}/path-${index}")" "${PYTHON_TEST_EXPECTED_PATH}"
}

@test "python_uv_package_install forwards packages and options to the main environment" {
	run python_uv_package_install 'black==25.1.0' 'project[cli]>=1' --index-url 'https://example.invalid/with space'
	assert_success
	python_test_assert_call 1 uv pip install --python "${AISTACK_RUNTIME_PYTHON_PATH}" --reinstall --verbose 'black==25.1.0' 'project[cli]>=1' --index-url 'https://example.invalid/with space'
}

@test "python_uv_package_uninstall targets the main environment" {
	run python_uv_package_uninstall black ruff
	assert_success
	python_test_assert_call 1 uv pip uninstall --python "${AISTACK_RUNTIME_PYTHON_PATH}" --verbose black ruff
}

@test "python package wrappers propagate manager errors" {
	local function_name
	for function_name in python_uv_package_install python_uv_package_uninstall python_pip_package_install python_pip_package_uninstall python_mamba_package_install python_mamba_package_uninstall; do
		uv() { return 23; }
		pip() { return 23; }
		mamba() { return 23; }
		run "${function_name}" black
		assert_failure 23
	done
}

@test "python package wrappers report missing dependencies" {
	unset -f uv pip mamba
	local function_name
	for function_name in python_uv_package_install python_uv_package_uninstall python_pip_package_install python_pip_package_uninstall python_mamba_package_install python_mamba_package_uninstall; do
		PATH="${PYTHON_TEST_TMP}/no executables" run -127 "${function_name}" black
		assert_failure 127
	done
}

@test "python_uv_isolated_package_clean_install replaces an incomplete venv and targets its Python" {
	mkdir -p "${PYTHON_TEST_ISOLATED}"
	touch "${PYTHON_TEST_ISOLATED}/partial"
	run python_uv_isolated_package_clean_install "${PYTHON_TEST_ISOLATED}" black ruff
	assert_success
	[ ! -e "${PYTHON_TEST_ISOLATED}/partial" ]
	python_test_assert_call 1 uv venv --python "${AISTACK_RUNTIME_PYTHON_PATH}" "${PYTHON_TEST_ISOLATED}"
	python_test_assert_call 2 uv pip install --python "${PYTHON_TEST_ISOLATED}/bin/python" --reinstall --verbose black ruff
}

@test "python_uv_isolated_package_clean_install stops when venv creation fails" {
	PYTHON_TEST_FAIL_COMMAND='uv venv --python'
	run python_uv_isolated_package_clean_install "${PYTHON_TEST_ISOLATED}" black
	assert_failure 1
	[ ! -e "${PYTHON_TEST_TMP}/call-2" ]
}

@test "python_uv_isolated_package_clean_install propagates package installation errors" {
	PYTHON_TEST_FAIL_COMMAND='uv pip install'
	run python_uv_isolated_package_clean_install "${PYTHON_TEST_ISOLATED}" black
	assert_failure 23
}

@test "python_uv_isolated_package_uninstall is a no-op without pyvenv.cfg" {
	run python_uv_isolated_package_uninstall "${PYTHON_TEST_ISOLATED}" black
	assert_success
	[ ! -e "${PYTHON_TEST_TMP}/call-1" ]
}

@test "python_uv_isolated_package_uninstall targets the isolated Python not the main runtime" {
	mkdir -p "${PYTHON_TEST_ISOLATED}"
	touch "${PYTHON_TEST_ISOLATED}/pyvenv.cfg"
	run python_uv_isolated_package_uninstall "${PYTHON_TEST_ISOLATED}" black ruff
	assert_success
	python_test_assert_call 1 uv pip uninstall --python "${PYTHON_TEST_ISOLATED}/bin/python" --verbose black ruff
}

@test "python_uv_isolated_package_uninstall propagates uninstall errors" {
	mkdir -p "${PYTHON_TEST_ISOLATED}"
	touch "${PYTHON_TEST_ISOLATED}/pyvenv.cfg"
	PYTHON_TEST_FAIL_COMMAND='uv pip uninstall'
	run python_uv_isolated_package_uninstall "${PYTHON_TEST_ISOLATED}" black
	assert_failure 23
}

@test "python_uv_tool_install uninstalls the tool list before installing each requirement" {
	run python_uv_tool_install 'black==25.1.0 ruff>=0.9'
	assert_success
	python_test_assert_call 1 uv tool uninstall --verbose black
	python_test_assert_call 2 uv tool uninstall --verbose ruff
	python_test_assert_call 3 uv tool install --python "${AISTACK_RUNTIME_PYTHON_PATH}" --reinstall --verbose 'black==25.1.0'
	python_test_assert_call 4 uv tool install --python "${AISTACK_RUNTIME_PYTHON_PATH}" --reinstall --verbose 'ruff>=0.9'
}

@test "python_uv_tool_install tolerates an absent previous installation" {
	PYTHON_TEST_FAIL_COMMAND='uv tool uninstall'
	run python_uv_tool_install black
	assert_success
	python_test_assert_call 2 uv tool install --python "${AISTACK_RUNTIME_PYTHON_PATH}" --reinstall --verbose black
}

@test "python_uv_tool_install stops after the first failed installation" {
	PYTHON_TEST_FAIL_COMMAND='uv tool install'
	run python_uv_tool_install 'black ruff'
	assert_failure 1
	[ ! -e "${PYTHON_TEST_TMP}/call-4" ]
}

@test "python tool uninstall strips versions operators and extras" {
	local function_name
	for function_name in python_uv_tool_uninstall python_uv_isolated_tool_uninstall; do
		if [ "${function_name}" = python_uv_isolated_tool_uninstall ]; then
			run "${function_name}" "${PYTHON_TEST_ISOLATED}" 'black==25.1.0 ruff>=0.9 foo<=2 bar!=1 baz~=1.2 qux[cli]==3 plain'
		else
			run "${function_name}" 'black==25.1.0 ruff>=0.9 foo<=2 bar!=1 baz~=1.2 qux[cli]==3 plain'
		fi
		assert_success
		python_test_assert_call 1 uv tool uninstall --verbose black
		python_test_assert_call 2 uv tool uninstall --verbose ruff
		python_test_assert_call 3 uv tool uninstall --verbose foo
		python_test_assert_call 4 uv tool uninstall --verbose bar
		python_test_assert_call 5 uv tool uninstall --verbose baz
		python_test_assert_call 6 uv tool uninstall --verbose qux
		python_test_assert_call 7 uv tool uninstall --verbose plain
	done
}

@test "python tool uninstall stops after the first failure" {
	PYTHON_TEST_FAIL_COMMAND='uv tool uninstall'
	run python_uv_tool_uninstall 'black ruff'
	assert_failure 1
	[ ! -e "${PYTHON_TEST_TMP}/call-2" ]
	run python_uv_isolated_tool_uninstall "${PYTHON_TEST_ISOLATED}" 'black ruff'
	assert_failure 1
	[ ! -e "${PYTHON_TEST_TMP}/call-2" ]
}

@test "python_uv_isolated_tool_clean_install replaces its root and scopes tool directories" {
	PYTHON_TEST_EXPECTED_PATH="${PYTHON_TEST_ISOLATED}/bin:${PYTHON_TEST_EXPECTED_PATH}"
	mkdir -p "${PYTHON_TEST_ISOLATED}"
	touch "${PYTHON_TEST_ISOLATED}/partial"
	run python_uv_isolated_tool_clean_install "${PYTHON_TEST_ISOLATED}" 'black==25.1.0 ruff'
	assert_success
	[ ! -e "${PYTHON_TEST_ISOLATED}/partial" ]
	python_test_assert_call 1 uv tool install --python "${AISTACK_RUNTIME_PYTHON_PATH}" --reinstall --verbose 'black==25.1.0'
	python_test_assert_call 2 uv tool install --python "${AISTACK_RUNTIME_PYTHON_PATH}" --reinstall --verbose ruff
	assert_equal "$(cat "${PYTHON_TEST_TMP}/dirs-1")" "$(printf '%s\n' "${PYTHON_TEST_ISOLATED}/tools" "${PYTHON_TEST_ISOLATED}/bin")"
	assert_equal "$(cat "${PYTHON_TEST_TMP}/dirs-2")" "$(cat "${PYTHON_TEST_TMP}/dirs-1")"
	[ ! -e "${PYTHON_TEST_TMP}/call-3" ]
}

@test "python_uv_isolated_tool_clean_install stops after the first failed installation" {
	PYTHON_TEST_FAIL_COMMAND='uv tool install'
	run python_uv_isolated_tool_clean_install "${PYTHON_TEST_ISOLATED}" 'black ruff'
	assert_failure 23
	[ ! -e "${PYTHON_TEST_TMP}/call-2" ]
}

@test "python_uv_isolated_tool_uninstall scopes directories without deleting its root" {
	mkdir -p "${PYTHON_TEST_ISOLATED}"
	touch "${PYTHON_TEST_ISOLATED}/keep"
	run python_uv_isolated_tool_uninstall "${PYTHON_TEST_ISOLATED}" 'black[cli]==25.1.0'
	assert_success
	python_test_assert_call 1 uv tool uninstall --verbose black
	assert_equal "$(cat "${PYTHON_TEST_TMP}/dirs-1")" "$(printf '%s\n' "${PYTHON_TEST_ISOLATED}/tools" "${PYTHON_TEST_ISOLATED}/bin")"
	[ -f "${PYTHON_TEST_ISOLATED}/keep" ]
}

@test "python package and tool wrappers do not leak PATH or UV directory changes" {
	# Deliberately do not use run: inspect the calling shell, not a subshell.
	python_uv_package_install black
	python_uv_package_uninstall black
	python_uv_isolated_package_clean_install "${PYTHON_TEST_ISOLATED}" black
	python_uv_isolated_package_install "${PYTHON_TEST_ISOLATED}" ruff
	python_uv_tool_install black
	python_uv_tool_uninstall black
	python_uv_isolated_tool_clean_install "${PYTHON_TEST_ISOLATED}" black
	python_uv_isolated_tool_install "${PYTHON_TEST_ISOLATED}" ruff
	python_uv_isolated_tool_uninstall "${PYTHON_TEST_ISOLATED}" black
	python_pip_package_install black
	python_pip_package_uninstall black
	python_mamba_package_install black
	python_mamba_package_uninstall black
	assert_equal "${PATH}" "${PYTHON_TEST_ORIGINAL_PATH}"
	assert_equal "${UV_TOOL_DIR}" "${PYTHON_TEST_TMP}/original tools"
	assert_equal "${UV_TOOL_BIN_DIR}" "${PYTHON_TEST_TMP}/original bin"
}

@test "python_pip_package_install preserves build policy and argument boundaries" {
	run python_pip_package_install 'project[cli]==1.0' '/path with spaces/package.whl'
	assert_success
	python_test_assert_call 1 pip install --no-cache-dir --no-binary=yara-x --force-reinstall --verbose 'project[cli]==1.0' '/path with spaces/package.whl'
}

@test "python_pip_package_uninstall is noninteractive" {
	run python_pip_package_uninstall black ruff
	assert_success
	python_test_assert_call 1 pip uninstall --yes --verbose black ruff
}

@test "python_mamba_package_install forwards multiple specifications" {
	run python_mamba_package_install 'python=3.12' 'numpy>=2'
	assert_success
	python_test_assert_call 1 mamba install -y 'python=3.12' 'numpy>=2'
}

@test "python_mamba_package_uninstall uses remove noninteractively" {
	run python_mamba_package_uninstall black ruff
	assert_success
	python_test_assert_call 1 mamba remove -y black ruff
}

# Safety regressions: rm is intercepted so malformed inputs can never delete data.
@test "python_uv_isolated_package_install creates a missing venv" {
	run python_uv_isolated_package_install "${PYTHON_TEST_ISOLATED}" black --no-deps
	assert_success
	python_test_assert_call 1 uv venv --python "${AISTACK_RUNTIME_PYTHON_PATH}" "${PYTHON_TEST_ISOLATED}"
	python_test_assert_call 2 uv pip install --python "${PYTHON_TEST_ISOLATED}/bin/python" --reinstall --verbose black --no-deps
}

@test "python_uv_isolated_package_install preserves an existing venv" {
	mkdir -p "${PYTHON_TEST_ISOLATED}/bin"
	touch "${PYTHON_TEST_ISOLATED}/pyvenv.cfg" "${PYTHON_TEST_ISOLATED}/bin/python" "${PYTHON_TEST_ISOLATED}/keep"
	chmod +x "${PYTHON_TEST_ISOLATED}/bin/python"
	run python_uv_isolated_package_install "${PYTHON_TEST_ISOLATED}" black
	assert_success
	[ -f "${PYTHON_TEST_ISOLATED}/keep" ]
	python_test_assert_call 1 uv pip install --python "${PYTHON_TEST_ISOLATED}/bin/python" --reinstall --verbose black
	[ ! -e "${PYTHON_TEST_TMP}/call-2" ]
}

@test "python_uv_isolated_package_install rejects a broken existing venv" {
	mkdir -p "${PYTHON_TEST_ISOLATED}"
	touch "${PYTHON_TEST_ISOLATED}/pyvenv.cfg"
	run python_uv_isolated_package_install "${PYTHON_TEST_ISOLATED}" black
	assert_failure 1
	assert_output --partial 'ERROR: invalid Python venv:'
	[ ! -e "${PYTHON_TEST_TMP}/call-1" ]
}

@test "python_uv_isolated_package_install stops when venv creation fails" {
	PYTHON_TEST_FAIL_COMMAND='uv venv --python'
	run python_uv_isolated_package_install "${PYTHON_TEST_ISOLATED}" black
	assert_failure 1
	[ ! -e "${PYTHON_TEST_TMP}/call-2" ]
}

@test "python_uv_isolated_package_install propagates installation errors" {
	PYTHON_TEST_FAIL_COMMAND='uv pip install'
	run python_uv_isolated_package_install "${PYTHON_TEST_ISOLATED}" black
	assert_failure 23
}

@test "python isolated tool installers forward options and preserve dependency path boundaries" {
	local function_name
	PYTHON_TEST_EXPECTED_PATH="${PYTHON_TEST_ISOLATED}/bin:${PYTHON_TEST_EXPECTED_PATH}"
	for function_name in python_uv_isolated_tool_install python_uv_isolated_tool_clean_install; do
		run "${function_name}" "${PYTHON_TEST_ISOLATED}" black --with "${PYTHON_TEST_TMP}/dependency wheel.whl" --no-index
		assert_success
		python_test_assert_call 1 uv tool install --python "${AISTACK_RUNTIME_PYTHON_PATH}" --reinstall --verbose --with "${PYTHON_TEST_TMP}/dependency wheel.whl" --no-index black
	done
}

@test "python_uv_isolated_tool_install preserves other tools in its root" {
	PYTHON_TEST_EXPECTED_PATH="${PYTHON_TEST_ISOLATED}/bin:${PYTHON_TEST_EXPECTED_PATH}"
	mkdir -p "${PYTHON_TEST_ISOLATED}/tools/existing"
	touch "${PYTHON_TEST_ISOLATED}/tools/existing/keep"
	run python_uv_isolated_tool_install "${PYTHON_TEST_ISOLATED}" 'black ruff'
	assert_success
	[ -f "${PYTHON_TEST_ISOLATED}/tools/existing/keep" ]
	python_test_assert_call 1 uv tool install --python "${AISTACK_RUNTIME_PYTHON_PATH}" --reinstall --verbose black
	python_test_assert_call 2 uv tool install --python "${AISTACK_RUNTIME_PYTHON_PATH}" --reinstall --verbose ruff
}

@test "python_uv_tool_install does not forward installation-only options to uninstall" {
	run python_uv_tool_install black --with "${PYTHON_TEST_TMP}/dependency wheel.whl"
	assert_success
	python_test_assert_call 1 uv tool uninstall --verbose black
	python_test_assert_call 2 uv tool install --python "${AISTACK_RUNTIME_PYTHON_PATH}" --reinstall --verbose --with "${PYTHON_TEST_TMP}/dependency wheel.whl" black
}

@test "python tool uninstall forwards its own options" {
	run python_uv_tool_uninstall black --offline
	assert_success
	python_test_assert_call 1 uv tool uninstall --verbose --offline black
	run python_uv_isolated_tool_uninstall "${PYTHON_TEST_ISOLATED}" black --offline
	assert_success
	python_test_assert_call 1 uv tool uninstall --verbose --offline black
}

@test "python non-clean isolated installers reject missing arguments without manager calls" {
	local function_name
	for function_name in python_uv_isolated_package_install python_uv_isolated_tool_install; do
		python_test_reject_missing_path "${function_name}"
		python_test_reject_no_packages "${function_name}"
		python_test_reject_invalid_path "${function_name}" ''
	done
}

python_test_with_mock_rm() (
	# Keep the mock in run's subshell, away from Bats cleanup.
	rm() { printf '%s\n' "${@}" > "${PYTHON_TEST_TMP}/rm-call"; }
	"${@}"
)

python_test_reject_missing_path() {
	run python_test_with_mock_rm "${1}"
	assert_failure
	[ ! -e "${PYTHON_TEST_TMP}/rm-call" ]
	[ ! -e "${PYTHON_TEST_TMP}/call-1" ]
}

python_test_reject_no_packages() {
	run python_test_with_mock_rm "${1}" "${PYTHON_TEST_ISOLATED}"
	assert_failure
	[ ! -e "${PYTHON_TEST_TMP}/rm-call" ]
	[ ! -e "${PYTHON_TEST_TMP}/call-1" ]
}

python_test_reject_invalid_path() {
	run python_test_with_mock_rm "${1}" "${2}" black
	assert_failure
	[ ! -e "${PYTHON_TEST_TMP}/rm-call" ]
	[ ! -e "${PYTHON_TEST_TMP}/call-1" ]
}

@test "python_uv_isolated_package_clean_install rejects a missing path before deletion" {
	python_test_reject_missing_path python_uv_isolated_package_clean_install
}

@test "python_uv_isolated_tool_clean_install rejects a missing path before deletion" {
	python_test_reject_missing_path python_uv_isolated_tool_clean_install
}

@test "python_uv_isolated_package_clean_install rejects a path without packages before deletion" {
	python_test_reject_no_packages python_uv_isolated_package_clean_install
}

@test "python_uv_isolated_tool_clean_install rejects a path without tools before deletion" {
	python_test_reject_no_packages python_uv_isolated_tool_clean_install
}

@test "python_uv_isolated_package_clean_install rejects an empty path before deletion" {
	python_test_reject_invalid_path python_uv_isolated_package_clean_install ''
}

@test "python_uv_isolated_tool_clean_install rejects an empty path before deletion" {
	python_test_reject_invalid_path python_uv_isolated_tool_clean_install ''
}
