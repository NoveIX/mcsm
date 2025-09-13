#!/usr/bin/env bash

# =========================================[ Parameter ]========================================== #

RunFile="$1"
CrashHandle="$2"
RestartFile="$3"
mcsm_dir="$4"

exit_while=false
restart_counter=0

# ========================================[ Crash handle ]======================================== #

# Loading log library
logging_library="$mcsm_dir/source/library/logging.sh"
log_dir="$mcsm_dir/logs"
source "$logging_library"

while [[ "$exit_while" == false ]]; do
    current_date=$(date '+%Y-%m-%d')
    LOG_FILE="$log_dir/mcsm_$current_date.log"

    # Start minecraft server
    start_ts=$(date +%s)

    # Starting Minecraft
    log_mcsm_info "Running $RunFile"
    source $RunFile

    # Calculate uptime
    end_ts=$(date +%s)
    runtime=$(( end_ts - start_ts ))

    sleep 30

    # Crash handling
    if [[ "$CrashHandle" == "true" ]]; then

        # Recive stop command
        if [[ -f "$RestartFile" ]]; then
            log_mcsm_warn "Server has crashed. Restarting..."
        else
            exit_while=true
        fi

        # Infinite loop protection (if it crashes in <2 minutes)
        if (( runtime < 120 )); then
            ((restart_counter++))
        else
            restart_counter=0
        fi

        # Exit from infinite loop
        if (( restart_counter >= 10 )); then
            log_mcsm_error "The server crashes too frequently. Exit..."
            exit_while=true
        fi
    else
        exit_while="true"
    fi
done