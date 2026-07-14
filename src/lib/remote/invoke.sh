# file: src/lib/remote/invoke.sh

invoke_mcsl() {
    local session="$1"
    local cmd="$2"
    local print="print"
    shift 2

    # status command is special, it should not print the log message
    [[ "$cmd" == "status" ]] && print="noprint"

    # mcsl command path for the specified session
    local mcslsh="$SERVER_CONTAINER/$session/mcsl/$MCSL_NAME"

    # Check if the mcsl command exists in the specified session
    if [[ ! -f "$mcslsh" ]]; then
        log_error "mcsl not found for server $session: $mcslsh" "print"
        return 1
    fi

    # Invoke_mcsl mcsl with all remaining args
    log_info "executing command $cmd on server $session" "$print"
    bash "$mcslsh" "$cmd" "$@" && return 0

    log_error "command $cmd failed on server $session" "print"
    return 1
}

invoke_session() {
    local session="$1"
    local command="$2"
    shift 2

    log_info "invoke $command command in session: $session"
    invoke_mcsl "$session" "$command" "$@"
}

invoke_sessions() {
    local command="$1"
    shift

    log_info "invoke $command command in all sessions"
    for dir in "$SERVER_CONTAINER"/*/; do
        [[ -d "$dir" ]] || continue

        local session="${dir%/}"
        session="${session##*/}"

        invoke_mcsl "$session" "$command" "$@"
    done
}
