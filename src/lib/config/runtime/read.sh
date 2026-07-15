# file: src/lib/config/runtime/read.sh

import "lib.core.param.require"
import "lib.config.runtime.default"
import "lib.util.trim"

read_runtime() {
    local file="$RUNTIME_CONF"
    local key value

    mkdir -p "$CFG_DIR"

    # Check if config file exists
    if [[ ! -f "$file" ]]; then
        log_info "generating default runtime configuration" "print"
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
            LogFiles)     LOG_FILES="${value,,}"    ;;
            *)
                log_warn "ignored unknown key: $key"
            ;;
        esac
    done < "$file"

    # Validate required config
    require_param "StartCommand" "$START_COMMAND" "read_runtime"

    # Default optional configs
    CRASH_HANDLE="${CRASH_HANDLE:-true}"
    MAX_RESTART="${MAX_RESTART:-3}"
    LOG_FILES="${LOG_FILES:-separate}"

    # Validate optional configs
    [[ "$CRASH_HANDLE" =~ ^(true|false)$ ]] || log_warn "invalid CrashHandle: $CRASH_HANDLE (expected: true|false)" "print"
    [[ "$MAX_RESTART" =~ ^(-1|[0-9]+)$ ]] || log_warn "invalid MaxRestart: $MAX_RESTART (expected: positive integer or -1)" "print"
    [[ "$LOG_FILES" =~ ^(separate|combined)$ ]] || log_warn "invalid LogFiles: $LOG_FILES (expected: separate|combined)" "print"

    log_info "runtime configuration loaded"
}
