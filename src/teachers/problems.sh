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

# =============================================================================
# My Problems Management Functions
# =============================================================================

# Get all problems created by a specific teacher
get_teacher_problems() {
    local teacher_username="$1"
    local -a teacher_problems=()
    
    # Search through all problem directories
    if [[ -d "$PROBLEMS_DIR" ]]; then
        for problem_dir in "$PROBLEMS_DIR"/P[0-9][0-9][0-9]_*; do
            if [[ -d "$problem_dir" ]]; then
                local problem_file="$problem_dir/problem.txt"
                if [[ -f "$problem_file" ]]; then
                    # Check if this problem was created by the teacher
                    if grep -q "^CREATED_BY: $teacher_username" "$problem_file" 2>/dev/null; then
                        teacher_problems+=("$(basename "$problem_dir")")
                    fi
                fi
            fi
        done
    fi
    
    # Sort problems by ID (newest first)
    if [[ ${#teacher_problems[@]} -gt 0 ]]; then
        IFS=$'\n' teacher_problems=($(sort -r <<< "${teacher_problems[*]}"))
        printf '%s\n' "${teacher_problems[@]}"
    fi
}

# Get problem details from problem.txt
get_problem_details() {
    local problem_dir_name="$1"
    local problem_path="$PROBLEMS_DIR/$problem_dir_name/problem.txt"
    
    if [[ ! -f "$problem_path" ]]; then
        return 1
    fi
    
    # Extract details from problem file
    local title=$(grep "^TITLE:" "$problem_path" | cut -d':' -f2- | xargs)
    local created_date=$(grep "^CREATED_DATE:" "$problem_path" | cut -d':' -f2- | xargs)
    local time_limit=$(grep "^TIME_LIMIT:" "$problem_path" | cut -d':' -f2 | xargs)
    
    # Count test cases
    local test_count=$(find "$PROBLEMS_DIR/$problem_dir_name" -name "test*.in" | wc -l)
    
    # Extract problem ID
    local problem_id=$(echo "$problem_dir_name" | cut -d'_' -f1)
    
    echo "$problem_id|$title|$created_date|$time_limit|$test_count"
}

# Display teacher's problems with pagination
show_teacher_problems() {
    local teacher_username="$1"
    local page="${2:-1}"
    local problems_per_page=10
    
    # Get all problems for the teacher
    local -a all_problems=()
    while IFS= read -r problem; do
        if [[ -n "$problem" ]]; then
            all_problems+=("$problem")
        fi
    done < <(get_teacher_problems "$teacher_username")
    
    local total_problems=${#all_problems[@]}
    
    if [[ $total_problems -eq 0 ]]; then
        echo "No problems found created by you"
        return 1
    fi
    
    # Calculate pagination
    local total_pages=$(( (total_problems + problems_per_page - 1) / problems_per_page ))
    local start_index=$(( (page - 1) * problems_per_page ))
    local end_index=$(( start_index + problems_per_page - 1 ))
    
    if [[ $end_index -ge $total_problems ]]; then
        end_index=$((total_problems - 1))
    fi
    
    # Display problems for current page
    echo -e "${CYAN}Your Problems:${NC}"
    echo
    printf "%-4s %-8s %-30s %-12s %-5s %-10s\n" "No." "ID" "Title" "Created" "Time" "Tests"
    show_separator "-" 75
    
    for ((i=start_index; i<=end_index; i++)); do
        local problem_dir="${all_problems[$i]}"
        local details=$(get_problem_details "$problem_dir")
        
        if [[ -n "$details" ]]; then
            IFS='|' read -r problem_id title created_date time_limit test_count <<< "$details"
            local short_date=$(echo "$created_date" | cut -d' ' -f1 | cut -c6-10)  # MM-DD format
            local short_title=$(echo "$title" | cut -c1-29)
            
            printf "%-4s %-8s %-30s %-12s %-5s %-10s\n" \
                "$((i+1))" \
                "$problem_id" \
                "$short_title" \
                "$short_date" \
                "${time_limit}s" \
                "$test_count"
        fi
    done
    
    echo
    echo -e "${CYAN}Page $page of $total_pages (Showing $((start_index + 1))-$((end_index + 1)) of $total_problems problems)${NC}"
    
    # Export pagination info for caller
    export CURRENT_PAGE=$page
    export TOTAL_PAGES=$total_pages
    export TOTAL_PROBLEMS=$total_problems
    export DISPLAYED_PROBLEMS=()
    
    # Store displayed problems for selection
    for ((i=start_index; i<=end_index; i++)); do
        DISPLAYED_PROBLEMS+=("${all_problems[$i]}")
    done
    
    return 0
}

# View/Edit a specific problem directly
view_teacher_problem() {
    local problem_dir_name="$1"
    local teacher_username="$2"
    local problem_path="$PROBLEMS_DIR/$problem_dir_name/problem.txt"
    
    if [[ ! -f "$problem_path" ]]; then
        show_message "Problem file not found: $problem_dir_name" "error"
        sleep 2
        return
    fi
    
    # Extract problem details
    local details=$(get_problem_details "$problem_dir_name")
    if [[ -z "$details" ]]; then
        show_message "Could not read problem details" "error"
        sleep 2
        return
    fi
    
    IFS='|' read -r problem_id title created_date time_limit test_count <<< "$details"
    
    clear_screen
    show_header "EDIT PROBLEM - $problem_id"
    
    echo -e "${CYAN}Problem Information:${NC}"
    echo -e "${YELLOW}ID:${NC} $problem_id"
    echo -e "${YELLOW}Title:${NC} $title"
    echo -e "${YELLOW}Created:${NC} $created_date"
    echo -e "${YELLOW}Time Limit:${NC} ${time_limit} seconds"
    echo -e "${YELLOW}Test Cases:${NC} $test_count"
    echo
    
    echo -e "${YELLOW}Opening problem file in editor...${NC}"
    echo -e "${YELLOW}Please save and close the editor when done.${NC}"
    echo
    
    read -p "$(echo -e "${CYAN}Press Enter to open editor or ESC to cancel: ${NC}")" -s -n1 key
    
    if [[ $(printf "%d" "'$key") -eq 27 ]] 2>/dev/null; then
        echo
        echo -e "${YELLOW}Edit cancelled.${NC}"
        sleep 1
        return
    fi
    
    echo
    echo -e "${YELLOW}Opening editor...${NC}"
    
    # Try different editors
    if command -v nano >/dev/null 2>&1; then
        nano "$problem_path"
    elif command -v vim >/dev/null 2>&1; then
        vim "$problem_path"
    elif command -v notepad.exe >/dev/null 2>&1; then
        notepad.exe "$problem_path"
    else
        echo -e "${RED}No suitable text editor found.${NC}"
        echo -e "${YELLOW}Please edit the file manually: $problem_path${NC}"
        sleep 3
        return
    fi
    
    # Log the edit action
    log_action "EDIT_PROBLEM" "$teacher_username" "Edited problem: $(basename "$(dirname "$problem_path")")"
    
    echo -e "${GREEN}Problem edited successfully!${NC}"
    sleep 2
}

# View problem content (standalone function for potential future use)
view_problem_content() {
    local problem_path="$1"
    
    clear_screen
    show_header "PROBLEM CONTENT"
    
    echo -e "${CYAN}Problem Description:${NC}"
    echo -e "${GRAY}$(printf '=%.0s' {1..80})${NC}"
    echo
    
    # Display the problem content with some formatting
    while IFS= read -r line; do
        if [[ "$line" =~ ^TITLE:|^CREATED_BY:|^TIME_LIMIT:|^CREATED_DATE: ]]; then
            echo -e "${CYAN}$line${NC}"
        elif [[ "$line" =~ ^[A-Z][A-Z_]*:$ ]]; then
            echo -e "${YELLOW}$line${NC}"
        else
            echo "$line"
        fi
    done < "$problem_path"
    
    echo
    echo -e "${GRAY}$(printf '=%.0s' {1..80})${NC}"
    echo
    echo -e "${YELLOW}Press any key to continue...${NC}"
    read -n 1 -s
}

# Legacy edit function (now integrated into view_teacher_problem)
edit_problem() {
    local problem_path="$1"
    local teacher_username="$2"
    
    clear_screen
    show_header "EDIT PROBLEM"
    
    echo -e "${CYAN}Current problem content:${NC}"
    echo -e "${GRAY}$(printf '=%.0s' {1..80})${NC}"
    cat "$problem_path"
    echo -e "${GRAY}$(printf '=%.0s' {1..80})${NC}"
    echo
    
    echo -e "${YELLOW}Note: This will open the problem file in a text editor.${NC}"
    echo -e "${YELLOW}Please save and close the editor when done.${NC}"
    echo
    
    read -p "$(echo -e "${CYAN}Press Enter to open editor or ESC to cancel: ${NC}")" -s -n1 key
    
    if [[ $(printf "%d" "'$key") -eq 27 ]] 2>/dev/null; then
        echo
        echo -e "${YELLOW}Edit cancelled.${NC}"
        sleep 1
        return
    fi
    
    echo
    echo -e "${YELLOW}Opening editor...${NC}"
    
    # Try different editors
    if command -v nano >/dev/null 2>&1; then
        nano "$problem_path"
    elif command -v vim >/dev/null 2>&1; then
        vim "$problem_path"
    elif command -v notepad.exe >/dev/null 2>&1; then
        notepad.exe "$problem_path"
    else
        echo -e "${RED}No suitable text editor found.${NC}"
        echo -e "${YELLOW}Please edit the file manually: $problem_path${NC}"
        sleep 3
        return
    fi
    
    # Log the edit action
    log_action "EDIT_PROBLEM" "$teacher_username" "Edited problem: $(basename "$(dirname "$problem_path")")"
    
    echo -e "${GREEN}Problem edited successfully!${NC}"
    sleep 2
}

# View test cases
view_test_cases() {
    local problem_dir="$1"
    
    clear_screen
    show_header "TEST CASES"
    
    echo -e "${CYAN}Test cases for: $(basename "$problem_dir")${NC}"
    echo
    
    local test_files=($(find "$problem_dir" -name "test*.in" | sort))
    
    if [[ ${#test_files[@]} -eq 0 ]]; then
        echo -e "${YELLOW}No test cases found.${NC}"
    else
        for test_file in "${test_files[@]}"; do
            local test_num=$(basename "$test_file" .in | sed 's/test//')
            local output_file="${test_file%.in}.out"
            
            echo -e "${YELLOW}Test Case $test_num:${NC}"
            echo -e "${CYAN}Input:${NC}"
            cat "$test_file"
            echo
            
            if [[ -f "$output_file" ]]; then
                echo -e "${CYAN}Expected Output:${NC}"
                cat "$output_file"
            else
                echo -e "${RED}Expected output file not found${NC}"
            fi
            
            echo
            show_separator "-" 40
            echo
        done
    fi
    
    echo -e "${YELLOW}Press any key to continue...${NC}"
    read -n 1 -s
}

# Main interface for teacher's problems
my_problems() {
    local teacher_username="$1"
    
    while true; do
        clear_screen
        show_header "MY PROBLEMS"
        
        # Show problems with pagination
        local current_page=1
        
        while true; do
            clear_screen
            show_header "MY PROBLEMS - $teacher_username"
            
            if show_teacher_problems "$teacher_username" "$current_page"; then
                echo
                echo -e "${CYAN}Options:${NC}"
                echo -e "${YELLOW}1.${NC} View/Edit specific problem"
                
                # Show navigation options if there are multiple pages
                if [[ $TOTAL_PAGES -gt 1 ]]; then
                    if [[ $current_page -gt 1 ]]; then
                        echo -e "${YELLOW}2.${NC} Previous page"
                    fi
                    if [[ $current_page -lt $TOTAL_PAGES ]]; then
                        echo -e "${YELLOW}3.${NC} Next page"
                    fi
                    echo -e "${YELLOW}4.${NC} Go to specific page"
                    echo -e "${YELLOW}5.${NC} Refresh list"
                    echo -e "${YELLOW}6.${NC} Back to dashboard"
                else
                    echo -e "${YELLOW}2.${NC} Refresh list"
                    echo -e "${YELLOW}3.${NC} Back to dashboard"
                fi
                echo
                
                read -p "$(echo -e "${CYAN}Enter your choice: ${NC}")" choice
                
                case $choice in
                    1)
                        echo
                        read -p "$(echo -e "${CYAN}Enter problem number (1-${#DISPLAYED_PROBLEMS[@]}): ${NC}")" problem_choice
                        if [[ "$problem_choice" =~ ^[0-9]+$ ]] && [[ "$problem_choice" -ge 1 ]] && [[ "$problem_choice" -le ${#DISPLAYED_PROBLEMS[@]} ]]; then
                            local selected_problem="${DISPLAYED_PROBLEMS[$((problem_choice-1))]}"
                            view_teacher_problem "$selected_problem" "$teacher_username"
                            log_action "VIEW_MY_PROBLEM" "$teacher_username" "Viewed own problem: $selected_problem"
                        else
                            show_message "Invalid problem number. Please select a number between 1 and ${#DISPLAYED_PROBLEMS[@]}." "error"
                            sleep 2
                        fi
                        ;;
                    2)
                        if [[ $TOTAL_PAGES -gt 1 && $current_page -gt 1 ]]; then
                            ((current_page--))
                        else
                            # This is "Refresh list" when there's only one page
                            current_page=1
                        fi
                        ;;
                    3)
                        if [[ $TOTAL_PAGES -gt 1 && $current_page -lt $TOTAL_PAGES ]]; then
                            ((current_page++))
                        else
                            # This is "Back to dashboard" when there's only one page
                            clear_screen
                            return
                        fi
                        ;;
                    4)
                        if [[ $TOTAL_PAGES -gt 1 ]]; then
                            echo
                            read -p "$(echo -e "${CYAN}Enter page number (1-$TOTAL_PAGES): ${NC}")" page_input
                            if [[ "$page_input" =~ ^[0-9]+$ ]] && [[ $page_input -ge 1 && $page_input -le $TOTAL_PAGES ]]; then
                                current_page=$page_input
                            else
                                show_message "Invalid page number. Please enter a number between 1 and $TOTAL_PAGES." "error"
                                sleep 2
                            fi
                        fi
                        ;;
                    5)
                        if [[ $TOTAL_PAGES -gt 1 ]]; then
                            current_page=1
                        fi
                        ;;
                    6)
                        if [[ $TOTAL_PAGES -gt 1 ]]; then
                            clear_screen
                            return
                        else
                            show_message "Invalid choice." "error"
                            sleep 2
                        fi
                        ;;
                    *)
                        show_message "Invalid choice." "error"
                        sleep 2
                        ;;
                esac
            else
                echo
                echo -e "${YELLOW}You haven't created any problems yet.${NC}"
                echo -e "${YELLOW}Use 'Add Problem' to create your first problem.${NC}"
                echo
                read -p "$(echo -e "${CYAN}Press any key to go back...${NC}")" -n 1
                clear_screen
                return
            fi
        done
    done
}
