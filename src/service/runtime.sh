#!/usr/bin/env bash

# File: runtime.sh
# Description: mcsl runtime controller for Minecraft server
# Author: NoveIX
# SPDX-License-Identifier: GPL-3.0-or-later

#set -euo pipefail

# ================================[ Function ]================================ #

pause() {
    read -r -n1 -t 30 -p "Press any key to exit..."
    exit 1
}

# ===============================[ Parameter ]================================ #

# service parameters
readonly MCSL_DIR="$1"
readonly LOG_MODE="$2"

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
import "lib.config.runtime.read" || pause
import "lib.config.backup.read" || pause
import "lib.filesystem.create" || pause
import "lib.filesystem.remove" || pause
import "lib.util.convert.second" || pause

# ===========================[ runtime bootstrap ]============================ #

# Generate log setting
log_setting "$LOGS_DIR/runtime" "info" "noprint" "$LOG_MODE"

# Read mcsl runtime config
read_runtime || pause
read_backup || pause

# Change dir to Minecraft server
cd "$MCSL_DIR/.."
log_info "changing working directory to the Minecraft server root" "print"

# Start mcsl runtime process
create_files "$RUNTIME_STATE" "runtime.state" "MCSL runtime service up"
log_info "starting mcsl runtime service" "print"

# ============================[ runtime service ]============================= #

# Runtime state variables
runtime_status="run"
crash_count=0

while [[ "$runtime_status" != "stop" ]]; do
    # Start timestamp
    sts=$(date +%s)
    create_files "$UPTIME_TIMESTAMP" "uptime.timestamp" "$sts"

    # Event on discord telegram
    #runtime_notification "start"

    # Remove crash control file
    remove_files "$CRASH_STATE" "crash.state"

    # set return code for server start command
    rc=0

    # Start Minecraft server
    if [[ -f "$START_COMMAND" ]]; then
        log_info "starting Minecraft server using configured script: $START_COMMAND" "print"
        bash "$START_COMMAND" || rc=$?
    else
        log_info "starting Minecraft server using configured command: $START_COMMAND" "print"
        bash -c "$START_COMMAND" || rc=$?
    fi

    # Log Minecraft server error
    if (( rc != 0 )); then
        log_error "Minecraft server start failed (cmd: $START_COMMAND, exit code: $rc)" "print"
        read -r -n1 -t 30 -p "Press any key to continue..."
    fi

    # End timestamp
    ets=$(date +%s)

    # Calculate uptime timestamp
    uts=$(( ets - sts ))
    log_info "Minecraft server uptime: $(convert_seconds "$uts")" "print"
    remove_files "$UPTIME_TIMESTAMP" "uptime.timestamp"

    # Stop requested
    if [[ ! -f "$RESTART_CTL" ]]; then
        #runtime_notification "stop"
        runtime_status="stop"; continue
    fi

    # Check crash handling setting
    if [[ "$CRASH_HANDLE" == "false" ]]; then
        log_info "crash handling disabled. Server will not restart" "print"
        #runtime_notification "handle"
        runtime_status="stop"; continue
    fi

    # Create crash control file
    create_files "$CRASH_STATE" "crash.state" "MCSL runtime crash detected"

    # Server crashed
    (( crash_count++ )) || true
    log_warn "Minecraft server crashed. Restarting (attempt $crash_count)" "print"
    #runtime_notification "crash"

    # Check crash retry limit
    if (( MAX_RESTART >= 0 && crash_count >= MAX_RESTART )); then
        log_warn "crash limit reached (Max $MAX_RESTART). Server will not restart" "print"
        #runtime_notification "loop"
        runtime_status="stop"; continue
    fi

    # Little delay before restart to prevent cpu saturation in case of instant crash loop
    sleep 5
done

# Stop mcsl runtime process
log_info "shutting down mcsl runtime service" "print"
remove_files "$RUNTIME_STATE" "runtime.state"

# sleep to read logs before tmux close
sleep 5
