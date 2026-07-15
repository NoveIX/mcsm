# file: src/lib/filesystem/create.sh

create_file() {
    local file="$1"
    local name="$2"
    local value="${3:-}"

    # Ensure cfg dir
    [[ ! -d "$(dirname $file)" ]] && mkdir -p "$(dirname $file)"

    # ensure restart/keep-alive file exists
    if printf '%s\n' "$value" > "$file"; then
        log_info "created $name: $file"
        return 0
    fi

    log_error "create $name failed: cannot write file: $file" "print"
    return 1
}
