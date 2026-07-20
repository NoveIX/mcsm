# file: src/commands/kill.sh

kill_server() {
    local session="$1"
    local confirm="$2"

    # Block external tmux session kill attempts
    if [[ "$session" != "$SESSION_NAME" ]]; then
        log_error "external tmux session not allowed. use kill without -s" "print"
        return 1
    fi

    # Check for confirmation flag
    if [[ "$confirm" == "false" ]]; then
        log_error "destructive operation blocked: --confirm-action required" "print"
        return 1
    fi

    # Import required module
    log_info "import required modules"
    import "lib.core.command"
    import "lib.tmux.kill"

    # Check required dependencies
    log_info "check required dependencies"
    check_command "tmux" "fatal"

    # Check if the tmux session exists.
    if exists_tmux_session "$SESSION_NAME"; then
        kill_tmux "$SESSION_NAME"
        print "tmux session $SESSION_NAME killed"
        return 0
    fi

    print "tmux session $SESSION_NAME does not exist" "info"
}
