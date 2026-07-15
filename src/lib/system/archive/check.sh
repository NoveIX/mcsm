# file: src/lib/system/tools/archive/check.sh

check_archive() {
    local format="$BACKUP_FORMAT"

    case "$format" in
        zip) check_command "zip" ;;

        tar.gz|tar.xz|tar.zst)
            check_command "tar"

            case "$format" in
                tar.gz)  check_command "gzip" ;;
                tar.xz)  check_command "xz"   ;;
                tar.zst) check_command "zstd" ;;
            esac
        ;;

        *)
            log_error "unsupported backup format: $format" "print"
            return 1
        ;;
    esac

    log_info "backup format $format is supported"
    return 0
}
