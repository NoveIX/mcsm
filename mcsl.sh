#!/usr/bin/env bash

# File: mcsl.sh
# Description: Minecraft Server Launcher
# Author: NoveIX
# SPDX-License-Identifier: GPL-3.0-or-later

set -euo pipefail

# ================================[ constant ]================================ #

# Resolve the absolute path of the mcsl installation directory.
readonly MCSL_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
readonly MCSL_NAME="$(basename -- "${BASH_SOURCE[0]}")"

readonly IMPORTSH="$MCSL_DIR/src/lib/core/import.sh"

# ==============================[ import module ]============================= #

# Check if loader module exists
if [[ ! -f "$IMPORTSH" ]]; then
    printf 'fatal: module import.sh not found. Required to execute script %s.\n' "$MCSL_NAME"
    exit 1
fi

# Load import module
source "$IMPORTSH"

# Load required module
import "lib.core.ctx"
import "lib.core.logger"
import "lib.tmux.name"
import "main"

# Tmux session name
readonly SESSION_NAME="$(get_session_name)"

# Generate log setting
log_setting "$LOGS_DIR/mcsl" "info" "noprint" "combined"

# ==================================[ main ]================================== #

# log the command to be executed
#log_debug "arguments: $0 $*"
log_info "execute command: $1"

# Execute main fuction
main $@
