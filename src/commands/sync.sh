# file: src/commands/migrate.sh

sync_server() {
    local dest="$1"
    local host="$2"
    local user="$3"
    local key="$4"
    local port="$5"
    local yes="$6"

    # Check mandatory parameters
    require_param "dest" "$dest" "sync"

    [[ "$dest" == *:* ]] && host="${dest%%:*}"
    if [[ -z "$host" ]]; then
        log_info "missing host parameter, performing local sync"
        sync_local "$dest" "$yes"
    else
        log_info "host parameter detected, performing remote sync"
        sync_remote "$@"
    fi
}

# Sync server root - LOCAL SYNC

sync_local() {
    local dest="$1"
    local yes="$2"
    local red="\033[31m"
    local yellow="\033[33m"
    local green="\033[32m"
    local blue="\033[94m"
    local reset="\033[0m"
    local dot="${red}●${reset}"
    local answer rc

    # Import required module
    log_info "import required modules"
    import "lib.core.command"
    import "lib.tmux.exists.session"

    # Check required dependencies
    log_info "check required dependencies"
    check_command "tmux" "fatal"
    check_command "rsync"

    # Trim trailing slash from destination path
    log_info "trim trailing slash from destination path"
    while [[ "$dest" == */ ]]; do
        dest="${dest%/}"
    done

    # Check for unsafe destination paths
    log_info "check for unsafe destination paths"
    [[ -z "$dest" ]] && dest="/"
    case "$dest" in
        /|/bin|/boot|/dev|/etc|/home|/lib|/lib32|/lib64|/media|/mnt|/opt|/proc|/root|/run|/sbin|/srv|/sys|/tmp|/usr|/var)
            log_error "destination path is protected: $dest" "print"
            return 1
        ;;
    esac

    # Convert to absolute path
    dest="$(realpath -m "$dest")"

    # Destination cannot be inside server root
    log_info "check if destination is inside server root"
    if [[ "$dest" == "$SERVER_ROOT" || "$dest" == "$SERVER_ROOT"/* ]]; then
        log_error "destination path is inside server root: $dest" "print"
        return 1
    fi

    # Sync information
    print
    print "${green}source:${reset}  $SERVER_ROOT/"
    print "${green}dest:${reset}    $dest/"
    print "${green}mode:${reset}    mirror"
    print
    print "${yellow}WARNING${reset}: destination files will be deleted to match the source."
    print
    log_info "local sync: $SERVER_ROOT/ -> $dest/"

    # Check if user wants to continue
    if [[ "$yes" == "false" ]]; then
        exists_tmux_session "$SESSION_NAME" && dot="${green}●${reset}"

        printf '%b' "$dot "
        read -r -p "Create mirror copy of the server $SESSION_NAME. Proceed with sync? [y/N]: " answer
        if [[ "${answer,,}" != "y" ]]; then
            print "synchronization aborted by user" "info"
            return 0
        fi
    fi

    # Ensure directory
    if ! mkdir -p "$dest"; then
        log_error "failed to create directory: $dest" "print"
        return 1
    fi

    # Sync server
    print; print "synchronization in progress" "info"
    rsync -ah --info=progress2 --delete "$SERVER_ROOT/" "$dest/" || rc=$?
    rc=$?

    if ! (( rc == 0 )); then
        log_error "rsync failed (code $rc): $SERVER_ROOT/ -> $dest/" "print"
        return 1
    fi

    # Log synchronization completion
    print "synchronization completed" "info"; print
}

# Sync server root - REMOTE SYNC

sync_remote() {
    local dest="$1"
    local host="$2"
    local user="$3"
    local key="$4"
    local port="$5"
    local yes="$6"
    local red="\033[31m"
    local yellow="\033[33m"
    local green="\033[32m"
    local blue="\033[94m"
    local reset="\033[0m"
    local dot="${red}●${reset}"
    local answer rc

    # Import required module
    log_info "import required modules"
    import "lib.core.command"
    import "lib.remote.ssh.test"
    import "lib.remote.ssh.command"
    import "lib.tmux.exists.session"

    # Check required dependencies
    log_info "check required dependencies"
    check_command "tmux" "fatal"
    check_command "ssh"
    check_command "rsync"

    # separate dest and host if dest contains ':'
    if [[ "$dest" == *:* ]]; then
        log_info "separate destination and host from dest parameter"
        host="${dest%%:*}"
        dest="${dest#*:}"
    fi

    # separate user and host if host contains '@'
    if [[ "$host" == *@* ]]; then
        log_info "separate host and user from host parameter"
        user="${host%%@*}"
        host="${host#*@}"
    fi

    # separate user and key if user contains '#'
    if [[ "$user" == *#* ]]; then
        log_info "separate user and key from user parameter"
        key="${user%%#*}"
        user="${user#*#}"
    fi

    # Trim trailing slash from destination path
    log_info "trim trailing slash from destination path"
    if [[ "$dest" != "/" ]]; then
        while [[ "$dest" == */ ]]; do
            dest="${dest%/}"
        done
    fi

    # Check for unsafe destination paths
    log_info "check for unsafe destination paths"
    case "$dest" in
        /|/bin|/boot|/dev|/etc|/home|/lib|/lib32|/lib64|/media|/mnt|/opt|/proc|/root|/run|/sbin|/srv|/sys|/tmp|/usr|/var)
            log_error "destination path is protected: $dest" "print"
            return 1
        ;;
    esac

    # Check SSH connectivity
    log_info "test SSH connection to $host"
    if ! test_ssh "$host" "$user" "$key" "$port"; then
        log_error "SSH connection test failed: $host" "print"
        return 1
    fi

    # Check required dependencies on remote host
    log_info "check required dependencies on remote host: $host"
    sshcheck_command "ssh" "$host" "error" "$user" "$key" "$port"
    sshcheck_command "rsync" "$host" "error" "$user" "$key" "$port"
    sshcheck_command "bash" "$host" "fatal" "$user" "$key" "$port"
    sshcheck_command "tmux" "$host" "fatal" "$user" "$key" "$port"
    sshcheck_command "java" "$host" "warn" "$user" "$key" "$port" || true

    # Sync information
    local login="${user:+$user@}$host"
    print
    print "${green}source:${reset}  $SERVER_ROOT/"
    print "${green}dest:${reset}    $login:$dest/"
    print "${green}mode:${reset}    mirror"
    print
    print "${yellow}WARNING:${reset} destination files will be deleted to match the source."
    print
    log_info "remote sync: $SERVER_ROOT/ -> $login:$dest/"

    # Check if user wants to continue
    if [[ "$yes" == "false" ]]; then
        exists_tmux_session "$SESSION_NAME" && dot="${green}●${reset}"

        printf '%b' "$dot "
        read -r -p "Create mirror copy of the server $SESSION_NAME. Proceed with sync? [y/N]: " answer
        if [[ "${answer,,}" != "y" ]]; then
            print "synchronization aborted by user" "info"
            return 0
        fi
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
    print; print "synchronization in progress" "info"
    rsync -azh --info=progress2 --delete -e "${ssh_cmd[*]}" "$SERVER_ROOT/" "$login:$dest/" || rc=$?
    rc=$?

    if ! (( rc == 0 )); then
        log_error "rsync failed: $SERVER_ROOT/ -> $login:$dest/" "print"
        return 1
    fi

    # Log synchronization completion
    print "synchronization completed" "info"; print
}
