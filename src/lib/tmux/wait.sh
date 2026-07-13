# file: src/lib/tmux/wait.sh

import "lib.tmux.exists.session"

wait_tmux() {
    local session="$1"
    local timeout="${2:-600}" # default: 10 minutes
    local elapsed=0

    log_info "waiting for tmux session $session to stop (timeout: ${timeout}s)"

    # Wait until the tmux session no longer exists
    while exists_tmux_session "$session"; do
        sleep 1
        ((elapsed++)) || true

        # Check for timeout
        if (( elapsed >= timeout )); then
            log_error "timeout waiting for tmux session $session to stop (${timeout}s)" "print"
            return 1
        fi
    done

    sleep 2
    log_info "tmux session $session stopped"
    return 0
}
