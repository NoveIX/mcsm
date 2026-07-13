# File: notifier.sh
# Description: notifier utility functions for bash scripts
# Author: NoveIX
# SPDX-License-Identifier: GPL-3.0-or-later

# ================================[ Function ]================================ #

send_discord() {
    local webhook_url="$1"
    local title="$2"
    local message="$3"
    local color="${4:-2326507}" # blu default

    # Check mandatory parameters
    require_param "webhook_url" "$webhook_url" "send_discord" || return 1
    require_param "title" "$title" "send_discord" || return 1
    require_param "message" "$message" "send_discord" || return 1

    # Check required dependencies
    check_command "jq" "warn" || return 1

    local payload
    payload=$(jq -n \
        --arg title "$title" \
        --arg message "$message" \
        --argjson color "$color" \
        '{
        embeds: [{
          title: $title,
          description: $message,
          color: $color
        }]
        }'
    )

    # Prefer curl
    if command -v curl >/dev/null 2>&1; then
        if curl -fsS \
            -H "Content-Type: application/json" \
            -X POST \
            -d "$payload" \
            "$webhook_url"; then

            log_info "Discord notification sent"
            return 0
        fi

        log_error "curl: failed to send Discord notification" "print"
        return 1
    fi

    # Fallback wget
    if command -v wget >/dev/null 2>&1; then
        if wget -q \
            --header="Content-Type: application/json" \
            --post-data="$payload" \
            -O /dev/null \
            "$webhook_url"; then

            log_info "Discord notification sent"
            return 0
        fi

        log_error "wget: failed to send Discord notification" "print"
        return 1
    fi

    log_error "neither curl nor wget is installed" "print"
    return 1
}

discord_event() {
    [[ -n "${DISCORD_WEBHOOK:-}" ]] || return 0
    [[ "${DISCORD_WEBHOOK,,}" != "https://discord.com/api/webhooks/HooksId" ]] || return 0
    send_discord "$DISCORD_WEBHOOK" "$ServerName" "$1" "${2:-}" || true
}

send_telegram() {
    local token_id="$1"
    local chat_id="$2"
    local message=$(printf %b "$3")

    # Check mandatory parameters
    require_param "token_id" "$token_id" "send_telegram" || return 1
    require_param "chat_id" "$chat_id" "send_telegram" || return 1
    require_param "message" "$message" "send_telegram" || return 1

    local url="https://api.telegram.org/bot${token_id}/sendMessage"

    # Prefer curl
    if command -v curl >/dev/null 2>&1; then
        if curl -fsS \
            -X POST \
            -d "chat_id=${chat_id}" \
            --data-urlencode "text=${message}" \
            -d "parse_mode=HTML" \
            "$url" >/dev/null; then

            log_info "Telegram notification sent"
            return 0
        fi

        log_error "curl: failed to send Telegram notification" "print"
        return 1
    fi

    # Fallback wget
    if command -v wget >/dev/null 2>&1; then
        if wget -q \
            --header="Content-Type: application/x-www-form-urlencoded" \
            --post-data="chat_id=${chat_id}&text=${message}&parse_mode=HTML" \
            -O /dev/null \
            "$url"; then

            log_info "Telegram notification sent"
            return 0
        fi

        log_error "wget: failed to send Telegram notification" "print"
        return 1
    fi

    log_error "neither curl nor wget is installed" "print"
    return 1
}

telegram_event() {
    [[ -n "${TELEGRAM_TOKEN:-}" && -n "${TELEGRAM_CHATID:-}" ]] || return 0
    [[ "${TELEGRAM_TOKEN,,}" != "tokenid" ]] || return 0
    [[ "${TELEGRAM_CHATID,,}" != "chatid" ]] || return 0
    send_telegram "$TELEGRAM_TOKEN" "$TELEGRAM_CHATID" "$1" || true
}

runtime_notification() {
    local type="$1"

    # Check notification enabled
    [[ "${ENABLE_NOTIFICATION,,}" == "true" ]] || return 0

    # Check mandatory parameters
    require_param "type" "$type" "runtime_notification" || return 1

    case "${type,,}" in
        start)
            discord_event "$ServerName" "Server is starting" "2935556"
            telegram_event "<b>$ServerName</b>\n<i>🟢 Server is starting</i>"
        ;;

        stop)
            discord_event "$ServerName" "Server stopped"
            telegram_event "<b>$ServerName</b>\n<i>🔵 Server stopped</i>"
        ;;

        handle)
            discord_event "$ServerName" "Crash handling disabled. Server will not restart"
            telegram_event "<b>$ServerName</b>\n<i>🟡 Crash handling disabled. Server will not restart</i>"
        ;;

        crash)
            discord_event "$ServerName" "Server crashed after $(format_duration "$uts"). Restarting" "15910673"
            telegram_event "<b>$ServerName</b>\n<i>🟡 Server crashed after $(format_duration "$uts"). Restarting</i>"
        ;;

        loop)
            discord_event "$ServerName" "Server crash limit reached (Max $MAX_RESTART). Server will not restart" "16711680"
            telegram_event "<b>$ServerName</b>\n<i>🔴 Server crash limit reached (Max $MAX_RESTART). Server will not restart</i>"
        ;;

        *)
            log_error "invalid notification type: $type" "print"
        ;;
    esac
}
