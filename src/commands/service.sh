# file: src/commands/service.sh

servicectl() {
    local session="$1"
    local name="$2"
    local action="$3"

    # Block external tmux service manager
    if [[ "$session" != "$SESSION_NAME" ]]; then
        log_error "external tmux session not allowed. use service without -s" "print"
        return 1
    fi

    # Import required modules
    log_info "import required modules"
    import "lib.core.command"
    import "lib.config.backup.read"
    import "lib.tmux.exists.session"
    import "lib.tmux.exists.window"

    # Check required dependencies
    log_info "check required dependencies"
    check_command "tmux" "fatal"

    case "$name" in
        backup)
            read_backup
            backup_service "$action"
        ;;

        *)
            log_error "unknown service: $name" "print"
            return 1
        ;;
    esac
}

backup_service() {
    local action="$1"

    case "$action" in
        start)
            if ! exists_tmux_session "$SESSION_NAME"; then
                log_error "tmux session not found: $SESSION_NAME" "print"
                return 1
            fi

            if exists_tmux_window "$SESSION_NAME" "1"; then
                print "backup scheduler is already running"
                return 0
            fi

            if tmux new-window -t "$SESSION_NAME" -n "backup" \
            bash "$BACKUP_SERVICE" "$MCSL_DIR" "$LOG_FILES" "$SESSION_NAME"; then
                og_info "created backup tmux window server: $SESSION_NAME"
                print "starting backup scheduler"
            else
                log_error "failed to create backup tmux window" "print"
                return 1
            fi
        ;;

        stop)
            # TODO: create stop file
            : > "$RUNTIME_DIR/backup.stop"

            print "stopping backup scheduler..."
        ;;

        restart)
            backup_service stop
            backup_service start
        ;;

        status)
            if ! exists_tmux_session "$SESSION_NAME"; then
                print "offline"
                return 1
            fi

            if exists_tmux_window "$SESSION_NAME" "1"; then
                print "running"
            else
                print "stopped"
            fi
        ;;

        *)
            log_error "invalid action: $action" "print"
            return 1
        ;;
    esac
}
