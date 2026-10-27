bats_load_library 'bats-assert'
bats_load_library 'bats-support'

setup() {
	load 'stella_bats_helper.bash'
	[ -x "${AISTACK_RUNTIME_PYTHON_PATH}" ] || {
		echo "ERROR: run with ./test/launch_test.sh python_integration" >&2
		return 1
	}
	PYTHON_INTEGRATION_TMP="$(mktemp -d "${BATS_TEST_TMPDIR}/python-integration.XXXXXX")"
	PYTHON_INTEGRATION_ENV="${PYTHON_INTEGRATION_TMP}/isolated env"
	export UV_TOOL_DIR="${PYTHON_INTEGRATION_TMP}/default tools"
	export UV_TOOL_BIN_DIR="${PYTHON_INTEGRATION_TMP}/default bin"
	export UV_CACHE_DIR="${PYTHON_INTEGRATION_TMP}/cache"
	export UV_OFFLINE=true
	export UV_PYTHON_DOWNLOADS=never
	PYTHON_INTEGRATION_WHEEL="${PYTHON_INTEGRATION_TMP}/aistack_test_fixture-1.0.0-py3-none-any.whl"
	PYTHON_INTEGRATION_SECOND_WHEEL="${PYTHON_INTEGRATION_TMP}/aistack_test_second-1.0.0-py3-none-any.whl"
	# Build a dependency-free wheel with the standard library, not pip/build.
	"${AISTACK_RUNTIME_PYTHON_PATH}" - "${PYTHON_INTEGRATION_WHEEL}" "${PYTHON_INTEGRATION_SECOND_WHEEL}" <<'PY'
import base64
import csv
import hashlib
import io
import sys
import zipfile

dist = "aistack_test_fixture-1.0.0.dist-info"
files = {
    "aistack_test_fixture.py": 'def main():\n    print("aistack fixture 1.0.0")\n',
    dist + "/METADATA": "Metadata-Version: 2.1\nName: aistack-test-fixture\nVersion: 1.0.0\n\n",
    dist + "/WHEEL": "Wheel-Version: 1.0\nGenerator: aistack-tests\nRoot-Is-Purelib: true\nTag: py3-none-any\n\n",
    dist + "/entry_points.txt": "[console_scripts]\naistack-fixture = aistack_test_fixture:main\n",
}
record = io.StringIO(newline="")
writer = csv.writer(record)
with zipfile.ZipFile(sys.argv[1], "w") as wheel:
    for name, text in files.items():
        data = text.encode()
        digest = base64.urlsafe_b64encode(hashlib.sha256(data).digest()).rstrip(b"=").decode()
        writer.writerow([name, "sha256=" + digest, len(data)])
        wheel.writestr(name, data)
    writer.writerow([dist + "/RECORD", "", ""])
    wheel.writestr(dist + "/RECORD", record.getvalue())

# A second independent package also serves as a --with dependency fixture.
dist = "aistack_test_second-1.0.0.dist-info"
files = {
    "aistack_test_second.py": 'def main():\n    print("aistack second 1.0.0")\n',
    dist + "/METADATA": "Metadata-Version: 2.1\nName: aistack-test-second\nVersion: 1.0.0\n\n",
    dist + "/WHEEL": "Wheel-Version: 1.0\nGenerator: aistack-tests\nRoot-Is-Purelib: true\nTag: py3-none-any\n\n",
    dist + "/entry_points.txt": "[console_scripts]\naistack-second = aistack_test_second:main\n",
}
record = io.StringIO(newline="")
writer = csv.writer(record)
with zipfile.ZipFile(sys.argv[2], "w") as wheel:
    for name, text in files.items():
        data = text.encode()
        digest = base64.urlsafe_b64encode(hashlib.sha256(data).digest()).rstrip(b"=").decode()
        writer.writerow([name, "sha256=" + digest, len(data)])
        wheel.writestr(name, data)
    writer.writerow([dist + "/RECORD", "", ""])
    wheel.writestr(dist + "/RECORD", record.getvalue())
PY
}

teardown() {
	if [ -n "${PYTHON_INTEGRATION_TMP}" ]; then
		command rm -rf -- "${PYTHON_INTEGRATION_TMP}"
	fi
}

@test "python integration creates a venv with an importable package and executable CLI" {
	mkdir -p "${PYTHON_INTEGRATION_ENV}"
	touch "${PYTHON_INTEGRATION_ENV}/partial"
	run python_uv_isolated_package_clean_install "${PYTHON_INTEGRATION_ENV}" "${PYTHON_INTEGRATION_WHEEL}"
	assert_success
	[ ! -e "${PYTHON_INTEGRATION_ENV}/partial" ]
	[ -f "${PYTHON_INTEGRATION_ENV}/pyvenv.cfg" ]
	run "${PYTHON_INTEGRATION_ENV}/bin/python" -c 'import aistack_test_fixture; aistack_test_fixture.main()'
	assert_success
	assert_output 'aistack fixture 1.0.0'
	run "${PYTHON_INTEGRATION_ENV}/bin/aistack-fixture"
	assert_success
	assert_output 'aistack fixture 1.0.0'
}

@test "python integration uninstalls a package from the dedicated venv" {
	python_uv_isolated_package_clean_install "${PYTHON_INTEGRATION_ENV}" "${PYTHON_INTEGRATION_WHEEL}"
	run python_uv_isolated_package_uninstall "${PYTHON_INTEGRATION_ENV}" aistack-test-fixture
	assert_success
	[ -f "${PYTHON_INTEGRATION_ENV}/pyvenv.cfg" ]
	run "${PYTHON_INTEGRATION_ENV}/bin/python" -c 'import importlib.util; assert importlib.util.find_spec("aistack_test_fixture") is None'
	assert_success
	[ ! -e "${PYTHON_INTEGRATION_ENV}/bin/aistack-fixture" ]
}

@test "python integration installs and uninstalls a tool in dedicated directories" {
	run python_uv_isolated_tool_clean_install "${PYTHON_INTEGRATION_ENV}" "${PYTHON_INTEGRATION_WHEEL}"
	assert_success
	[ -f "${PYTHON_INTEGRATION_ENV}/tools/aistack-test-fixture/pyvenv.cfg" ]
	[ ! -e "${PYTHON_INTEGRATION_ENV}/bin/python" ]
	run "${PYTHON_INTEGRATION_ENV}/bin/aistack-fixture"
	assert_success
	assert_output 'aistack fixture 1.0.0'
	run python_uv_isolated_tool_uninstall "${PYTHON_INTEGRATION_ENV}" 'aistack-test-fixture==1.0.0'
	assert_success
	[ ! -e "${PYTHON_INTEGRATION_ENV}/bin/aistack-fixture" ]
	[ ! -e "${PYTHON_INTEGRATION_ENV}/tools/aistack-test-fixture" ]
}

@test "python integration scopes default tool operations to temporary directories" {
	run python_uv_tool_install "${PYTHON_INTEGRATION_WHEEL}"
	assert_success
	run "${UV_TOOL_BIN_DIR}/aistack-fixture"
	assert_success
	assert_output 'aistack fixture 1.0.0'
	run python_uv_tool_uninstall 'aistack-test-fixture==1.0.0'
	assert_success
	[ ! -e "${UV_TOOL_BIN_DIR}/aistack-fixture" ]
	[ ! -e "${UV_TOOL_DIR}/aistack-test-fixture" ]
}

@test "python integration non-clean package installation creates then preserves a venv" {
	python_uv_isolated_package_install "${PYTHON_INTEGRATION_ENV}" "${PYTHON_INTEGRATION_WHEEL}"
	touch "${PYTHON_INTEGRATION_ENV}/keep"
	run python_uv_isolated_package_install "${PYTHON_INTEGRATION_ENV}" "${PYTHON_INTEGRATION_SECOND_WHEEL}"
	assert_success
	[ -f "${PYTHON_INTEGRATION_ENV}/keep" ]
	run "${PYTHON_INTEGRATION_ENV}/bin/python" -c 'import aistack_test_fixture, aistack_test_second'
	assert_success
}

@test "python integration non-clean tool installation preserves previously installed tools" {
	python_uv_isolated_tool_install "${PYTHON_INTEGRATION_ENV}" "${PYTHON_INTEGRATION_WHEEL}"
	run python_uv_isolated_tool_install "${PYTHON_INTEGRATION_ENV}" "${PYTHON_INTEGRATION_SECOND_WHEEL}"
	assert_success
	run "${PYTHON_INTEGRATION_ENV}/bin/aistack-fixture"
	assert_success
	assert_output 'aistack fixture 1.0.0'
	run "${PYTHON_INTEGRATION_ENV}/bin/aistack-second"
	assert_success
	assert_output 'aistack second 1.0.0'
}

@test "python integration clean tool installation removes previously installed tools" {
	python_uv_isolated_tool_install "${PYTHON_INTEGRATION_ENV}" "${PYTHON_INTEGRATION_WHEEL}"
	run python_uv_isolated_tool_clean_install "${PYTHON_INTEGRATION_ENV}" "${PYTHON_INTEGRATION_SECOND_WHEEL}"
	assert_success
	[ ! -e "${PYTHON_INTEGRATION_ENV}/tools/aistack-test-fixture" ]
	[ ! -e "${PYTHON_INTEGRATION_ENV}/bin/aistack-fixture" ]
	run "${PYTHON_INTEGRATION_ENV}/bin/aistack-second"
	assert_success
}

@test "python integration isolated tool installation includes a local wheel with --with" {
	run python_uv_isolated_tool_clean_install "${PYTHON_INTEGRATION_ENV}" "${PYTHON_INTEGRATION_WHEEL}" --with "${PYTHON_INTEGRATION_SECOND_WHEEL}"
	assert_success
	run "${PYTHON_INTEGRATION_ENV}/tools/aistack-test-fixture/bin/python" -c 'import aistack_test_fixture, aistack_test_second'
	assert_success
	[ ! -e "${PYTHON_INTEGRATION_ENV}/tools/aistack-test-second" ]
}

@test "python integration installs and uninstalls a tool list using local wheels" {
	run python_uv_isolated_tool_install "${PYTHON_INTEGRATION_ENV}" \
		'aistack-test-fixture aistack-test-second' --no-index --find-links "${PYTHON_INTEGRATION_TMP}"
	assert_success
	[ -x "${PYTHON_INTEGRATION_ENV}/bin/aistack-fixture" ]
	[ -x "${PYTHON_INTEGRATION_ENV}/bin/aistack-second" ]
	run python_uv_isolated_tool_uninstall "${PYTHON_INTEGRATION_ENV}" \
		'aistack-test-fixture aistack-test-second'
	assert_success
	[ ! -e "${PYTHON_INTEGRATION_ENV}/tools/aistack-test-fixture" ]
	[ ! -e "${PYTHON_INTEGRATION_ENV}/tools/aistack-test-second" ]
}

@test "python integration installs a real package with scripts using uv pip not uv tool" {
	export UV_OFFLINE=false
	run python_uv_isolated_package_clean_install "${PYTHON_INTEGRATION_ENV}" 'Pygments==2.19.2'
	assert_success
	[ -f "${PYTHON_INTEGRATION_ENV}/pyvenv.cfg" ]
	[ -x "${PYTHON_INTEGRATION_ENV}/bin/python" ]
	[ -x "${PYTHON_INTEGRATION_ENV}/bin/pygmentize" ]
	[ ! -e "${PYTHON_INTEGRATION_ENV}/tools" ]
	[ ! -e "${UV_TOOL_DIR}/pygments" ]
	run "${PYTHON_INTEGRATION_ENV}/bin/python" -c 'import pygments; print(pygments.__version__)'
	assert_success
	assert_output '2.19.2'
	run "${PYTHON_INTEGRATION_ENV}/bin/pygmentize" -V
	assert_success
	assert_output --partial 'Pygments version 2.19.2'
	run python_uv_isolated_package_uninstall "${PYTHON_INTEGRATION_ENV}" Pygments
	assert_success
	[ ! -e "${PYTHON_INTEGRATION_ENV}/bin/pygmentize" ]
	run "${PYTHON_INTEGRATION_ENV}/bin/python" -c 'import importlib.util; assert importlib.util.find_spec("pygments") is None'
	assert_success
}

@test "python integration installs real ruff and black tools in separate dedicated venvs" {
	export UV_OFFLINE=false
	run python_uv_isolated_tool_clean_install "${PYTHON_INTEGRATION_ENV}" 'ruff==0.11.13 black==25.1.0'
	assert_success
	[ -f "${PYTHON_INTEGRATION_ENV}/tools/ruff/pyvenv.cfg" ]
	[ -f "${PYTHON_INTEGRATION_ENV}/tools/black/pyvenv.cfg" ]
	[ ! -e "${PYTHON_INTEGRATION_ENV}/bin/python" ]
	[ -x "${PYTHON_INTEGRATION_ENV}/bin/blackd" ]
	run "${PYTHON_INTEGRATION_ENV}/bin/ruff" --version
	assert_success
	assert_output 'ruff 0.11.13'
	run "${PYTHON_INTEGRATION_ENV}/bin/black" --version
	assert_success
	assert_output --partial '25.1.0'
	run python_uv_isolated_tool_uninstall "${PYTHON_INTEGRATION_ENV}" 'ruff==0.11.13 black==25.1.0'
	assert_success
	[ ! -e "${PYTHON_INTEGRATION_ENV}/bin/ruff" ]
	[ ! -e "${PYTHON_INTEGRATION_ENV}/bin/black" ]
	[ ! -e "${PYTHON_INTEGRATION_ENV}/bin/blackd" ]
	[ ! -e "${PYTHON_INTEGRATION_ENV}/tools/ruff" ]
	[ ! -e "${PYTHON_INTEGRATION_ENV}/tools/black" ]
}

@test "python integration installs real ruff with default tool helpers in temporary directories" {
	export UV_OFFLINE=false
	run python_uv_tool_install 'ruff==0.11.13'
	assert_success
	[ -f "${UV_TOOL_DIR}/ruff/pyvenv.cfg" ]
	[ ! -e "${UV_TOOL_BIN_DIR}/python" ]
	run "${UV_TOOL_BIN_DIR}/ruff" --version
	assert_success
	assert_output 'ruff 0.11.13'
	run python_uv_tool_uninstall 'ruff==0.11.13'
	assert_success
	[ ! -e "${UV_TOOL_BIN_DIR}/ruff" ]
	[ ! -e "${UV_TOOL_DIR}/ruff" ]
}
