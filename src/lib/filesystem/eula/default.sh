# file: src/lib/filesystem/eula/default.sh

default_eula() {
    cat <<EOF > "$1"
#By changing the setting below to TRUE you are indicating your agreement to our EULA (https://aka.ms/MinecraftEULA).
#$(date "+%a %b %d %T %Z %Y")
eula=false
EOF
}
