# file: src/lib/system/backup.sh

check_backup() {
    case "${1,,}" in
        zip)
            check_command "zip" || return 1
        ;;

        tar.gz)
            check_command "tar" || return 1
            check_command "gzip" || return 1
        ;;

        tar.xz)
            check_command "tar" || return 1
            check_command "xz" || return 1
        ;;

        tar.zst)
            check_command "tar" || return 1
            check_command "zstd" || return 1
        ;;

        *)
            log_error "unsupported backup format: ${1,,}" "print"
            return 1
        ;;
    esac

    return 0
}
