#!/bin/bash

# =============================================================================
# Code Submission Checker - Main Entry Point
# =============================================================================
# Author: Mahir Salahin
# Description: Interactive CLI for automated code submission checking
# =============================================================================

set -euo pipefail

# Get the directory where the script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"

# Source configuration and utility files
source "$SCRIPT_DIR/src/config/config.sh"
source "$SCRIPT_DIR/src/utils/ui.sh"
source "$SCRIPT_DIR/src/auth/auth.sh"
source "$SCRIPT_DIR/src/problems/problems.sh"
source "$SCRIPT_DIR/src/problems/submissions.sh"
source "$SCRIPT_DIR/src/teachers/problems.sh"
source "$SCRIPT_DIR/src/teachers/reports.sh"

# =============================================================================
# Main Function
# =============================================================================
main() {
    # Initialize directories and files
    init_system
    
    # Show welcome screen
    show_welcome
    
    # Main authentication loop
    while true; do
        show_main_menu
        read -p "$(echo -e "${CYAN}Enter your choice: ${NC}")" choice
        
        case $choice in
            1)
                handle_signin
                ;;
            2)
                handle_signup
                ;;
            3)
                clear_screen
                show_message "Thank you for using Code Submission Checker!" "info"
                exit 0
                ;;
            *)
                show_message "Invalid choice. Please select 1, 2, or 3." "error"
                ;;
        esac
    done
}

# =============================================================================
# System Initialization
# =============================================================================
init_system() {
    # Create necessary directories
    mkdir -p "$DATA_DIR"
    mkdir -p "$LOG_DIR"
    mkdir -p "$SUBMISSIONS_DIR"
    mkdir -p "$REPORTS_DIR"
    mkdir -p "$PROBLEMS_DIR"
    
    # Create data files if they don't exist
    touch "$USERS_FILE"
    touch "$LOG_FILE"
    
    # Set proper permissions
    chmod 600 "$USERS_FILE"
    chmod 644 "$LOG_FILE"
}

# =============================================================================
# Authentication Handlers
# =============================================================================
handle_signin() {
    clear_screen
    show_header "SIGN IN - Press ESC to go back"
    
    echo
    
    local username password
    
    # Get username with ESC detection
    if ! read_input_esc "${CYAN}Username: ${NC}" username; then
        clear_screen
        return  # ESC was pressed
    fi
    
    # Check if username is empty
    if [[ -z "$username" ]]; then
        show_message "Username cannot be empty!" "error"
        sleep 2
        return
    fi
    
    # Get password with ESC detection
    if ! read_password_esc "${CYAN}Password: ${NC}" password; then
        clear_screen
        return  # ESC was pressed
    fi
    echo
    
    # Check if password is empty
    if [[ -z "$password" ]]; then
        show_message "Password cannot be empty!" "error"
        sleep 2
        return
    fi
    
    if signin_user "$username" "$password"; then
        local role
        role=$(get_user_role "$username")
        show_message "Sign-in successful! Welcome, $username" "success"
        sleep 1
        
        case $role in
            "student")
                show_student_menu "$username"
                ;;
            "teacher")
                show_teacher_menu "$username"
                ;;
        esac
    else
        show_message "Invalid username or password!" "error"
        sleep 2
        clear_screen
    fi
}

handle_signup() {
    clear_screen
    show_header "SIGN UP"
    
    echo -e "${CYAN}Select your role:${NC}"
    echo -e "${YELLOW}1.${NC} Student"
    echo -e "${YELLOW}2.${NC} Teacher"
    echo -e "${YELLOW}3.${NC} Back to main menu"
    echo
    
    read -p "$(echo -e "${CYAN}Enter your choice: ${NC}")" role_choice
    
    case $role_choice in
        1)
            signup_student
            ;;
        2)
            signup_teacher
            ;;
        3)
            clear_screen
            return
            ;;
        *)
            show_message "Invalid choice. Please select 1, 2, or 3." "error"
            sleep 2
            ;;
    esac
}

signup_student() {
    clear_screen
    show_header "STUDENT REGISTRATION - Press ESC to go back"
    
    echo
    
    local student_id
    
    # Get student ID with ESC detection
    echo -e "${CYAN}Enter your Student ID (this will be your username):${NC}"
    if ! read_input_esc "Student ID: " student_id; then
        clear_screen
        return  # ESC was pressed
    fi
    
    if [[ -z "$student_id" ]]; then
        show_message "Student ID cannot be empty!" "error"
        sleep 2
        clear_screen
        return
    fi
    
    if user_exists "$student_id"; then
        show_message "Student ID already registered!" "error"
        sleep 2
        clear_screen
        return
    fi
    
    echo -e "${CYAN}Create a password:${NC}"
    local password confirm_password
    
    if ! read_password_esc "Password: " password; then
        clear_screen
        return  # ESC was pressed
    fi
    echo
    
    if ! read_password_esc "Confirm Password: " confirm_password; then
        clear_screen
        return  # ESC was pressed
    fi
    echo
    
    if [[ "$password" != "$confirm_password" ]]; then
        show_message "Passwords do not match!" "error"
        sleep 2
        clear_screen
        return
    fi
    
    if [[ ${#password} -lt 6 ]]; then
        show_message "Password must be at least 6 characters long!" "error"
        sleep 2
        clear_screen
        return
    fi
    
    if register_user "$student_id" "student" "$password"; then
        show_message "Student registration successful! You can now sign in." "success"
        log_action "REGISTER" "$student_id" "Student registered successfully"
        sleep 2
        clear_screen
    else
        show_message "Registration failed. Please try again." "error"
        sleep 2
        clear_screen
    fi
}

signup_teacher() {
    clear_screen
    show_header "TEACHER REGISTRATION - Press ESC to go back"
    
    echo
    
    local username
    
    # Get username with ESC detection
    echo -e "${CYAN}Enter your username:${NC}"
    if ! read_input_esc "Username: " username; then
        clear_screen
        return  # ESC was pressed
    fi
    
    if [[ -z "$username" ]]; then
        show_message "Username cannot be empty!" "error"
        sleep 2
        clear_screen
        return
    fi
    
    if user_exists "$username"; then
        show_message "Username already taken!" "error"
        sleep 2
        clear_screen
        return
    fi
    
    echo -e "${CYAN}Create a password:${NC}"
    local password confirm_password
    
    if ! read_password_esc "Password: " password; then
        clear_screen
        return  # ESC was pressed
    fi
    echo
    
    if ! read_password_esc "Confirm Password: " confirm_password; then
        clear_screen
        return  # ESC was pressed
    fi
    echo
    
    if [[ "$password" != "$confirm_password" ]]; then
        show_message "Passwords do not match!" "error"
        sleep 2
        clear_screen
        return
    fi
    
    if [[ ${#password} -lt 6 ]]; then
        show_message "Password must be at least 6 characters long!" "error"
        sleep 2
        clear_screen
        return
    fi
    
    if register_user "$username" "teacher" "$password"; then
        show_message "Teacher registration successful! You can now sign in." "success"
        log_action "REGISTER" "$username" "Teacher registered successfully"
        sleep 2
        clear_screen
    else
        show_message "Registration failed. Please try again." "error"
        sleep 2
        clear_screen
    fi
}

# =============================================================================
# User Menu Systems
# =============================================================================
show_student_menu() {
    local username="$1"
    
    while true; do
        clear_screen
        show_header "STUDENT DASHBOARD - Welcome, $username"
        
        echo -e "${CYAN}What would you like to do?${NC}"
        echo -e "${YELLOW}1.${NC} Browse Problems"
        echo -e "${YELLOW}2.${NC} Submit Solution"
        echo -e "${YELLOW}3.${NC} My Submissions"
        echo -e "${YELLOW}4.${NC} Sign Out"
        echo
        
        read -p "$(echo -e "${CYAN}Enter your choice: ${NC}")" choice
          case $choice in
            1)
                browse_problems "$username"
                ;;
            2)
                submit_solution "$username"
                ;;            3)
                show_my_submissions "$username"
                ;;
            4)
                log_action "SIGNOUT" "$username" "Student signed out"
                show_message "Signed out successfully!" "success"
                sleep 1
                clear_screen
                return
                ;;
            *)
                show_message "Invalid choice. Please select 1, 2, 3, or 4." "error"
                ;;
        esac
    done
}

show_teacher_menu() {
    local username="$1"
    
    while true; do
        clear_screen
        show_header "TEACHER DASHBOARD - Welcome, $username"
        
        echo -e "${CYAN}What would you like to do?${NC}"
        echo -e "${YELLOW}1.${NC} Add Problem"
        echo -e "${YELLOW}2.${NC} See Reports"
        echo -e "${YELLOW}3.${NC} My Problems"
        echo -e "${YELLOW}4.${NC} Sign Out"
        echo
        
        read -p "$(echo -e "${CYAN}Enter your choice: ${NC}")" choice
        
        case $choice in
            1)
                add_problem "$username"
                ;;
            2)
                see_reports "$username"
                ;;
            3)
                my_problems "$username"
                ;;
            4)
                log_action "SIGNOUT" "$username" "Teacher signed out"
                show_message "Signed out successfully!" "success"
                sleep 1
                clear_screen
                return
                ;;
            *)
                show_message "Invalid choice. Please select 1, 2, 3, or 4." "error"
                ;;
        esac
    done
}

# =============================================================================
# Entry Point
# =============================================================================
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
