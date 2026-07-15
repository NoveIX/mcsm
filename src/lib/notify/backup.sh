# file: src/lib/notify/backup.sh

import "lib.notify.discord.color"
import "lib.notify.discord.send"
import "lib.notify.telegram.send"
import "lib.util.convert.second"

backup_notify() {
    local type="$1"
    local msg

    # Check notification enabled
    [[ "$BACKUP_NOTIFY" == "true" ]] || return 0

    case "$type" in
        start)
            msg="Server is starting"
            send_discord "$BACKUP_WEBHOOK" "$SERVER_NAME" "$msg" "$DISCORD_GREEN" "start"
            send_telegram "$BACKUP_TOKEN" "$BACKUP_CHATID" "<b>$SERVER_NAME</b>\n<i>🟢 $msg</i>" "start"
        ;;

        stop)
            msg="Server stopped"
            send_discord "$BACKUP_WEBHOOK" "$SERVER_NAME" "$msg" "$DISCORD_BLUE" "stop"
            send_telegram "$BACKUP_TOKEN" "$BACKUP_CHATID" "<b>$SERVER_NAME</b>\n<i>🔵 $msg</i>" "stop"
        ;;

        handle)
            msg="Crash handling disabled. Server will not restart"
            send_discord "$BACKUP_WEBHOOK" "$SERVER_NAME" "$msg" "$DISCORD_YELLOW" "handle"
            send_telegram "$BACKUP_TOKEN" "$BACKUP_CHATID" "<b>$SERVER_NAME</b>\n<i>🟡 $msg</i>" "handle"
        ;;

        crash)
            msg="Server crashed after $(convert_seconds "$uts"). Restarting"
            send_discord "$BACKUP_WEBHOOK" "$SERVER_NAME" "$msg" "$DISCORD_YELLOW" "crash"
            send_telegram "$BACKUP_TOKEN" "$BACKUP_CHATID" "<b>$SERVER_NAME</b>\n<i>🟡 $msg</i>" "crash"

        ;;

        loop)
            msg="Server crash limit reached (max $MAX_RESTART). Server will not restart"
            send_discord "$BACKUP_WEBHOOK" "$SERVER_NAME" "$msg" "$DISCORD_RED" "loop"
            send_telegram "$BACKUP_TOKEN" "$BACKUP_CHATID" "<b>$SERVER_NAME</b>\n<i>🔴 $msg</i>" "loop"
        ;;

        *)
            log_error "invalid notification type: $type" "print"
        ;;
    esac
}
