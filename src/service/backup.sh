#!/usr/bin/env bash

# File: backup.sh
# Description: mcsl backup controller for Minecraft server
# Author: NoveIX
# SPDX-License-Identifier: GPL-3.0-or-later

#set -euo pipefail

# ================================[ Function ]================================ #

pause() {
    read -r -n1 -t 30 -p "Press any key to exit..."
    exit 1
}

# ===============================[ Parameter ]================================ #

# Define the directory of the script and its name
readonly mcsl_dir="$1"
readonly session_name="$2"
readonly log_mode="$3"
readonly mcsl_name="$(basename -- "${BASH_SOURCE[0]}")"
readonly server_root="$(dirname "$mcsl_dir")"

# Source directories
readonly cfg_dir="$mcsl_dir/cfg"
readonly logs_dir="$mcsl_dir/logs"
readonly core_dir="$mcsl_dir/src/lib/core"

# Runtime directory and control files
readonly runtime_dir="$mcsl_dir/.runtime"
readonly mcslctl="$runtime_dir/runtimectl"
readonly crashctl="$runtime_dir/crashctl"

# Backup configuration variables
readonly backup_dir="$server_root/backups"

# Runtime state variables
runtime_status="run"

# ==============================[ Import module ]============================= #

# Check if loader module exists
if [[ ! -f "$core_dir/loader.sh" ]]; then
    printf 'fatal: module loader.sh not found. required to execute script %s.\n' "$mcsl_name" >&2
    pause
fi

# Load loader module
source "$core_dir/loader.sh"

# Load required module
load_module "$core_dir/logger.sh" || pause
load_module "$core_dir/parameter.sh" || pause
load_module "$core_dir/command.sh" || pause
load_module "$core_dir/common.sh" || pause
load_module "$core_dir/config.sh" || pause
load_module "$core_dir/filesystem.sh" || pause
load_module "$core_dir/server.sh" || pause
load_module "$core_dir/tmux.sh" || pause

# ============================[ backup bootstrap ]============================ #

# Generate log setting
log_setting "$logs_dir/backup" "info" "noprint" "$log_mode"

# Read mcsl backup config
read_config_backup "$cfg_dir/backup.conf" || pause
check_backup "$BACKUP_FORMAT" || pause

# Change dir to Minecraft server
cd "$mcsl_dir/.."
log_info "changing working directory to the Minecraft server root" "print"

# Read world directory from server.properties
world_dir=$(get_property "$server_root/server.properties" "level-name" ) || {
    log_warn "failed to read level-name from server.properties. using default world directory: world" "print"
    world_dir="world"
}

# Start backup process
log_info "starting mcsl backup service" "print"

# ============================[ backup service ]============================== #

sts=$(date +%s)

# Wait for mcslctl to be available
while [[ ! -f "$mcslctl" ]]; do
    now=$(date +%s)
    if (( now - sts >= 120 )); then
        log_fatal "timeout waiting for $mcslctl" "print"
        runtime_status="stop"; break
    fi

    sleep 1
done

# Wait Minecraft server to be ready
#sleep 300
sleep 30

log_info "backup service use this current settings (delay: $BACKUP_DELAY m, format: $BACKUP_FORMAT)" "print"

# Backup loop
while [[ "${runtime_status,,}" != "stop" ]]; do

    # Ensure directory
    if [[ ! -d "$backup_dir" ]] && ! mkdir -p "$backup_dir"; then
        log_error "failed to create backup directory: $backup_dir" "print"
        runtime_status="stop"; continue
    fi

    # Convert minutes in seconds
    delay=$((BACKUP_DELAY * 60))
    elapsed=0

    # Sleep loop with check every second
    while [[ $elapsed -lt $delay ]]; do
        # Check if mcslctl exists
        if [[ ! -f "$mcslctl" ]]; then
            log_info "mcsl runtime control file not found. stopping backup process" "print"
            runtime_status="stop"; continue 2
        fi

        ((elapsed++)) || true
        sleep 1
    done

    # Check if crashctl exists
    if [[ -f "$crashctl" ]]; then
        log_warn "crash detected. Skipping current backup" "print"
        continue
    fi

    if [[ ! -d "$world_dir" ]]; then
        log_error "world directory not found: $world_dir" "print"
        runtime_status="stop"; continue
    fi

    # Backup name
    ts=$(date +%Y-%m-%d-%H-%M-%S)

    # Check if the tmux session exists
    if ! exists_tmux_window "$SESSION_NAME" "0"; then
        log_error "tmux window 0 not found in session $SESSION_NAME" "print"
        runtime_status="stop"; continue
    fi

    sts=$(date +%s%3N)

    # Send save-all command to the tmux session and wait for the save to complete
    if ! send_tmux "$SESSION_NAME" "0" "save-all flush"; then
        log_error "failed to send save-all command to $SESSION_NAME" "print"
        runtime_status="stop"; continue
    fi

    # Wait for the "Saved the game" message in the latest.log file
    if ! wait_pattern "$server_root/logs/latest.log" "Saved the game"; then
        log_error "timeout waiting for save-all to complete" "print"
        runtime_status="stop"; continue
    fi

    # Send a message to the tmux session indicating that the backup is starting
    if ! send_tmux "$SESSION_NAME" "0" "say Starting Server backup"; then
        log_error "failed to send message to $SESSION_NAME" "print"
        runtime_status="stop"; continue
    fi

    # Determine the backup file name based on the selected format
    archive_file="$backup_dir/$ts.$BACKUP_FORMAT"

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
        log_error "failed to create backup archive: $archive_file" "print"
        continue
    fi

    # Check if the backup archive was created
    if [[ ! -f "$archive_file" ]]; then
        log_error "backup archive not found: $archive_file" "print"
        continue
    fi

    # Calculate the elapsed time for the backup process
    ets=$(date +%s%3N)
    uts=$(( ets - sts ))

    # Calculate the size of the backup file in bytes and human-readable format
    bytes=$(stat -c%s "$archive_file") || log_warn "failed to read archive size" "print"
    hbytes=$(numfmt --to=iec --suffix=B "$bytes") || log_warn "failed to convert archive size to human-readable format" "print"

    # Calculate the SHA1 checksum of the backup file
    sha1=$(sha1sum "$archive_file" | awk '{print $1}') || log_warn "failed to calculate sha1" "print"
    log_info "new backup created at $archive_file size: $hbytes took: $(format_durationms "$uts") sha1: $sha1" "print"

    # Send a message to the tmux session indicating that the backup has finished
    send_tmux "$SESSION_NAME" "0" "say Backup finished in $(format_durationms "$uts")" || true
done

# Stop mcsl backup process
log_info "shutting down mcsl backup service" "print"

# sleep to read logs before tmux close
sleep 5
