# file: src/lib/filesystem/remove.sh

remove_files() {
    local file="$1"
    local name="$2"

    # return 0 if file does not exist
    [[ ! -f "$file" ]] && return 0

    # Remove restartctl file
    if rm -f "$file"; then
        log_info "removed $name: $file"
        return 0
    fi

    log_error "remove $name failed: cannot remove file: $file" "print"
    return 1
}
