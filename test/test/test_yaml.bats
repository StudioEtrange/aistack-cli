bats_load_library 'bats-assert'
bats_load_library 'bats-support'


setup() {
	load 'stella_bats_helper.bash'
}

teardown() {
    true
}


# GENERIC -------------------------------------------------------------------

@test "yaml_has_key detects a false value" {
	run yaml_has_key "a.b" <<'EOF'
a:
  b: false
EOF
	assert_success
	assert_output ""
}

@test "yaml_has_key detects a missing key in an existing object" {
	run yaml_has_key "a.c" <<'EOF'
a:
  b: value
EOF
	assert_failure 10
	assert_output ""
}

@test "yaml_has_key detects an existing array index with null value" {
	run yaml_has_key "a.0" <<'EOF'
a:
  - null
EOF
	assert_success
	assert_output ""
}

@test "yaml_has_key check key with value exist" {

	run yaml_has_key "a.b.c" <<'EOF'
a:
  b:
    c: "localhost"
EOF
	assert_success
	assert_output ""
}

@test "yaml_has_key check key with empty value exist" {

	run yaml_has_key "a.b.c" <<'EOF'
a:
  b:
    c:
EOF
	assert_success
	assert_output ""
}


@test "yaml_has_key check root key with empty value exist" {

	run yaml_has_key "a" <<'EOF'
a:
EOF
	assert_success
	assert_output ""
}

@test "yaml_has_key check key does not exist" {

	run yaml_has_key "a.b.c.d" <<'EOF'
a:
  b:
    c:
EOF
	assert_failure 10
	assert_output ""
}

@test "yaml_get_key non existing key" {

	run yaml_get_key "a.b.c" <<'EOF'
a:
  b:
EOF
	assert_success
	assert_output ""
}

@test "yaml_get_key get key with true value" {

	run yaml_get_key "a.b.c" <<'EOF'
a:
  b:
    c: true
EOF
	expected=$(cat <<'EOF'
true
EOF
	)
	assert_success
	assert_output "$expected"
}


@test "yaml_get_key get key with false value" {

	run yaml_get_key "a.b.c" <<'EOF'
a:
  b:
    c: false
EOF
	expected=$(cat <<'EOF'
false
EOF
	)
	assert_success
	assert_output "$expected"
}

@test "yaml_get_key get key with a value" {

	run yaml_get_key "a.b.c" <<'EOF'
a:
  b:
    c: "localhost"
EOF
	expected=$(cat <<'EOF'
localhost
EOF
	)
	assert_success
	assert_output "$expected"
}

@test "yaml_get_key get key with key path starting with a dot" {

	run yaml_get_key ".a.b.c" <<'EOF'
a:
  b:
    c: "localhost"
EOF
	expected=$(cat <<'EOF'
localhost
EOF
	)
	assert_success
	assert_output "$expected"
}

@test "yaml_get_key get key with an empty value" {

	run yaml_get_key "a.b.c" <<'EOF'
a:
  b:
    c: ""
EOF
	expected=$(cat <<'EOF'
EOF
	)
	assert_success
	assert_output "$expected"
}


@test "yaml_get_key get key with an empty value 2" {

	run yaml_get_key "a.b.c" <<'EOF'
a:
  b:
    c:
d: 4
EOF
	assert_success
	assert_output ""
}

@test "yaml_set_key change existing key value" {

	run yaml_set_key "a.b.c" 'new_value' <<'EOF'
a:
  b:
    c: value
    d: value
EOF
	expected=$(cat <<'EOF'
a:
  b:
    c: new_value
    d: value
EOF
	)
	assert_output "$expected"
}

@test "yaml_set_key add a new key with an array as value" {

	run yaml_set_key "users.admins" '[alice, bob]' <<'EOF'
a:
  b:
    c: value
    d: value
EOF
	expected=$(cat <<'EOF'
a:
  b:
    c: value
    d: value
users:
  admins: [alice, bob]
EOF
	)
	assert_output "$expected"
}



@test "yaml_set_key set an indice value of an array of a key" {

	run yaml_set_key "a.b.array.3" '999' <<'EOF'
a:
  b:
    array: [10, 20, 30, 40, 50]
EOF
	expected=$(cat <<'EOF'
a:
  b:
    array: [10, 20, 30, 999, 50]
EOF
	)
	assert_output "$expected"
}


@test "yaml_set_key set value of an index for list of a key" {

	run yaml_set_key "a.b.array.3" '999' <<'EOF'
a:
  b:
    array:
      - 10
      - 20
      - 30
      - 40
      - 50
EOF
	expected=$(cat <<'EOF'
a:
  b:
    array:
      - 10
      - 20
      - 30
      - 999
      - 50
EOF
	)
	assert_output "$expected"
}

@test "yaml_set_key add a new key with value without quote" {

	run yaml_set_key "a.b.c" 'new_value' <<'EOF'
a:
  b:
EOF
	expected=$(cat <<'EOF'
a:
  b:
    c: new_value
EOF
	)
	assert_output "$expected"
}


@test "yaml_set_key add a new key with value with single quote" {

	run yaml_set_key ".a.b.c" "new_value" "single"
	expected=$(cat <<'EOF'
a:
  b:
    c: 'new_value'
EOF
	)
	assert_output "$expected"
}

@test "yaml_set_key add a new key with value with double quote" {

	run yaml_set_key ".a.b.c" "new_value" "double"
	expected=$(cat <<'EOF'
a:
  b:
    c: "new_value"
EOF
	)
	assert_output "$expected"
}

@test "yaml_set_key set a folded value" {

	run yaml_set_key ".a.b.c" "new_value" "folded"
	expected=$(cat <<'EOF'
a:
  b:
    c: >-
      new_value
EOF
	)
	assert_output "$expected"
}

@test "yaml_set_key set a literal value" {

	run yaml_set_key ".a.b.c" "new_value" "literal"
	expected=$(cat <<'EOF'
a:
  b:
    c: |-
      new_value
EOF
	)
	assert_output "$expected"
}

@test "yaml_set_key set a flow value" {

	run yaml_set_key ".a.b.c" "new_value" "flow"
	expected=$(cat <<'EOF'
a:
  b:
    c: new_value
EOF
	)
	assert_output "$expected"
}


@test "yaml_set_key reads stdin from file redirection" {
	local input_file
	input_file="$(mktemp)"
	cat > "${input_file}" <<'EOF'
a:
  b:
    c: old_value
    preserved: true
EOF

	run yaml_set_key ".a.b.c" "new_value" < "${input_file}"
	rm -f "${input_file}"

	expected=$(cat <<'EOF'
a:
  b:
    c: new_value
    preserved: true
EOF
	)
	assert_success
	assert_output "$expected"
}


@test "yaml_set_key reads stdin from here string" {
	local input
	input=$'a:\n  b:\n    c: old_value\n'

	run yaml_set_key ".a.b.c" "new_value" "double" <<< "${input}"

	expected=$(cat <<'EOF'
a:
  b:
    c: "new_value"
EOF
	)
	assert_success
	assert_output "$expected"
}


@test "yaml_set_key handles empty stdin" {
	run yaml_set_key ".a.b.c" "new_value" "single" < /dev/null

	expected=$(cat <<'EOF'
a:
  b:
    c: 'new_value'
EOF
	)
	assert_success
	assert_output "$expected"
}






@test "yaml_del_key non empty key exist" {

	run yaml_del_key "a.b.c" <<'EOF'
a:
  b:
    c: value
EOF
	expected=$(cat <<'EOF'
a:
  b: {}
EOF
	)
	assert_output "$expected"

}

@test "yaml_del_key non empty key exist case 2" {

	run yaml_del_key "a.b.c" <<'EOF'
a:
  b:
    c: value
    d: value
EOF
	expected=$(cat <<'EOF'
a:
  b:
    d: value
EOF
	)
	assert_output "$expected"

}

@test "yaml_del_key key do not exist" {

	run yaml_del_key "a.w" <<'EOF'
a:
  b:
    c: value
    d: value
EOF
	expected=$(cat <<'EOF'
a:
  b:
    c: value
    d: value
EOF
	)
	assert_failure 10
	assert_output "$expected"

}


@test "yaml_del_key_from_file delete a sample key with its value" {

	tmp="$(mktemp)"
	cat >"$tmp" <<'EOF'
a:
  b:
    c: value
EOF

	run yaml_del_key_from_file "$tmp" "a.b.c"
	assert_success
	expected=$(cat <<'EOF'
a:
  b: {}
EOF
	)
	assert_equal "$(cat "$tmp")" "$expected"

}


@test "yaml_del_key_from_file delete a key which have a brother" {

	tmp="$(mktemp)"
	cat >"$tmp" <<'EOF'
a:
  b:
    c: value
    d: value
EOF
	run yaml_del_key_from_file "$tmp" "a.b.d"
 	assert_success
 	expected=$( cat <<'EOF'
a:
  b:
    c: value
EOF
 	)
 	assert_equal "$(cat "$tmp")" "$expected"

}

@test "yaml_del_key_from_file delete a non existing key" {

	tmp="$(mktemp)"
	cat >"$tmp" <<'EOF'
a:
  b:
    c: value
    d: value
EOF

	run yaml_del_key_from_file "$tmp" "a.w.d"
 	assert_success
 	expected=$( cat <<'EOF'
a:
  b:
    c: value
    d: value
EOF
 	)
 	assert_equal "$(cat "$tmp")" "$expected"

	rm -f $tmp
}


@test "merge_yaml_file1" {

	tmp1="$(mktemp)"
	tmp2="$(mktemp)"

  	cat >"$tmp1" <<'EOF'
a:
  b: new_value1
  c: value2
d: value3
EOF

  	cat >"$tmp2" <<'EOF'
a:
  b: value1
  e: value4
f: value5
EOF

	run merge_yaml_file "$tmp1" "$tmp2"
	assert_success

	expected=$(cat <<'EOF'
a:
  b: new_value1
  e: value4
  c: value2
f: value5
d: value3
EOF
	)
	assert_equal "$(cat "$tmp2")" "$expected"

	rm -f $tmp1 $tmp2
}


@test "yaml_set_key_into_file1" {

	tmp="$(mktemp)"
	cat >"$tmp" <<'EOF'
a:
  b:
    c: value
EOF

	run yaml_set_key_into_file "$tmp" "a.b.c" 'test'
	assert_success
	expected=$(cat <<'EOF'
a:
  b:
    c: test
EOF
	)
	assert_equal "$(cat "$tmp")" "$expected"

}

@test "yaml_set_key_into_file2" {

	tmp="$(mktemp)"
	cat >"$tmp" <<'EOF'
a:
  b:
    c: value
EOF

	run yaml_set_key_into_file "$tmp" "a.b.c" 'test' "single"
	assert_success
	expected=$(cat <<'EOF'
a:
  b:
    c: 'test'
EOF
	)
	assert_equal "$(cat "$tmp")" "$expected"

}


@test "yaml_set_key_into_file3" {

	tmp="$(mktemp)"
	cat >"$tmp" <<'EOF'
a:
  b:
    c: value
EOF

	run yaml_set_key_into_file "$tmp" ".a.b.c" 'test' "double"
	assert_success
	expected=$(cat <<'EOF'
a:
  b:
    c: "test"
EOF
	)
	assert_equal "$(cat "$tmp")" "$expected"

}


@test "yaml_set_key_into_file4" {

	tmp="$(mktemp)"
	
	run yaml_set_key_into_file "$tmp" ".a.b.c" 'test' "double"
	assert_success
	expected=$(cat <<'EOF'
a:
  b:
    c: "test"
EOF
	)
	assert_equal "$(cat "$tmp")" "$expected"

}



@test "yaml_set_key_into_file5" {

	tmp="$(mktemp)"

	run yaml_set_key_into_file "$tmp" .a."foo\.bar".c "test"
	assert_success
	expected=$(cat <<'EOF'
a:
  foo.bar:
    c: test
EOF
	)
	assert_equal "$(cat "$tmp")" "$expected"

}
