# file: src/commands/start.sh

start_server() {
    local session="$1"
    local console="$2"
    local all="$3"

    # INVOKE

    if [[ "$all" == "true" || "$session" != "$SESSION_NAME" ]]; then
        import "lib.remote.invoke"

        local -a args=()
        [[ "$console" == "true" ]] && args+=(--console)

        # Call command in the specified session or all sessions
        if [[ "$all" == "true" ]]; then
            invoke_sessions start "${args[@]}"
        else
            invoke_session "$session" start "${args[@]}"
        fi

        return 0
    fi

    # GENERATE CONFIG

    # Genereting default config
    if [[ ! -f "$RUNTIME_CONF" ]]; then
        import "lib.config.runtime.default"
        import "lib.config.backup.default"
        import "lib.config.notify.default"

        mkdir -p "$CFG_DIR"

        # Generate default configuration file
        print "generating default configuration"
        default_runtime "$RUNTIME_CONF"
        default_backup "$BACKUP_CONF"
        default_notify "$NOTIFY_CONF"

        # Log message to inform the user about the generated configuration file
        print "edit $RUNTIME_CONF to configure mcsl runtime"
        print "edit $BACKUP_CONF to configure mcsl backup"
        print "edit $NOTIFY_CONF to configure mcsl notify"
        return 0
    fi

    # EXECUTION

    # Import required module
    log_info "import required modules"
    import "lib.core.command"
    import "lib.config.runtime.read"
    import "lib.config.backup.read"
    import "lib.filesystem.eula.read"
    import "lib.filesystem.create"
    import "lib.tmux.attach"

    # Check required dependencies
    log_info "check required dependencies"
    check_command "tmux" "fatal"
    check_command "java" "warn" || true

    # Check if the tmux session already exists
    if ! exists_tmux_session "$SESSION_NAME"; then
        read_runtime
        read_backup

        read_eula "$SERVER_ROOT/eula.txt"

        # Create the restart control file to indicate that the server will restart on crash.
        create_file "$RESTART_CTL" "restartctl"

        # Create a new detached tmux session that runs the mcsl script
        if tmux new-session -d -s "$SESSION_NAME" -n "runtime" \
        bash "$RUNTIME_SERVICE" "$MCSL_DIR" "$LOG_FILES" "$SESSION_NAME"; then
            log_info "created new tmux session. Runtime service (server: $SESSION_NAME)"
            print "starting server $SESSION_NAME"
        fi

        # Create a new detached tmux window for backup operations
        if [[ "$BACKUP_ENABLED" == "true" ]]; then
            if tmux new-window -t "$SESSION_NAME:1" -n "backup" \
            bash "$BACKUP_SERVICE" "$MCSL_DIR" "$LOG_FILES" "$SESSION_NAME"; then
                log_info "created new tmux window. Backup scheduler (server: $SESSION_NAME)"
                print "starting backup scheduler"
            fi
        fi

        # Connect to tmux session
        [[ "$console" == "true" ]] && attach_tmux "$SESSION_NAME"
        return 0
    fi

    print "server $SESSION_NAME is running" "info"
    return 0
}
