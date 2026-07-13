# file: src/lib/config/backup/read.sh

import "lib.config.backup.default"
import "lib.util.trim"

read_backup() {
    local file="$BACKUP_CONF"
    local key value
    local valid=true

    mkdir -p "$CFG_DIR"

    # Check if config file exists
    if [[ ! -f "$file" ]]; then
        log_info "generating default backup configuration" "print"
        default_backup "$file"
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
