# file: src/lib/notify/runtime.sh

import "lib.notify.discord.color"
import "lib.notify.discord.send"
import "lib.notify.telegram.send"
import "lib.util.convert.second"

runtime_notify() {
    local type="$1"
    local msg="$2"
    local color emoji

    # Check notification enabled
    [[ "$RUNTIME_NOTIFY" == "false" ]] && return 0

    case "$type" in
        info)
            color="$DISCORD_GREEN"
            emoji="🔵"
        ;;

        warn)
            color="$DISCORD_YELLOW"
            emoji="🟡"
        ;;

        error)
            color="$DISCORD_RED"
            emoji="🔴"
        ;;

        fatal)
            color="$DISCORD_RED"
            emoji="🟣"
        ;;

        done)
            color="$DISCORD_BLUE"
            emoji="🟢"
        ;;

        *)
            log_error "invalid notification type: $type" "print"
            return 1
        ;;
    esac

    if [[ -n "$RUNTIME_WEBHOOK" ]]; then
        send_discord \
        "$RUNTIME_WEBHOOK" \
        "$SERVER_NAME" \
        "$msg" \
        "$color" \
        "$type" || true
    fi

    if [[ -n "$RUNTIME_TOKEN" && -n "$RUNTIME_CHATID" ]]; then
        send_telegram \
        "$RUNTIME_TOKEN" \
        "$RUNTIME_CHATID" \
        "<b>$emoji $SERVER_NAME</b>\n$msg" \
        "$type" || true
    fi
}
