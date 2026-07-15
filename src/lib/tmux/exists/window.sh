# file: src/lib/tmux/exists/window.sh

exists_tmux_window() {
    local session="$1"
    local window="$2"

    # Check window exists inside session
    tmux list-windows -t "$session" -F "#{window_index}" 2>/dev/null \
        | grep -qx "$window"
}
