# file: src/commands/kill.sh

# ================================[ Command ]================================= #

kill_server() {
    local session="$1"
    local confirm="$2"

    # Block external tmux session kill attempts
    if [[ "$session" != "$SESSION_NAME" ]]; then
        log_error "external tmux session not allowed. use kill without -s" "print"
        return 1
    fi

    # Check confirm is a valid boolean value (true/false)
    if [[ ! "$confirm" =~ ^(true|false)$ ]]; then
        log_error "invalid confirm value $confirm (expected true|false)" "print"
        return 1
    fi

    # Check for confirmation flag
    if [[ "$confirm" == "false" ]]; then
        log_error "destructive operation blocked: --confirm-action required" "print"
        return 1
    fi

    # Import required module
    import "lib.core.command"
    import "lib.tmux.kill"

    # Check required dependencies
    check_command "tmux" "fatal"

    # Check if the tmux session exists.
    if exists_tmux_session "$session"; then
        kill_tmux "$session"
        return 0
    fi

    print "tmux session $session does not exist" "info"
}
