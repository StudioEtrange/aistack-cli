# ----------------------------------- YAML UTILITIES -----------------------------------

# build a YAML array for yq
# build_yq_array_from_path <key_path>
#
build_yq_array_from_path() {
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

    if [ "$esc" -eq 1 ]; then
        buf="${buf}\\"
    fi

    [ -n "$buf" ] && parts+=("$buf")
    ((${#parts[@]} > 0)) || { echo "ERROR: invalid key path '$key_path'" >&2; return 1; }

    local yq_path
    yq_path="$(
		set -o pipefail
        printf '%s\n' "${parts[@]}" \
			| jq -R 'if test("^[0-9]+$") then tonumber else . end' \
			| jq -s -c .
    )" || { echo "ERROR: building yq path" >&2; return 1; }

    printf "%s" "$yq_path"
}


# build an expression for yq
# build_yq_expr_from_path <key_path>
#
# build_yq_expr_from_path ".a.b.c"
#          .["a"]["b"]["c"]
build_yq_expr_from_path() {
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

    if [ "$esc" -eq 1 ]; then
        buf="${buf}\\"
    fi

    [ -n "$buf" ] && parts+=("$buf")
    ((${#parts[@]} > 0)) || { echo "ERROR: invalid key path '$key_path'" >&2; return 1; }

    local yq_expr="."
    local key json_key
    for key in "${parts[@]}"; do
        case "$key" in
            (*[!0-9]*|'')  # non numeric
                json_key="$(printf '%s' "$key" | jq -R .)" || { echo "ERROR: escaping key" >&2; return 1; }
                yq_expr+="[$json_key]"
                ;;
            (*)            # numeric
                yq_expr+="[$key]"
                ;;
        esac
    done

    printf "%s" "$yq_expr"
}

# NOTE : yq cannot naturaly distinguish existing key but with empty value and non existing key
# return 0 if key_path exists with empty or not empty value
# return 10 if key_path do not exists
yaml_has_key() {
	local key_path="$1"
    if [ -z "$key_path" ]; then
        echo "ERROR : yaml key path empty"
        return 1
    fi

	local yq_path parent_expr leaf_key exists rc

	yq_path="$(build_yq_array_from_path "${key_path}")" || return 1

	parent_expr="$(printf '%s' "${yq_path}" | jq -r '
		reduce .[0:-1][] as $key
			("." ; . + "[" + ($key | tojson) + "]")
	')" || return 1

	leaf_key="$(printf '%s' "${yq_path}" | jq -c '.[-1]')" || return 1

	exists="$(
		PARENT_EXPR="${parent_expr}" LEAF_KEY="${leaf_key}" \
			yq eval 'eval(strenv(PARENT_EXPR)) | has(env(LEAF_KEY))'
	)"
	rc=$?

	# A yq error is not an absent key
	[ "${rc}" -eq 0 ] || return "${rc}"

	case "${exists}" in
		true)
			return 0
			;;
		false)
			return 10
			;;
		*)
			echo "ERROR: unexpected YAML key existence result" >&2
			return 1
			;;
	esac
}

# get a key from yaml input
# cat input.yaml | yaml_get_key <key_path>
# yaml_get_key <key_path> < input.yaml
# key_path : can contains index for array
# return empty string if key do not exists or have empty value
yaml_get_key() {
    local key_path="$1"

    if [ "$#" -lt 1 ]; then
        echo "ERROR : argument missing" >&2
        return 1
    fi

    if [ -z "$key_path" ]; then
        echo "ERROR : yaml key path empty" >&2
        return 1
    fi

    local yq_path
    yq_path="$(build_yq_expr_from_path "$key_path")" || return 1

    # NOTE : with yq we cannot distinguish existing key but with empty value and non existing key
    # so in any of these cases we return empty string
    # and we use a hack for special boolean value "false", which yq considers as a fault result and return 1

    if ! PATH_VAR="$yq_path" yq eval -e 'eval(strenv(PATH_VAR)) | tostring | sub("^false$"; "false") | sub("^null$"; "")'; then
        echo "ERROR : get key path: $key_path"
        return 1
    fi
}

yaml_get_key_from_file() {
    local target_file="$1"
    local key_path="$2"

    if [ "$#" -lt 2 ]; then
        echo "ERROR : argument missing" >&2
        return 1
    fi

    if [ -z "$key_path" ]; then
        echo "ERROR : yaml key path empty" >&2
        return 1
    fi

    if [ ! -s "$target_file" ]; then
        echo "ERROR : file do not exist $target_file" >&2
        return 1
    fi

    yaml_get_key "$key_path" < "$target_file"
    local ret=$?

    if [ $ret -ne 0 ]; then
        echo "ERROR : processing with yq"
    fi

    return $ret
}

# set a key from yaml input
# cat input.yaml | yaml_set_key <key_path> <value> <string_style>
# yaml_set_key <key_path> <value> < input.yaml
# key_path : can contains index for array
# value: must be a valid YAML value
# string_style (optional) : double|single|literal|folded|flow https://mikefarah.gitbook.io/yq/operators/style
#   single: string with single quote
#   double: string with double quote
# yaml_set_key "a.b.c" "new_value"
yaml_set_key() {
	local key_path="$1"
	local value="$2"
	local string_style="$3"
	local prog yq_path input_file ret

	if [ "$#" -lt 2 ]; then
		echo "ERROR : argument missing" >&2
		return 1
	fi

	if [ -z "$key_path" ]; then
		echo "ERROR : yaml key path empty" >&2
		return 1
	fi

	case "$string_style" in
		double|single|literal|folded|flow)
			# force string + style (double/single/literal/folded/flow)
			prog='eval(strenv(PATH_VAR)) = strenv(VAL) | eval(strenv(PATH_VAR)) style=strenv(STRING_STYLE)'
			;;
		*)
			# default: yq parse value as YAML (true, 12, [a,b], {k:v}, ...)
			prog='eval(strenv(PATH_VAR)) = env(VAL)'
			;;
	esac

	yq_path="$(build_yq_expr_from_path "$key_path")" || return 1

	if [ -t 0 ]; then
		STRING_STYLE="${string_style}" PATH_VAR="${yq_path}" VAL="${value}" \
			yq eval --null-input "$prog"
		return $?
	fi

	input_file="$(mktemp)" || {
		echo "ERROR : unable to create temporary YAML file" >&2
		return 1
	}
	if ! cat > "$input_file"; then
		echo "ERROR: unable to save YAML to a temp file" >&2
		rm -f "${input_file}"
		return 1
	fi

	if [ -s "$input_file" ]; then
		STRING_STYLE="${string_style}" PATH_VAR="${yq_path}" VAL="${value}" \
			yq eval "$prog" "$input_file"
		ret=$?
	else
		STRING_STYLE="${string_style}" PATH_VAR="${yq_path}" VAL="${value}" \
			yq eval --null-input "$prog"
		ret=$?
	fi

	rm -f "$input_file"
	if [ "$ret" -ne 0 ]; then
		echo "ERROR : generating yaml from key_path/value" >&2
	fi

	return "$ret"

}


# set a yaml key into a file
# yaml_set_key_into_file <file> <key_path> <value> <string_style>
# string_style (optional) : double|single|literal|folded|flow https://mikefarah.gitbook.io/yq/operators/style
#   single: string with single quote
#   double: string with double quote
# target_file : if name given but file not exist, it is created empty
# yaml_set_key_into_file "input.yaml" ".a.b.c" 'value' 
yaml_set_key_into_file() {
    local target_file="$1"
    local key_path="$2"
    local value="$3"
    local string_style="$4"

    if [ "$#" -lt 3 ]; then
        echo "ERROR : argument missing"
        exit 1
    fi
    if [ -z "$key_path" ]; then
        echo "ERROR : yaml key path to set empty"
        exit 1
    fi
	if [ -z "$target_file" ]; then
		echo "ERROR : target yaml file empty name given"
        exit 1
	fi
    if [ ! -s "$target_file" ]; then
        echo "Valid target file not found at $target_file. Creating it."
        mkdir -p "$(dirname "$target_file")"
        touch "$target_file"
    fi


    local yq_opt=""
    local prog
    case "$string_style" in
       double|single|literal|folded|flow)
            # force string + style (double/single/literal/folded/flow)
            prog='eval(strenv(PATH_VAR)) = strenv(VAL) | eval(strenv(PATH_VAR)) style=strenv(STRING_STYLE)'
            ;;
       *) 
            # default: yq parse value as YAML (true, 12, [a,b], {k:v}, ...)
            prog='eval(strenv(PATH_VAR)) = env(VAL)'
            # NOTE : avoid -P usage because it simplfy style and remove some quotes
            #yq_opt="$yq_opt -P"
            ;;
    esac

    local yq_path
    yq_path="$(build_yq_expr_from_path "$key_path")" || return 1

    local tmp_target_file="$(mktemp)"
    # NOTE : avoid using -i to preserve file formatting like quote style for values
    if ! STRING_STYLE="${string_style}" PATH_VAR="${yq_path}" VAL="${value}" yq eval $yq_opt "$prog" "$target_file" > "$tmp_target_file"; then
        echo "ERROR : generating yaml from key_path/value" >&2
        rm -f "$tmp_target_file"
        return 1
    fi

	if ! cat "${tmp_target_file}" > "${target_file}"; then
		echo "ERROR: unable to fill YAML file: ${target_file}" >&2
		rm -f "$tmp_target_file"
		return 1
	fi

    rm -f "$tmp_target_file"
	return 0
}


# delete a key from yaml input
# cat input.yaml | yaml_del_key <key_path>
# yaml_del_key <key_path> < input.yaml
# Return 10 if key do not exist
yaml_del_key() {
    local key_path="$1"
    if [ -z "$key_path" ]; then
        echo "ERROR : yaml key path empty"
        return 1
    fi
	local tmp_file yq_expr rc
	yq_expr="$(build_yq_expr_from_path "${key_path}")" || return 1

	tmp_file="$(mktemp)" || return 1
	if [ ! -t 0 ]; then
		if ! cat > "${tmp_file}"; then
			rm -f "${tmp_file}"
			return 1
		fi

		yaml_has_key "$key_path" < "$tmp_file"
		rc="$?"
		if [ "${rc}" -ne 0 ]; then
			
			if [ "${rc}" -eq 10 ]; then
				cat "$tmp_file"
				rm -f "${tmp_file}"
				return 10
			fi
			rm -f "${tmp_file}"
			return "${rc}"
		fi


		PATH_EXPR="${yq_expr}" \
			yq eval 'del(eval(strenv(PATH_EXPR)))' "${tmp_file}"
		rc=$?
		rm -f "${tmp_file}"
		return "${rc}"
	else
		rm -f "${tmp_file}"
		return 1
	fi

}

# delete a yaml key from a file
# yaml_del_key_from_file <file> <key_path>
#
# yaml_del_key_from_file "input.yaml" ".a.b.c"
# if key_path do not exists return 0
yaml_del_key_from_file() {
    local target_file="$1"
    local key_path="$2"
	local tmp_file rc

    if [ -z "$key_path" ]; then
        echo "ERROR : yaml key path to remove empty"
        return 1
    fi
    if [ ! -s "$target_file" ]; then
        echo "WARN : file not found $target_file"
        return 0
    fi

	tmp_file="$(mktemp "${target_file}.tmp.XXXXXX")" || {
		echo "ERROR: unable to create temporary file for ${target_file}" >&2
		return 1
	}

	yaml_del_key "${key_path}" < "${target_file}" > "${tmp_file}"
	rc=$?
	if [ "${rc}" -ne 0 ]; then
		rm -f "${tmp_file}"
		[ "${rc}" -eq 10 ] && return 0
		return "${rc}"
	fi

	if ! cat "${tmp_file}" > "${target_file}"; then
		echo "ERROR: unable to fill YAML file: ${target_file}" >&2
		rm -f "${tmp_file}"
		return 1
	fi
	
	rm -f "${tmp_file}"
	return 0
}



# merge one yaml file (file_to_merge) into another (file_to_merge_into)
# file_to_merge_into : if not exist, it is created empty
# file_to_merge : have higher priority and erase file_to_merge_into content
# file_to_merge also support environment variable injection ${VAR} (Replace ${VAR} with environnement variable if it exists)
merge_yaml_file() {
    local file_to_merge="$1"
    local file_to_merge_into="$2"

    if [ ! -f "$file_to_merge" ]; then
        echo "ERROR : file to merge not found $file_to_merge"
        exit 1
    fi

	if [ -z "$file_to_merge_into" ]; then
		echo "ERROR : file to merge into empty name given"
        exit 1
	fi

    if [ ! -s "$file_to_merge_into" ]; then
        mkdir -p "$(dirname "$file_to_merge_into")"
        touch "$file_to_merge_into"
    fi

    local tmp_merge="$(mktemp)"
    
    # Environment variable injection ${VAR}
    # Using yq to convert to json, jq to expand env (to match merge_json_file logic), then back to yaml
    if ! yq -o json "$file_to_merge" | jq \
            'def expand_env:
                walk(
                    if type=="string" then
                        gsub("\\$\\{(?<k>[A-Za-z_][A-Za-z0-9_]*)\\}"; (env[.k] // ("${"+.k+"}")))
                    else 
                        . 
                    end
                    );
            expand_env
    ' | yq -P > "$tmp_merge"; then
        echo "ERROR : expanding environment variables in $file_to_merge" >&2
        rm -f "$tmp_merge"
        exit 1
    fi

    # To preserve order as much as possible like jq does, we do the merge via json conversion
    local tmp_into_json="$(mktemp)"
    yq -o json "$file_to_merge_into" > "$tmp_into_json"
    
    if ! yq -o json "$tmp_merge" | jq -s '.[0] * .[1]' "$tmp_into_json" - | yq -P > "$file_to_merge_into"; then
        echo "ERROR : merging with yq/jq"
        rm -f "$tmp_merge" "$tmp_into_json"
        exit 1
    fi

    rm -f "$tmp_merge" "$tmp_into_json"
}


