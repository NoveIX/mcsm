#!/usr/bin/env bash

# File: import.sh
# Description: Import function for bash scripts
# Author: NoveIX
# SPDX-License-Identifier: GPL-3.0-or-later

# ================================[ Function ]================================ #

declare -A LOADED_FILES

import() {
    local ns="$1"

    # Check mandatory parameters
    if [[ -z "$ns" ]]; then
        printf 'import: missing required parameter: ns\n'
        return 1
    fi

    # convert module.tmux.wait → module/tmux/wait.sh
    local fx="${ns//./\/}.sh"

    # Check if the module file exists
    if [[ ! -f "$fx" ]]; then
        printf 'import: module not found: %s\n' "$fx"
        return 1
    fi

    # Check if the module has already been loaded
    if [[ "${LOADED_FILES["$fx"]:-}" == 1 ]]; then
        return 0
    fi

    # shellcheck source=/dev/null
    if ! source "$fx"; then
        printf 'import: failed to load: %s\n' "$fx"
        return 1
    fi

    LOADED_FILES["$fx"]=1
}

#reset_loaded() {
#    unset LOADED_FILES
#    declare -gA LOADED_FILES
#}
