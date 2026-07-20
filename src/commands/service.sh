# file: src/commands/service.sh

servicectl() {
    local name="$1"
    local action="$2"

    # Import required modules
    log_info "import required modules"
    import "lib.core.command"
    import "lib.config.backup.read"
    import "lib.config.runtime.read"
    import "lib.filesystem.remove"
    import "lib.tmux.exists.session"
    import "lib.tmux.exists.window"

    # Check required dependencies
    log_info "check required dependencies"
    check_command "tmux" "fatal"

    # Read runtime config
    read_runtime

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
            # Check session
            if ! exists_tmux_session "$SESSION_NAME"; then
                log_error "tmux session not found: $SESSION_NAME" "print"
                return 1
            fi

            # Check window
            if exists_tmux_window "$SESSION_NAME" "1"; then
                print "backup scheduler is already running" "info"
                return 0
            fi

            # Check config
            if [[ "$BACKUP_ENABLED" == "false" ]]; then
                print "backup is disabled by configuration" "info"
                return 0
            fi

            # Start service
            if tmux new-window -d \
            -t "$SESSION_NAME":1 \
            -n "backup" \
            bash "$BACKUP_SERVICE" "$MCSL_DIR" "$LOG_FILES" "$SESSION_NAME"; then
                log_info "created new tmux window. Backup scheduler (server: $SESSION_NAME)"
                print "starting backup scheduler"
            else
                log_error "failed to create new tmux window. Backup scheduler (server: $SESSION_NAME)" "print"
                return 1
            fi
        ;;

        stop)
            print "Stopping backup scheduler"
            remove_file "$BACKUP_STATE" "backup.state"
            wait_tmux_window "$SESSION_NAME" "1"
        ;;

        restart)
            if exists_tmux_window "$SESSION_NAME" "1"; then
                backup_service stop || {
                    log_error "timeout waiting for backup scheduler to stop" "print"
                    return 1
                }
            fi

            backup_service start
        ;;

        status)
            # Color var
            local red="\033[31m"
            local blue="\033[94m"
            local green="\033[32m"
            local reset="\033[0m"

            # Status var
            local dot="${red}●${reset}"
            local state="${red}Stopped${reset}"

            # Check if window exist
            exists_tmux_session "$SESSION_NAME" && dot="${green}●${reset}"
            exists_tmux_window "$SESSION_NAME" "1" && state="${green}Running${reset}"

            printf '%b %-20s %-10b\n' "$dot" "Backup scheduler" "$state"
        ;;

        *)
            log_error "invalid action: $action" "print"
            return 1
        ;;
    esac
}

wait_tmux_window() {
    local session="$1"
    local window="$2"
    local timeout="${3:-600}" # default: 10 minutes
    local elapsed=0

    log_info "waiting for tmux window $window (session: $session) to stop (timeout: ${timeout}s)"

    # Wait until the tmux window no longer exists
    while exists_tmux_window "$session" "$window"; do
        sleep 1
        ((elapsed++)) || true

        # Check for timeout
        if (( elapsed >= timeout )); then
            log_error "timeout waiting for tmux window $window (session: $session) to stop (${timeout}s)" "print"
            return 1
        fi
    done

    sleep 2
    log_info "tmux window $window (session: $session) stopped"
    return 0
}
