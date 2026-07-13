# File: parameter.sh
# Description: parameter utility functions for bash scripts
# Author: NoveIX
# SPDX-License-Identifier: GPL-3.0-or-later

# ================================[ Function ]================================ #

validate_param() {
    local name="$1"
    local value="$2"

    case "$name" in
        session)
            [[ -z "$value" ]] && return 0  # optional

            [[ ${#value} -le 16 ]] || {
                log_error "invalid session (max 16 chars)" "print"
                return 1
            }
        ;;

        time)
            [[ -z "$value" ]] && return 0  # optional

            [[ "$value" =~ ^[0-9]+$ ]] || {
                log_error "invalid time value: $time (must be integer)" "print"
                return 1
            }
        ;;

        host|port|path|user|key)
            [[ -z "$value" ]] && return 0  # all optional

            case "$name" in
                port)
                    [[ "$value" =~ ^[0-9]+$ && "$value" -ge 1 && "$value" -le 65535 ]] || {
                        log_error "invalid port value: $port" "print"
                        return 1
                    }
                ;;

                *)
                    # generic string
                ;;
            esac
        ;;
    esac

    return 0
}

validate_flags() {
    local flag="$1"
    local next="$2"

    # error only if the next one is NOT a flag
    [[ -n "$next" && "$next" != -* ]] && {
        log_error "$flag does not accept parameters: $next" "print"
        return 1
    }

    return 0
}

require_param() {
    local name="$1"
    local value="$2"
    local ctx="${3:-unknown}"
    local stream="${4:-out}"

    # Check mandatory parameter
    if [[ -z "$value" ]]; then
        log_error "$ctx: missing required parameter: $name" "print" "$stream"
        return 1
    fi

    return 0
}
