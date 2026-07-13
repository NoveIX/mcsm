# file: src/lib/tmux/name.sh

get_session_name() {
    local name

    name="$(basename "$SERVER_ROOT" \
        | tr -d '[[:space:]]' \
        | tr -c '[[:alnum:]_.-]' '_')"

    printf '%s\n' "${name:0:16}"
}
