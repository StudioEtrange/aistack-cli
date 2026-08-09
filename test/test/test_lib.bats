#!/usr/bin/env bats

bats_load_library 'bats-assert'
bats_load_library 'bats-support'

setup() {
	load 'stella_bats_helper.bash'
}

@test "shell_quote_posix quotes an empty string" {
	run shell_quote_posix ""

	assert_success
	assert_output "''"
}

@test "shell_quote_posix quotes a simple string" {
	run shell_quote_posix "hello"

	assert_success
	assert_output "'hello'"
}

@test "shell_quote_posix preserves spaces" {
	run shell_quote_posix "hello world"

	assert_success
	assert_output "'hello world'"
}

@test "shell_quote_posix escapes single quotes" {
	run shell_quote_posix "it's quoted"

	assert_success
	assert_output "'it'\\''s quoted'"
}

@test "shell_quote_posix prevents shell expansion" {
	local value='${HOME}; $(printf injected); `printf injected`; * ? [abc]'
	local quoted

	quoted="$(shell_quote_posix "${value}")"
	run env QUOTED="${quoted}" sh -c 'eval "set -- ${QUOTED}"; printf "%s" "$1"'

	assert_success
	assert_output "${value}"
}

@test "shell_quote_posix round-trips embedded newlines" {
	local value
	local quoted
	value="$(printf 'first line\nsecond line')"

	quoted="$(shell_quote_posix "${value}")"
	run env QUOTED="${quoted}" sh -c 'eval "set -- ${QUOTED}"; printf "%s" "$1"'

	assert_success
	assert_output "${value}"
}
