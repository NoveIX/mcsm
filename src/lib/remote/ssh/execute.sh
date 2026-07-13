# file: src/lib/remote/ssh/execute.sh

execute_ssh() {
    local host="$1"
    local user="$2"
    local key="$3"
    local port="$4"
    shift 4

    # Build the SSH target string
    local target="${user:+$user@}$host"

    # Execute the SSH command with the provided parameters for scripts
    ssh -o BatchMode=yes -o PasswordAuthentication=no -o KbdInteractiveAuthentication=no \
        ${port:+-p "$port"} \
        ${key:+-i "$key"} \
        "$target" \
        "$@"
}
