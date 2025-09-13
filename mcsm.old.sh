#!/usr/bin/env bash

show_help() {
    cat << EOF
Usage: $0 <arguments>

Commands:
  -s or --start     Start server
  -e or --exit      Stop server
  -r or --restart   Restart server
  -c or --console   Open server console
EOF
}

# Check if there is at least one argument
if [[ $# -lt 1 ]]; then
    show_help
    exit 0
fi

# color
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

INFO="[${BLUE}INFO${NC}]"
WARN="[${YELLOW}WARN${NC}]"
ERROR="[${RED}ERROR${NC}]"

# Locate script path and set dir script path
SCRIPT_DIR=$(dirname "$(realpath "$0")")
cd "$SCRIPT_DIR"

# ==========================================[ Validate ]========================================== #

# Check if tmux is installed
if ! command -v tmux &>/dev/null; then
    echo -e "$ERROR - tmux is not installed. Please install tmux to run the server."
    exit 1
fi

# Reads the session name, ignoring comments and spaces
SESSION=$(basename "$SCRIPT_DIR" | tr -d '[:space:]' | tr -c '[:alnum:]_.-' '_')

if [ -z "$SESSION" ]; then
    echo -e "$ERROR - tmux session with name  $SESSION is invalid"
    exit 1
fi

# Check full name for the session
if [[ ! "$SESSION" =~ ^[a-zA-Z0-9_.-]+$ ]]; then
    echo -e "$ERROR - tmux session with name  $SESSION contain a invalid characters"
    echo -e "Allowed characters:"
    echo -e "   Letters: a-z e A-Z"
    echo -e "   Numbers: 0-9"
    echo -e "   Symbols: -, _, ."
    exit 1
fi

# =========================================[ EULA Check ]========================================= #

EULA_FILE="eula.txt"

# Create deafult EULA
if [ ! -f "$EULA_FILE" ]; then
    cat <<EOF > "$EULA_FILE"
#By changing the setting below to TRUE you are indicating your agreement to our EULA (https://aka.ms/MinecraftEULA).
#$(date "+%a %b %d %T %Z %Y")
eula=false
EOF
fi

# Read current EULA value
EULA_ACCEPTED=$(grep -i 'eula=' "$EULA_FILE" | cut -d'=' -f2)

# Ask to accept eula
if [[ "$EULA_ACCEPTED" != "true" ]]; then
    read -p "The EULA is not accepted. Do you want to accept it now? [y/N]: " REPLY
    if [[ "$REPLY" =~ ^[Yy]$ ]]; then
        sed -i 's/eula=.*/eula=true/' "$EULA_FILE"
        echo -e "${GREEN}EULA accepted.${NC}"
    else
        echo -e "${RED}EULA not accepted. Server will not start.${NC}"
        exit 0
    fi
fi

# =======================================[ Tmux function ]======================================== #

# Check if the tmux session exists
session_exist() {
    tmux has-session -t "$SESSION" 2>/dev/null
}

# Exit if the tmux session exists
exit_if_session_exists() {
    if session_exist; then
        echo -e "$WARN - Tmux session '$SESSION' already exists."
        exit 3
    fi
}

# Exit if the tmux session is missing
exit_if_session_missing() {
    if ! session_exist; then
        echo -e "$WARN - Tmux session '$SESSION' not found."
        exit 3
    fi
}

# Wait until the tmux session is closed
wait_closing_session() {
    while session_exist; do
        sleep 1
    done
}

# ==================================[ Tmux server interaction ]=================================== #

# Start, stop and enter server functions
tmux_server_start() {
    tmux new-session -d -s "$SESSION" -c "$SCRIPT_DIR" "./run.sh"
}

tmux_server_stop() {
    tmux send-keys -t "$SESSION" "stop" ENTER
}

tmux_server_warn() {
    tmux send-keys -t "$SESSION" "say Server will restart in 30 seconds. Please prepare to disconnect." ENTER
}

tmux_server_enter() {
    tmux send-keys -t "$SESSION" ENTER
}


# =========================================[ Run server ]========================================= #

start_server() {
    # Validate if the session already exists
    exit_if_session_exists

    # Start the server in a new tmux session
    tmux_server_start
    echo -e "$INFO - Minecraft server '$SESSION' is starting..."
}

# ========================================[ Stop server ]========================================= #

stop_server() {
    local status=${1:-stop}

    # Validate if the session is missing
    exit_if_session_missing

    # Warn the players that the server will stop in 30 seconds
    tmux_server_warn
    echo -e "$INFO - Minecraft server '$SESSION' will $status in 30 seconds..."
    sleep 30

    # Clean console Debian 13
    tmux_server_enter

    # Stop the server
    tmux_server_stop
    echo -e "$INFO - Minecraft server '$SESSION' is stopping..."
}

# =======================================[ Restart server ]======================================= #

restart_server() {
    # If the session exists, stop it first
    if session_exist; then
        stop_server restart

        # Wait until the server is fully stopped
        wait_closing_session
        echo -e "$INFO - Server closed. Waiting 10 seconds before starting a new server"
        sleep 10
    fi
    start_server
}

# =======================================[ Console server ]======================================= #

open_console() {
    exit_if_session_missing
    tmux attach -t "$SESSION"
}

# ======================================[ Argument options ]====================================== #

# Gestione operazioni
case "$1" in
    -s|--start)
        start_server
    ;;
    -e|--exit)
        stop_server
    ;;
    -r|--restart)
        restart_server
    ;;
    -c|--console)
        open_console
    ;;
    -h|--help|"/?"|"-?")
        show_help
    ;;
    *)
        echo "ERROR: Unknown arguments '$1'"
        show_help
        exit 1
    ;;
esac