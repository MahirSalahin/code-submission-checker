# =============================================================================
# User Interface Utilities
# =============================================================================
# Functions for creating a professional CLI interface
# =============================================================================

# Color definitions
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[0;37m'
GRAY='\033[0;90m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# =============================================================================
# Display Functions
# =============================================================================

# Clear screen function
clear_screen() {
    clear
}

# Show application header
show_header() {
    local title="$1"
    local width=80
    
    echo
    printf "${CYAN}%*s${NC}\n" $width | tr ' ' '='
    printf "${CYAN}%*s${NC}\n" $(((${#title}+$width)/2)) "$title"
    printf "${CYAN}%*s${NC}\n" $width | tr ' ' '='
    echo
}

# Show welcome screen
show_welcome() {
    clear_screen
    
    cat << 'EOF'
 ██████╗ ██████╗ ██████╗ ███████╗    ██████╗██╗  ██╗███████╗ ██████╗██╗  ██╗███████╗██████╗ 
██╔════╝██╔═══██╗██╔══██╗██╔════╝   ██╔════╝██║  ██║██╔════╝██╔════╝██║ ██╔╝██╔════╝██╔══██╗
██║     ██║   ██║██║  ██║█████╗     ██║     ███████║█████╗  ██║     █████╔╝ █████╗  ██████╔╝
██║     ██║   ██║██║  ██║██╔══╝     ██║     ██╔══██║██╔══╝  ██║     ██╔═██╗ ██╔══╝  ██╔══██╗
╚██████╗╚██████╔╝██████╔╝███████╗   ╚██████╗██║  ██║███████╗╚██████╗██║  ██╗███████╗██║  ██║
 ╚═════╝ ╚═════╝ ╚═════╝ ╚══════╝    ╚═════╝╚═╝  ╚═╝╚══════╝ ╚═════╝╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝
EOF
    
    echo -e "${CYAN}===============================================================================${NC}"
    echo -e "${YELLOW}                    Automated Code Submission Checker${NC}"
    echo -e "${YELLOW}                        CUET CSE Department${NC}"
    echo -e "${CYAN}===============================================================================${NC}"
    echo
    echo -e "${GREEN}Welcome to the Code Submission Checker System!${NC}"
    echo -e "${WHITE}A comprehensive solution for automated code evaluation and grading.${NC}"
    echo
    echo -e "${CYAN}Supported Languages:${NC} C, C++, C#, Java, Python"
    echo -e "${CYAN}Features:${NC} Automated Testing, Batch Processing, Detailed Reports"
    echo
    echo -e "${CYAN}===============================================================================${NC}"
    echo
}

# Show main menu
show_main_menu() {
    echo -e "${CYAN}Please choose an option:${NC}"
    echo -e "${YELLOW}1.${NC} Sign In"
    echo -e "${YELLOW}2.${NC} Sign Up"
    echo -e "${YELLOW}3.${NC} Exit"
    echo
}

# Show message with different types
show_message() {
    local message="$1"
    local type="${2:-info}"
    
    case $type in
        "success")
            echo -e "${GREEN}✓ $message${NC}"
            ;;
        "error")
            echo -e "${RED}✗ $message${NC}"
            ;;
        "warning")
            echo -e "${YELLOW}⚠ $message${NC}"
            ;;
        "info")
            echo -e "${CYAN}ℹ $message${NC}"
            ;;
        *)
            echo -e "${WHITE}$message${NC}"
            ;;
    esac
}

# Show loading animation
show_loading() {
    local message="$1"
    local duration="${2:-2}"
    
    echo -n -e "${CYAN}$message${NC}"
    
    for i in $(seq 1 $duration); do
        for j in $(seq 1 3); do
            echo -n "."
            sleep 0.3
        done
        echo -n -e "\b\b\b   \b\b\b"
    done
    echo
}

# Show progress bar
show_progress() {
    local current="$1"
    local total="$2"
    local width=50
    local percentage=$((current * 100 / total))
    local filled=$((current * width / total))
    local empty=$((width - filled))
    
    printf "\r${CYAN}Progress: [${NC}"
    printf "%*s" $filled | tr ' ' '█'
    printf "%*s" $empty | tr ' ' '░'
    printf "${CYAN}] %d%% (%d/%d)${NC}" $percentage $current $total
}

# Show separator line
show_separator() {
    local char="${1:--}"
    local width="${2:-80}"
    printf "${CYAN}%*s${NC}\n" $width | tr ' ' "$char"
}

# Show box with text
show_box() {
    local text="$1"
    local color="${2:-$CYAN}"
    local width=$((${#text} + 4))
    
    echo -e "${color}┌$(printf '%*s' $((width-2)) | tr ' ' '─')┐${NC}"
    echo -e "${color}│ $text │${NC}"
    echo -e "${color}└$(printf '%*s' $((width-2)) | tr ' ' '─')┘${NC}"
}

# Pause function
pause() {
    local message="${1:-Press any key to continue...}"
    echo
    read -n 1 -s -r -p "$(echo -e "${YELLOW}$message${NC}")"
    echo
}

# =============================================================================
# Input Functions with ESC Detection
# =============================================================================

# Read input with ESC key detection
# Returns 1 if ESC was pressed, 0 if normal input
read_with_esc() {
    local prompt="$1"
    local var_name="$2"
    local is_password="${3:-false}"
    local input=""
    local char=""
    
    echo -n -e "$prompt"
    
    # Read character by character to detect ESC
    while true; do
        read -s -n1 char
        
        # Check for ESC key (ASCII 27)
        if [[ $(printf "%d" "'$char") -eq 27 ]] 2>/dev/null; then
            echo
            echo -e "${YELLOW}✓ Returning to previous menu...${NC}"
            sleep 0.5
            return 1  # ESC was pressed
        fi
        
        # Check for Enter key (empty char)
        if [[ -z "$char" ]]; then
            echo
            break
        fi
        
        # Check for backspace (ASCII 127 or 8)
        if [[ $(printf "%d" "'$char") -eq 127 ]] 2>/dev/null || [[ $(printf "%d" "'$char") -eq 8 ]] 2>/dev/null; then
            if [[ ${#input} -gt 0 ]]; then
                input="${input%?}"  # Remove last character
                echo -n -e "\b \b"  # Move back, print space, move back again
            fi
            continue
        fi
        
        # Add character to input
        input="$input$char"
        
        # Display character (or * for password)
        if [[ "$is_password" == "true" ]]; then
            echo -n "*"
        else
            echo -n "$char"  # Echo the character for normal input
        fi
    done
    
    # Set the variable using indirect assignment
    eval "$var_name=\"\$input\""
    return 0
}

# Simplified wrapper for normal input with ESC
read_input_esc() {
    local prompt="$1"
    local var_name="$2"
    
    if read_with_esc "$prompt" "$var_name" "false"; then
        return 0  # Normal input
    else
        return 1  # ESC pressed
    fi
}

# Simplified wrapper for password input with ESC
read_password_esc() {
    local prompt="$1"
    local var_name="$2"
    
    if read_with_esc "$prompt" "$var_name" "true"; then
        return 0  # Normal input
    else
        return 1  # ESC pressed
    fi
}

# =============================================================================
# Alternative Input Functions for File Paths
# =============================================================================

# Simple read function for file paths (more reliable than character-by-character)
read_file_path() {
    local prompt="$1"
    local var_name="$2"
    local input=""
    
    echo -e "${YELLOW}💡 Press Ctrl+C to cancel${NC}"
    echo -n -e "$prompt"
    
    # Use regular read for better file path input
    if ! read -r input; then
        # Ctrl+C was pressed
        echo
        echo -e "${YELLOW}✓ Cancelled...${NC}"
        sleep 0.5
        return 1
    fi
    
    # Set the variable using indirect assignment
    eval "$var_name=\"\$input\""
    return 0
}