# file: src/commands/stop.sh

# ================================[ Command ]================================= #

stop_server() {
    local session="$1"
    local time="$2"
    local mode="$3"
    local wait="$4"
    local all="$5"

    # =================================[ invoke ]================================= #

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

    # ===============================[ execution ]================================ #

    # Import required module
    log_info "import required modules"
    import "lib.core.command"
    import "lib.filesystem.remove"
    import "lib.tmux.send"
    import "lib.tmux.wait"

    # Check required dependencies
    log_info "check required dependencies"
    check_command "tmux" "fatal"

    if exists_tmux_session "$session"; then

        # Remove the restartctl file to indicate that the server is stopping
        remove_files "$RESTART_CTL" "restartctl"

        # Stop the server with a warning message if the time time is greater than 30 seconds
        if (( time > 30 )); then
            local prewarn=$((time - 30))
            send_tmux "$session" "0" "say Server will $mode in $time seconds. Please prepare to disconnect."
            sleep "$prewarn"

            # 30 Seconds - cit. Lester
            send_tmux "$session" "0" "say Server will $mode in 30 seconds. Please prepare to disconnect."
            sleep 30
        else
            send_tmux "$session" "0" "say Server will $mode in $time seconds. Please prepare to disconnect."
            sleep "$time"
        fi

        # Send the stop command to the tmux session to initiate server shutdown.
        send_tmux "$session" "0" "stop"
        print "stopping server $session" "info"

        # Wait for the tmux session is closed before returning
        [[ "$wait" == "true" ]] && wait_tmux "$session"

        return 0
    fi

    print "server $session is not running" "info"
}
