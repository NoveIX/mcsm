# file: src/commands/stop.sh

stop_server() {
    local session="$1"
    local time="$2"
    local mode="$3"
    local wait="$4"
    local all="$5"

    # INVOKE

    if [[ "$all" == "true" || "$session" != "$SESSION_NAME" ]]; then
        import "lib.remote.invoke"

        # Call command in the specified session or all sessions
        if [[ "$all" == "true" ]]; then
            invoke_sessions stop --time "$time"
        else
            invoke_session "$session"  stop --time "$time"
        fi

        return 0
    fi

    # EXECUTION

    # Import required module
    log_info "import required modules"
    import "lib.core.command"
    import "lib.filesystem.remove"
    #import "lib.filesystem.wait"
    import "lib.tmux.send"
    import "lib.tmux.wait"

    # Check required dependencies
    log_info "check required dependencies"
    check_command "tmux" "fatal"

    if exists_tmux_session "$SESSION_NAME"; then

        # Remove the restartctl file to indicate that the server is stopping
        remove_file "$RESTART_CTL" "restartctl"

        # Stop the server with a warning message if the time time is greater than 30 seconds
        if (( time > 30 )); then
            local prewarn=$((time - 30))
            send_tmux "$SESSION_NAME" "0" "say Server will $mode in $time seconds. Please prepare to disconnect."
            sleep "$prewarn"

            # 30 Seconds - cit. Lester
            send_tmux "$SESSION_NAME" "0" "say Server will $mode in 30 seconds. Please prepare to disconnect."
            sleep 30
        else
            send_tmux "$SESSION_NAME" "0" "say Server will $mode in $time seconds. Please prepare to disconnect."
            sleep "$time"
        fi

        # Send the stop command to the tmux session to initiate server shutdown.
        send_tmux "$SESSION_NAME" "0" "stop"
        print "stopping server $SESSION_NAME" "info"

        # Retry stop server
        #if ! wait_pattern "$SERVER_ROOT/logs/latest.log" "Stopping the server" "120"; then
        #    log_warn "timeout waiting for server to stop. Retry sending stop command." "print"
        #    send_tmux "$SESSION_NAME" "0" "stop"
        #    if ! wait_pattern "$SERVER_ROOT/logs/latest.log" "Stopping the server" "120"; then
        #        log_error "timeout waiting for server to stop. Server may not have stopped cleanly." "print"
        #        print "server $SESSION_NAME may not have stopped cleanly"
        #        return 1
        #    fi
        #fi

        # Wait for the tmux session is closed before returning
        [[ "$wait" == "true" ]] && wait_tmux "$SESSION_NAME"
        return 0
    fi

    print "server $SESSION_NAME is not running" "info"
}
