# file: src/lib/filesystem/eula/read.sh

import "lib.filesystem.eula.default"

read_eula() {
    local file="$1"
    local value answer

    # Check if eula file exists
    if [[ ! -f "$file" ]]; then
        log_info "generating default eula" "print"
        default_eula "$file"
    fi

    # Read the eula value from the file
    value=$(grep -E '^[[:space:]]*eula[[:space:]]*=' "$file" \
        | tail -n 1 \
        | cut -d'=' -f2 \
    | tr -d '[:space:]')

    # Default if missing
    [[ -z "$value" ]] && value="false"

    # Check if the eula is accepted
    if [[ "$value" != "true" ]]; then
        read -r -p "The EULA is not accepted. Accept it now? [y/N]: " answer

        if [[ "${answer,,}" == "y" ]]; then
            # ensure file exists
            touch "$file"

            # Update or add eula=true in the file
            if grep -q '^[[:space:]]*eula[[:space:]]*=' "$file"; then
                sed -i 's/^[[:space:]]*eula[[:space:]]*=.*/eula=true/' "$file"
            else
                printf '%s\n' "eula=true" >> "$file"
            fi

            # Log EULA acceptance and return success
            log_info "EULA accepted by user"
            return 0
        fi

        # Log EULA rejection and return failure
        log_warn "EULA not accepted by user. Server will not start" "print"
        return 1
    fi

    # Log EULA is already accepted and return success
    log_info "EULA already accepted"
    return 0
}
