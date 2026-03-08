#!/bin/bash
_CURRENT_FILE_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
_CURRENT_RUNNING_DIR="$( cd "$( dirname "${BASH_SOURCE[1]}" )" && pwd )"

STELLA_LOG_STATE=OFF
. "$_CURRENT_FILE_DIR/stella-link.sh" include

#$STELLA_API require "bats" "bats" "INTERNAL"
$STELLA_API get_feature "bats"

function init_aistack_test_env() {
	# create a temporary working directory for tests
	mkdir -p "$STELLA_APP_WORK_ROOT"

	# load aistack libraries
	. "$STELLA_APP_ROOT/../lib/lib.sh"
	. "$STELLA_APP_ROOT/../lib/lib_json.sh"
	. "$STELLA_APP_ROOT/../lib/lib_yaml.sh"
	. "$STELLA_APP_ROOT/../lib/lib_cpa.sh"
	. "$STELLA_APP_ROOT/../lib/lib_vscode.sh"
	. "$STELLA_APP_ROOT/../lib/lib_gemini.sh"
	. "$STELLA_APP_ROOT/../lib/lib_opencode.sh"
	. "$STELLA_APP_ROOT/../lib/lib_mcp.sh"

	# initialize aistack paths
	aistack_path 1>/dev/null 2>&1
	runtime_path 1>/dev/null 2>&1

	# install dependencies
	#( aistack_install_dependencies 1>/dev/null 2>&1 )
	aistack_install_dependencies
}

function test_launch_bats() {
	local domain="$1"
	# regular expression that will match tests functions names
	local filter="$2"

	local _v=$(mktmp)
	declare >"$_v"
	declare -f >>"$_v"

	if [ "$filter" = "" ]; then
		__BATS_STELLA_DECLARE="$_v" bats --verbose-run "$STELLA_APP_ROOT/test/test_$domain.bats"
	else
		__BATS_STELLA_DECLARE="$_v" bats --verbose-run "$STELLA_APP_ROOT/test/test_$domain.bats" -f ${filter}
	fi
	rm -f "$_v"
}

#STELLA_LOG_STATE=ON
case $1 in
  h|help|--help|-h)
    echo " * Usage $0 json|yaml|all [test-name]"
	echo "sample:"
	echo "$0 json json_has_path"
    ;;
  all|"")
	init_aistack_test_env
    test_launch_bats common_json $2
	test_launch_bats common_yaml $2
    ;;
  json)
	init_aistack_test_env
    test_launch_bats common_json $2
  	;;
  yaml)
	init_aistack_test_env
    test_launch_bats common_yaml $2
  	;;
  *)
	echo " * Usage $0 json|yaml|all [test-name]"
	echo "sample:"
	echo "$0 json json_has_path"
    ;;
esac
