# file: src/lib/notify/backup.sh

import "lib.notify.discord.color"
import "lib.notify.discord.send"
import "lib.notify.telegram.send"
import "lib.util.convert.second"

backup_notify() {
    local type="$1"
    local detail="${2:-}"
    local msg color emoji

    [[ "$BACKUP_NOTIFY" == "false" ]] && return 0

    case "$type" in
        info)
            msg="Backup is starting"
            color="$DISCORD_BLUE"
            emoji="🔵"
        ;;

        warn)
            msg="Backup warning\n\nReason:\n$detail"
            color="$DISCORD_YELLOW"
            emoji="🟡"
        ;;

        error)
            msg="Backup failed\n\nReason:\n$detail"
            color="$DISCORD_RED"
            emoji="🔴"
        ;;

        fatal)
            msg="Backup fatal\n\nReason:\n$detail"
            color="$DISCORD_PURPLE"
            emoji="🟣"
        ;;

        done)
            msg="Backup completed\n\n$detail"
            color="$DISCORD_GREEN"
            emoji="🟢"
        ;;

        *)
            log_error "invalid notification type: $type" "print"
            return 1
        ;;
    esac

    if [[ -n "$BACKUP_WEBHOOK" ]]; then
        send_discord \
        "$BACKUP_WEBHOOK" \
        "$SERVER_NAME" \
        "$msg" \
        "$color" \
        "$type" || true
    fi

    if [[ -n "$BACKUP_TOKEN" && -n "$BACKUP_CHATID" ]]; then
        send_telegram \
        "$BACKUP_TOKEN" \
        "$BACKUP_CHATID" \
        "<b>$emoji $SERVER_NAME</b>\n$msg" \
        "$type" || true
    fi
}
