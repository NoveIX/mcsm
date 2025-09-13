#!/usr/bin/env bash

# Dizionario dei tipi attesi
declare -A EXPECTED_TYPES=(
    [RunFile]="string"
    [CrashHandle]="bool"
    [GitEnable]="bool"
    [GitRepository]="string"
    [GitBranch]="string"
    [GitSSHPublicKeyDirectLink]="string"
    [GitSSHPrivateKeyDirectLink]="string"
)

parse_toml() {
    local config_file="$1"
    local errors=0

    # Check if file exists
    if [[ ! -f "$config_file" ]]; then
        log_error_cli "Config file not found: $config_file"
        return 1
    fi

    while IFS='=' read -r raw_key raw_value; do
        # Skip empty lines, comments, or lines without '='
        [[ -z "$raw_key" || "$raw_key" =~ ^# || "$raw_key" != *"="* ]] && continue

        # Trim spaces/tabs
        key="$(echo -e "$raw_key" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"
        value="$(echo -e "$raw_value" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"

        # Remove surrounding quotes
        value="${value%\"}"
        value="${value#\"}"

        # If key without value
        [[ -z "$raw_value" ]] && value=""

        # Normalize booleans
        if [[ "${EXPECTED_TYPES[$key]}" == "bool" ]]; then
            case "${value,,}" in
                true) value="true" ;;
                false) value="false" ;;
                "") ;;
                *)
                    log_error_cli "Config: $key must be boolean (true or false), found $value"
                    ((errors++))
                    continue ;;
            esac
        fi

        # Export as global variable
        declare -g "$key"="$value"
    done < "$config_file"

    # Validate keys
    for k in "${!EXPECTED_TYPES[@]}"; do
        local type="${EXPECTED_TYPES[$k]}"
        local val="${!k}"

        if [[ "$type" == "bool" && -z "$val" ]]; then
            log_error_cli "Config: Parameter $k is boolean and cannot be empty"
            ((errors++))
            continue
        fi

        case "$type" in
            bool)
                if [[ "$val" != "true" && "$val" != "false" ]]; then
                    log_error_cli "Config: $k must be true or false, found $val"
                    ((errors++))
                fi
                ;;
            string)
                # string can be empty
                ;;
        esac
    done

    # Final result log
    if (( errors > 0 )); then
        log_error "Config: validation failed with $errors errors"
        return 1
    else
        return 0
    fi
}
