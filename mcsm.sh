#!/usr/bin/env bash

show_help() {
    cat << EOF
Usage: $0 <arguments>

Commands:
  -s or --start     Start server
  -e or --exit      Stop server
  -r or --restart   Restart server
  -c or --console   Open server console
  --mcsm-update      Update mcsm folder
EOF
}

# Check if there is at least one argument
if [[ -z "$1" ]]; then
    show_help
    exit 0
fi

# ======================================[ Global parameter ]====================================== #

# Self defined parameter
CURRENT_DATE=$(date '+%Y-%m-%d')                # today
SCRIPT_ROOT=$(dirname "$(realpath "$0")")       # $HOME/modpack/mcsm

# Path
MODPACK_DIR=$(dirname "$SCRIPT_ROOT")           # $HOME/modpack
MCSM_DIR="$SCRIPT_ROOT"                         # $HOME/modpack/mcsm
LOG_DIR="$MCSM_DIR/logs"                        # $HOME/modpack/mcsm/logs
CONFIG_DIR="$MCSM_DIR/config"                   # $HOME/modpack/mcsm/config
SOURCE_DIR="$MCSM_DIR/source"                   # $HOME/modpack/mcsm/source
LIBRARY_DIR="$SOURCE_DIR/library"               # $HOME/modpack/mcsm/source/library
SCRIPT_DIR="$SOURCE_DIR/script"                 # $HOME/modpack/mcsm/source/script
KEY_DIR="$MCSM_DIR/key"                         # $HOME/modpack/mcsm/key
TEMP_DIR="$MCSM_DIR/temp"                       # $HOME/modpack/mcsm/temp

#File
LOG_FILE="$LOG_DIR/mcsm_$CURRENT_DATE.log"      # $HOME/modpack/mcsm/logs/mcsm_YYYY-MM-DD.log
LOG_MCSM_FILE="$LOG_DIR/server_crash.log"       # $HOME/modpack/mcsm/logs/server_crash.log
CONFIG_FILE="$CONFIG_DIR/mcsm-common.toml"      # $HOME/modpack/mcsm/config/mcsm-common.toml
LOADER_FILE="$SOURCE_DIR/loader.sh"             # $HOME/modpack/mcsm/source/loader.sh
RUN_SERVER_FILE="$SCRIPT_DIR/run_server.sh"     # $HOME/modpack/mcsm/source/script/run_server.sh
KEY_FILE_PUBLIC="$KEY_DIR/modpack_readonly.pub" # $HOME/modpack/mcsm/keys/modpack_readonly.pub
KEY_FILE_PRIVATE="$KEY_DIR/modpack_readonly"    # $HOME/modpack/mcsm/keys/modpack_readonly
VALIDATE_TEMP_FILE="$TEMP_DIR/validate.txt"     # $HOME/modpack/mcsm/temp/validate.txt
RESTART_TEMP_FILE="$TEMP_DIR/restart.txt"       # $HOME/modpack/mcsm/temp/restart.txt
CONFIG_TEMP_FILE="$TEMP_DIR/config.txt"         # $HOME/modpack/mcsm/temp/config.txt

# Minecraft file
EULA_FILE="$MODPACK_DIR/eula.txt"               # $HOME/modpack/eula.txt
SESSION_NAME=$(basename "$MODPACK_DIR" | tr -d '[:space:]' | tr -c '[:alnum:]_.-' '_') # Session name for tmux (es. modpack)

# =====================================[ Validate directory ]===================================== #

if [[ ! -d "$CONFIG_DIR" ]]; then
    echo "ERROR: config directory not found: $CONFIG_DIR"
    exit 1
fi

if [[ ! -d "$SOURCE_DIR" ]]; then
    echo "ERROR: source directory not found: $SOURCE_DIR"
    exit 1
fi

if [[ ! -d "$LIBRARY_DIR" ]]; then
    echo "ERROR: library directory not found: $LIBRARY_DIR"
    exit 1
fi

if [[ ! -d "$SCRIPT_DIR" ]]; then
    echo "ERROR: script directory not found: $SCRIPT_DIR"
    exit 1
fi

if [[ ! -f $LOADER_FILE ]]; then
    echo "ERROR: loader file not found: $LOADER_FILE"
    exit 1
fi

mkdir -p "$LOG_DIR"

# ===========================================[ Loader ]=========================================== #

source "$LOADER_FILE"
load_all_libraries

# =====================================[ Validate software ]====================================== #

if [[ ! -d "$TEMP_DIR" ]]; then
    mkdir -p "$TEMP_DIR"
    log_info "Created temp directory: $TEMP_DIR"
fi

if [[ ! -f $VALIDATE_TEMP_FILE ]]; then
    validate_software
fi

# ========================================[ Server config ]======================================= #

source "$CONFIG_FILE"

if ! parse_toml $CONFIG_FILE; then
    log_error "Failed to parse config file. Exiting"
    exit 1
fi

# =======================================[ Server script ]======================================== #

# Operation management
case "$1" in
    -s|--start)
        start_minecraft_server
    ;;
    -e|--exit)
        stop_minecraft_server
    ;;
    -r|--restart)
        restart_minecraft_server
    ;;
    -c|--console)
        open_minecraft_server_console
    ;;
    --mcsm-update)
        mcsm_update
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