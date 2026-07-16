# file: src/commands/migrate.sh

migrate_server() {
    local dest="$1"
    local host="$2"
    local user="$3"
    local key="$4"
    local port="$5"
    local time="$6"
    local confirm="$7"
    local restart="$8"

    # Check mandatory parameters
    require_param "dest" "$dest" "migrate"

    [[ "$dest" == *:* ]] && host="${dest%%:*}"
    if [[ -z "$host" ]]; then
        log_info "missing host parameter, performing local migration"
        migrate_local "$dest" "$time"
    else
        log_info "host parameter detected, performing remote migration"
        migrate_remote "$@"
    fi
}

# Move server root - LOCAL MIGRATION

migrate_local() {
    local dest="$1"
    local time="$2"
    local confirm="$3"
    local restart="$4"
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
    import "commands.stop"

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

    # Migrate information
    if [[ "$confirm" == "false" ]]; then
        print
        print "source:      $SERVER_ROOT/"
        print "destination: $dest/"
        print "mode:        move"
        print
        print "${yellow}WARNING${reset}: source directory will be removed after migration."
        print
    fi
    log_info "local move: $SERVER_ROOT/ -> $dest/"

    # Check if session exist
    exists_tmux_session "$SESSION_NAME" && dot="${green}●${reset}"

    # Check if user wants to continue
    if [[ "$confirm" == "false" ]]; then
        printf '%b' "$dot "
        read -r -p "Server $SESSION_NAME will be stopped if running. Proceed with migration? [y/N]: " answer
        if [[ "${answer,,}" != "y" ]]; then
            print "migration aborted by user" "info"
            return 0
        fi
    fi

    # Stop server
    stop_server "$SESSION_NAME" "$time" "shutdown" "true" "false"

    # OVERRIDE log setting to print only in console.
    log_info "override log setting to print only in console"
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
    rsync -ah --info=progress2 "$SERVER_ROOT/" "$dest/" || rc=$?
    rc=$?

    if ! (( rc == 0 )); then
        log_error "rsync failed (code $rc): $SERVER_ROOT/ -> $dest/" "print"
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

    print "migration completed"; print

    # Start server after migration (default: yes)
    if [[ "$restart" != "true" ]]; then
        printf '%b' "${blue}●${reset} "
        read -r -p "Start migrated server now? [Y/n]: " answer

        [[ "${answer,,}" == "n" ]] && return 0
    fi

    bash "$dest/mcsl/$MCSL_NAME" start
}

# Move server root - REMOTE MIGRATION

migrate_remote() {
    local dest="$1"
    local host="$2"
    local user="$3"
    local key="$4"
    local port="$5"
    local time="$6"
    local confirm="$7"
    local restart="$8"
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
    import "commands.stop"

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

    # Migrate information
    local login="${user:+$user@}$host"
    if [[ "$confirm" == "false" ]]; then
        print
        print "source:      $SERVER_ROOT/"
        print "destination: $login:$dest/"
        print "mode:        move"
        print
        print "${yellow}WARNING${reset}: source directory will be removed after migration."
        print
    fi
    log_info "remote move: $SERVER_ROOT/ -> $login:$dest/"

    # Check if session exist
    exists_tmux_session "$SESSION_NAME" && dot="${green}●${reset}"

    # Check if user wants to continue
    if [[ "$confirm" == "false" ]]; then
        printf '%b ' "$dot"
        read -r -p "Server $SESSION_NAME will be stopped if running. Proceed with migration? [y/N]: " answer
        if [[ "${answer,,}" != "y" ]]; then
            print "migration aborted by user" "info"
            return 0
        fi
    fi

    # Stop server
    stop_server "$SESSION_NAME" "$time" "shutdown" "true" "false"

    # OVERRIDE log setting to print only in console.
    log_info "override log setting to print only in console"
    log_setting

    # Ensure directory
    if ! execute_ssh "$host" "$user" "$key" "$port" mkdir -p "$dest"; then
        log_error "failed to create remote directory: $login:$dest/" "print"
        return 1
    fi

    # Check empty dir - NOTE: find+grep returns 0 if NOT empty, 1 if empty (inverted logic)
    if execute_ssh "$host" "$user" "$key" "$port" find "$dest/" -mindepth 1 -print -quit | grep -q .; then
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
    rsync -azh --info=progress2 -e "${ssh_cmd[*]}" "$SERVER_ROOT/" "$login:$dest/" || rc=$?
    rc=$?

    if ! (( rc == 0 )); then
        log_error "rsync failed (code $rc): $SERVER_ROOT/ -> $login:$dest/" "print"
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

    print "migration completed"; print

    # Start server after migration (default: yes)
    if [[ "$restart" != "true" ]]; then
        printf '%b' "${blue}●${reset} "
        read -r -p "Start migrated server now? [Y/n]: " answer

        [[ "${answer,,}" == "n" ]] && return 0
    fi

    execute_ssh "$host" "$user" "$key" "$port" bash "$dest/mcsl/$MCSL_NAME" start
}
