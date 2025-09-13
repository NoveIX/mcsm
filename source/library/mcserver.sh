#!/usr/bin/env bash

# =======================================[ EULA function ]======================================== #

# Create a default EULA file
create_deafult_eula() {
    cat <<EOF > "$EULA_FILE"
#By changing the setting below to TRUE you are indicating your agreement to our EULA (https://aka.ms/MinecraftEULA).
#$(date "+%a %b %d %T %Z %Y")
eula=false
EOF
}

# Ask user to accept EULA if not already accepted
read_eula() {
    # Read current EULA value
    local eula_value=$(grep -i 'eula=' "$EULA_FILE" | cut -d'=' -f2)

    # Ask to accept EULA
    if [[ "$eula_value" != "true" ]]; then
        read -p "The EULA is not accepted. Do you want to accept it now? [y/N]: " REPLY
        if [[ "$REPLY" =~ ^[Yy]$ ]]; then
            sed -i 's/eula=.*/eula=true/' "$EULA_FILE"
            echo -e "EULA accepted"
            log_info "EULA accepted by user"
        else
            echo -e "EULA not accepted. Server will not start"
            log_warn "EULA not accepted by user. Exiting"
            exit 0
        fi
    else
        log_info "EULA already accepted"
    fi
}

# EULA Handle
eula_handle() {
    if [[ ! -f "$EULA_FILE" ]]; then
        create_deafult_eula "$EULA_FILE"
        log_info "Created default EULA file $EULA_FILE"
    else
        log_info "EULA file found $EULA_FILE"
    fi

    read_eula "$EULA_FILE"
}


# =======================================[ Main function ]======================================== #


# Start the Minecraft server
start_minecraft_server() {
    if [[ "$CrashHandle" == "true" ]]; then
        git_handle
    fi

    eula_handle
    check_session_name
    exit_if_session_exists
    tmux_server_start
}

stop_minecraft_server() {
    local status=${1:-shutdown}

    exit_if_session_missing

    if [[ "$status" == "shutdown" ]]; then
        tmux_server_shutdown_player_warn
        sleep 30
    fi

    if [[ "$status" == "restart" ]]; then
        tmux_server_restart_player_warn
        sleep 30
    fi

    tmux_server_enter # Only for Debain 13
    tmux_server_stop
}

# Restart server
restart_minecraft_server() {
    if session_exist; then
        stop_minecraft_server restart
        wait_closing_session
    fi
    start_minecraft_server
}

# Open server console
open_minecraft_server_console() {
    exit_if_session_missing
    tmux_attach_server
}