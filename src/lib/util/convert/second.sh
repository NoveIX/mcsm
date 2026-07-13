# file: src/lib/convert/second.sh

convert_seconds() {
    local s=${1:-0}

    local days=$(( s / 86400 ))
    local hours=$(( (s % 86400) / 3600 ))
    local minutes=$(( (s % 3600) / 60 ))
    local seconds=$(( s % 60 ))

    local result trim

    # Construct the formatted duration string based on non-zero time components
    (( days > 0 )) && result+="${days}d "
    (( hours > 0 )) && result+="${hours}h "
    (( minutes > 0 )) && result+="${minutes}m "
    result+="${seconds}s"

    # Remove trailing space and return the formatted duration string
    printf '%s\n' "${result% }"
}
