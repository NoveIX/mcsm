# file: src/lib/convert/millisecond.sh

convert_milliseconds() {
    local ms=${1:-0}

    local days=$(( ms / 86400000 ))
    local hours=$(( (ms % 86400000) / 3600000 ))
    local minutes=$(( (ms % 3600000) / 60000 ))
    local seconds=$(( (ms % 60000) / 1000 ))
    local milliseconds=$(( ms % 1000 ))

    local result

    # Construct the formatted duration string based on non-zero time components
    (( days > 0 )) && result+="${days}d "
    (( hours > 0 )) && result+="${hours}h "
    (( minutes > 0 )) && result+="${minutes}m "
    (( seconds > 0 || result )) && result+="${seconds}s "
    (( milliseconds > 0 || !result )) && result+="${milliseconds}ms"

    # Remove trailing space and return the formatted duration string
    printf '%s\n' "${result% }"
}
