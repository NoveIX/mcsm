# file: src/lib/config/backup/default.sh

default_backup() {
    cat <<"EOF" > "$1"
# MCSL Backup Configuration

# Enable or disable automatic Minecraft server backups.
EnableBackup=false

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

# Number of days to retain backup files.
# Backups older than this value will be deleted automatically.
# Set to -1 to keep backups indefinitely.
# Default: 7
CleanDays=7
EOF
}
