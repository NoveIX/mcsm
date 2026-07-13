# file: src/commands/restart.sh

# ================================[ Command ]================================= #

restart_server() {
    local session="$1"
    local time="$2"
    local console="$3"
    local all="$4"

    # =================================[ invoke ]================================= #

    if [[ "${all,,}" == "true" || "$session" != "$SESSION_NAME" ]]; then
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

    # ===============================[ execution ]================================ #

    # Import required module
    import "lib.core.command"
    import "lib.tmux.exists.session"
    import "commands.start"
    import "commands.stop"

    # Check required dependencies
    check_command "tmux" "fatal"

    # Restart server
    if exists_tmux_session "$session"; then
        stop_server "$session" "$time" "restart" "true" "$all"
    fi

    start_server "$session" "$console" "$all"
}
