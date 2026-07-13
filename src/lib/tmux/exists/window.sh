# file: src/lib/tmux/exists/window.sh


import "lib.tmux.exists.session"

exists_tmux_window() {
    local session="$1"
    local window="$2"

    # First check session exists
    if ! exists_tmux_session "$session"; then
        log_error "tmux session $session not found" "print"
        return 1
    fi

    # Check window exists inside session
    tmux list-windows -t "$session" -F "#{window_index}" 2>/dev/null \
        | grep -qx "$window"
}
