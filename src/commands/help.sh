# file: src/commands/help.sh

print_help() {
    import "commands.version"
    local cmd="${1:-}"

    local version=$(get_version)

    if [[ -n "$cmd" ]]; then
        case "$cmd" in
            start)                help_start      ;;
            stop)                 help_stop       ;;
            restart)              help_restart    ;;
            console|--console|-c) help_console    ;;
            status)               help_status     ;;
            migrate)              help_migrate    ;;
            sync)                 help_sync       ;;
            kill)                 help_kill       ;;
            service)              help_service    ;;
            selfupdate)           help_selfupdate ;;
            version|-v|--version) help_version    ;;
            help|--help|-h)       help_help       ;;

            *)
                log_error "help: unknown command: $cmd"
                print "Use 'help' to display the list of available commands."
                return 1
            ;;
        esac
        return 0
    fi

    cat <<EOF
Usage: ${mcsl_name:-mcsl.sh} <command> [options]

Commands:
  help [command]         Show the command list or detailed help for a command.
  version, -v, --version Show the installed MCSL version.
  start                  Start the Minecraft server.
  stop                   Stop the server gracefully.
  restart                Restart the server.
  console, -c, --console Attach to the server tmux console.
  status                 Display the server status.
  selfupdate             Update MCSL from the Git repository.
  migrate                Move the server to a new location.
  sync                   Mirror the server files to another location.
  kill                   Forcefully terminate a server tmux session.
  service <name> <action> Manage services (currently backup).

Use 'help <command>' for more details, for example:
  ./mcsl.sh help start
  ./mcsl.sh help migrate

Version: $version
EOF
}

help_help() {
    cat <<EOF
Usage: ${mcsl_name:-mcsl.sh} help [command]

Description:
  Show the list of available commands or detailed help for a specific command.

Examples:
  ./mcsl.sh help
  ./mcsl.sh help start
  ./mcsl.sh help migrate
EOF
}

help_version() {
    cat <<EOF
Usage: ${mcsl_name:-mcsl.sh} version

Description:
  Show the installed MCSL version.
EOF
}

help_start() {
    cat <<EOF
Usage: ${mcsl_name:-mcsl.sh} start [options]

Description:
  Start the Minecraft server through tmux.

Options:
  -s, --session <name>   Target the tmux session.
  -c, --console          Attach to the tmux console after start.
  -a, --all              Apply the command to all servers in the parent container directory.

Examples:
  ./mcsl.sh start
  ./mcsl.sh start --console
EOF
}

help_stop() {
    cat <<EOF
Usage: ${mcsl_name:-mcsl.sh} stop [options]

Description:
  Stop the server gracefully.

Options:
  -s, --session <name>   Target the tmux session.
  -t, --time <seconds>   Delay before sending the stop command.
  -w, --wait             Wait until the tmux session closes.
  -a, --all              Apply the command to all servers in the parent container directory.

Examples:
  ./mcsl.sh stop
  ./mcsl.sh stop --time 30 --wait
EOF
}

help_restart() {
    cat <<EOF
Usage: ${mcsl_name:-mcsl.sh} restart [options]

Description:
  Stop and then start the server again.

Options:
  -s, --session <name>   Target the tmux session.
  -t, --time <seconds>   Delay before stopping the server.
  -c, --console          Attach to the tmux console after restart.
  -a, --all              Apply the command to all servers in the parent container directory.

Examples:
  ./mcsl.sh restart
  ./mcsl.sh restart --time 60 --console
EOF
}

help_console() {
    cat <<EOF
Usage: ${mcsl_name:-mcsl.sh} console [options]

Description:
  Attach to the tmux console for the target server session.

Options:
  -s, --session <name>   Target the tmux session.

Examples:
  ./mcsl.sh console
EOF
}

help_status() {
    cat <<EOF
Usage: ${mcsl_name:-mcsl.sh} status [options]

Description:
  Check whether the server is reachable and display its status.

Options:
  -s, --session <name>   Target the tmux session.
  -h, --host <host>      Host to query (default: localhost).
  -p, --port <port>      TCP port to query (default: 25565).
  -a, --all              Apply the command to all servers in the parent container directory.

Examples:
  ./mcsl.sh status
  ./mcsl.sh status --host mc.example.com --port 25000
EOF
}

help_migrate() {
    cat <<EOF
Usage: ${mcsl_name:-mcsl.sh} migrate [options]

Description:
  Move the server to a new local or remote location.

Options:
  -d, --dest <dest>      Destination path or remote target.
  -u, --user <user>      SSH user for remote migration.
  -k, --key <key>        SSH key for remote migration.
  -t, --time <seconds>   Delay before stopping the server.
  -y, --yes              Skip confirmation prompts.
  --restart              Restart the server after migration.
  --no-restart           Do not restart the server after migration.
  -a, --all              Apply the command to all servers in the parent container directory.

Examples:
  ./mcsl.sh migrate -d /new/path --time 60
  ./mcsl.sh migrate -d user@host:/new/path
EOF
}

help_sync() {
    cat <<EOF
Usage: ${mcsl_name:-mcsl.sh} sync [options]

Description:
  Mirror the server files to another local or remote location.

Options:
  -d, --dest <dest>      Destination path or remote target.
  -u, --user <user>      SSH user for remote sync.
  -k, --key <key>        SSH key for remote sync.
  -y, --yes              Skip confirmation prompts.
  -a, --all              Apply the command to all servers in the parent container directory.

Examples:
  ./mcsl.sh sync -d /backup/server
EOF
}

help_kill() {
    cat <<EOF
Usage: ${mcsl_name:-mcsl.sh} kill [options]

Description:
  Forcefully terminate the tmux session for the target server.

Options:
  -s, --session <name>   Target the tmux session.
  --confirm-action       Required to proceed with this destructive action.

Examples:
  ./mcsl.sh kill --confirm-action
EOF
}

help_service() {
    cat <<EOF
Usage: ${mcsl_name:-mcsl.sh} service <name> <action>

Description:
  Manage server services.

Supported services:
  backup

Supported actions:
  start, stop, restart, status

Examples:
  ./mcsl.sh service backup status
  ./mcsl.sh service backup restart
EOF
}

help_selfupdate() {
    cat <<EOF
Usage: ${mcsl_name:-mcsl.sh} selfupdate [options]

Description:
  Update MCSL from the Git repository.

Options:
  -s, --session <name>   Target the tmux session.
  -a, --all              Apply the command to all servers in the parent container directory.

Examples:
  ./mcsl.sh selfupdate
EOF
}
