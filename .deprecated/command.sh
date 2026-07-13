# File: command.sh
# Description: Command utility functions for bash scripts
# Author: NoveIX
# SPDX-License-Identifier: GPL-3.0-or-later

# ================================[ Function ]================================ #

check_command() {
    local cmd="$1"
    local mode="${2:-fatal}"

    # Check if command exists
    command -v "$cmd" >/dev/null 2>&1 && return 0

    # Log missing command based on priority
    local msg="required command not found: $cmd"

    case "${mode,,}" in
        warn)  log_warn  "$msg" "print" ;;
        error) log_error "$msg" "print" ;;
        fatal) log_fatal "$msg" "print" ;;
        *)     log_error "check_command: invalid mode $mode (defaulting to error): $msg" "print" ;;
    esac

    return 1
}
