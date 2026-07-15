# file: src/lib/tmux/send.sh

import "lib.tmux.exists.session"

send_tmux() {
    local session="$1"
    local window="$2"

    # Shift the command arguments to get the actual command to send
    shift 2

    # Check if command is provided
    if [[ $# -eq 0 ]]; then
        log_error "send_tmux: missing command" "print"
        return 1
    fi

    # Check if the tmux session exists
    if ! exists_tmux_session "$session"; then
        log_error "tmux session $session not found" "print"
        return 1
    fi

    # Send the command to the tmux session
    if tmux send-keys -t "${session}:${window}" "$*" C-m; then
        log_info "sent command to session $session: $*"
        return 0
    fi

    log_error "failed to send command to session $session: $*" "print"
    return 1
}
