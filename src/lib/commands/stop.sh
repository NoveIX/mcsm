# File: stop.sh
# Description: Stop command functions for mcsl
# Author: NoveIX
# SPDX-License-Identifier: GPL-3.0-or-later

# ================================[ Command ]================================= #

stop_server() {
    local session="$1"
    local time="$2"
    local mode="$3"
    local all="$4"

    # Check mandatory parameters
    require_param "session" "$session" "stop_server" || return 1
    require_param "time" "$time" "stop_server" || return 1
    require_param "mode" "$mode" "stop_server" || return 1
    require_param "all" "$all" "stop_server" || return 1

    # REMOTE DELEGATION

        if [[ "${all,,}" == "true" || "$session" != "$session_name" ]]; then
        load_module "$core_dir/caller.sh" || return 1

        # Call command in the specified session or all sessions
        if [[ "${all,,}" == "true" ]]; then
            call_sessions stop --time "$time" || return 1
        else
            call_session "$session"  stop --time "$time" || return 1
        fi

        return 0
    fi

    # STOP COMMAND EXECUTION

    # Load required modules
    load_module "$core_dir/command.sh" || return 1
    load_module "$core_dir/common.sh" || return 1
    load_module "$core_dir/tmux.sh" || return 1
    load_module "$core_dir/filesystem.sh" || return 1

    # Check required dependencies
    check_command "tmux" "fatal" || return 1

    # Check if the tmux session exists. If it does, proceed with the shutdown process. If not, simply return without doing anything.
    if exists_tmux "$session"; then
        # Remove any existing restart/keep-alive flag to ensure a clean shutdown process.
        remove_restartctl "$restartctl" || return 1

        # Stop the server with a warning message if the time time is greater than 30 seconds, otherwise send the stop command immediately
        if (( time > 30 )); then
            local prewarn=$((time - 30))
            send_tmux "$session" "0" "say Server will $mode in $time seconds. Please prepare to disconnect."
            sleep "$prewarn"

            # 30 Seconds - cit. Lester
            send_tmux "$session" "0" "say Server will $mode in 30 seconds. Please prepare to disconnect."
            sleep 30
        else
            send_tmux "$session" "0" "say Server will $mode in $time seconds. Please prepare to disconnect."
            sleep "$time"
        fi

        # Send the stop command to the tmux session to initiate server shutdown and log the stopping time.
        log_info "stopping server $session at $(date "+%F %T")" "print"
        send_tmux "$session" "0" "stop" || return 1
        return 0
    fi

    log_info "server $session is not running" "print"
    return 0
}
