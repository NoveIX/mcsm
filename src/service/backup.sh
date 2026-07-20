#!/usr/bin/env bash

# file: src/service/backup.sh

set -euo pipefail

# ================================[ Function ]================================ #

pause() {
    read -r -n1 -t 30 -p "Press any key to exit..."
    exit 1
}

# ===============================[ Parameter ]================================ #

# service parameters
readonly MCSL_DIR="$1"
readonly LOG_MODE="$2"
readonly SESSION_NAME="$3"

# ===============================[ constants ]================================ #

# Resolve the absolute path of the mcsl installation directory.
readonly MCSL_NAME="$(basename -- "${BASH_SOURCE[0]}")"
readonly IMPORTSH="$MCSL_DIR/src/lib/core/import.sh"

# ==============================[ Import module ]============================= #

# Check if loader module exists
if [[ ! -f "$IMPORTSH" ]]; then
    printf 'fatal: module import.sh not found. Required to execute script %s.\n' "$MCSL_NAME"
    pause
fi

# Load import module
source "$IMPORTSH"

# Load required module
import "lib.core.ctx" || pause
import "lib.core.logger" || pause
import "lib.config.backup.read" || pause
import "lib.config.notify.read" || pause
import "lib.filesystem.cleanup" || pause
import "lib.filesystem.create" || pause
import "lib.filesystem.get" || pause
import "lib.filesystem.remove" || pause
import "lib.filesystem.wait" || pause
import "lib.notify.backup" || pause
import "lib.system.archive.check" || pause
import "lib.tmux.send" || pause
import "lib.tmux.exists.window" || pause
import "lib.util.convert.millisecond" || pause

# ============================[ backup bootstrap ]============================ #

# Generate log setting
log_setting "$LOGS_DIR/backup" "info" "noprint" "$LOG_MODE"

# Read mcsl backup and notify config
read_backup || pause
read_notify || pause

# Check archive system command
check_archive || pause

# Change dir to Minecraft server
cd "$MCSL_DIR/.."
log_info "changing working directory to the Minecraft server root" "print"

# Read world directory from server.properties
world_dir=$(get_property "$SERVER_ROOT/server.properties" "level-name" ) || {
    log_warn "failed to read level-name from server.properties. using default world directory: world" "print"
    world_dir="world"
}

# Start backup process
create_file "$BACKUP_STATE" "backup.state" "MCSL backup service up"
log_info "starting mcsl backup service" "print"

# ============================[ backup service ]============================== #

sts=$(date +%s)

# Wait for runtime.state to be available
while [[ ! -f "$RUNTIME_STATE" ]]; do
    now=$(date +%s)
    if (( now - sts >= 300 )); then
        log_fatal "timeout waiting for $RUNTIME_STATE" "print"
        backup_status="stop"; break
    fi

    sleep 1
done

# Wait Minecraft server to be ready
log_info "runtime state file found. waiting for Minecraft server to be ready" "print"
wait_pattern "$SERVER_ROOT/logs/latest.log" "Done (" "150" || log_warn "timeout waiting for Minecraft server to be ready" "print"
log_info "backup service use this current settings (delay: $BACKUP_DELAY m, format: $BACKUP_FORMAT, keep: $KEEP_LAST)" "print"

# Runtime state variables
backup_status="run"

# Backup loop
while [[ "$backup_status" != "stop" ]]; do

    # Ensure directory
    if [[ ! -d "$BACKUP_DIR" ]] && ! mkdir -p "$BACKUP_DIR"; then
        log_error "failed to create backup directory: $BACKUP_DIR" "print"
        backup_status="stop"; continue
    fi

    # Convert minutes in seconds
    delay=$((BACKUP_DELAY * 60))
    elapsed=0

    # Sleep delay before next backup, check if runtime.state and backup.state exists every second
    while [[ $elapsed -lt $delay ]]; do
        if [[ ! -f "$RUNTIME_STATE" ]]; then
            log_info "runtime service state file not found. Stopping backup process" "print"
            backup_status="stop"; continue 2
        fi

        if [[ ! -f "$BACKUP_STATE" ]]; then
            log_info "backup service state file not found. Stopping backup process" "print"
            backup_status="stop"; continue 2
        fi

        ((elapsed++)) || true
        sleep 1
    done

    # Check if crashctl exists
    if [[ -f "$CRASH_STATE" ]]; then
        log_warn "crash detected. Skipping current backup" "print"
        backup_notify "warn" "Detect server crash. Backup skipped"
        continue
    fi

    if [[ ! -d "$world_dir" ]]; then
        log_error "world directory not found: $world_dir" "print"
        backup_notify "error" "World directory not found"
        backup_status="stop"; continue
    fi

    # Backup name
    ts=$(date +%Y-%m-%d-%H-%M-%S)
    backup_notify "info"

    # Check if the tmux session window exists
    if ! exists_tmux_window "$SESSION_NAME" "0"; then
        log_error "tmux window not found (session: $SESSION_NAME, window: 0)" "print"
        backup_notify "error" "Tmux window not found"
        backup_status="stop"; continue
    fi

    sts=$(date +%s%3N)

    # Send save-all command to the tmux session and wait for the save to complete
    if ! send_tmux "$SESSION_NAME" "0" "save-all flush"; then
        log_error "failed to send save-all command (session: $SESSION_NAME, window: 0)" "print"
        backup_notify "error" "Send save-all command"
        backup_status="stop"; continue
    fi

    # Wait for the "Saved the game" message in the latest.log file
    if ! wait_pattern "$SERVER_ROOT/logs/latest.log" "Saved the game"; then
        log_error "timeout waiting for save-all operation" "print"
        backup_notify "error" "Server save operation timed out"

        # Retry save operation once
        log_warn "retrying save-all operation" "print"
        if ! send_tmux "$SESSION_NAME" "0" "save-all flush"; then
            log_error "failed to send save-all command during retry" "print"
            backup_notify "error" "Send save-all command during retry"
            backup_status="stop"; continue
        fi

        # Wait retry
        if ! wait_pattern "$SERVER_ROOT/logs/latest.log" "Saved the game"; then
            log_error "timeout waiting for save-all operation during retry. Backup skipped" "print"
            backup_notify "error" "Server save operation timed out during retry. Backup skipped"
            continue
        fi
    fi

    # Send a message to the tmux session indicating that the backup is starting
    if ! send_tmux "$SESSION_NAME" "0" "say Starting Server backup"; then
        log_warn "failed to send backup notification command (session: $SESSION_NAME, window: 0)" "print"
    fi

    # Determine the backup file name based on the selected format
    archive_name="$ts.$BACKUP_FORMAT"
    archive_file="$BACKUP_DIR/$archive_name"

    # set return code for backup job
    rc=0

    case "$BACKUP_FORMAT" in
        zip)     zip -rq "$archive_file" "$world_dir" || rc=$? ;;
        tar.gz)  tar -czf "$archive_file" "$world_dir" || rc=$? ;;
        tar.xz)  tar -cJf "$archive_file" "$world_dir" || rc=$? ;;
        tar.zst) tar --zstd -cf "$archive_file" "$world_dir" || rc=$? ;;
    esac

    # Check if the backup command was successful
    if (( rc != 0 )); then
        log_error "failed to create backup archive (file: $archive_file)" "print"
        backup_notify "error" "Create backup archive"
        continue
    fi

    # Check if the backup archive was created
    if [[ ! -f "$archive_file" ]]; then
        log_error "backup archive missing (file: $archive_file)" "print"
        backup_notify "error" "Missing backup archive"
        continue
    fi

    # Calculate the elapsed time for the backup process
    ets=$(date +%s%3N)
    uts=$(( ets - sts ))

    # Calculate the size of the backup file
    bytes=$(stat -c%s "$archive_file") || {
        log_warn "failed to read archive size (file: $archive_file)" "print"
        bytes=0
    }

    # Converto bytes in human-readable
    hbytes=$(numfmt --to=iec --suffix=B "$bytes") || {
        log_warn "failed to format archive size (bytes: $bytes)" "print"
        hbytes="unknown"
    }

    # Calculate the SHA1 checksum of the backup file
    sha1=$(sha1sum "$archive_file" | awk '{print $1}') || {
        log_warn "failed to calculate sha1 (file: $archive_file)" "print"
        sha1="unknown"
    }

    # Backup completed
    log_info "new backup created at $archive_file size: $hbytes took: $(convert_milliseconds "$uts") sha1: $sha1" "print"
    backup_notify "done" "File: $archive_name\nSize: $hbytes\nDuration: $(convert_milliseconds "$uts")\nsha1: $sha1"

    # Send a message to the tmux session indicating that the backup has finished
    if ! send_tmux "$SESSION_NAME" "0" "say Backup finished in $(convert_milliseconds "$uts")"; then
        log_warn "failed to send backup completion message (session: $SESSION_NAME, window: 0)"
    fi

    # Cleanup old backups
    cleanup_backup "$BACKUP_DIR" "$KEEP_LAST" "$BACKUP_FORMAT"
done

# Stop mcsl backup process
log_info "shutting down mcsl backup service" "print"
remove_file "$BACKUP_STATE" "runtime.state"

# sleep to read logs before tmux close
sleep 10
