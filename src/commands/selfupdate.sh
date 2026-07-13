# file: src/commands/selfupdate.sh

# ================================[ Command ]================================= #

selfupdate() {
    local session="$1"
    local all="$2"

    # =================================[ invoke ]================================= #

    if [[ "$all" == "true" || "$session" != "$SESSION_NAME" ]]; then
        import "lib.remote.invoke"

        # Call command in the specified session or all sessions
        if [[ "$all" == "true" ]]; then
            invoke_sessions selfupdate
        else
            invoke_session "$session" selfupdate
        fi

        return 0
    fi

    # ===============================[ execution ]================================ #

    # Import required module
    import "lib.core.command"
    import "commands.version"

    # Check required dependencies
    check_command "git"

    # Get mcsl current version
    local old_version=$(get_version)

    # restore mcsl dir
    log_info "check for mcsl updates" "print"
    git -C "$MCSL_DIR" restore -- .

    local output=$(git -C "$MCSL_DIR" pull 2>&1)
    local status=$?

    # Check git pull exit code
    if [[ "${status:-1}" -eq 0 ]]; then

        # Check if version file exists
        if [[ -f "$VERSION_FILE" ]]; then
            local new_version
            new_version=$(get_version)

            # Check different version
            if [[ "$old_version" != "$new_version" ]]; then
                print "mcsl update completed" "info"; print
                print_version
            else
                print "mcsl is already running the latest version" "info"
            fi
        fi
    else
        log_error "mcsl update failed" "print"
        printf '%s\n' "$output"
    fi

    chmod u+rwx,g+rw,o+r "$MCSL_DIR/$MCSL_NAME"
}
