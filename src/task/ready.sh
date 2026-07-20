#!/usr/bin/env bash

# file: src/task/ready.sh

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
import "lib.config.notify.read" || pause
import "lib.filesystem.wait" || pause
import "lib.notify.runtime" || pause

# ============================[ ready bootstrap ]============================= #

# Generate log setting
log_setting "$LOGS_DIR/runtime" "info" "noprint" "$LOG_MODE"

# Read mcsl runtime and notify config
read_notify || pause

# Change dir to Minecraft server
cd "$MCSL_DIR/.."
log_info "starting mcsl ready task" "print"

# ==============================[ runtime task ]============================== #

if ! wait_pattern "$SERVER_ROOT/logs/latest.log" "Done (" "300"; then
    log_warn "timeout waiting for Minecraft server to be ready" "print"
    pause
fi

# Send notification that server is ready
runtime_notify "done" "Server ready"

log_info "shutting down mcsl ready task" "print"

# sleep to read logs before tmux close
sleep 10
