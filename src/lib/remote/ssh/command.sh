# file: src/lib/remote/ssh/command.sh

import "lib.remote.ssh.execute"

sshcheck_command() {
    local cmd="$1"
    local host="$2"
    local mode="${3:-error}"
    local user="${4:-}"
    local key="${5:-}"
    local port="${6:-}"

    # Check if command exists - remote SSH
    if execute_ssh "$host" "$user" "$key" "$port" command -v "$cmd" >/dev/null 2>&1; then
        log_info "remote host $host command found: $cmd"
        return 0
    fi

    # Log missing command based on priority
    local msg="remote host $host command not found: $cmd"

    case "$mode" in
        warn)  log_warn  "$msg" "print" ;;
        error) log_error "$msg" "print" ;;
        fatal) log_fatal "$msg" "print" ;;
        *)     log_error "check_command: invalid mode $mode (defaulting to error): $msg" "print" ;;
    esac

    return 1
}
