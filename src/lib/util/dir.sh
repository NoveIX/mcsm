# file: src/lib/util/dir.sh

new_dir() {
    [[ ! -d "$1" ]] && mkdir -p "$1"
}
