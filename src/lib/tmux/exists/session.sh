# file: src/lib/tmux/exists/session.sh

# Check if the tmux session exists
exists_tmux_session() {
    tmux has-session -t "$1" 2>/dev/null
}
