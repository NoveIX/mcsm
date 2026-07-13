# file: src/lib/config/runtime/default.sh

default_runtime() {
    cat <<"EOF" > "$1"
# Minecraft Server Launcher Runtime Configuration

# Command used to start the Minecraft server.
# The command is executed from the server root directory.
# Supports relative or absolute paths, as well as commands with arguments.
# Examples:
#   StartCommand=java -jar server.jar nogui
#   StartCommand=run.sh
StartCommand=run.sh

# Automatically restart the server if it crashes.
# Valid values: true, false
# Default: true
CrashHandle=true

# Maximum number of restart attempts before giving up.
# Use a positive integer to limit retries.
# Use -1 for unlimited restart attempts.
# Default: 3
MaxRestart=3

# Default log mode used by runtime.
# Valid values:
#   separate - Creates dedicated log files for warnings, errors, and fatal messages.
#   combined - Writes all log messages to a single file.
# Default: separate
LogFiles=separate
EOF
}
