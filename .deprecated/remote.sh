# File: remote.sh
# Description: Module remote for bash scripts
# Author: NoveIX
# SPDX-License-Identifier: GPL-3.0-or-later

# ================================[ Function ]================================ #

execute_ssh() {
    local host="$1"
    local user="$2"
    local key="$3"
    local port="$4"
    shift 4

    # Check mandatory parameters
    require_param "host" "$host" "execute_ssh" || return 1

    # Build the SSH target string
    local target="${user:+$user@}$host"

    # Execute the SSH command with the provided parameters for scripts
    ssh -o BatchMode=yes -o PasswordAuthentication=no -o KbdInteractiveAuthentication=no \
        ${port:+-p "$port"} \
        ${key:+-i "$key"} \
        "$target" \
        "$@"
}

test_ssh() {
    local host="$1"
    local user="$2"
    local key="$3"
    local port="$4"

    # Check mandatory parameters
    require_param "host" "$host" "test_ssh" || return 1

    # simple SSH connectivity test
    execute_ssh "$host" "$user" "$key" "$port" ":" >/dev/null 2>&1
}

sshcheck_command() {
    local cmd="$1"
    local host="$2"
    local mode="${3:-fatal}"
    local user="${4:-}"
    local key="${5:-}"
    local port="${6:-}"

    # Check mandatory parameters
    require_param "cmd" "$cmd" "sshcheck_command" || return 1
    require_param "host" "$host" "sshcheck_command" || return 1

    # Check if command exists - remote SSH
    execute_ssh "$host" "$user" "$key" "$port" command -v "$cmd" >/dev/null 2>&1 && return 0

    # Log missing command based on priority
    local msg="required command not found on remote host $host: $cmd"

    case "$mode" in
        warn)  log_warn  "$msg" "print" ;;
        error) log_error "$msg" "print" ;;
        fatal) log_fatal "$msg" "print" ;;
        *)     log_error "check_command: invalid mode $mode (defaulting to error): $msg" "print" ;;
    esac

    return 1
}
