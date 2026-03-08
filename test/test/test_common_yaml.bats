bats_load_library 'bats-assert'
bats_load_library 'bats-support'


setup() {
	load 'stella_bats_helper.bash'
}

teardown() {
    true
}


# GENERIC -------------------------------------------------------------------


@test "yaml_get_key1" {

	run yaml_get_key "a.b.c" <<'EOF'
a:
  b:
EOF
	assert_success
	assert_output ""
}

@test "yaml_get_key2" {

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


@test "yaml_get_key3" {

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

@test "yaml_get_key4" {

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

@test "yaml_get_key5" {

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

@test "yaml_get_key6" {

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


@test "yaml_get_key7" {

	run yaml_get_key "a.b.c" <<'EOF'
a:
  b:
    c:
d: 4
EOF
	assert_success
	assert_output ""
}

@test "yaml_set_key1" {

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

@test "yaml_set_key2" {

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



@test "yaml_set_key3" {

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


@test "yaml_set_key31" {

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

@test "yaml_set_key4" {

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


@test "yaml_set_key6" {

	run yaml_set_key ".a.b.c" "new_value" "single"
	expected=$(cat <<'EOF'
a:
  b:
    c: 'new_value'
EOF
	)
	assert_output "$expected"
}

@test "yaml_set_key7" {

	run yaml_set_key ".a.b.c" "new_value" "double"
	expected=$(cat <<'EOF'
a:
  b:
    c: "new_value"
EOF
	)
	assert_output "$expected"
}

@test "yaml_set_key8" {

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

@test "yaml_set_key9" {

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

@test "yaml_set_key10" {

	run yaml_set_key ".a.b.c" "new_value" "flow"
	expected=$(cat <<'EOF'
a:
  b:
    c: new_value
EOF
	)
	assert_output "$expected"
}






@test "yaml_del_key1" {

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

@test "yaml_del_key2" {

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

@test "yaml_del_key3" {

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
	assert_output "$expected"

}


@test "yaml_del_key_from_file1" {

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


@test "yaml_del_key_from_file2" {

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

@test "yaml_del_key_from_file3" {

	tmp="$(mktemp)"
	cat >"$tmp" <<'EOF'
a:
  b:
    c: value
    d: value
EOF

	run yaml_del_key_from_file "$tmp" "a.w.d"
 	assert_failure
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
