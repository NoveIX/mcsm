# file: src/lib/core/logger.sh

# Map log levels to numeric values for comparison.
loglevel_map() {
    case "${1,,}" in
        trace) printf '%s\n' 0 ;;
        debug) printf '%s\n' 1 ;;
        info)  printf '%s\n' 2 ;;
        warn)  printf '%s\n' 3 ;;
        error) printf '%s\n' 4 ;;
        fatal) printf '%s\n' 5 ;;
        done)  printf '%s\n' 6 ;;
        *)     printf '%s\n' 0 ;;
    esac
}

# Map log levels to ANSI color codes for terminal output.
logcolor_map() {
    case "${1,,}" in
        trace) printf '\033[90m' ;;
        debug) printf '\033[37m' ;;
        info)  printf '\033[94m' ;;
        warn)  printf '\033[33m' ;;
        error) printf '\033[31m' ;;
        fatal) printf '\033[35m' ;;
        done)  printf '\033[32m' ;;
        *)     printf '\033[0m'  ;;
    esac
}

# ================================[ Function ]================================ #

should_log() {
    # Check if the log level of the message is greater than or equal to the global minimum log level.
    (( $(loglevel_map "$1") >= $(loglevel_map "$GLOBAL_MINLEVEL") ))
}

# Set global log file paths and logging settings.
log_setting() {
    GLOBAL_LOGFILE="${1:-}"
    GLOBAL_MINLEVEL="${2:-info}"
    GLOBAL_PRINT="${3:-noprint}"
    local logfiles="${4:-separate}"

    # If global_logfile is set, create log file paths with date suffixes for organized logging.
    if [[ -n "$GLOBAL_LOGFILE" ]]; then
        local logdate="$(date +%F)"
        local logname="$(basename "$GLOBAL_LOGFILE")"
        local logdir="$(dirname "$GLOBAL_LOGFILE")"

        # Set global log file paths with date suffixes for different log levels.
        GLOBAL_LOGFILE="${logdir}/${logname}_${logdate}.log"
        if [[ "$logfiles" == "separate" ]]; then
            GLOBAL_LOGFILE_WARN="${logdir}/${logname}_${logdate}_warn.log"
            GLOBAL_LOGFILE_ERROR="${logdir}/${logname}_${logdate}_error.log"
            GLOBAL_LOGFILE_FATAL="${logdir}/${logname}_${logdate}_fatal.log"
        fi
    fi
}

# main log function that handles log level checking, terminal output, and file output based on the provided parameters.
log() {
    local level="${1,,}"
    local message=$(printf %b "$2")
    local print="${3:-$GLOBAL_PRINT}"
    local stream="${4:-out}"
    local path="${5:-$GLOBAL_LOGFILE}"

    # log level check
    should_log "$level" || return 0

    local color reset="\033[0m"
    color="$(logcolor_map "$level")"

    # terminal output
    if [[ "$print" == "print" ]]; then
        case "$stream" in
            out)
                printf '%b%s%b: %s\n' "$color" "$level" "$reset" "$message"
            ;;

            err)
                printf '%b%s%b: %s\n' "$color" "$level" "$reset" "$message" >&2
            ;;

            both)
                printf '%b%s%b: %s\n' "$color" "$level" "$reset" "$message"
                printf '%b%s%b: %s\n' "$color" "$level" "$reset" "$message" >&2
            ;;

            *)
            ;;
        esac
    fi

    # file output
    if [[ -n "$path" ]]; then
        if [[ ! -d "$(dirname "$path")" ]]; then
            mkdir -p "$(dirname "$path")"
        fi

        # Write log on file
        printf '%s %s %s\n' \
        "$(date "+%Y-%m-%d %H:%M:%S")" \
        "$level" \
        "$message" >> "$path"
    fi
}

# Convenience functions for each log level that call the main log function with the appropriate parameters.

log_trace() {
    # DarkGray TRACE log level.
    log "TRACE" "${1:-}" "${2:-}" "${3:-}"
}

log_debug() {
    # Gray DEBUG log level.
    log "DEBUG" "${1:-}" "${2:-}" "${3:-}"
}

log_info() {
    # Blue INFO log level.
    log "INFO" "${1:-}" "${2:-}" "${3:-}"
}

log_warn() {
    # DarkYellow WARN log level.
    log "WARN" "${1:-}" "${2:-}" "${3:-}"

    # Print on warn file log
    if [[ -n "${GLOBAL_LOGFILE_WARN:-}" ]]; then
        log "WARN" "${1:-}" "noprint" "none" "$GLOBAL_LOGFILE_WARN"
    fi
}

log_error() {
    # DarkRed ERROR log level.
    log "ERROR" "${1:-}" "${2:-}" "${3:-}"

    # Print on error file log
    if [[ -n "${GLOBAL_LOGFILE_ERROR:-}" ]]; then
        log "ERROR" "${1:-}" "noprint" "none" "$GLOBAL_LOGFILE_ERROR"
    fi
}

log_fatal() {
    # Magenta FATAL log level.
    log "FATAL" "${1:-}" "${2:-}" "${3:-}"

    # Print on fatal file log
    if [[ -n "${GLOBAL_LOGFILE_FATAL:-}" ]]; then
        log "FATAL" "${1:-}" "noprint" "none" "$GLOBAL_LOGFILE_FATAL"
    fi
}

log_done() {
    # Green DONE log level.
    log "DONE" "${1:-}" "${2:-}" "${3:-}"
}

print() {
    local message="${1:-}"
    local level="${2:-}"

    printf '%b\n' "$message"

    case "$level" in
        info)  log_info "$message"  ;;
        warn)  log_warn "$message"  ;;
        error) log_error "$message" ;;
        fatal) log_fatal "$message" ;;
    esac
}
