# file: src/lib/notify/runtime.sh

import "lib.notify.discord.color"
import "lib.notify.discord.send"
import "lib.notify.telegram.send"
import "lib.util.convert.second"

runtime_notify() {
    local type="$1"
    local msg="$2"

    # Check notification enabled
    [[ "$RUNTIME_NOTIFY" == "true" ]] || return 0

    case "$type" in
        info)
            send_discord "$RUNTIME_WEBHOOK" "$SERVER_NAME" "$msg" "$DISCORD_GREEN" "info" || true
            send_telegram "$RUNTIME_TOKEN" "$RUNTIME_CHATID" "<b>🔵 $SERVER_NAME</b>\n$msg" "info" || true
        ;;

        warn)
            send_discord "$RUNTIME_WEBHOOK" "$SERVER_NAME" "$msg" "$DISCORD_YELLOW" "warn" || true
            send_telegram "$RUNTIME_TOKEN" "$RUNTIME_CHATID" "<b>🟡 $SERVER_NAME</b>\n$msg" "warn" || true
        ;;

        error)
            send_discord "$RUNTIME_WEBHOOK" "$SERVER_NAME" "$msg" "$DISCORD_RED" "fail" || true
            send_telegram "$RUNTIME_TOKEN" "$RUNTIME_CHATID" "<b>🔴 $SERVER_NAME</b>\n$msg" "fail" || true
        ;;

        fatal)
            send_discord "$RUNTIME_WEBHOOK" "$SERVER_NAME" "$msg" "$DISCORD_RED" "fatal" || true
            send_telegram "$RUNTIME_TOKEN" "$RUNTIME_CHATID" "<b>🟣 $SERVER_NAME</b>\n$msg" "fatal" || true
        ;;

        done)
            send_discord "$RUNTIME_WEBHOOK" "$SERVER_NAME" "$msg" "$DISCORD_BLUE" "done" || true
            send_telegram "$RUNTIME_TOKEN" "$RUNTIME_CHATID" "<b>🟢 $SERVER_NAME</b>\n$msg" "done" || true
        ;;

        *)
            log_error "invalid notification type: $type" "print"
        ;;
    esac
}
