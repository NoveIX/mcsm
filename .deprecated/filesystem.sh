# File: loader.sh
# Description: Module loader for bash scripts
# Author: NoveIX
# SPDX-License-Identifier: GPL-3.0-or-later

# ================================[ Function ]================================ #

create_restartctl() {
    local file="$1"

    # Ensure cfg dir
    [[ ! -d "$(dirname $file)" ]] && mkdir -p "$(dirname $file)"

    # ensure restart/keep-alive file exists
    if printf 'starting server at %s\n' "$(date '+%F %T')" > "$file"; then
        log_info "created restartctl: $file"
        return 0
    fi

    log_error "write restartctl failed: $file" "print"
    return 1
}

remove_restartctl() {
    local file="$1"

    # Remove restartctl file
    if rm -f "$file"; then
        log_info "removed restartctl: $file"
        return 0
    fi

    log_error "remove restartctl failed: $file" "print"
    return 1
}

wait_pattern() {
    local file="$1"
    local pattern="$2"
    local timeout="${3:-30}"   # secondi
    local elapsed=0

    while (( elapsed < timeout )); do
        if tail -n 0 -F "$file" 2>/dev/null | grep -q --line-buffered "$pattern"; then
            return 0
        fi

        sleep 1
        ((elapsed++))
    done

    return 1
}

check_backup() {
    case "${1,,}" in
        zip)
            check_command "zip" || return 1
        ;;

        tar.gz)
            check_command "tar" || return 1
            check_command "gzip" || return 1
        ;;

        tar.xz)
            check_command "tar" || return 1
            check_command "xz" || return 1
        ;;

        tar.zst)
            check_command "tar" || return 1
            check_command "zstd" || return 1
        ;;

        *)
            log_error "unsupported backup format: ${1,,}" "print"
            return 1
        ;;
    esac

    return 0
}
