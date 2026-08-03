bats_load_library 'bats-assert'
bats_load_library 'bats-support'


setup() {
	load 'stella_bats_helper.bash'
}

teardown() {
    true
}






@test "opencode_set_default_and_small_models" {
	tmp="$(mktemp)"
	printf '{}\n' > "${tmp}"
	export AISTACK_OPENCODE_CONFIG_FILE="${tmp}"

	run opencode_set_default_model "aistack-cpa" "default-model"
	assert_success
	run opencode_set_small_model "aistack-cpa" "small-model"
	assert_success

	assert_equal "$(json_get_key_from_file "${tmp}" '.model')" "aistack-cpa/default-model"
	assert_equal "$(json_get_key_from_file "${tmp}" '.small_model')" "aistack-cpa/small-model"
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
	assert_equal "$(json_get_key_from_file "${tmp}" '.small_model')" "aistack-cpa/small-model"
	assert_equal "$(json_get_key_from_file "${tmp}" '.provider.aistack-cpa.models.remote-model.id')" "remote-model"
	assert_equal "$(json_get_key_from_file "${tmp}" '.provider.aistack-cpa.models.small-model.id')" "small-model"
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
	assert_equal "$(json_get_key_from_file "${tmp}" '.small_model')" "aistack-cpa/small-model"
	assert_equal "$(json_get_key_from_file "${tmp}" '.provider.aistack-cpa.models.default-model.id')" "default-model"
	rm -f "${tmp}"
}