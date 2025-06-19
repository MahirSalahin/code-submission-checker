# =============================================================================
# Configuration File
# =============================================================================
# Central configuration for the Code Submission Checker system
# =============================================================================

# Project root directory
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." &> /dev/null && pwd)"

# Directory structure
DATA_DIR="$PROJECT_ROOT/data"
SRC_DIR="$PROJECT_ROOT/src"
LOG_DIR="$PROJECT_ROOT/logs"
SUBMISSIONS_DIR="$DATA_DIR/submissions"
REPORTS_DIR="$DATA_DIR/reports"
PROBLEMS_DIR="$DATA_DIR/problems"

# Data files
USERS_FILE="$DATA_DIR/users.txt"
LOG_FILE="$LOG_DIR/system.log"

# System settings
HASH_ALGORITHM="sha256sum"
MIN_PASSWORD_LENGTH=6
MAX_LOGIN_ATTEMPTS=3

# Supported languages and their configurations
declare -A COMPILE_COMMANDS
COMPILE_COMMANDS[c]="gcc -o {output} {input}"
COMPILE_COMMANDS[cpp]="g++ -o {output} {input}"
COMPILE_COMMANDS[cs]="mcs -out:{output}.exe {input}"
COMPILE_COMMANDS[java]="javac {input}"
COMPILE_COMMANDS[py]="# Python doesn't need compilation"

declare -A RUN_COMMANDS
RUN_COMMANDS[c]="./{output}"
RUN_COMMANDS[cpp]="./{output}"
RUN_COMMANDS[cs]="mono {output}.exe"
RUN_COMMANDS[java]="java {class_name}"
RUN_COMMANDS[py]="python3 {input}"

declare -A VALID_EXTENSIONS
VALID_EXTENSIONS[c]=".c"
VALID_EXTENSIONS[cpp]=".cpp"
VALID_EXTENSIONS[cs]=".cs"
VALID_EXTENSIONS[java]=".java"
VALID_EXTENSIONS[py]=".py"

# Export important variables
export PROJECT_ROOT DATA_DIR SRC_DIR LOG_DIR SUBMISSIONS_DIR REPORTS_DIR PROBLEMS_DIR
export USERS_FILE LOG_FILE HASH_ALGORITHM MIN_PASSWORD_LENGTH MAX_LOGIN_ATTEMPTS
