# file: src/lib/config/backup/read.sh

import "lib.config.backup.default"
import "lib.util.trim"

read_backup() {
    local file="$BACKUP_CONF"
    local key value

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
            BackupEnabled) BACKUP_ENABLED="${value,,}" ;;
            BackupFormat)  BACKUP_FORMAT="${value,,}"  ;;
            BackupDelay)   BACKUP_DELAY="$value"       ;;
            KeepLast)      KEEP_LAST="$value"          ;;
            *)
                log_warn "ignored unknown key: $key"
            ;;
        esac
    done < "$file"

    # Validate required config
    if [[ ! "$BACKUP_ENABLED" =~ ^(true|false)$ ]]; then
        log_error "invalid EnableBackup: $BACKUP_ENABLED (expected: true|false)" "print"
        return 1
    fi

    # Validate optional configs
    BACKUP_FORMAT="${BACKUP_FORMAT:-zip}"
    BACKUP_DELAY="${BACKUP_DELAY:-30}"
    KEEP_LAST="${KEEP_LAST:-5}"

    if [[ "$BACKUP_ENABLED" == "true" ]]; then
        case "$BACKUP_FORMAT" in
            zip|tar.gz|tar.bz2|tar.xz|tar.zst) ;;
            *) log_warn "invalid BackupFormat: $BACKUP_FORMAT (expected: zip, tar.gz, tar.bz2, tar.xz, or tar.zst)" ;;
        esac
        [[ "$BACKUP_DELAY" =~ ^([0-9]+)$ ]] || log_warn "invalid BackupDelay: $BACKUP_DELAY (expected: positive integer)" "print"
        [[ "$KEEP_LAST" =~ ^(-1|[0-9]+)$ ]] || log_warn "invalid KeepLast: $KEEP_LAST (expected: positive integer or -1)" "print"
    fi

    log_info "backup configuration loaded"
}
