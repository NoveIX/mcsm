# file: src/commands/help.sh

print_help() {
    import "commands.version"

    local version=$(get_version)

    cat <<EOF
Script Name:              ${mcsl_name:-mcsl.sh} - Minecraft Server Launcher
Description:              Runtime bash script for managing Minecraft servers.
                          Provides start, stop, restart, status, migrate, kill and update actions.
                          Uses tmux to manage the Minecraft server process.

Usage:                    ${mcsl_name:-mcsl.sh} <command> [options]

Commands:
  help, -h, --help        Show this help message.
  version, -v, --version  Show the installed MCSL version.
  start                   Start the Minecraft server (use --console to attach).
  stop                    Stop the server gracefully.
  restart                 Restart the server (stop + start).
  console, -c, --console  Attach to the server tmux console.
  status                  Display the server status (host/port tcp/ip checks).
  selfupdate              Update MCSL from the Git repository.
  migrate                 Move the server to a new location (local or remote).
  kill                    Forcefully terminate a server tmux session (destructive action).

Options:
  -s, --session <name>    Name of the tmux session to target (default: derived from server root).
  -t, --time <seconds>    Delay in seconds for stop/restart/migrate operations.
  -c, --console           Attach to the tmux session after starting or restarting.
  -h, --host <host>       Host to query for status (default: localhost).
  -p, --port <port>       Port to query for status (default: 25565).
  -d, --dest <dest>       Destination for migrate (local path or user@host:dest).
  -u, --user <user>       User for remote migration.
  -k, --key <key>         SSH key for remote migration.
  -a, --all               Apply the command to all servers in the parent container directory.
  --confirm-action        Required for destructive actions like kill to proceed.

Note: '-h' is recognized as a top-level alias for 'help'. After a command, '-h' is also used as the short form of '--host' for 'status'.

Examples:
  ./mcsl.sh start
  ./mcsl.sh start --console
  ./mcsl.sh stop --time 30
  ./mcsl.sh restart --time 60 --console
  ./mcsl.sh console
  ./mcsl.sh status
  ./mcsl.sh status --host mc.example.com --port 25000
  ./mcsl.sh migrate -d /new/path --time 60
  ./mcsl.sh migrate -d user@host:/new/path
  ./mcsl.sh migrate --dest /new/path --host host --user user --key key
  ./mcsl.sh kill --confirm-action
  ./mcsl.sh selfupdate
  ./mcsl.sh --help

Features:
  - Start, stop, and restart the server with graceful warnings and pre-warn messages.
  - Attach to the Minecraft server console through tmux (use --console or tmux attach).
  - Query server online/offline status via TCP checks.
  - Migrate server files locally or to a remote host using rsync.
  - Forcefully kill a tmux session when required (use with --confirm-action).
  - Self-update MCSL from the Git repository.

Notes:
  - Requires Bash 4.4+ for associative arrays and shell features.
  - Requires tmux for server process management and rsync/ssh for migrations.
  - Tested on Ubuntu 24.04 and Debian 13; WSL2 on Windows is supported.
  - Ensure write permission in the output and runtime directories.

More info:
  - GitHub:           https://github.com/NoveIX/MCSLauncher

License:              GPL-3.0-or-later
Author:               NoveIX
Version:              $version
EOF
}
