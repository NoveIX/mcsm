# file: src/commands/migrate.sh

# ================================[ Command ]================================= #

migrate_server() {
    local dest="$1"
    local host="$2"
    local user="$3"
    local key="$4"
    local port="$5"
    local time="$6"

    # Check mandatory parameters
    require_param "dest" "$dest" "migrate"

    [[ "$dest" == *:* ]] && host="${dest%%:*}"
    if [[ -z "$host" ]]; then
        migrate_local "$dest" "$time"
    else
        migrate_remote "$@"
    fi
}

# Move server root - LOCAL MIGRATION

migrate_local() {
    local dest="$1"
    local time="$2"
    local red="\033[31m"
    local green="\033[32m"
    local blue="\033[94m"
    local reset="\033[0m"
    local dot="${red}●${reset}"
    local answer

    # Import required module
    import "lib.core.command"
    import "lib.tmux.exists.session"
    import "commands.stop"

    # Check required dependencies
    check_command "tmux" "fatal"
    check_command "rsync"

    # Trim trailing slash from destination path
    while [[ "$dest" == */ ]]; do
        dest="${dest%/}"
    done

    # Destination info
    print; print "local move: $dest/"; print

    # Check if session exist
    exists_tmux_session "$SESSION_NAME" && dot="${green}●${reset}"

    # Check if user wants to continue
    printf '%b' "$dot "
    read -r -p "Server will be stopped if running. Proceed with migration? [y/N]: " answer
    if [[ "${answer,,}" != "y" ]]; then
        print "migration aborted by user" "info"
        return 0
    fi

    # Stop server
    stop_server "$SESSION_NAME" "$time" "shutdown" "true" "false"

    # OVERRIDE log setting to print only in console.
    log_setting

    # Ensure directory
    if ! mkdir -p "$dest"; then
        log_error "failed to create directory: $dest" "print"
        return 1
    fi

    # Check empty dir - NOTE: find+grep returns 0 if NOT empty, 1 if empty (inverted logic)
    if find "$dest" -mindepth 1 -print -quit | grep -q .; then
        log_error "destination directory is not empty: $dest" "print"
        return 1
    fi

    # Move server
    print; print "migration in progress"
    if ! rsync -ah --info=progress2 "$SERVER_ROOT/" "$dest/"; then
        log_error "rsync failed: $SERVER_ROOT/ -> $dest/" "print"
        return 1
    fi

    # Change dir to prevent this error:
    # shell-init: error retrieving current directory: getcwd: cannot access parent directories: No such file or directory
    cd "$HOME"

    # Remove server root
    if ! rm -rf "$SERVER_ROOT"; then
        log_error "failed to remove server root: $SERVER_ROOT" "print"
        return 1
    fi

    # Log migration completion
    print "migration completed"; print

    # Ask restart after migration
    printf '%b' "${blue}●${reset} "
    read -r -p "Restart server now? [Y/n]: " ask

    # Restart server if user agrees (default: yes)
    [[ "${ask,,}" != "n" ]] && bash "$dest/mcsl/$MCSL_NAME" start
}

# Move/clone server root - REMOTE MIGRATION

migrate_remote() {
    local dest="$1"
    local host="$2"
    local user="$3"
    local key="$4"
    local port="$5"
    local time="$6"
    local red="\033[31m"
    local green="\033[32m"
    local blue="\033[94m"
    local reset="\033[0m"
    local dot="${red}●${reset}"
    local answer

    # Import required module
    import "lib.core.command"
    import "lib.remote.ssh.test"
    import "lib.remote.ssh.command"
    import "lib.tmux.exists.session"
    import "commands.stop"

    # Check required dependencies
    check_command "tmux" "fatal"
    check_command "ssh"
    check_command "rsync"

    # separate dest and host if dest contains ':'
    if [[ "$dest" == *:* ]]; then
        host="${dest%%:*}"
        dest="${dest#*:}"
    fi

    # separate user and host if host contains '@'
    if [[ "$host" == *@* ]]; then
        user="${host%%@*}"
        host="${host#*@}"
    fi

    # separate user and key if user contains '#'
    if [[ "$user" == *#* ]]; then
        key="${user%%#*}"
        user="${user#*#}"
    fi

    # Trim trailing slash from destination path
    while [[ "$dest" == */ ]]; do
        dest="${dest%/}"
    done

    # Check SSH connectivity
    log_info "testing SSH connection to $host"

    if ! test_ssh "$host" "$user" "$key" "$port"; then
        log_error "SSH connection test failed: $host" "print"
        return 1
    fi

    log_info "SSH connection test successful: $host"

    # Check required dependencies on remote host
    sshcheck_command "ssh" "$host" "error" "$user" "$key" "$port"
    sshcheck_command "rsync" "$host" "error" "$user" "$key" "$port"
    sshcheck_command "bash" "$host" "fatal" "$user" "$key" "$port"
    sshcheck_command "tmux" "$host" "fatal" "$user" "$key" "$port"
    sshcheck_command "java" "$host" "warn" "$user" "$key" "$port" || true

    # Destination info
    local login="${user:+$user@}$host"
    print; print "remote move: $login:$dest/"; print

    # Check if session exist
    exists_tmux_session "$SESSION_NAME" && dot="${green}●${reset}"

    # Check if user wants to continue
    printf '%b ' "$dot"
    read -r -p "Server will be stopped if running. Proceed with migration? [y/N]: " answer
    if [[ "${answer,,}" != "y" ]]; then
        print "migration aborted by user" "info"
        return 0
    fi

    # Stop server
    stop_server "$SESSION_NAME" "$time" "shutdown" "true" "false"

    # OVERRIDE log setting to print only in console.
    log_setting

    # Ensure directory
    if ! execute_ssh "$host" "$user" "$key" "$port" mkdir -p "$dest"; then
        log_error "failed to create remote directory: $login:$dest/" "print"
        return 1
    fi

    # Check empty dir - NOTE: find+grep returns 0 if NOT empty, 1 if empty (inverted logic)
    if ! execute_ssh "$host" "$user" "$key" "$port" find "$dest/" -mindepth 1 -print -quit | grep -q .; then
        log_error "destination directory is not empty: $login:$dest/" "print"
        return 1
    fi

    # Build SSH command for rsync
    local -a ssh_cmd=(
        ssh
        -o BatchMode=yes
        -o PasswordAuthentication=no
        -o KbdInteractiveAuthentication=no
    )

    # Add user, key, and port options if provided
    [[ -n "$key" ]] && ssh_cmd+=(-i "$key")
    [[ -n "$port" ]] && ssh_cmd+=(-p "$port")

    # Move server
    print; print "migration in progress"
    if ! rsync -azh --info=progress2 -e "${ssh_cmd[*]}" "$SERVER_ROOT/" "$login:$dest/"; then
        log_error "rsync failed: $SERVER_ROOT/ -> $login:$dest/" "print"
        return 1
    fi

    # Change dir to prevent this error:
    #shell-init: error retrieving current directory: getcwd: cannot access parent directories: No such file or directory
    cd $HOME

    # Remove server root
    if ! rm -rf "$SERVER_ROOT"; then
        log_error "failed to remove server root: $SERVER_ROOT" "print"
        return 1
    fi

    # Log migration completion
    print "migration completed"; print

    # Ask restart after migration
    printf '%b' "${blue}●${reset} "
    read -r -p "Start migrated server now? [Y/n]: " ask

    # Start server if user agrees (default: yes)
    [[ "${ask,,}" != "n" ]] && execute_ssh "$host" "$user" "$key" "$port" bash "$dest/mcsl/$MCSL_NAME" start
}
