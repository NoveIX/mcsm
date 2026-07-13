# file: src/lib/remote/ssh/test.sh

import "lib.remote.ssh.execute"

test_ssh() {
    local host="$1"
    local user="$2"
    local key="$3"
    local port="$4"

    # simple SSH connectivity test
    execute_ssh "$host" "$user" "$key" "$port" ":" >/dev/null 2>&1
}
