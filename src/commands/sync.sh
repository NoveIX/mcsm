# file: src/commands/migrate.sh

# ================================[ Command ]================================= #

sync_server() {
    local dest="$1"
    local host="$2"
    local user="$3"
    local key="$4"
    local port="$5"

    # Check mandatory parameters
    require_param "dest" "$dest" "migrate"

    [[ "$dest" == *:* ]] && host="${dest%%:*}"
    if [[ -z "$host" ]]; then
        sync_local "$dest" "$time"
    else
        sync_remote "$@"
    fi
}

# Sync server root - LOCAL SYNC

sync_local() {
    local dest="$1"
    local time="$2"
    local red="\033[31m"
    local yellow="\033[33m"
    local green="\033[32m"
    local blue="\033[94m"
    local reset="\033[0m"
    local dot="${red}●${reset}"

    # Import required module
    import "lib.core.command"
    import "lib.tmux.exists.session"

    # Check required dependencies
    check_command "tmux" "fatal"
    check_command "rsync"

    # Trim trailing slash from destination path
    if [[ "$dest" != "/" ]]; then
        while [[ "$dest" == */ ]]; do
            dest="${dest%/}"
        done
    fi

    # Check for unsafe destination paths
    case "$dest" in
        /|/bin|/boot|/dev|/etc|/home|/lib|/lib32|/lib64|/media|/mnt|/opt|/proc|/root|/run|/sbin|/srv|/sys|/tmp|/usr|/var)
            log_error "unsafe destination path: $dest"
            return 1
        ;;
    esac

    # Mirror information
    print
    print "source:      $SERVER_ROOT/" "info"
    print "destination: $dest/" "info"
    print "mode:        mirror (--delete enabled)" "info"
    print
    print "${yellow}WARNING${reset}: files existing only in destination may be removed." "warn"
    print

    # Check if session exist
    exists_tmux_session "$SESSION_NAME" && dot="${green}●${reset}"

    # Check if user wants to continue
    printf '%b' "$dot "
    read -r -p "Create mirror copy of the server $SESSION_NAME. Proceed with sync? [y/N]: " answer
    if [[ "${answer,,}" != "y" ]]; then
        print "synchronization aborted by user" "info"
        return 0
    fi

    # Ensure directory
    if ! mkdir -p "$dest"; then
        log_error "failed to create directory: $dest" "print"
        return 1
    fi

    # Sync server
    print; print "Sync in progress" "info"
    if ! rsync -ah --delete --info=progress2 "$SERVER_ROOT/" "$dest/"; then
        log_error "rsync failed: $SERVER_ROOT/ -> $dest/" "print"
        return 1
    fi

    # Log migration completion
    print "Sync completed" "info"; print
}

# Sync server root - REMOTE SYNC

sync_remote() {
    local dest="$1"
    local host="$2"
    local user="$3"
    local key="$4"
    local port="$5"
    local red="\033[31m"
    local yellow="\033[33m"
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
    if [[ "$dest" != "/" ]]; then
        while [[ "$dest" == */ ]]; do
            dest="${dest%/}"
        done
    fi

    # Check for unsafe destination paths
    case "$dest" in
        /|/bin|/boot|/dev|/etc|/home|/lib|/lib32|/lib64|/media|/mnt|/opt|/proc|/root|/run|/sbin|/srv|/sys|/tmp|/usr|/var)
            log_error "unsafe destination path: $dest"
            return 1
        ;;
    esac

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

    # Mirror information
    local login="${user:+$user@}$host"
    print
    print "source:      $SERVER_ROOT/" "info"
    print "destination: $login:$dest/" "info"
    print "mode:        mirror (--delete enabled)" "info"
    print
    print "${yellow}WARNING${reset}: files existing only in destination may be removed." "warn"
    print

    # Check if session exist
    exists_tmux_session "$SESSION_NAME" && dot="${green}●${reset}"

    # Check if user wants to continue
    printf '%b' "$dot "
    read -r -p "Create mirror copy of the server $SESSION_NAME. Proceed with sync? [y/N]: " answer
    if [[ "${answer,,}" != "y" ]]; then
        print "synchronization aborted by user" "info"
        return 0
    fi

    # Ensure directory
    if ! execute_ssh "$host" "$user" "$key" "$port" mkdir -p "$dest"; then
        log_error "failed to create remote directory: $login:$dest/" "print"
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

    # Sync server
    print; print "Sync in progress" "info"
    if ! rsync -azh --delete --info=progress2 -e "${ssh_cmd[*]}" "$SERVER_ROOT/" "$login:$dest/"; then
        log_error "rsync failed: $SERVER_ROOT/ -> $login:$dest/" "print"
        return 1
    fi

    # Log migration completion
    print "Sync completed" "info"; print
}
