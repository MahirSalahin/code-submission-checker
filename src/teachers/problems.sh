# =============================================================================
# Teacher Problems Module
# =============================================================================
# Functions for teachers to add and manage programming problems
# =============================================================================

source "$(dirname "${BASH_SOURCE[0]}")/../config/config.sh"
source "$(dirname "${BASH_SOURCE[0]}")/../utils/ui.sh"
source "$(dirname "${BASH_SOURCE[0]}")/../utils/logging.sh"

# =============================================================================
# File Path Resolution Functions
# =============================================================================

# Resolve and validate file path using comprehensive cross-platform approach
resolve_file_path() {
    local input_path="$1"
    local file_type="$2"  # For error messages
    
    # Normalize path for Windows compatibility
    input_path=$(echo "$input_path" | sed 's|\\|/|g')
    
    # Try different path formats
    local test_paths=("$input_path")
    
    # Add relative path attempts
    local basename_only=$(basename "$input_path")
    test_paths+=("./$basename_only")
    test_paths+=("$basename_only")
    
    # Add Windows drive letter conversions if applicable
    if [[ "$input_path" =~ ^[A-Za-z]: ]]; then
        local drive_letter=$(echo "$input_path" | cut -c1 | tr '[:upper:]' '[:lower:]')
        local path_without_drive=$(echo "$input_path" | cut -c3-)
        
        # Try various mount point formats
        test_paths+=("/${drive_letter}${path_without_drive}")
        test_paths+=("/cygdrive/${drive_letter}${path_without_drive}")
        test_paths+=("/mnt/${drive_letter}${path_without_drive}")
        
        # Try with uppercase drive letter
        local drive_letter_upper=$(echo "$input_path" | cut -c1 | tr '[:lower:]' '[:upper:]')
        test_paths+=("/${drive_letter_upper}${path_without_drive}")
        test_paths+=("/cygdrive/${drive_letter_upper}${path_without_drive}")
        test_paths+=("/mnt/${drive_letter_upper}${path_without_drive}")
    fi
    
    # For paths that don't start with drive letter, try as-is and with various prefixes
    if [[ ! "$input_path" =~ ^[A-Za-z]: ]]; then
        # Try with current working directory
        test_paths+=("$(pwd)/$input_path")
        
        # Try common mount points
        test_paths+=("/cygdrive/c/$input_path")
        test_paths+=("/mnt/c/$input_path")
        test_paths+=("/c/$input_path")
    fi
    
    # Debug output to stderr so it doesn't interfere with return value (commented out for cleaner output)
    # echo -e "${YELLOW}Attempting paths for $input_path:${NC}" >&2
    # for test_path in "${test_paths[@]}"; do
    #     echo -e "${YELLOW}  - $test_path${NC}" >&2
    # done
    
    # Find working path
    for test_path in "${test_paths[@]}"; do
        if [[ -f "$test_path" ]]; then
            echo -e "${GREEN}✓ Found: $(basename "$test_path")${NC}" >&2
            echo "$test_path"  # Return only the clean path
            return 0
        fi
    done
    
    # File not found
    echo -e "${RED}✗ ${file_type} not found: $(basename "$input_path")${NC}" >&2
    echo -e "${YELLOW}Please check file path and try again${NC}" >&2
    return 1
}

# =============================================================================
# Problem Management Functions
# =============================================================================

# Get the next problem ID
get_next_problem_id() {
    local max_id=0
    
    if [[ -d "$PROBLEMS_DIR" ]]; then
        for problem_dir in "$PROBLEMS_DIR"/P[0-9][0-9][0-9]_*; do
            if [[ -d "$problem_dir" ]]; then
                local problem_name=$(basename "$problem_dir")
                local problem_id=$(echo "$problem_name" | cut -d'_' -f1 | sed 's/P//')
                
                if [[ "$problem_id" =~ ^[0-9]+$ ]] && [[ $problem_id -gt $max_id ]]; then
                    max_id=$problem_id
                fi
            fi
        done
    fi
    
    printf "P%03d" $((max_id + 1))
}

# Add a new problem to the system
add_problem() {
    local username="$1"
    
    while true; do
        clear_screen
        show_header "ADD PROBLEM - Press ESC to go back"
        
        echo -e "${YELLOW}💡 For paths, you may use forward slashes (/) or  backslashes (\\\)${NC}"
        echo
        
        local title problem_file_path test_in_paths test_out_paths time_limit
        
        # Get problem title
        echo -e "${CYAN}Enter problem title:${NC}"
        if ! read_input_esc "Title: " title; then
            clear_screen
            return
        fi
        
        if [[ -z "$title" ]]; then
            show_message "Problem title cannot be empty!" "error"
            sleep 2
            continue
        fi
        
        # Get time limit
        echo -e "${CYAN}Enter time limit in seconds (default: 5):${NC}"
        if ! read_input_esc "Time limit: " time_limit; then
            clear_screen
            return
        fi
        
        # Validate time limit
        if [[ -z "$time_limit" ]]; then
            time_limit=5  # Default value
        elif [[ ! "$time_limit" =~ ^[0-9]+$ ]] || [[ $time_limit -lt 1 ]] || [[ $time_limit -gt 60 ]]; then
            show_message "Time limit must be a number between 1 and 60 seconds!" "error"
            sleep 2
            continue
        fi
        
        # Get problem.txt path with better instructions
        echo -e "${CYAN}Enter full path to problem.txt file:${NC}"
        if ! read_file_path "Problem file: " problem_file_path; then
            clear_screen
            return
        fi
        
        if [[ -z "$problem_file_path" ]]; then
            show_message "Problem file path cannot be empty!" "error"
            sleep 2
            continue
        fi
        
        # Resolve and validate file path
        local resolved_path
        if resolved_path=$(resolve_file_path "$problem_file_path" "Problem file"); then
            problem_file_path="$resolved_path"
        else
            sleep 3
            continue
        fi
        
        # Get test input files
        echo -e "${CYAN}Enter paths to test input files (separated by spaces):${NC}"
        if ! read_file_path "Test input files: " test_in_paths; then
            clear_screen
            return
        fi
        
        if [[ -z "$test_in_paths" ]]; then
            show_message "Test input files cannot be empty!" "error"
            sleep 2
            continue
        fi
        
        # Validate and resolve test input files
        local normalized_test_in=""
        local valid_test_in=true
        for test_in_file in $test_in_paths; do
            local resolved_test_in_path
            if resolved_test_in_path=$(resolve_file_path "$test_in_file" "Test input file"); then
                normalized_test_in="$normalized_test_in $resolved_test_in_path"
            else
                valid_test_in=false
                sleep 3
                break
            fi
        done
        
        if [[ "$valid_test_in" != "true" ]]; then
            continue
        fi
        
        test_in_paths="$normalized_test_in"
        
        # Get test output files
        echo -e "${CYAN}Enter paths to test output files (separated by spaces):${NC}"
        if ! read_file_path "Test output files: " test_out_paths; then
            clear_screen
            return
        fi
        
        if [[ -z "$test_out_paths" ]]; then
            show_message "Test output files cannot be empty!" "error"
            sleep 2
            continue
        fi
        
        # Validate and resolve test output files
        local normalized_test_out=""
        local valid_test_out=true
        for test_out_file in $test_out_paths; do
            local resolved_test_out_path
            if resolved_test_out_path=$(resolve_file_path "$test_out_file" "Test output file"); then
                normalized_test_out="$normalized_test_out $resolved_test_out_path"
            else
                valid_test_out=false
                sleep 3
                break
            fi
        done
        
        if [[ "$valid_test_out" != "true" ]]; then
            continue
        fi
        
        test_out_paths="$normalized_test_out"
        
        # Count test files
        local test_in_count=$(echo $test_in_paths | wc -w)
        local test_out_count=$(echo $test_out_paths | wc -w)
        
        if [[ $test_in_count -ne $test_out_count ]]; then
            show_message "Number of test input files ($test_in_count) must match test output files ($test_out_count)!" "error"
            sleep 2
            continue
        fi
        
        # Show confirmation
        clear_screen
        show_header "CONFIRM PROBLEM ADDITION"
        
        echo -e "${CYAN}Problem Details:${NC}"
        echo -e "${YELLOW}Title:${NC} $title"
        echo -e "${YELLOW}Time Limit:${NC} $time_limit seconds"
        echo -e "${YELLOW}Problem File:${NC} $problem_file_path"
        echo -e "${YELLOW}Test Cases:${NC} $test_in_count"
        echo
        
        echo -e "${CYAN}Do you want to add this problem? (y/n):${NC}"
        read -n 1 -s choice
        echo
        
        case $choice in
            [Yy])
                if create_problem "$title" "$problem_file_path" "$test_in_paths" "$test_out_paths" "$username" "$time_limit"; then
                    show_message "Problem added successfully!" "success"
                    sleep 2
                    clear_screen
                    return
                else
                    show_message "Failed to add problem. Please try again." "error"
                    sleep 2
                fi
                ;;
            [Nn])
                show_message "Problem addition cancelled." "info"
                sleep 2
                continue
                ;;
            *)
                show_message "Please enter 'y' for yes or 'n' for no." "error"
                sleep 2
                ;;
        esac
    done
}

# Create the problem directory and copy files
create_problem() {
    local title="$1"
    local problem_file_path="$2"
    local test_in_paths="$3"
    local test_out_paths="$4"
    local username="$5"
    local time_limit="$6"
    
    # Generate problem ID and clean title
    local problem_id=$(get_next_problem_id)
    local clean_title=$(echo "$title" | tr ' ' '_' | tr -cd '[:alnum:]_')
    local problem_dir_name="${problem_id}_${clean_title}"
    local problem_dir="$PROBLEMS_DIR/$problem_dir_name"
    local current_date=$(date "+%Y-%m-%d %H:%M:%S")
    
    # Create problem directory
    if ! mkdir -p "$problem_dir"; then
        return 1
    fi
    
    # Create problem file with header information
    local problem_dest="$problem_dir/problem.txt"
    
    # Add header information
    cat > "$problem_dest" << EOF
TITLE: $title
CREATED_BY: $username
TIME_LIMIT: $time_limit
CREATED_DATE: $current_date

EOF
    
    # Append original problem content
    if ! cat "$problem_file_path" >> "$problem_dest"; then
        rm -rf "$problem_dir"
        return 1
    fi
    
    # Copy test files
    local test_in_array=($test_in_paths)
    local test_out_array=($test_out_paths)
    local test_count=${#test_in_array[@]}
    
    for ((i=0; i<test_count; i++)); do
        local test_num=$((i + 1))
        
        # Copy test input file
        if ! cp "${test_in_array[$i]}" "$problem_dir/test${test_num}.in"; then
            rm -rf "$problem_dir"
            return 1
        fi
        
        # Copy test output file
        if ! cp "${test_out_array[$i]}" "$problem_dir/test${test_num}.out"; then
            rm -rf "$problem_dir"
            return 1
        fi
    done
    
    # Log the action
    log_action "ADD_PROBLEM" "$username" "Added problem: $problem_dir_name with $test_count test cases"
    
    return 0
}
