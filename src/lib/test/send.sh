# File: start.sh
# Description: Start command functions for mcsl
# Author: NoveIX
# SPDX-License-Identifier: GPL-3.0-or-later

# ================================[ Command ]================================= #

send_server() {
    local session="$1"
    local cmd="$2"
    local all="$3"

    # Check mandatory parameters
    require_param "session" "$session" "send_server" || return 1
    require_param "cmd" "$cmd" "send_server" || return 1

    # REMOTE DELEGATION

    # Remote session delegation - ALL MODE (priority)
    if [[ "${all,,}" == "true" ]]; then
        load_module "$core_dir/caller.sh" || return 1

        for dir in "$server_container"/*/; do
            [[ -d "$dir" ]] || continue

            # Extract the session name from the directory path
            session="${dir%/}"
            session="${session##*/}"

            # Call command in the specified session
            call_mcsl "$session" send "$cmd" || true
        done

        return 0
    fi

    # Remote session delegation - SINGLE SESSION
    if [[ "$session" != "$session_name" ]]; then
        load_module "$core_dir/caller.sh" || return 1

        # Call command in the specified session
        call_mcsl "$session" send "$cmd" || true

        return 0
    fi

    # SEND COMMAND EXECUTION

    # Load required modules
    load_module "$core_dir/command.sh" || return 1
    load_module "$core_dir/tmux.sh" || return 1

    # Check required dependencies
    check_command "tmux" "fatal" || return 1

    # Send command to tmux session if it exists
    if exists_tmux "$session"; then
        if send_tmux "$session" "0" "$cmd"; then
            log_info "sent to $session: $cmd"
            return 0
        fi

        log_error "failed to send to $session: $cmd" "print"
        return 1
    fi

    log_warn "tmux session $session does not exist" "print"
    return 1
}
