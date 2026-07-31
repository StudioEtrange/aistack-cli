bats_load_library 'bats-assert'
bats_load_library 'bats-support'


setup() {
	load 'stella_bats_helper.bash'
}

teardown() {
    true
}


@test "glibc_version_require accepts equal or newer explicit version" {
	run glibc_version_require "2.28" "2.28"
	assert_success

	run glibc_version_require "2.28" "2.39"
	assert_success

	run glibc_version_require "2.17" "3"
	assert_success
}


@test "glibc_version_require rejects older explicit version" {
	run glibc_version_require "2.28" "2.17"
	assert_failure

	run glibc_version_require "2.39" "2.38.9"
	assert_failure
}


@test "glibc_version_require rejects missing minimum version" {
	run glibc_version_require "" "2.39"
	assert_failure
}


@test "glibc_version_require uses detected system version by default" {
	glibc_version() {
		printf '%s' "2.28"
	}

	run glibc_version_require "2.17"
	assert_success

	run glibc_version_require "2.39"
	assert_failure
}


@test "glibc_version_require rejects unavailable system version" {
	glibc_version() {
		return 1
	}

	run glibc_version_require "2.17"
	assert_failure
}


@test "glibc_alternative_path selects exact minimum runtime" {
	local runtime_217="$(mktemp -d)"
	local runtime_228="$(mktemp -d)"
	local runtime_239="$(mktemp -d)"

	export AISTACK_GLIBC_217_PATH="${runtime_217}"
	export AISTACK_GLIBC_228_PATH="${runtime_228}"
	export AISTACK_GLIBC_239_PATH="${runtime_239}"

	run glibc_alternative_path "2.28"
	assert_success
	assert_output "${runtime_228}"

	run glibc_alternative_path "2.39"
	assert_success
	assert_output "${runtime_239}"

	rm -rf "${runtime_217}" "${runtime_228}" "${runtime_239}"
}


@test "glibc_alternative_path selects lowest compatible fallback" {
	local runtime_239="$(mktemp -d)"

	export AISTACK_GLIBC_217_PATH=""
	export AISTACK_GLIBC_228_PATH=""
	export AISTACK_GLIBC_239_PATH="${runtime_239}"

	run glibc_alternative_path "2.28"
	assert_success
	assert_output "${runtime_239}"

	rm -rf "${runtime_239}"
}


@test "glibc_alternative_path skips invalid configured path" {
	local runtime_239="$(mktemp -d)"

	export AISTACK_GLIBC_217_PATH=""
	export AISTACK_GLIBC_228_PATH="/missing/aistack-glibc-228"
	export AISTACK_GLIBC_239_PATH="${runtime_239}"

	run glibc_alternative_path "2.28"
	assert_success
	assert_line "WARN: AISTACK_GLIBC_228_PATH does not reference a directory: /missing/aistack-glibc-228"
	assert_line "${runtime_239}"

	rm -rf "${runtime_239}"
}


@test "glibc_alternative_path fails without compatible runtime" {
	export AISTACK_GLIBC_217_PATH=""
	export AISTACK_GLIBC_228_PATH=""
	export AISTACK_GLIBC_239_PATH=""

	run glibc_alternative_path "2.28"
	assert_failure
	assert_output ""

	run glibc_alternative_path "2.40"
	assert_failure
	assert_output ""
}


@test "glibc_alternative_path rejects missing required version" {
	run glibc_alternative_path ""
	assert_failure
	assert_output ""
}


@test "glibc_alternative_system selects runtime per tool requirement" {
	local runtime_217="$(mktemp -d)"
	local runtime_228="$(mktemp -d)"
	local runtime_239="$(mktemp -d)"

	export AISTACK_GLIBC_217_PATH="${runtime_217}"
	export AISTACK_GLIBC_228_PATH="${runtime_228}"
	export AISTACK_GLIBC_239_PATH="${runtime_239}"

	unset AISTACK_INIT_FORCE_NODE_GBC AISTACK_INIT_FORCE_AGY_GBC AISTACK_INIT_FORCE_LLMFIT_GBC
	export AISTACK_GLIBC_CURRENT_VERSION="2.17"
	glibc_alternative_system
	[ "${AISTACK_INIT_FORCE_NODE_GBC}" = "${runtime_228}" ]
	[ "${AISTACK_INIT_FORCE_AGY_GBC}" = "${runtime_228}" ]
	[ "${AISTACK_INIT_FORCE_LLMFIT_GBC}" = "${runtime_239}" ]

	unset AISTACK_INIT_FORCE_NODE_GBC AISTACK_INIT_FORCE_AGY_GBC AISTACK_INIT_FORCE_LLMFIT_GBC
	export AISTACK_GLIBC_CURRENT_VERSION="2.28"
	glibc_alternative_system
	[ -z "${AISTACK_INIT_FORCE_NODE_GBC}" ]
	[ -z "${AISTACK_INIT_FORCE_AGY_GBC}" ]
	[ "${AISTACK_INIT_FORCE_LLMFIT_GBC}" = "${runtime_239}" ]

	unset AISTACK_INIT_FORCE_NODE_GBC AISTACK_INIT_FORCE_AGY_GBC AISTACK_INIT_FORCE_LLMFIT_GBC
	export AISTACK_GLIBC_CURRENT_VERSION="2.39"
	glibc_alternative_system
	[ -z "${AISTACK_INIT_FORCE_NODE_GBC}" ]
	[ -z "${AISTACK_INIT_FORCE_AGY_GBC}" ]
	[ -z "${AISTACK_INIT_FORCE_LLMFIT_GBC}" ]

	rm -rf "${runtime_217}" "${runtime_228}" "${runtime_239}"
}


@test "glibc_alternative_system uses newer configured fallback" {
	local runtime_239="$(mktemp -d)"

	export AISTACK_GLIBC_CURRENT_VERSION="2.17"
	export AISTACK_GLIBC_228_PATH=""
	export AISTACK_GLIBC_239_PATH="${runtime_239}"
	unset AISTACK_INIT_FORCE_NODE_GBC AISTACK_INIT_FORCE_AGY_GBC AISTACK_INIT_FORCE_LLMFIT_GBC

	glibc_alternative_system
	[ "${AISTACK_INIT_FORCE_NODE_GBC}" = "${runtime_239}" ]
	[ "${AISTACK_INIT_FORCE_AGY_GBC}" = "${runtime_239}" ]
	[ "${AISTACK_INIT_FORCE_LLMFIT_GBC}" = "${runtime_239}" ]

	rm -rf "${runtime_239}"
}


@test "glibc_alternative_system preserves explicit tool runtime" {
	local runtime_228="$(mktemp -d)"

	export AISTACK_GLIBC_CURRENT_VERSION="2.17"
	export AISTACK_GLIBC_228_PATH="${runtime_228}"
	export AISTACK_GLIBC_239_PATH="${runtime_228}"
	export AISTACK_INIT_FORCE_NODE_GBC="/custom/node-glibc"
	unset AISTACK_INIT_FORCE_AGY_GBC AISTACK_INIT_FORCE_LLMFIT_GBC

	glibc_alternative_system
	[ "${AISTACK_INIT_FORCE_NODE_GBC}" = "/custom/node-glibc" ]
	[ "${AISTACK_INIT_FORCE_AGY_GBC}" = "${runtime_228}" ]

	rm -rf "${runtime_228}"
}
