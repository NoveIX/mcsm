# file: src/lib/config/notify/default.sh

default_notify() {
    cat <<"EOF" > "$1"
# MCSL Notify Configuration

# Server name displayed in notifications.
ServerName=My Minecraft Server

# Runtime notifications.
RuntimeNotifyEnabled=false
RuntimeDiscordWebHook=
RuntimeTelegramToken=
RuntimeTelegramChatID=

# Backup notifications.
# By default, uses the corresponding runtime notification settings.
# Leave DiscordWebHook, TelegramToken, or TelegramChatID empty to inherit them.
BackupNotifyEvent=false
BackupDiscordWebHook=
BackupTelegramToken=
BackupTelegramChatID=
EOF
}
