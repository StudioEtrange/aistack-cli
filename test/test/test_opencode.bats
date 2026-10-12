bats_load_library 'bats-assert'
bats_load_library 'bats-support'


setup() {
	load 'stella_bats_helper.bash'
}

teardown() {
    true
}






@test "opencode_set_default_and_title_models" {
	tmp="$(mktemp)"
	printf '{}\n' > "${tmp}"
	export AISTACK_OPENCODE_CONFIG_FILE="${tmp}"

	run opencode_set_default_model "aistack-cpa" "default-model"
	assert_success
	run opencode_set_small_model "aistack-cpa" "small-model"
	assert_success

	assert_equal "$(json_get_key_from_file "${tmp}" '.model')" "aistack-cpa/default-model"
	assert_equal "$(json_get_key_from_file "${tmp}" '.agents.title.model')" "aistack-cpa/small-model"
	rm -f "${tmp}"
}


@test "opencode_connect_cpa_registers_models_and_explicit selections" {
	tmp="$(mktemp)"
	printf '{}\n' > "${tmp}"
	export AISTACK_OPENCODE_CONFIG_FILE="${tmp}"
	export AISTACK_CLIPROXYAPI_KEY_FOR_OPENCODE="test-key"

	cpa_is_configured() { return 0; }
	opencode_generate_cpa_key() { return 0; }
	cpa_settings_get_api_endpoint() { echo "http://localhost:8317/v1"; }
	cpa_instance_reachable() { return 0; }
	cpa_get_model_list() { echo "remote-model default-model"; }

	run opencode_connect_cpa "default-model" "small-model"
	assert_success
	assert_equal "$(json_get_key_from_file "${tmp}" '.model')" "aistack-cpa/default-model"
	assert_equal "$(json_get_key_from_file "${tmp}" '.agents.title.model')" "aistack-cpa/small-model"
	assert_equal "$(json_get_key_from_file "${tmp}" '.providers.aistack-cpa.models.remote-model.modelID')" "remote-model"
	assert_equal "$(json_get_key_from_file "${tmp}" '.providers.aistack-cpa.models.small-model.modelID')" "small-model"
	assert_equal "$(json_get_key_from_file "${tmp}" '.providers.aistack-cpa.package')" "@opencode/ai/providers/openai-compatible"
	assert_equal "$(json_get_key_from_file "${tmp}" '.providers.aistack-cpa.settings.baseURL')" "http://localhost:8317/v1"
	assert_equal "$(json_get_key_from_file "${tmp}" '.providers.aistack-cpa.settings.apiKey')" "test-key"
	rm -f "${tmp}"
}


@test "opencode_connect_cpa_supports_explicit models while offline" {
	tmp="$(mktemp)"
	printf '{}\n' > "${tmp}"
	export AISTACK_OPENCODE_CONFIG_FILE="${tmp}"
	export AISTACK_CLIPROXYAPI_KEY_FOR_OPENCODE="test-key"

	cpa_is_configured() { return 0; }
	opencode_generate_cpa_key() { return 0; }
	cpa_settings_get_api_endpoint() { echo "http://localhost:8317/v1"; }
	cpa_instance_reachable() { return 1; }

	run opencode_connect_cpa "default-model" "small-model"
	assert_success
	assert_equal "$(json_get_key_from_file "${tmp}" '.model')" "aistack-cpa/default-model"
	assert_equal "$(json_get_key_from_file "${tmp}" '.agents.title.model')" "aistack-cpa/small-model"
	assert_equal "$(json_get_key_from_file "${tmp}" '.providers.aistack-cpa.models.default-model.modelID')" "default-model"
	rm -f "${tmp}"
}


@test "opencode_title_model_rejects_missing_arguments_without_changes" {
	tmp="$(mktemp)"
	printf '%s\n' '{"small_model":"old/small"}' > "${tmp}"
	export AISTACK_OPENCODE_CONFIG_FILE="${tmp}"
	run opencode_set_title_model
	assert_failure
	run opencode_set_title_model "aistack-cpa"
	assert_failure
	assert_equal "$(json_get_key_from_file "${tmp}" '.small_model')" "old/small"
	rm -f "${tmp}"
}


@test "opencode_register_model_uses_native_capabilities_and_limits" {
	tmp="$(mktemp)"
	printf '{}\n' > "${tmp}"
	export AISTACK_OPENCODE_CONFIG_FILE="${tmp}"
	run opencode_register_model "aistack-cpa" "model.1" "upstream.1" "Model" "false" "100000" "10000"
	assert_success
	run jq -e '.providers["aistack-cpa"].models["model.1"] | .modelID == "upstream.1" and .name == "Model" and .capabilities.tools == false and .limit.context == 100000 and .limit.output == 10000 and .reasoning == null and .id == null and .tool_call == null' "${tmp}"
	assert_success
	run opencode_register_model
	assert_failure
	run opencode_register_model "aistack-cpa" "model"
	assert_failure
	rm -f "${tmp}"
}
