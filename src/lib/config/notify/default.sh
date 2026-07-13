# file: src/lib/config/notify/default.sh

default_notify() {
    cat <<"EOF" > "$1"
# Minecraft Server Launcher Event Configuration

# Enable or disable notifications for server events.
EnableEvent=false

# Name of the server shown in notifications
ServerName=My Minecraft Server

# Discord webhook URL for server events
DiscordWebHook=https://discord.com/api/webhooks/HooksId

# Telegram bot token
TelegramToken=TokenId

# Telegram chat ID (can be negative for groups)
TelegramChatID=ChatId
EOF
}
