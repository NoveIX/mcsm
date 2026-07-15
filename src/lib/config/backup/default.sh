# file: src/lib/config/backup/default.sh

default_backup() {
    cat <<"EOF" > "$1"
# MCSL Backup Configuration

# Enable or disable automatic Minecraft server backups.
BackupEnabled=false

# Backup archive format.
# Supported: zip, tar.gz, tar.xz, tar.zst
# Required tools:
#   zip:     zip command-line utility (included in most systems)
#   tar.gz:  tar with gzip support (requires gzip)
#   tar.xz:  tar with xz support (requires xz-utils)
#   tar.zst: tar with zstd support (requires zstd)
# Default: zip
BackupFormat=zip

# Backup interval in minutes.
# Default: 30
BackupDelay=30

# Maximum number of backups to keep.
# Older backups are removed automatically.
# Set to -1 to keep backups indefinitely.
# Default: 5
KeepLast=5
EOF
}
