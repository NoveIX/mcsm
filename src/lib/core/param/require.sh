# file: src/lib/cli/param/require.sh

require_param() {
    local name="$1"
    local value="$2"
    local ctx="${3:-unknown}"
    local stream="${4:-out}"

    # Check mandatory parameter
    if [[ -z "$value" ]]; then
        log_error "$ctx: missing required parameter: $name" "print" "$stream"
        return 1
    fi

    return 0
}
