
#GLOBAL_JQ_OPTIONS="--indent 4"

# ----------------------------------- JSON UTILITIES -----------------------------------
# build a JSON array for jq
# build_jq_array_from_path <key_path>
#
# build_jq_array_from_path ".a.b.c"
#          ["a","b","c"]
build_jq_array_from_path() {
    local key_path="$1"
    [ -n "$key_path" ] || { echo "ERROR: key_path empty" >&2; return 1; }

    # remove any starting "."
    key_path="${key_path#.}"
    [ -n "$key_path" ] || { echo "ERROR: invalid key path '$1'" >&2; return 1; }

    local -a parts=()
    local buf="" c="" esc=0
    local i=0 len=${#key_path}

    while [ "$i" -lt "$len" ]; do
        c="${key_path:$i:1}"

        if [ "$esc" -eq 1 ]; then
            # only two special escapes:
            #   \.  => .
            #   \\  => \
            # otherwise keep the backslash: \x => \x
            case "$c" in
                "." ) buf="${buf}." ;;
                "\\" ) buf="${buf}\\" ;;
                *   ) buf="${buf}\\${c}" ;;
            esac
            esc=0
        else
            case "$c" in
                "\\") esc=1 ;;
                ".")
                    [ -n "$buf" ] && parts+=("$buf")
                    buf=""
                    ;;
                *) buf="${buf}${c}" ;;
            esac
        fi

        i=$((i+1))
    done

    # trailing "\" kept as literal "\"
    if [ "$esc" -eq 1 ]; then
        buf="${buf}\\"
    fi

    [ -n "$buf" ] && parts+=("$buf")
    ((${#parts[@]} > 0)) || { echo "ERROR: invalid key path '$key_path'" >&2; return 1; }

    local jq_path
    jq_path="$(
        printf '%s\n' "${parts[@]}" \
        | jq -R 'if test("^[0-9]+$") then tonumber else . end' \
        | jq -s -c .
    )" || { echo "ERROR: building jq path" >&2; return 1; }

    printf "%s" "$jq_path"
}

# build an expression for jq
# build_jq_expr_from_path <key_path>
#
# build_jq_expr_from_path ".a.b.c"
#          .["a"]["b"]["c"]
build_jq_expr_from_path() {
    local key_path="$1"
    [ -n "$key_path" ] || { echo "ERROR: key_path empty" >&2; return 1; }

    # remove any starting "."
    key_path="${key_path#.}"
    [ -n "$key_path" ] || { echo "ERROR: invalid key path '$1'" >&2; return 1; }

    # split with escapes: \. and \\ supported
    local -a parts=()
    local buf="" c="" esc=0
    local i=0 len=${#key_path}

    while [ "$i" -lt "$len" ]; do
        c="${key_path:$i:1}"

        if [ "$esc" -eq 1 ]; then
            case "$c" in
                ".")  buf="${buf}." ;;
                "\\") buf="${buf}\\" ;;
                *)    buf="${buf}\\${c}" ;;
            esac
            esc=0
        else
            case "$c" in
                "\\") esc=1 ;;
                ".")
                    [ -n "$buf" ] && parts+=("$buf")
                    buf=""
                    ;;
                *) buf="${buf}${c}" ;;
            esac
        fi

        i=$((i+1))
    done

    # trailing "\" kept literally
    if [ "$esc" -eq 1 ]; then
        buf="${buf}\\"
    fi

    [ -n "$buf" ] && parts+=("$buf")
    ((${#parts[@]} > 0)) || { echo "ERROR: invalid key path '$key_path'" >&2; return 1; }

    local jq_expr="."
    local key json_key
    for key in "${parts[@]}"; do
        case "$key" in
            (*[!0-9]*|'')  # non numérique
                json_key="$(printf '%s' "$key" | jq -R .)" || { echo "ERROR: escaping key" >&2; return 1; }
                jq_expr+="[$json_key]"
                ;;
            (*)            # numérique
                jq_expr+="[$key]"
                ;;
        esac
    done

    printf "%s" "$jq_expr"
}


# format and fix invalid json (i.e: remove last comma at the end of a json object)
# can be used in a stream :
#       echo '{ "to" :"",}' | sanitize_json
#       sanitize_json - < file.json 
# or if a file is passed as argument 1, the file will be sanitize itself
#       sanitize_json "file.json"
# or if a string is passed as argument 1
#       sanitize_json '{ "to" :"a",}'
# json5 options
#   -s : size of indentation
#   -c : convert inplace without making output file https://github.com/json5/json5/blob/main/lib/cli.js#L87
sanitize_json() {
    local arg="$1"

    require "json5"
    
    if [ ! -t 0 ]; then
        # parse stream
        PATH="${AISTACK_NODEJS_BIN_PATH}:${PATH}" json5 -s 2
        return $?
    fi

    if [ -z "$arg" ] || [ "$arg" = "-" ]; then
        echo "ERROR: sanitize_json expects stdin or a file/string argument" >&2
        return 2
    fi

    if [ ! -f "$arg" ]; then
        echo "$arg" | PATH="${AISTACK_NODEJS_BIN_PATH}:${PATH}" json5 -s 2
        return $?
    fi


    local tmp_file="$(mktemp)"

    PATH="${AISTACK_NODEJS_BIN_PATH}:${PATH}" json5 -s 2 "$arg" 2>/dev/null >"$tmp_file" 
    if [ $? -ne 0 ]; then
        echo "ERROR : failed to sanitize json from $arg"
        rm -f "$tmp_file"
        return 1
    else
        mv "$tmp_file" "$arg"
        return 0
    fi
}


# test json 
# if invalid json sanitize it
# then exit 1 if still invalid json
test_and_fix_json_file() {
    local file_to_test="$1"

    if [ ! -f "$file_to_test" ]; then
        echo "ERROR : file not found $file_to_test"
        exit 1
    fi

    if ! jq -e . "$file_to_test" >/dev/null 2>&1; then
        echo "WARN : invalid json file : $file_to_test"
        echo "       try to sanitize it"
        sanitize_json "$file_to_test"
        if ! jq -e . "$file_to_test" >/dev/null 2>&1; then
            echo "ERROR : invalid json file : $file_to_test"
            exit 1
        else
            echo "       it should be a valid json file now"
        fi
    fi

}


# check if a path exists in jison input
# cat input.json | json_has_path <path>
# json_has_path <path> < input.json
#
# echo '{"a":{"b":{"c": "value","d":"value"}}}' | json_has_path ".a.b.d"
#       true
# echo '{"a":{"b":{"c": "value","d":"value"}}}' | json_has_path ".a.b.w"
#       false
json_has_path() {
  local path="$1"
  local jq_expr="$(build_jq_array_from_path "$path")" || return 1

  jq -e --argjson path "$jq_expr" '
    ($path | length) > 0
    and (
      if ($path | length) == 1 then
        has($path[0])
      else
        getpath($path[0:-1]) | has($path[-1])
      end
    )
  ' 1>/dev/null 2>&1
  return $?
}

# set a key from json input
# cat input.json | json_set_key <key_path> <value>
# json_set_key <key_path> <value> < input.json
# key_path : can contains index for array
#
# json_set_key "a.b.c" '"new_value"'
# echo '{"a":{"b":{"c": "value","d":"value"}}}' | json_set_key "a.b.c" '"new_value"'
# echo '{"a":{"b":{"array":[10,20,30,40,50]}}}' | json_set_key "a.b.array.3" '999'
#          => '{"a":{"b":{"array":[10,20,30,999,50]}}}'
json_set_key() {
    local key_path="$1"
    local value="$2"

    if [ "$#" -lt 2 ]; then
        echo "ERROR : argument missing"
        exit 1
    fi

    if [ -z "$key_path" ]; then
        echo "ERROR : json key path empty"
        exit 1
    fi

    local jq_opt
    if [ ! -t 0 ]; then
        # parse stream from stdin
        :
    else
        # no stdin, create new json
        jq_opt="-n"
    fi

    local jq_path
    jq_path="$(build_jq_array_from_path "$key_path")" || return 1

    # value must be a valid JSON (ie: '"str"', '123', 'true', '{"x":1}', '["a"]', etc.)
    if ! jq $jq_opt --argjson path "$jq_path" --argjson v "$value" \
        'setpath($path; $v)'; then
        echo "ERROR : generating json from key_path/value (value must be valid JSON)" >&2
        return 1
    fi
}


# set a json key into a file
# json_set_key_into_file <file> <key_path> <value>
#
# json_set_key_into_file "input.json" ".a.b.c" '"value"'
json_set_key_into_file() {
    local target_file="$1"
    local key_path="$2"
    local value="$3"

    if [ "$#" -lt 3 ]; then
        echo "ERROR : argument missing"
        exit 1
    fi
    if [ -z "$key_path" ]; then
        echo "ERROR : json key path to set empty"
        exit 1
    fi
    if [ ! -s "$target_file" ]; then
        echo "Valid target file not found at $target_file. Creating it."
        mkdir -p "$(dirname "$target_file")"
        echo "{}" > "$target_file"
    else
        test_and_fix_json_file "$target_file"
    fi

    local tmp_file="$(mktemp)"
    json_set_key "$key_path" "$value" < "$target_file" > "$tmp_file"
    local ret=$?

    if [ $ret -ne 0 ]; then
        echo "ERROR : processing with jq"
        rm -f "$tmp_file"
        return $ret
    else
        mv "$tmp_file" "$target_file"
        rm -f "$tmp_file"
    fi
    sanitize_json "$target_file"
}


# delete a key from json input
# cat input.json | json_del_key <key_path>
# json_del_key <key_path> < input.json
#
# echo '{"a":{"b":{"c": "value","d":"value"}}}' | json_del_key "a.b.c"
json_del_key() {
    local key_path="$1"
    local jq_path
    if [ ! -t 0 ]; then
        jq_path="$(build_jq_array_from_path "$key_path")" || return 1
        jq "delpaths([$jq_path])"
    fi
}

# delete a json key from a file
# json_del_key_from_file <file> <key_path>
#
# json_del_key_from_file "input.json" ".a.b.c"
json_del_key_from_file() {
    local target_file="$1"
    local key_path="$2"


    if [ -z "$key_path" ]; then
        echo "ERROR : json key path to remove empty"
        exit 1
    fi
    if [ ! -s "$target_file" ]; then
        echo "WARN : file not found $target_file"
        return
    fi

    test_and_fix_json_file "$target_file"

    if ! json_has_path "$key_path" < "$target_file"; then
        sanitize_json "$target_file"
        # key not found
        return 1
    fi
   
    local tmp_file="$(mktemp)"
    json_del_key "$key_path" < "$target_file" > "$tmp_file"

    if [ $? -ne 0 ]; then
        echo "ERROR : processing with jq"
        rm -f "$tmp_file"
        exit 1
    else
        mv "$tmp_file" "$target_file"
        rm -f "$tmp_file"
    fi

    sanitize_json "$target_file"
}



# merge one jwon file (file_to_merge) into another (file_to_merge_into)
# file_to_merge : have higher priority and erase file_to_merge_into content
# file_to_merge also support environment variable injection ${VAR} (Replace ${VAR} with environnement variable if it exists)
merge_json_file() {
    local file_to_merge="$1"
    local file_to_merge_into="$2"

    if [ ! -f "$file_to_merge" ]; then
        echo "ERROR : file to merge not found $file_to_merge"
        exit 1
    fi

    # do not modify file to merge
    local tmp_file_to_merge="$(mktemp)"
    cat "$file_to_merge" > "$tmp_file_to_merge"
    test_and_fix_json_file "$tmp_file_to_merge"

    if [ ! -s "$file_to_merge_into" ]; then
        echo "Valid target file not found at $file_to_merge_into. Creating it."
        mkdir -p "$(dirname "$file_to_merge_into")"
        echo "{}" > "$file_to_merge_into"
    fi

    test_and_fix_json_file "$file_to_merge_into"

    local tmp_merge="$(mktemp)"
    # Replace ${VAR} with environnement variable if it exists or keep ${VAR} as is.
    # if VAR exists but empty, ${VAR} is replaced with an empty string.
    # do NOT replace $VAR, only ${VAR}
    if ! jq \
            'def expand_env:
                walk(
                    if type=="string" then
                        gsub("\\$\\{(?<k>[A-Za-z_][A-Za-z0-9_]*)\\}"; (env[.k] // ("${"+.k+"}")))
                    else 
                        . 
                    end
                    );
            expand_env
    ' "$tmp_file_to_merge" > "$tmp_merge"; then
        echo "ERROR : expanding environment variables in $tmp_file_to_merge" >&2
        exit 1
    fi

    test_and_fix_json_file "$tmp_merge"

    local tmp_file="$(mktemp)"
    # Merge the two json files
    jq -s '.[0] * .[1]' "${file_to_merge_into}" "$tmp_merge" > "$tmp_file"
    
    if [ $? -ne 0 ]; then
        rm -f "$tmp_file" "$tmp_merge"
        exit 1
    else
        mv "$tmp_file" "$file_to_merge_into"
        rm -f "$tmp_file" "$tmp_merge"
    fi
}

json_tweak_value_of_list_into_file() {
    local key_path="$1"
    local value="$2"
    local separator="$3"
    local target_file="$4"
    local mode="${5:-ALWAYS_PREPEND}"

    if [ "$#" -lt 4 ]; then
        echo "ERROR : argument missing"
        exit 1
    fi
    if [ -z "$key_path" ]; then
        echo "ERROR : json key path to set empty"
        exit 1
    fi
    if [ ! -s "$target_file" ]; then
        echo "Valid target file not found at $target_file. Creating it."
        mkdir -p "$(dirname "$target_file")"
        echo "{}" > "$target_file"
    else
        test_and_fix_json_file "$target_file"
    fi

    local tmp_file="$(mktemp)"
    json_tweak_value_of_list "$key_path" "$value" "$separator" "$mode" < "$target_file" > "$tmp_file"
    if [ $? -ne 0 ]; then
        echo "ERROR : processing with jq"
        rm -f "$tmp_file"
        exit 1
    else
        mv "$tmp_file" "$target_file"
        rm -f "$tmp_file"
    fi
    sanitize_json "$target_file"
}

# if a string contains a given charactor, this function can replace the string with an escaped string and back
json_escape_string_containing_char() {
    local string="$1"
    local character="$2"
    local mode="${3:-ESCAPE}" # ESCAPE or RESTORE
    # ESCAPE : escape string containing a character in the input string
    # RESTORE : do the opposite to the input string
    # GET_ESCAPED_VALUE : output escaped string
    

    if [ -z "$character" ]; then
        echo "ERROR : json_escape_string_containing_char - character is empty"
        return 1
    fi

    # Escape character inside string with ASCII Unit character (0x1f)
    local alt_character=$'\x1f'
    local string_raw="$string"
    local string_escaped="${string//"$character"/"$alt_character"}"

    if [ "$mode" = "GET_ESCAPED_VALUE" ]; then
        printf "%s" "$string_escaped"
        return 0
    fi

    if [ -z "$string" ]; then
        if [ ! -t 0 ]; then
            # return stdin
            jq
        else
            # return empty json
            jq -n '{}'
        fi
        return 0
    fi

    local jq_opt
    if [ ! -t 0 ]; then
        # parse stream from stdin
        :
    else
        jq_opt="-n"
    fi

    # replace all occurences of string with string_escaped
    if ! jq $jq_opt --arg string_raw "$string_raw" --arg string_escaped "$string_escaped" --arg mode "$mode" '
  
        def escape_regex:
            gsub("(?<c>[\\\\.^$|()\\[\\]{}*+?])"; "\\\(.c)");

        def process:
            if . == null or . == "" then
                {}
            else
                if $mode == "ESCAPE" then
                    ($string_raw | escape_regex) as $pattern

                    | walk(
                        if type == "string" then
                            gsub($pattern; $string_escaped)
                        else
                            .
                        end
                        )
                elif $mode == "RESTORE" then
                    ($string_escaped | escape_regex) as $pattern

                    | walk(
                        if type == "string" then
                            gsub($pattern; $string_raw)
                        else
                            .
                        end
                        )
                else
                    .
                end
            end;
        . as $doc
        | process
    '; then
        
        echo "ERROR json_escape_string_containing_separator - mode : $mode"
        return 1
    fi
}


json_tweak_value_of_list() {
    local key_path="$1"
    local value="$2"
    local separator="$3" # separator of values in the list
    local mode="${4:-ALWAYS_PREPEND}"
    # ALWAYS_PREPEND add path or move it at the begining position
    # ALWAYS_POSTPEND add path or move it at the end position
    # PREPEND_IF_NOT_EXISTS add path at the begining position only if not already present
    # POSTPEND_IF_NOT_EXISTS add path at the end position only if not already present
    # REMOVE remove all occurences of a fix expression
    # REMOVE_REGEXP remove all occurences of an regexp expression

    if [ "$#" -lt 3 ]; then
        echo "ERROR : argument missing"
        exit 1
    fi

    if [ -z "$key_path" ]; then
        echo "ERROR : json key path empty"
        exit 1
    fi

    if [ -z "$separator" ]; then
        echo "ERROR : value separator is empty"
        exit 1
    fi
    
    # string is empty
    if [ -z "$value" ]; then
        if [ ! -t 0 ]; then
            # return stdin
            jq
        else
            # return empty json
            jq -n '{}'
        fi
        return 0
    fi

    local jq_opt
    if [ ! -t 0 ]; then
        # parse stream from stdin
        :
    else
        # no stdin, create new json
        jq_opt="-n"
    fi

    local jq_path
    jq_path="$(build_jq_array_from_path "$key_path")" || return 1

    # escape value if it contains separator
    local escaped_value="$(json_escape_string_containing_char "$value" "$separator" "GET_ESCAPED_VALUE")"


    if ! {
        json_escape_string_containing_char "$value" "$separator" "ESCAPE" \
        | jq $jq_opt --arg separator "$separator" --arg value "$escaped_value" --arg mode "$mode" --argjson key_path "$jq_path" '
    
            # split by "$separator"
            def split_by_separator:
                if (type!="string") or (.=="") then 
                    []
                else 
                    ( . | split($separator) )
                end;
            
            def process:
                if ($mode | startswith("REMOVE") | not) then
                    if . == null or . == "" then
                        $value
                    else
                        if $mode == "ALWAYS_PREPEND" then
                            ( split_by_separator
                                | map(select(. != "" and . != $value))
                                | [$value] + .
                                | join($separator)
                            )
                        elif $mode == "ALWAYS_POSTPEND" then
                            ( split_by_separator
                                | map(select(. != "" and . != $value))
                                | . + [$value]
                                | join($separator)
                            )
                        elif $mode == "PREPEND_IF_NOT_EXISTS" then
                            (split_by_separator) as $parts |
                            if ($parts | index($value)) then 
                                . 
                            else 
                                ( [$value] + $parts | join($separator) ) 
                            end
                        elif $mode == "POSTPEND_IF_NOT_EXISTS" then
                            (split_by_separator) as $parts |
                            if ($parts | index($value)) then 
                                . 
                            else 
                                ($parts + [$value] | join($separator)) 
                            end
                        else
                            .
                        end
                    end
                else
                    if . == null or . == "" then
                        .
                    else
                        if $mode == "REMOVE" then
                            ( split_by_separator
                                | map(select(. != "" and . != $value))
                                | join($separator)
                            )
                        elif $mode == "REMOVE_REGEXP" then
                            ( split_by_separator
                                | map(select(. != "" and (. | test($value) | not)))
                                | join($separator)
                            )
                        else
                            .
                        end
                    end
                end;

            # update target path
            . as $doc
            | (getpath($key_path)) as $cur
            | setpath($key_path; ($cur | process))
        ' \
        | json_escape_string_containing_char "$value" "$separator" "RESTORE"
    }; then
        echo "ERROR json_tweak_value_of_list"
        return 1
    fi

}

