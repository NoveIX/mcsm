# file: src/lib/config/runtime/read.sh

import "lib.core.param.require"
import "lib.config.runtime.default"
import "lib.util.trim"

read_runtime() {
    local file="$RUNTIME_CONF"
    local key value
    local valid=true

    mkdir -p "$CFG_DIR"

    # Check if config file exists
    if [[ ! -f "$file" ]]; then
        log_info "generating default configuration" "print"
        default_runtime "$file"
    fi

    # Check if config file is readable
    while IFS='=' read -r key value; do
        key="$(trim "$key")"
        value="$(trim "$value")"

        # Skip empty lines and comments
        [[ -z "$key" || "$key" == \#* ]] && continue

        case "$key" in
            StartCommand) START_COMMAND="$value"    ;;
            CrashHandle)  CRASH_HANDLE="${value,,}" ;;
            MaxRestart)   MAX_RESTART="$value"      ;;
            LogFiles)     LOG_FILES="${value,,}"     ;;
            *)
                log_error "unknown config key: $key"
                valid=false
            ;;
        esac
    done < "$file"

    # Required parameters
    require_param "StartCommand" "$START_COMMAND" "read_runtime" || return 1

    # Optional defaults
    CRASH_HANDLE="${CRASH_HANDLE:-true}"
    MAX_RESTART="${MAX_RESTART:-3}"
    LOG_FILES="${LOG_FILES:-separate}"

    # Validation
    [[ ! "$CRASH_HANDLE" =~ ^(true|false)$ ]] && log_warn "invalid CrashHandle value $CRASH_HANDLE (expected true|false)" "print"
    [[ ! "$MAX_RESTART" =~ ^(-1|[0-9]+)$ ]] && log_warn "invalid MaxRestart value $MAX_RESTART (expected integer or -1)" "print"
    [[ ! "$LOG_FILES" =~ ^(separate|combined)$ ]] && log_warn "invalid LogFiles value $LOG_FILES (expected separate|combined)" "print"

    if [[ "${valid,,}" != "true" ]]; then
        log_error "runtime configuration validation failed" "print"
        return 1
    fi

    # Result
    log_info "runtime configuration loaded successfully"
    return 0
}
