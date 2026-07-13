# file: src/commands/status.sh

# ================================[ Command ]================================= #

status_server() {
    local session="$1"
    local host="$2"
    local port="$3"
    local all="$4"

    # =================================[ invoke ]================================= #

    if [[ "$all" == "true" || "$session" != "$SESSION_NAME" ]]; then
        import "lib.remote.invoke"

        # Call command in the specified session or all sessions
        if [[ "$all" == "true" ]]; then
            invoke_sessions status
        else
            invoke_session "$session" status
        fi

        return 0
    fi

    # ===============================[ execution ]================================ #

    # Function var
    local address="$host"

    # Color var
    local red="\033[31m"
    local blue="\033[94m"
    local green="\033[32m"
    local reset="\033[0m"

    # Status var
    local dot="${red}●${reset}"
    local online="${green}Online${reset}"
    local offline="${red}Offline${reset}"
    local uptime="${blue}Uptime${reset}: N/A"

    # If localhost -> read port from server.properties
    if [[ "$host" == "127.0.0.1" || "$host" == "localhost" ]]; then
        import "lib.tmux.exists.session"
        import "lib.filesystem.get"
        import "lib.util.convert.second"

        # Check if session exist
        exists_tmux_session "$SESSION_NAME" && dot="${green}●${reset}"

        # Get server port
        port=$(get_property "$SERVER_ROOT/server.properties" "server-port") || true
        address="$session"

        # Get server uptime
        if [[ -f "$UPTIME_TIMESTAMP" ]]; then
            local sts

            read -r sts < "$UPTIME_TIMESTAMP"
            uptime="${blue}Uptime${reset}: $(convert_seconds "$(( $(date +%s) - sts ))")"
        fi
    fi

    # Prepare message
    [[ -n "$port" && "$port" != "25565" ]] && address="$address:$port"

    # Check TCP connectivity
    if timeout 3 bash -c "</dev/tcp/$host/$port" 2>/dev/null; then
        printf '%b %-20s %-10b  | %b\n' "$dot" "$address" "$online" "$uptime"
        return 0
    fi

    printf '%b %-20s %-10b | %b\n' "$dot" "$address" "$offline" "$uptime"
    return 0
}
