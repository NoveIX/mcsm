# File: common.sh
# Description: Common utility functions for bash scripts
# Author: NoveIX
# SPDX-License-Identifier: GPL-3.0-or-later

# ================================[ Function ]================================ #

# Format a duration in seconds into a human-readable string (e.g., "1d 2h 3m 4s").
format_duration() {
    local total_seconds=${1:-0}

    local days=$(( total_seconds / 86400 ))
    local hours=$(( (total_seconds % 86400) / 3600 ))
    local minutes=$(( (total_seconds % 3600) / 60 ))
    local seconds=$(( total_seconds % 60 ))

    local result trim

    # Construct the formatted duration string based on non-zero time components
    (( days > 0 )) && result+="${days}d "
    (( hours > 0 )) && result+="${hours}h "
    (( minutes > 0 )) && result+="${minutes}m "
    result+="${seconds}s"

    # Remove trailing space and return the formatted duration string
    printf '%s\n' "${result% }"
}

format_durationms() {
    local total_ms=${1:-0}

    local days=$(( total_ms / 86400000 ))
    local hours=$(( (total_ms % 86400000) / 3600000 ))
    local minutes=$(( (total_ms % 3600000) / 60000 ))
    local seconds=$(( (total_ms % 60000) / 1000 ))
    local milliseconds=$(( total_ms % 1000 ))

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
