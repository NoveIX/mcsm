# file: src/main.sh

main() {
    local cmd="${1:-}"

    # Check if the command is provided
    if [[ -z "$cmd" ]]; then
        log_error "missing command. Use '$0 -h' to display the available commands." "print"
        return 1
    fi

    # If the command is help, print help immediately and skip flag parsing.
    if [[ "${cmd,,}" =~ ^(help|--help|-h)$ ]]; then
        import "commands.help"
        print_help
        return 0
    fi

    # If the command is version, print version immediately and skip flag parsing.
    if [[ "${cmd,,}" =~ ^(version|--version|-v)$ ]]; then
        import "commands.version"
        print_version
        return 0
    fi

    # Shift the command parameter to parse flags
    shift || true

    # Initialize variables for flags
    local session time console wait host port dest user key yes restart norestart all confirm

    # Import required module
    import "lib.core.param.require"
    import "lib.core.param.validate"
    import "lib.cli.flags.validate"

    # Parse flags
    while [[ $# -gt 0 ]]; do

        # Parse combined short flags (-cq, -cwa, etc.)
        if [[ "$1" =~ ^-[^-]{2,}$ ]]; then
            flags="${1:1}"

            while [[ -n "$flags" ]]; do
                flag="${flags:0:1}"
                flags="${flags:1}"

                case "$flag" in
                    c)
                        console="true"
                        validate_flag "console" "${2:-}"
                    ;;

                    w)
                        wait="true"
                        validate_flag "wait" "${2:-}"
                    ;;

                    a)
                        all="true"
                        validate_flag "all" "${2:-}"
                    ;;

                    *)
                        log_error "unknown argument: -$flag" "print"
                        return 1
                    ;;
                esac
            done

            shift
            continue
        fi

        case "$1" in
            --session|-s)
                session="${2:-}"
                require_param "session" "$session" "main"
                validate_flag "session" "${3:-}"
                shift 2
            ;;

            --time|-t)
                time="${2:-}"
                require_param "time" "$time" "main"
                validate_flag "time" "${3:-}"
                shift 2
            ;;

            --console|-c)
                console="true"
                validate_flag "console" "${2:-}"
                shift
            ;;

            --wait|-w)
                wait="true"
                validate_flag "wait" "${2:-}"
                shift
            ;;

            --host|-h)
                host="${2:-}"
                require_param "host" "$host" "main"
                validate_flag "host" "${3:-}"
                shift 2
            ;;

            --port|-p)
                port="${2:-}"
                require_param "port" "$port" "main"
                validate_flag "port" "${3:-}"
                shift 2
            ;;

            --dest|-d)
                dest="${2:-}"
                require_param "dest" "$dest" "main"
                validate_flag "dest" "${3:-}"
                shift 2
            ;;

            --user|-u)
                user="${2:-}"
                require_param "user" "$user" "main"
                validate_flag "user" "${3:-}"
                shift 2
            ;;

            --key|-k)
                key="${2:-}"
                require_param "key" "$key" "main"
                validate_flag "key" "${3:-}"
                shift 2
            ;;

            --yes|-y)
                yes="true"
                validate_flag "yes" "${2:-}"
                shift
            ;;

            --restart)
                restart="true"
                validate_flag "restart" "${2:-}"
                shift
            ;;

            --no-restart)
                norestart="true"
                validate_flag "norestart" "${2:-}"
                shift
            ;;


            --all|-a)
                all="true"
                validate_flag "all" "${2:-}"
                shift
            ;;

            --confirm-action)
                confirm="true"
                validate_flag "confirm" "${2:-}"
                shift
            ;;

            *)
                if [[ "$cmd" == "service" ]]; then
                    srvname="$1"
                    srvaction="$2"
                    shift 2
                else
                    log_error "unknown argument: $1" "print"
                    return 1
                fi
            ;;
        esac
    done

    # Set default values for optional parameters
    session=${session:-$SESSION_NAME}
    time=${time:-0}
    console=${console:-false}
    wait=${wait:-false}
    host=${host:-}
    port=${port:-}
    dest=${dest:-}
    user=${user:-}
    key=${key:-}
    yes=${yes:-false}
    restart=${restart:-false}
    norestart=${norestart:-false}
    all=${all:-false}
    confirm=${confirm:-false}

    # Validate parameter
    validate_param session "$session"
    validate_param time "$time"
    validate_param host "$host"
    validate_param port "$port"
    validate_param dest "$dest"
    validate_param user "$user"
    validate_param key "$key"

    case "${cmd,,}" in
        # Start command. Starts the server.
        start)
            import "commands.start"
            start_server "$session" "$console" "$all"
        ;;

        # Stop command. Stops the server.
        stop)
            import "commands.stop"
            stop_server "$session" "$time" "shutdown" "$wait" "$all"
        ;;

        # Restart command. Stops and then starts the server.
        restart)
            import "commands.restart"
            restart_server "$session" "$time" "$console" "$all"
        ;;

        # Console command. Attaches to the tmux session of the server.
        console|--console|-c)
            import "lib.tmux.attach"
            attach_tmux "$session"
        ;;

        # Status command. Prints the status of the server.
        status)
            import "commands.status"
            status_server "$session" "${host:-localhost}" "${port:-25565}" "$all"
        ;;

        # Migration command. Migrates the server to another location or host.
        migrate)
            import "commands.migrate"
            migrate_server "$dest" "$host" "$user" "$key" "$port" "$time" "$yes" "$restart" "$norestart"
        ;;

        # Sync command. Sync the server files to another location or host.
        sync)
            import "commands.sync"
            sync_server "$dest" "$host" "$user" "$key" "$port" "$yes"
        ;;

        # Kill command. Kill the tmux session of the server immediately.
        kill)
            import "commands.kill"
            kill_server "$session" "$confirm"
        ;;

        #
        service)
            import "commands.service"
            servicectl "$srvname" "$srvaction"
        ;;

        # SelfUpdate command. Updates the mcsl script itself.
        selfupdate)
            import "commands.selfupdate"
            selfupdate "$session" "$all"
        ;;

        # Default case. Prints the help message for mcsl.
        *)
            log_error "main: unknown command: $cmd" "print"
        ;;
    esac
}
