# file: src/lib/tmux/enter.sh


import "lib.tmux.exists.session"

enter_tmux() {
    local session="$1"
    local window="${2:-0}"

    # Check if the tmux session exists
    if ! exists_tmux_session "$session"; then
        log_error "tmux session $session not found" "print"
        return 1
    fi

    # Send an enter key to the tmux session
    if tmux send-keys -t "${session}:${window}" C-m; then
        log_info "sent enter to tmux session $session"
        return 0
    fi

    log_error "failed to send enter to tmux session $session" "print"
    return 1
}
