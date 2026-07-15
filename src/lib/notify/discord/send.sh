# file: src/lib/notify/discord/send.sh

import "lib.notify.discord.json"

send_discord() {
    local webhook_url="$1"
    local title="$2"
    local message="$3"
    local color="${4:-2326507}" # blu default
    local type="$5"

    # Create json payload
    local payload=$(discord_json "$title" "$message" "$color") || {
        log_error "failed to generate Discord JSON payload" "print"
        return 1
    }

    # Prefer curl
    if command -v curl >/dev/null 2>&1; then
        if curl -fsS \
        -H "Content-Type: application/json" \
        -X POST \
        -d "$payload" \
        "$webhook_url"; then

            log_info "Discord $type notification sent"
            return 0
        fi

        log_error "curl: failed to send Discord $type notification" "print"
        return 1
    fi

    # Fallback wget
    if command -v wget >/dev/null 2>&1; then
        if wget -q \
        --header="Content-Type: application/json" \
        --post-data="$payload" \
        -O /dev/null \
        "$webhook_url"; then

            log_info "Discord $type notification sent"
            return 0
        fi

        log_error "wget: failed to send Discord $type notification" "print"
        return 1
    fi

    log_error "neither curl nor wget is installed" "print"
    return 1
}
