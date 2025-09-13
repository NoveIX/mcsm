#!/usr/bin/env bash

# ===========================================[ Color ]============================================ #

# color
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# ========================================[ Lib function ]======================================== #

# Core log function
log_message() {
    local level="$1"
    local msg="$2"
    local timestamp=$(date '+%H:%M:%S')
    echo "[$timestamp] [$level] - $msg" >> "$LOG_FILE"
}

# Simple wrappers
log_info()  { log_message "INFO" "$1"; }
log_warn()  { log_message "WARN" "$1"; }
log_error() { log_message "ERROR" "$1"; }

# Crash script
log_mcsm_info() { log_message "tmux/INFO" "$1"; }
log_mcsm_warn() { log_message "tmux/WARN" "$1"; }
log_mcsm_error() { log_message "tmux/ERROR" "$1"; }

# Console + file
log_info_cli()  { echo -e "[${BLUE}INFO${NC}] - $1"; log_message "INFO" "$1"; }
log_warn_cli()  { echo -e "[${YELLOW}WARN${NC}] - $1"; log_message "WARN" "$1"; }
log_error_cli() { echo -e "[${RED}ERROR${NC}] - $1"; log_message "ERROR" "$1"; }