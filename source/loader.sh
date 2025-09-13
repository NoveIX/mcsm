#!/usr/bin/env bash

# Default library folder
lib_dir="${LIBRARY_DIR:-library}"

# Associative array to track loaded libraries
declare -A LIBS_LOADED

load_library() {
    # Load a single library
    # $1 = library name (es. directory.sh)
    # $2 = force_reload (optional, default 0)

    # Parameters
    local lib_name="$1"
    local force_reload="${2:-0}"

    # Skip if already loaded and not forcing reload
    if [[ "${LIBS_LOADED[$lib_name]}" == "1" && $force_reload -eq 0 ]]; then
        return 0
    fi

    # Check if library file exists
    local lib_path="$lib_dir/$lib_name.sh"
    if [[ ! -f "$lib_path" ]]; then
        echo "ERROR: Library $lib_name not found in $lib_dir"
        return 1
    fi

    # Load the library
    source "$lib_path"
    LIBS_LOADED[$lib_name]=1
}

load_all_libraries() {
    # Load all libraries in the library directory
    # $1 = force_reload (opzionale, default 0)

    # Parameters
    local force_reload="${1:-0}"

    # Check if library directory exists
    if [[ ! -d "$lib_dir" ]]; then
        echo "ERROR: library folder $lib_dir not found"
        return 1
    fi

    # Load each library file in the directory
    for lib_file in "$lib_dir"/*.sh; do
        [[ -f "$lib_file" ]] || continue
        local lib_name
        lib_name=$(basename "$lib_file" .sh)
        load_library "$lib_name" "$force_reload"
    done
}
