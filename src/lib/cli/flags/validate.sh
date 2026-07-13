# file: src/lib/core/flags/validate.sh

validate_flag() {
    local flag="$1"
    local next="$2"

    # error only if the next one is NOT a flag
    [[ -n "$next" && "$next" != -* ]] && {
        log_error "$flag does not accept parameters: $next" "print"
        return 1
    }

    return 0
}
