# file: src/lib/config/backup/default.sh

default_backup() {
    cat <<"EOF" > "$1"
# Minecraft Server Launcher Backup Configuration

# Enable or disable automatic backups for the Minecraft server.
EnableBackup=false

# Backup archive format
# Supported: zip, tar.gz, tar.xz, tar.zst
# Required tools:
#   zip:     zip command-line utility (included in most systems)
#   tar.gz:  tar with gzip support (requires gzip installed)
#   tar.xz:  tar with xz support   (requires xz-utils installed)
#   tar.zst: tar with zstd support (requires zstd installed)
BackupFormat=zip

# Backup delay in minutes.
BackupDelay=30
EOF
}
