# =============================================================================
# Teacher Problems Module
# =============================================================================
# Functions for teachers to add and manage programming problems
# =============================================================================

source "$(dirname "${BASH_SOURCE[0]}")/../config/config.sh"
source "$(dirname "${BASH_SOURCE[0]}")/../utils/ui.sh"
source "$(dirname "${BASH_SOURCE[0]}")/../utils/logging.sh"

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
        
        echo -e "${YELLOW}💡 Tip: Press ESC key to return to previous menu${NC}"
        echo -e "${YELLOW}💡 For Windows paths, use forward slashes (/) or double backslashes (\\\\)${NC}"
        echo
        
        local title problem_file_path test_in_paths test_out_paths
        
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
        
        # Get problem.txt path with better instructions
        echo -e "${CYAN}Enter full path to problem.txt file:${NC}"
        echo -e "${YELLOW}Examples:${NC}"
        echo -e "${YELLOW}  - ./problem.txt (if file is in current directory)${NC}"
        echo -e "${YELLOW}  - C:/Users/YourName/Desktop/problem.txt${NC}"
        echo -e "${YELLOW}  - /cygdrive/f/Programs/bash/code-submission-checker/problem.txt${NC}"
        echo -e "${CYAN}Current directory: $(pwd)${NC}"
        if ! read_file_path "Problem file: " problem_file_path; then
            clear_screen
            return
        fi
        
        if [[ -z "$problem_file_path" ]]; then
            show_message "Problem file path cannot be empty!" "error"
            sleep 2
            continue
        fi
        
        # Normalize path for Windows compatibility
        problem_file_path=$(echo "$problem_file_path" | sed 's|\\|/|g')
        
        # Try different path formats and show debugging info
        local test_paths=("$problem_file_path")
        
        # Add various Windows path conversion attempts
        if [[ "$problem_file_path" =~ ^[A-Za-z]: ]]; then
            # Convert C:/path to /c/path format
            local drive_letter=$(echo "$problem_file_path" | cut -c1 | tr '[:upper:]' '[:lower:]')
            local path_without_drive=$(echo "$problem_file_path" | cut -c3-)
            test_paths+=("/${drive_letter}${path_without_drive}")
        fi
        
        # Add current directory relative path attempt
        local basename_only=$(basename "$problem_file_path")
        test_paths+=("./$basename_only")
        test_paths+=("$basename_only")
        
        # Add absolute path with cygdrive prefix
        if [[ "$problem_file_path" =~ ^[A-Za-z]: ]]; then
            local drive_letter=$(echo "$problem_file_path" | cut -c1 | tr '[:upper:]' '[:lower:]')
            local path_without_drive=$(echo "$problem_file_path" | cut -c3-)
            test_paths+=("/cygdrive/${drive_letter}${path_without_drive}")
        fi
        
        # Debug: Show current directory and attempted paths
        echo -e "${YELLOW}Debug Info:${NC}"
        echo -e "${YELLOW}Current directory: $(pwd)${NC}"
        echo -e "${YELLOW}Attempting paths:${NC}"
        for test_path in "${test_paths[@]}"; do
            echo -e "${YELLOW}  - $test_path${NC}"
        done
        echo
        
        local file_found=false
        local working_path=""
        for test_path in "${test_paths[@]}"; do
            if [[ -f "$test_path" ]]; then
                file_found=true
                working_path="$test_path"
                echo -e "${GREEN}✓ Found at: $test_path${NC}"
                break
            fi
        done
        
        if [[ "$file_found" != "true" ]]; then
            echo -e "${RED}File not found at any of the attempted paths.${NC}"
            echo -e "${YELLOW}Please try:${NC}"
            echo -e "${YELLOW}1. Copy the file to: $(pwd)/problem.txt${NC}"
            echo -e "${YELLOW}2. Or use relative path: ./problem.txt${NC}"
            echo -e "${YELLOW}3. Or try full path with /cygdrive/ prefix${NC}"
            sleep 5
            continue
        fi
        
        problem_file_path="$working_path"
        
        # Get test input files
        echo -e "${CYAN}Enter paths to test input files (separated by spaces):${NC}"
        echo -e "${YELLOW}Examples:${NC}"
        echo -e "${YELLOW}  - ./test.in (if file is in current directory)${NC}"
        echo -e "${YELLOW}  - C:/test1.in C:/test2.in${NC}"
        echo -e "${YELLOW}  - /mnt/f/Programs/bash/code-submission-checker/test.in${NC}"
        if ! read_file_path "Test input files: " test_in_paths; then
            clear_screen
            return
        fi
        
        if [[ -z "$test_in_paths" ]]; then
            show_message "Test input files cannot be empty!" "error"
            sleep 2
            continue
        fi
        
        # Validate and normalize test input files
        local normalized_test_in=""
        local valid_test_in=true
        echo -e "${YELLOW}Debug Info for Test Input Files:${NC}"
        for test_in_file in $test_in_paths; do
            # Normalize path
            test_in_file=$(echo "$test_in_file" | sed 's|\\|/|g')
            
            # Try different path formats
            local test_in_paths_array=("$test_in_file")
            
            # Add relative path attempts
            local basename_only=$(basename "$test_in_file")
            test_in_paths_array+=("./$basename_only")
            test_in_paths_array+=("$basename_only")
            
            # Add drive letter conversions if applicable
            if [[ "$test_in_file" =~ ^[A-Za-z]: ]]; then
                local drive_letter=$(echo "$test_in_file" | cut -c1 | tr '[:upper:]' '[:lower:]')
                local path_without_drive=$(echo "$test_in_file" | cut -c3-)
                test_in_paths_array+=("/${drive_letter}${path_without_drive}")
                test_in_paths_array+=("/cygdrive/${drive_letter}${path_without_drive}")
                test_in_paths_array+=("/mnt/${drive_letter}${path_without_drive}")
            fi
            
            echo -e "${YELLOW}Attempting paths for $test_in_file:${NC}"
            for test_path in "${test_in_paths_array[@]}"; do
                echo -e "${YELLOW}  - $test_path${NC}"
            done
            
            local in_file_found=false
            local working_in_path=""
            for test_in_path in "${test_in_paths_array[@]}"; do
                if [[ -f "$test_in_path" ]]; then
                    in_file_found=true
                    working_in_path="$test_in_path"
                    echo -e "${GREEN}✓ Found at: $test_in_path${NC}"
                    break
                fi
            done
            
            if [[ "$in_file_found" != "true" ]]; then
                echo -e "${RED}✗ Test input file not found: $test_in_file${NC}"
                echo -e "${YELLOW}Suggestion: Try ./$(basename "$test_in_file")${NC}"
                sleep 3
                valid_test_in=false
                break
            fi
            
            normalized_test_in="$normalized_test_in $working_in_path"
        done
        
        if [[ "$valid_test_in" != "true" ]]; then
            continue
        fi
        
        test_in_paths="$normalized_test_in"
        
        # Get test output files
        echo -e "${CYAN}Enter paths to test output files (separated by spaces):${NC}"
        echo -e "${YELLOW}Examples:${NC}"
        echo -e "${YELLOW}  - ./test.out (if file is in current directory)${NC}"
        echo -e "${YELLOW}  - C:/test1.out C:/test2.out${NC}"
        echo -e "${YELLOW}  - /mnt/f/Programs/bash/code-submission-checker/test.out${NC}"
        if ! read_file_path "Test output files: " test_out_paths; then
            clear_screen
            return
        fi
        
        if [[ -z "$test_out_paths" ]]; then
            show_message "Test output files cannot be empty!" "error"
            sleep 2
            continue
        fi
        
        # Validate and normalize test output files
        local normalized_test_out=""
        local valid_test_out=true
        echo -e "${YELLOW}Debug Info for Test Output Files:${NC}"
        for test_out_file in $test_out_paths; do
            # Normalize path
            test_out_file=$(echo "$test_out_file" | sed 's|\\|/|g')
            
            # Try different path formats
            local test_out_paths_array=("$test_out_file")
            
            # Add relative path attempts
            local basename_only=$(basename "$test_out_file")
            test_out_paths_array+=("./$basename_only")
            test_out_paths_array+=("$basename_only")
            
            # Add drive letter conversions if applicable
            if [[ "$test_out_file" =~ ^[A-Za-z]: ]]; then
                local drive_letter=$(echo "$test_out_file" | cut -c1 | tr '[:upper:]' '[:lower:]')
                local path_without_drive=$(echo "$test_out_file" | cut -c3-)
                test_out_paths_array+=("/${drive_letter}${path_without_drive}")
                test_out_paths_array+=("/cygdrive/${drive_letter}${path_without_drive}")
                test_out_paths_array+=("/mnt/${drive_letter}${path_without_drive}")
            fi
            
            echo -e "${YELLOW}Attempting paths for $test_out_file:${NC}"
            for test_path in "${test_out_paths_array[@]}"; do
                echo -e "${YELLOW}  - $test_path${NC}"
            done
            
            local out_file_found=false
            local working_out_path=""
            for test_out_path in "${test_out_paths_array[@]}"; do
                if [[ -f "$test_out_path" ]]; then
                    out_file_found=true
                    working_out_path="$test_out_path"
                    echo -e "${GREEN}✓ Found at: $test_out_path${NC}"
                    break
                fi
            done
            
            if [[ "$out_file_found" != "true" ]]; then
                echo -e "${RED}✗ Test output file not found: $test_out_file${NC}"
                echo -e "${YELLOW}Suggestion: Try ./$(basename "$test_out_file")${NC}"
                sleep 3
                valid_test_out=false
                break
            fi
            
            normalized_test_out="$normalized_test_out $working_out_path"
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
        echo -e "${YELLOW}Problem File:${NC} $problem_file_path"
        echo -e "${YELLOW}Test Cases:${NC} $test_in_count"
        echo
        
        echo -e "${CYAN}Do you want to add this problem? (y/n):${NC}"
        read -n 1 -s choice
        echo
        
        case $choice in
            [Yy])
                if create_problem "$title" "$problem_file_path" "$test_in_paths" "$test_out_paths" "$username"; then
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
    
    # Generate problem ID and clean title
    local problem_id=$(get_next_problem_id)
    local clean_title=$(echo "$title" | tr ' ' '_' | tr -cd '[:alnum:]_')
    local problem_dir_name="${problem_id}_${clean_title}"
    local problem_dir="$PROBLEMS_DIR/$problem_dir_name"
    
    # Create problem directory
    if ! mkdir -p "$problem_dir"; then
        return 1
    fi
    
    # Copy problem file
    if ! cp "$problem_file_path" "$problem_dir/problem.txt"; then
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
