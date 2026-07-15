# file: src/lib/filesystem/delete.sh

cleanup_backup() {
    local dir="$1"
    local keep="$2"
    local format="$3"

    # Keep all backups
    [[ "$keep" == "-1" ]] && return 0

    # Check if backup directory exists
    if [[ ! -d "$dir" ]]; then
        log_error "backup directory not found: $dir" "print"
        return 1
    fi

    # List backups sorted by modification time (oldest first)
    local -a files
    mapfile -t files < <(
        find "$dir" -maxdepth 1 -type f -name "*.$format" \
            -printf '%T@ %p\n' |
        sort -n |
        cut -d' ' -f2-
    )

    # Check if there are files to delete
    local count="${#files[@]}"
    [[ "$count" -le "$keep" ]] && return 0

    # Calculate how many files to remove and delete them
    local remove=$((count - keep))
    for ((i=0; i<remove; i++)); do
        if rm -f "${files[$i]}"; then
            log_info "removed old backup: ${files[$i]}"
        else
            log_error "failed to remove backup: ${files[$i]}" "print"
        fi
    done
}
