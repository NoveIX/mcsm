# file: src/lib/config/notify/read.sh

import "lib.config.notify.default"
import "lib.util.trim"

read_notify() {
    local file="$1"
    local key value
    local valid=true

    mkdir -p "$CFG_DIR"

    # Check if config file exists
    if [[ ! -f "$file" ]]; then
        log_info "generating default notify configuration" "print"
        default_notify "$file"
    fi

    # Check if config file is readable
    while IFS='=' read -r key value; do
        key="$(trim "$key")"
        value="$(trim "$value")"

        # Skip empty lines and comments
        [[ -z "$key" || "$key" == \#* ]] && continue

        case "$key" in
            EnableEvent)    ENABLE_EVENT="${value,,}" ;;
            ServerName)     SERVER_NAME="$value"      ;;
            DiscordWebHook) DISCORD_WEBHOOK="$value"  ;;
            TelegramToken)  TELEGRAM_TOKEN="$value"   ;;
            TelegramChatID) TELEGRAM_CHATID="$value"  ;;
            *)
                log_error "unknown config key: $key"
                valid=false
            ;;
        esac
    done < "$file"

    #    # Validation (notify-specific)
    if [[ ! "$ENABLE_EVENT" =~ ^(true|false)$ ]]; then
        log_error "invalid EnableNotification value $ENABLE_EVENT (expected true|false)" "print"
        valid=false
    fi

    if [[ "$ENABLE_EVENT" == "true" ]]; then
        [[ -z "$SERVER_NAME" ]] && log_warn "ServerName is empty" "print"
        [[ -z "$DISCORD_WEBHOOK" ]] && log_warn "DiscordWebHook is empty (Discord notifications disabled)" "print"
        [[ -z "$TELEGRAM_TOKEN" || -z "$TELEGRAM_CHATID" ]] && log_warn "Telegram is not fully configured (missing token or chat ID)" "print"
    fi

    if [[ "$valid" != "true" ]]; then
        log_error "notify configuration validation failed" "print"
        return 1
    fi

    # Result
    log_info "notify configuration loaded successfully"
    return 0
}
