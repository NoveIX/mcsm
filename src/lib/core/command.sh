# file: src/lib/core/command.sh

check_command() {
    local cmd="$1"
    local mode="${2:-error}"

    # Check if command exists
    if command -v "$cmd" >/dev/null 2>&1; then
        log_info "command found: $cmd"
        return 0
    fi

    # Log missing command based on priority
    local msg="command not found: $cmd"

    case "$mode" in
        warn)  log_warn  "$msg" "print" ;;
        error) log_error "$msg" "print" ;;
        fatal) log_fatal "$msg" "print" ;;
        *)     log_error "check_command: invalid mode $mode (defaulting to error): $msg" "print" ;;
    esac

    return 1
}
