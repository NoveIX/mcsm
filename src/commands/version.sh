# file: src/commands/version.sh

get_version() {
    # Extract version by removing ONLY carriage returns, preserving all spaces
    local version
    if ! IFS= read -r version < "$VERSION_FILE";then
        log_error "failed to read version from $VERSION_FILE" "print" "err"
        printf '%s\n' "unknown"
        return 0
    fi

    # Print the version string, stripping the \r if present
    printf '%s\n' "${version//$'\r'/}"
}

print_version() {
    # Get version from file
    local version=$(get_version)

    cat <<EOF
Minecraft Server Launcher (MCSL)
Version: $version
EOF
}
