# file: src/commands/restart.sh

restart_server() {
    local session="$1"
    local time="$2"
    local console="$3"
    local all="$4"

    # INVOKE

    if [[ "$all" == "true" || "$session" != "$SESSION_NAME" ]]; then
        import "lib.remote.invoke"

        local -a args=()
        [[ "$console" == "true" ]] && args+=(--console)

        # Call command in the specified session or all sessions
        if [[ "$all" == "true" ]]; then
            invoke_sessions restart "${args[@]}"
        else
            invoke_session "$session" restart "${args[@]}"
        fi

        return 0
    fi

    # EXECUTION

    # Import required module
    log_info "import required modules"
    import "lib.core.command"
    import "lib.tmux.exists.session"
    import "commands.start"
    import "commands.stop"

    # Check required dependencies
    log_info "check required dependencies"
    check_command "tmux" "fatal"

    # Restart server
    if exists_tmux_session "$SESSION_NAME"; then
        stop_server "$SESSION_NAME" "$time" "restart" "true" "$all" || {
            log_error "timeout waiting for server to stop" "print"
            return 1
        }
    fi

    start_server "$SESSION_NAME" "$console" "$all"
}
