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
            send_discord "$BACKUP_WEBHOOK" "$SERVER_NAME" "$msg" "$DISCORD_GREEN" "start" || true
            send_telegram "$BACKUP_TOKEN" "$BACKUP_CHATID" "<b>$SERVER_NAME</b>\n<i>🔵 $msg</i>" "start" || true
        ;;

        done)
            msg="Backup completed\n\n$detail"
            send_discord "$BACKUP_WEBHOOK" "$SERVER_NAME" "$msg" "$DISCORD_BLUE" "done" || true
            send_telegram "$BACKUP_TOKEN" "$BACKUP_CHATID" "<b>$SERVER_NAME</b>\n<i>🟢 $msg</i>" "done" || true
        ;;

        warn)
            msg="Backup warning\n\nReason:\n$detail"
            send_discord "$BACKUP_WEBHOOK" "$SERVER_NAME" "$msg" "$DISCORD_YELLOW" "warn" || true
            send_telegram "$BACKUP_TOKEN" "$BACKUP_CHATID" "<b>$SERVER_NAME</b>\n<i>🟡 $msg</i>" "warn" || true
        ;;

        fail)
            msg="Backup failed\n\nReason:\n$detail"
            send_discord "$BACKUP_WEBHOOK" "$SERVER_NAME" "$msg" "$DISCORD_RED" "fail" || true
            send_telegram "$BACKUP_TOKEN" "$BACKUP_CHATID" "<b>$SERVER_NAME</b>\n<i>🔴 $msg</i>" "fail" || true
        ;;

        *)
            log_error "invalid notification type: $type" "print"
        ;;
    esac
}
