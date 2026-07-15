# file: src/lib/config/notify/read.sh

import "lib.config.notify.default"
import "lib.util.trim"

read_notify() {
    local file="$NOTIFY_CONF"
    local key value

    mkdir -p "$CFG_DIR"

    # Check if config file exists
    if [[ ! -f "$file" ]]; then
        log_info "generating default notify configuration"
        default_notify "$file"
    fi

    # Check if config file is readable
    while IFS='=' read -r key value; do
        key="$(trim "$key")"
        value="$(trim "$value")"

        # Skip empty lines and comments
        [[ -z "$key" || "$key" == \#* ]] && continue

        case "$key" in
            ServerName)            SERVER_NAME="$value"        ;;
            RuntimeNotifyEnabled)  RUNTIME_NOTIFY="${value,,}" ;;
            RuntimeDiscordWebHook) RUNTIME_WEBHOOK="$value"    ;;
            RuntimeTelegramToken)  RUNTIME_TOKEN="$value"      ;;
            RuntimeTelegramChatID) RUNTIME_CHATID="$value"     ;;
            BackupNotifyEnabled)   BACKUP_NOTIFY="${value,,}"  ;;
            BackupDiscordWebHook)  BACKUP_WEBHOOK="$value"     ;;
            BackupTelegramToken)   BACKUP_TOKEN="$value"       ;;
            BackupTelegramChatID)  BACKUP_CHATID="$value"      ;;
            *)
                log_warn "ignored unknown key: $key"
            ;;
        esac
    done < "$file"

    # Validate required config
    if [[ ! "$RUNTIME_NOTIFY" =~ ^(true|false)$ ]]; then
        log_error "invalid RuntimeNotifyEnabled: $RUNTIME_NOTIFY (expected: true|false)" "print"
        return 1
    fi

    if [[ ! "$BACKUP_NOTIFY" =~ ^(true|false)$ ]]; then
        log_error "invalid BackupNotifyEnabled: $BACKUP_NOTIFY (expected: true|false)" "print"
        return 1
    fi

    if [[ "$BACKUP_NOTIFY" == "true" ]]; then
        BACKUP_WEBHOOK=${BACKUP_WEBHOOK:-$RUNTIME_WEBHOOK}
        BACKUP_TOKEN=${BACKUP_TOKEN:-$RUNTIME_TOKEN}
        BACKUP_CHATID=${BACKUP_CHATID:-$RUNTIME_CHATID}
    fi

    log_info "notify configuration loaded"
}
