# file: src/lib/filesystem/wait.sh

wait_pattern() {
    local file="$1"
    local pattern="$2"
    local timeout="${3:-300}" # default: 5 minutes
    local elapsed=0

    while (( elapsed < timeout )); do
        tail -n 0 -F "$file" 2>/dev/null | grep -q --line-buffered "$pattern" && return 0

        sleep 1
        ((elapsed++)) || true
    done

    return 1
}
