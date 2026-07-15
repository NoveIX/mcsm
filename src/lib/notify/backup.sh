# file: src/lib/notify/backup.sh

import "lib.notify.discord.color"
import "lib.notify.discord.send"
import "lib.notify.telegram.send"
import "lib.util.convert.second"

backup_notify() {
    local type="$1"
    local detail="${2:-}"
    local msg

    # Check notification enabled
    [[ "$BACKUP_NOTIFY" == "true" ]] || return 0

    case "$type" in
        info)
            msg="Backup is starting"
            send_discord "$BACKUP_WEBHOOK" "$SERVER_NAME" "$msg" "$DISCORD_BLUE" "info" || true
            send_telegram "$BACKUP_TOKEN" "$BACKUP_CHATID" "<b>🔵 $SERVER_NAME</b>\n$msg" "info" || true
        ;;

        warn)
            msg="Backup warning\n\nReason:\n$detail"
            send_discord "$BACKUP_WEBHOOK" "$SERVER_NAME" "$msg" "$DISCORD_YELLOW" "warn" || true
            send_telegram "$BACKUP_TOKEN" "$BACKUP_CHATID" "<b>🟡 $SERVER_NAME</b>\n$msg" "warn" || true
        ;;

        error)
            msg="Backup failed\n\nReason:\n$detail"
            send_discord "$BACKUP_WEBHOOK" "$SERVER_NAME" "$msg" "$DISCORD_RED" "error" || true
            send_telegram "$BACKUP_TOKEN" "$BACKUP_CHATID" "<b>🔴 $SERVER_NAME</b>\n$msg" "error" || true
        ;;

        fatal)
            msg="Backup fatal\n\nReason:\n$detail"
            send_discord "$BACKUP_WEBHOOK" "$SERVER_NAME" "$msg" "$DISCORD_PURPLE" "fatal" || true
            send_telegram "$BACKUP_TOKEN" "$BACKUP_CHATID" "<b>🟣 $SERVER_NAME</b>\n$msg" "fatal" || true
        ;;

        done)
            msg="Backup completed\n\n$detail"
            send_discord "$BACKUP_WEBHOOK" "$SERVER_NAME" "$msg" "$DISCORD_GREEN" "done" || true
            send_telegram "$BACKUP_TOKEN" "$BACKUP_CHATID" "<b>🟢 $SERVER_NAME</b>\n$msg" "done" || true
        ;;

        *)
            log_error "invalid notification type: $type" "print"
        ;;
    esac
}
