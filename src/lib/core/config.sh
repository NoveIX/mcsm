# File: config.sh
# Description: Config utility functions for bash scripts
# Author: NoveIX
# SPDX-License-Identifier: GPL-3.0-or-later

# ================================[ Function ]================================ #

# Trim leading and trailing whitespace from a string.
trim() {
    local s="$1"

    s="${s#"${s%%[![:space:]]*}"}"
    s="${s%"${s##*[![:space:]]}"}"

    printf '%s\n' "$s"
}

# Generate a default configuration file with example settings.
default_config_runtime() {
    local file="$1"

    # Create and write default config
    cat <<"EOF" > "$file"
# Minecraft Server Launcher Runtime Configuration

# Command used to start the Minecraft server.
# The command is executed from the server root directory.
# Supports relative or absolute paths, as well as commands with arguments.
# Examples:
#   StartCommand=java -jar server.jar nogui
#   StartCommand=run.sh
StartCommand=run.sh

# Automatically restart the server if it crashes.
# Valid values: true, false
# Default: true
CrashHandle=true

# Maximum number of restart attempts before giving up.
# Use a positive integer to limit retries.
# Use -1 for unlimited restart attempts.
# Default: 3
MaxRestart=3

# Default log mode used by runtime.
# Valid values:
#   separate - Creates dedicated log files for warnings, errors, and fatal messages.
#   combined - Writes all log messages to a single file.
# Default: separate
LogMode=separate
EOF
}

default_config_backup() {
    local file="$1"

    # Create and write default config
    cat <<"EOF" > "$file"
# Minecraft Server Launcher Backup Configuration

# Enable or disable automatic backups for the Minecraft server.
EnableBackup=false

# Backup archive format
# Supported: zip, tar.gz, tar.xz, tar.zst
# Required tools:
#   zip:     zip command-line utility (included in most systems)
#   tar.gz:  tar with gzip support (requires gzip installed)
#   tar.xz:  tar with xz support   (requires xz-utils installed)
#   tar.zst: tar with zstd support (requires zstd installed)
BackupFormat=zip

# Backup delay in minutes.
BackupDelay=30
EOF
}

default_config_notify() {
    local file="$1"

    # Create and write default config
    cat <<"EOF" > "$file"
# Minecraft Server Launcher Notification Configuration

# Enable or disable notifications for server events.
EnableNotification=false

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

# Read configuration from a file and set global variables accordingly. Validates required parameters and applies defaults for optional ones.
read_config_runtime() {
    local file="$1"
    local key value
    local valid=true

    # Ensure cfg dir
    [[ ! -d "$cfg_dir" ]] && mkdir -p "$cfg_dir"

    # Check if config file exists
    if [[ ! -f "$file" ]]; then
        log_info "generating default configuration" "print"
        default_config_runtime "$file"
    fi

    # Check if config file is readable
    while IFS='=' read -r key value; do
        key="$(trim "$key")"
        value="$(trim "$value")"

        # Skip empty lines and comments
        [[ -z "$key" || "$key" == \#* ]] && continue

        case "$key" in
            StartCommand) START_COMMAND="$value" ;;
            CrashHandle)  CRASH_HANDLE="${value,,}"  ;;
            MaxRestart)   MAX_RESTART="$value"   ;;
            LogMode)      LOG_MODE="${value,,}"      ;;
            *)
                log_error "unknown config key: $key"
                valid=false
            ;;
        esac
    done < "$file"

    # Required parameters
    require_param "StartCommand" "$START_COMMAND" "read_config_runtime" || return 1

    # Optional defaults
    CRASH_HANDLE="${CRASH_HANDLE:-true}"
    MAX_RESTART="${MAX_RESTART:-3}"
    LOG_MODE="${LOG_MODE:-separate}"

    # Validation
    [[ ! "$CRASH_HANDLE" =~ ^(true|false)$ ]] && log_warn "invalid CrashHandle value $CRASH_HANDLE (expected true|false)" "print"
    [[ ! "$MAX_RESTART" =~ ^(-1|[0-9]+)$ ]] && log_warn "invalid MaxRestart value $MAX_RESTART (expected integer or -1)" "print"
    [[ ! "$LOG_MODE" =~ ^(separate|combined)$ ]] && log_warn "invalid LogMode value $LOG_MODE (expected separate|combined)" "print"

    if [[ "${valid,,}" != "true" ]]; then
        log_error "runtime configuration validation failed" "print"
        return 1
    fi

    # Result
    log_info "runtime configuration loaded successfully"
    return 0
}

read_config_backup() {
    local file="$1"
    local key value
    local valid=true

    # Ensure cfg dir
    [[ ! -d "$cfg_dir" ]] && mkdir -p "$cfg_dir"

    # Check if config file exists
    if [[ ! -f "$file" ]]; then
        log_info "generating default backup configuration" "print"
        default_config_backup "$file"
    fi

    # Check if config file is readable
    while IFS='=' read -r key value; do
        key="$(trim "$key")"
        value="$(trim "$value")"

        # Skip empty lines and comments
        [[ -z "$key" || "$key" == \#* ]] && continue

        case "$key" in
            EnableBackup) ENABLE_BACKUP="${value,,}" ;;
            BackupFormat) BACKUP_FORMAT="${value,,}" ;;
            BackupDelay)  BACKUP_DELAY="$value"  ;;
            *)
                log_error "unknown config key: $key"
                valid=false
            ;;
        esac
    done < "$file"

    # Validation
    if [[ ! "$ENABLE_BACKUP" =~ ^(true|false)$ ]]; then
        log_error "invalid EnableBackup value $ENABLE_BACKUP (expected true|false)" "print"
        valid=false
    fi

    # Optional defaults
    BACKUP_FORMAT="${BACKUP_FORMAT:-zip}"
    BACKUP_DELAY="${BACKUP_DELAY:-30}"

    if [[ "$ENABLE_BACKUP" == "true" ]]; then
        case "$BACKUP_FORMAT" in
            zip|tar.gz|tar.bz2|tar.xz|tar.zst) ;;
            *) log_warn "Invalid BackupFormat $BACKUP_FORMAT (expected zip, tar.gz, tar.bz2, tar.xz, or tar.zst)";;
        esac
        [[ ! "$BACKUP_DELAY" =~ ^(-1|[0-9]+)$ ]] && log_warn "invalid BackupDelay value $BACKUP_DELAY (expected integer or -1)" "print"
    fi

    if [[ "$valid" != "true" ]]; then
        log_error "backup configuration validation failed" "print"
        return 1
    fi

    # Result
    log_info "backup configuration loaded successfully"
    return 0
}

read_config_notify() {
    local file="$1"
    local key value
    local valid=true

    # Ensure cfg dir
    [[ ! -d "$cfg_dir" ]] && mkdir -p "$cfg_dir"

    # Check if config file exists
    if [[ ! -f "$file" ]]; then
        log_info "generating default notify configuration" "print"
        default_config_notify "$file"
    fi

    # Check if config file is readable
    while IFS='=' read -r key value; do
        key="$(trim "$key")"
        value="$(trim "$value")"

        # Skip empty lines and comments
        [[ -z "$key" || "$key" == \#* ]] && continue

        case "$key" in
            EnableNotification) ENABLE_NOTIFICATION="${value,,}" ;;
            ServerName)         SERVER_NAME="$value"         ;;
            DiscordWebHook)     DISCORD_WEBHOOK="$value"     ;;
            TelegramToken)      TELEGRAM_TOKEN="$value"      ;;
            TelegramChatID)     TELEGRAM_CHATID="$value"     ;;
            *)
                log_error "unknown config key: $key"
                valid=false
            ;;
        esac
    done < "$file"

    #    # Validation (notify-specific)
    if [[ ! "$ENABLE_NOTIFICATION" =~ ^(true|false)$ ]]; then
        log_error "invalid EnableNotification value $ENABLE_NOTIFICATION (expected true|false)" "print"
        valid=false
    fi

    if [[ "$ENABLE_NOTIFICATION" == "true" ]]; then
        [[ -z "$SERVER_NAME" ]] && log_warn "ServerName is empty" "print"
        [[ -z "$DISCORD_WEBHOOK" ]] && log_warn "DiscordWebHook is empty (Discord notifications disabled)" "print"
        [[ -z "$TELEGRAM_TOKEN" || -z "$TELEGRAM_CHATID" ]] && log_warn "Telegram is not fully configured (missing token or chat ID)" "print"
    fi

    if [[ "$valid" != "true" ]]; then
        log_error "notify configuration validation failed" "print"
        return 1
    fi

    # Result
    log_info "notify configuration loaded successfully"
    return 0
}
