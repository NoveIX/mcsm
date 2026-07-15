# file: src/lib/notify/runtime.sh

import "lib.notify.discord.color"
import "lib.notify.discord.send"
import "lib.notify.telegram.send"
import "lib.util.convert.second"

runtime_notify() {
    local type="$1"
    local msg

    # Check notification enabled
    [[ "$RUNTIME_NOTIFY" == "true" ]] || return 0

    case "$type" in
        start)
            msg="Server is starting"
            send_discord "$RUNTIME_WEBHOOK" "$SERVER_NAME" "$msg" "$DISCORD_GREEN" "start" || true
            send_telegram "$RUNTIME_TOKEN" "$RUNTIME_CHATID" "<b>$SERVER_NAME</b>\n<i>🟢 $msg</i>" "start" || true
        ;;

        stop)
            msg="Server stopped"
            send_discord "$RUNTIME_WEBHOOK" "$SERVER_NAME" "$msg" "$DISCORD_BLUE" "stop" || true
            send_telegram "$RUNTIME_TOKEN" "$RUNTIME_CHATID" "<b>$SERVER_NAME</b>\n<i>🔵 $msg</i>" "stop" || true
        ;;

        handle)
            msg="Crash handling disabled. Server will not restart"
            send_discord "$RUNTIME_WEBHOOK" "$SERVER_NAME" "$msg" "$DISCORD_YELLOW" "handle" || true
            send_telegram "$RUNTIME_TOKEN" "$RUNTIME_CHATID" "<b>$SERVER_NAME</b>\n<i>🟡 $msg</i>" "handle" || true
        ;;

        crash)
            msg="Server crashed after $(convert_seconds "$uts"). Restarting"
            send_discord "$RUNTIME_WEBHOOK" "$SERVER_NAME" "$msg" "$DISCORD_YELLOW" "crash" || true
            send_telegram "$RUNTIME_TOKEN" "$RUNTIME_CHATID" "<b>$SERVER_NAME</b>\n<i>🟡 $msg</i>" "crash" || true

        ;;

        loop)
            msg="Server crash limit reached (max $MAX_RESTART). Server will not restart"
            send_discord "$RUNTIME_WEBHOOK" "$SERVER_NAME" "$msg" "$DISCORD_RED" "loop" || true
            send_telegram "$RUNTIME_TOKEN" "$RUNTIME_CHATID" "<b>$SERVER_NAME</b>\n<i>🔴 $msg</i>" "loop" || true
        ;;

        *)
            log_error "invalid notification type: $type" "print"
        ;;
    esac
}
