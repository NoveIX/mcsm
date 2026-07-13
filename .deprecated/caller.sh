# File: command.sh
# Description: Command utility functions for bash scripts
# Author: NoveIX
# SPDX-License-Identifier: GPL-3.0-or-later

# ================================[ Function ]================================ #

call_mcsl() {
    local session="$1"
    local cmd="$2"
    local print="print"
    shift 2

    # Check mandatory parameters
    require_param "session" "$session" "call_mcsl" || return 1
    require_param "cmd" "$cmd" "call_mcsl" || return 1

    # status command is special, it should not print the log message
    [[ "${cmd,,}" == "status" ]] && print="noprint"

    # mcsl command path for the specified session
    local mcslsh="$server_container/$session/mcsl/$mcsl_name"

    # Check if the mcsl command exists in the specified session
    if [[ ! -f "$mcslsh" ]]; then
        log_error "mcsl not found for server $session: $mcslsh" "print"
        return 1
    fi

    # Call mcsl with all remaining args
    log_info "executing command $cmd on server $session" "$print"
    bash "$mcslsh" "$cmd" "$@" && return 0

    log_error "command $cmd failed on server $session" "print"
    return 1
}

call_session() {
    local session="$1"
    local command="$2"
    shift 2

    # Check mandatory parameters
    require_param "session" "$session" "call_session" || return 1
    require_param "command" "$command" "call_session" || return 1

    call_mcsl "$session" "$command" "$@" || true
}

call_sessions() {
    local command="$1"
    shift

    # Check mandatory parameters
    require_param "command" "$command" "call_sessions" || return 1

    for dir in "$server_container"/*/; do
        [[ -d "$dir" ]] || continue

        local session="${dir%/}"
        session="${session##*/}"

        call_mcsl "$session" "$command" "$@" || true
    done
}
