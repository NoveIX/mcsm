# file: src/lib/tmux/kill.sh


import "lib.tmux.exists.session"

kill_tmux() {
    local session="$1"

    # Check if the tmux session exists
    if ! exists_tmux_session "$session"; then
        log_error "tmux session $session not found" "print"
        return 1
    fi

    # Kill tmux session
    if tmux kill-session -t "$session"; then
        log_info "tmux session $session killed"
        return 0
    fi

    log_error "failed to kill tmux session $session" "print"
    return 1
}
