# file: src/lib/cli/param/validate.sh

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
