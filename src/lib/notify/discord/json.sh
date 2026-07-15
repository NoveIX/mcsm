# file: src/lib/notify/discord/json.sh

import "lib.core.command"

discord_json() {
    local title="$1"
    local message="$2"
    local color="$3"

    if command -v jq >/dev/null 2>&1; then
        jq -n \
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
        return 0
    fi

    if command -v python3 >/dev/null 2>&1; then
        python3 - "$title" "$message" "$color" <<'PY'
import json
import sys

print(json.dumps({
    "embeds": [{
        "title": sys.argv[1],
        "description": sys.argv[2],
        "color": int(sys.argv[3])
    }]
}))
PY
        return 0
    fi

    printf '{"embeds":[{"title":"%s","description":"%s","color":%s}]}' \
    "$title" "$message" "$color"
}
