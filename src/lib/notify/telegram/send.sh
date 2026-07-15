# file: src/lib/notify/telegram/send.sh

send_telegram() {
    local token_id="$1"
    local chat_id="$2"
    local message=$(printf %b "$3")
    local type="$4"

    local url="https://api.telegram.org/bot${token_id}/sendMessage"

    # Prefer curl
    if command -v curl >/dev/null 2>&1; then
        if curl -fsS \
            -X POST \
            -d "chat_id=${chat_id}" \
            --data-urlencode "text=${message}" \
            -d "parse_mode=HTML" \
            "$url" >/dev/null; then

            log_info "Telegram $type notification sent"
            return 0
        fi

        log_error "curl: failed to send Telegram $type notification" "print"
        return 1
    fi

    # Fallback wget
    if command -v wget >/dev/null 2>&1; then
        if wget -q \
            --header="Content-Type: application/x-www-form-urlencoded" \
            --post-data="chat_id=${chat_id}&text=${message}&parse_mode=HTML" \
            -O /dev/null \
            "$url"; then

            log_info "Telegram $type notification sent"
            return 0
        fi

        log_error "wget: failed to send Telegram $type notification" "print"
        return 1
    fi

    log_error "neither curl nor wget is installed" "print"
    return 1
}
