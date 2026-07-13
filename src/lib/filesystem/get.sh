# file: src/lib/filesystem/get.sh

get_property() {
    local file="$1"
    local key="$2"
    local value

    # Check server.properties exists
    if [[ ! -f "$file" ]]; then
        log_error "get_property: file not found: $file" "print" "err"
        return 1
    fi

    # Extract the key value from file
    value=$(grep -m1 -E "^${key}=" "$file") || true
    value=${value#*=}

    # Check if the value was found
    if [[ -z "$value" ]]; then
        log_error "get_property: $key not found in $file" "print" "err"
        return 1
    fi

    # Output the value
    printf '%s\n' "$value"
}
