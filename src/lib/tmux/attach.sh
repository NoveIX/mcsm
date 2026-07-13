# file: src/lib/tmux/attach.sh


import "lib.tmux.exists.session"

attach_tmux() {
    local session="$1"
    local window="${2:-0}"

    # Check if the tmux session exists
    if ! exists_tmux_session "$session"; then
        log_error "tmux session $session not found" "print"
        return 1
    fi

    # Attach to the tmux session
    log_info "connecting to session $session"
    tmux attach-session -t "${session}:${window}"
}
