# file: src/lib/core/ctx.sh

# Config
readonly CFG_DIR="$MCSL_DIR/cfg"
readonly RUNTIME_CONF="$CFG_DIR/runtime.conf"
readonly BACKUP_CONF="$CFG_DIR/backup.conf"
readonly NOTIFY_CONF="$CFG_DIR/notify.conf"

# Logs
readonly LOGS_DIR="$MCSL_DIR/logs"

# Source
readonly SRC_DIR="$MCSL_DIR/src"
# readonly LIB_DIR="$SRC_DIR/lib" - NOT USED
readonly DATA_DIR="$SRC_DIR/data"
readonly COMMANDS_DIR="$SRC_DIR/commands"

# Service scripts
readonly RUNTIME_SERVICE="$SRC_DIR/service/runtime.sh"
readonly BACKUP_SERVICE="$SRC_DIR/service/backup.sh"

# Runtime state
readonly RUNTIME_DIR="$MCSL_DIR/.runtime"
readonly RUNTIME_STATE="$RUNTIME_DIR/runtime.state"
readonly BACKUP_STATE="$RUNTIME_DIR/backup.state"
readonly CRASH_STATE="$RUNTIME_DIR/crash.state"
readonly RESTART_CTL="$RUNTIME_DIR/restartctl"
readonly UPTIME_TIMESTAMP="$RUNTIME_DIR/uptime.timestamp"

# Data
readonly VERSION_FILE="$DATA_DIR/version"

# Server
readonly SERVER_ROOT="$(dirname "$MCSL_DIR")"
readonly SERVER_CONTAINER="$(dirname "$SERVER_ROOT")"

# Backup
readonly BACKUP_DIR="$SERVER_ROOT/backups"
