# =============================================================================
# Student Submissions Module
# =============================================================================
# Functions for students to submit and manage their solutions
# =============================================================================

source "$(dirname "${BASH_SOURCE[0]}")/../config/config.sh"
source "$(dirname "${BASH_SOURCE[0]}")/../utils/ui.sh"
source "$(dirname "${BASH_SOURCE[0]}")/../utils/logging.sh"

# Load the problems module to reuse problem lookup functions
source "$(dirname "${BASH_SOURCE[0]}")/problems.sh"

# =============================================================================
# Submission Management Functions
# =============================================================================

# Get file extension from filename
get_file_extension() {
    local filename="$1"
    echo "${filename##*.}"
}

# Detect programming language from file extension
detect_language() {
    local extension="$1"
    
    case "$extension" in
        c) echo "c" ;;
        cpp|cc|cxx) echo "cpp" ;;
        cs) echo "cs" ;;
        java) echo "java" ;;
        py) echo "py" ;;
        *) echo "unknown" ;;
    esac
}

# Resolve and validate solution file path using the same DRY approach as teacher problems
resolve_solution_file_path() {
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
    
    # Add drive letter conversions if applicable
    if [[ "$input_path" =~ ^[A-Za-z]: ]]; then
        local drive_letter=$(echo "$input_path" | cut -c1 | tr '[:upper:]' '[:lower:]')
        local path_without_drive=$(echo "$input_path" | cut -c3-)
        test_paths+=("/${drive_letter}${path_without_drive}")
        test_paths+=("/cygdrive/${drive_letter}${path_without_drive}")
        test_paths+=("/mnt/${drive_letter}${path_without_drive}")
    fi
    
    # Debug output to stderr so it doesn't interfere with return value
    echo -e "${YELLOW}Attempting paths for $input_path:${NC}" >&2
    for test_path in "${test_paths[@]}"; do
        echo -e "${YELLOW}  - $test_path${NC}" >&2
    done
    
    # Find working path
    for test_path in "${test_paths[@]}"; do
        if [[ -f "$test_path" ]]; then
            echo -e "${GREEN}✓ Found at: $test_path${NC}" >&2
            echo "$test_path"  # Return only the clean path
            return 0
        fi
    done
    
    # File not found
    echo -e "${RED}✗ ${file_type} not found: $input_path${NC}" >&2
    echo -e "${YELLOW}Suggestion: Try ./$(basename "$input_path")${NC}" >&2
    return 1
}

# Prompt for and validate solution file
prompt_and_validate_solution_file() {
    local result_var="$1"
    
    echo -e "${CYAN}Enter the path to your solution file:${NC}"
    echo -e "${YELLOW}Supported languages: C (.c), C++ (.cpp), C# (.cs), Java (.java), Python (.py)${NC}"
    echo -e "${YELLOW}Examples:${NC}"
    echo -e "${YELLOW}  - ./solution.cpp (if file is in current directory)${NC}"
    echo -e "${YELLOW}  - C:/Users/YourName/Desktop/solution.py${NC}"
    echo -e "${YELLOW}  - /mnt/c/path/to/solution.java${NC}"
    echo -e "${CYAN}Current directory: $(pwd)${NC}"
    
    local solution_path
    if ! read_file_path "Solution file: " solution_path; then
        return 1  # ESC pressed
    fi
    
    if [[ -z "$solution_path" ]]; then
        show_message "Solution file path cannot be empty!" "error"
        sleep 2
        return 2  # Empty input
    fi
    
    # Resolve and validate the path
    echo -e "${YELLOW}Debug Info for Solution File:${NC}"
    local resolved_path
    if resolved_path=$(resolve_solution_file_path "$solution_path" "Solution file"); then
        # Validate file extension
        local extension=$(get_file_extension "$resolved_path")
        local language=$(detect_language "$extension")
        
        if [[ "$language" == "unknown" ]]; then
            echo -e "${RED}Unsupported file type: .$extension${NC}"
            echo -e "${YELLOW}Supported extensions: .c, .cpp, .cs, .java, .py${NC}"
            sleep 3
            return 3  # Unsupported file type
        fi
        
        echo -e "${GREEN}✓ Detected language: $language${NC}"
        eval "$result_var=\"\$resolved_path\""
        return 0  # Success
    else
        sleep 3
        return 3  # File not found
    fi
}

# Generate submission ID
generate_submission_id() {
    local username="$1"
    local timestamp=$(date +"%Y%m%d_%H%M%S")
    echo "${username}_${timestamp}"
}

# Create submission report
create_submission_report() {
    local username="$1"
    local problem_id="$2"
    local problem_name="$3"
    local solution_file="$4"
    local language="$5"
    local submission_id="$6"
    local test_results="$7"
    
    local timestamp=$(date "+%Y-%m-%d %H:%M:%S")
    local report_file="$REPORTS_DIR/${submission_id}_report.txt"
    
    # Create reports directory if it doesn't exist
    mkdir -p "$REPORTS_DIR"
    
    # Generate the report
    cat > "$report_file" << EOF
================================================================================
                          SUBMISSION REPORT
================================================================================

Student Information:
  Username: $username
  Submission ID: $submission_id
  Timestamp: $timestamp

Problem Information:
  Problem ID: $problem_id
  Problem Name: $problem_name

Solution Information:
  File: $(basename "$solution_file")
  Language: $language
  Full Path: $solution_file

Test Results:
$test_results

================================================================================
Report generated by Code Submission Checker System
================================================================================
EOF

    echo "$report_file"
}

# Save submission to submissions directory
save_submission() {
    local username="$1"
    local problem_id="$2"
    local solution_file="$3"
    local submission_id="$4"
    
    local user_submission_dir="$SUBMISSIONS_DIR/$username"
    local submission_dir="$user_submission_dir/${problem_id}"
    
    # Create submission directories
    mkdir -p "$submission_dir"
    
    # Copy the solution file with timestamp
    local solution_filename=$(basename "$solution_file")
    local saved_solution="$submission_dir/${submission_id}_${solution_filename}"
    
    if cp "$solution_file" "$saved_solution"; then
        echo "$saved_solution"
        return 0
    else
        return 1
    fi
}

# Simulate test execution with basic output comparison
# Get time limit from problem.txt
get_time_limit() {
    local problem_dir="$1"
    local problem_file="$problem_dir/problem.txt"
    
    if [[ -f "$problem_file" ]]; then
        local time_limit=$(grep "^TIME_LIMIT:" "$problem_file" | cut -d':' -f2 | tr -d ' ')
        if [[ "$time_limit" =~ ^[0-9]+$ ]]; then
            echo "$time_limit"
        else
            echo "5"  # Default fallback
        fi
    else
        echo "5"  # Default fallback
    fi
}

# Execute code and capture output
execute_solution() {
    local solution_file="$1"
    local language="$2"
    local input_file="$3"
    local temp_dir="$4"
    local time_limit="$5"
    
    local output_file="$temp_dir/actual_output.txt"
    local error_file="$temp_dir/error.txt"
    local executable="$temp_dir/solution"
    local exit_code_file="$temp_dir/exit_code.txt"
    
    # Remove any existing output/error files
    rm -f "$output_file" "$error_file" "$exit_code_file"
    
    case "$language" in
        "c")
            # Compile C code
            if gcc -o "$executable" "$solution_file" 2>"$error_file"; then
                # Run with input and capture exit code
                if [[ -f "$input_file" ]]; then
                    timeout "${time_limit}s" bash -c "
                        '$executable' < '$input_file' > '$output_file' 2>>'$error_file'
                        echo \$? > '$exit_code_file'
                    " 2>/dev/null
                    local timeout_exit=$?
                else
                    timeout "${time_limit}s" bash -c "
                        '$executable' > '$output_file' 2>>'$error_file'
                        echo \$? > '$exit_code_file'
                    " 2>/dev/null
                    local timeout_exit=$?
                fi
                
                # Check if timeout occurred
                if [[ $timeout_exit -eq 124 ]]; then
                    echo "TIME_LIMIT_EXCEEDED" > "$output_file"
                    echo "124" > "$exit_code_file"
                fi
                
                # Read actual exit code if available
                if [[ -f "$exit_code_file" ]]; then
                    local actual_exit=$(cat "$exit_code_file" 2>/dev/null || echo "1")
                else
                    local actual_exit=$timeout_exit
                fi
                
                echo "$actual_exit"
            else
                echo "COMPILATION_ERROR" > "$output_file"
                echo "1"
            fi
            ;;
        "cpp")
            # Compile C++ code
            if g++ -o "$executable" "$solution_file" 2>"$error_file"; then
                # Run with input and capture exit code
                if [[ -f "$input_file" ]]; then
                    timeout "${time_limit}s" bash -c "
                        '$executable' < '$input_file' > '$output_file' 2>>'$error_file'
                        echo \$? > '$exit_code_file'
                    " 2>/dev/null
                    local timeout_exit=$?
                else
                    timeout "${time_limit}s" bash -c "
                        '$executable' > '$output_file' 2>>'$error_file'
                        echo \$? > '$exit_code_file'
                    " 2>/dev/null
                    local timeout_exit=$?
                fi
                
                # Check if timeout occurred
                if [[ $timeout_exit -eq 124 ]]; then
                    echo "TIME_LIMIT_EXCEEDED" > "$output_file"
                    echo "124" > "$exit_code_file"
                fi
                
                # Read actual exit code if available
                if [[ -f "$exit_code_file" ]]; then
                    local actual_exit=$(cat "$exit_code_file" 2>/dev/null || echo "1")
                else
                    local actual_exit=$timeout_exit
                fi
                
                echo "$actual_exit"
            else
                echo "COMPILATION_ERROR" > "$output_file"
                echo "1"
            fi
            ;;
        "java")
            # Compile Java code
            local class_name=$(basename "$solution_file" .java)
            if javac -d "$temp_dir" "$solution_file" 2>"$error_file"; then
                # Run with input and capture exit code
                if [[ -f "$input_file" ]]; then
                    timeout "${time_limit}s" bash -c "
                        cd '$temp_dir' && java '$class_name' < '$input_file' > '$output_file' 2>>'$error_file'
                        echo \$? > '$exit_code_file'
                    " 2>/dev/null
                    local timeout_exit=$?
                else
                    timeout "${time_limit}s" bash -c "
                        cd '$temp_dir' && java '$class_name' > '$output_file' 2>>'$error_file'
                        echo \$? > '$exit_code_file'
                    " 2>/dev/null
                    local timeout_exit=$?
                fi
                
                # Check if timeout occurred
                if [[ $timeout_exit -eq 124 ]]; then
                    echo "TIME_LIMIT_EXCEEDED" > "$output_file"
                    echo "124" > "$exit_code_file"
                fi
                
                # Read actual exit code if available
                if [[ -f "$exit_code_file" ]]; then
                    local actual_exit=$(cat "$exit_code_file" 2>/dev/null || echo "1")
                else
                    local actual_exit=$timeout_exit
                fi
                
                echo "$actual_exit"
            else
                echo "COMPILATION_ERROR" > "$output_file"
                echo "1"
            fi
            ;;
        "py")
            # Run Python code directly with better error handling
            if [[ -f "$input_file" ]]; then
                timeout "${time_limit}s" bash -c "
                    python3 '$solution_file' < '$input_file' > '$output_file' 2>'$error_file'
                    echo \$? > '$exit_code_file'
                " 2>/dev/null
                local timeout_exit=$?
            else
                timeout "${time_limit}s" bash -c "
                    python3 '$solution_file' > '$output_file' 2>'$error_file'
                    echo \$? > '$exit_code_file'
                " 2>/dev/null
                local timeout_exit=$?
            fi
            
            # Check if timeout occurred
            if [[ $timeout_exit -eq 124 ]]; then
                echo "TIME_LIMIT_EXCEEDED" > "$output_file"
                echo "124" > "$exit_code_file"
            fi
            
            # Read actual exit code if available
            if [[ -f "$exit_code_file" ]]; then
                local actual_exit=$(cat "$exit_code_file" 2>/dev/null || echo "1")
            else
                local actual_exit=$timeout_exit
            fi
            
            echo "$actual_exit"
            ;;
        "cs")
            # Compile C# code
            if mcs -out:"$executable.exe" "$solution_file" 2>"$error_file"; then
                # Run with input and capture exit code
                if [[ -f "$input_file" ]]; then
                    timeout "${time_limit}s" bash -c "
                        mono '$executable.exe' < '$input_file' > '$output_file' 2>>'$error_file'
                        echo \$? > '$exit_code_file'
                    " 2>/dev/null
                    local timeout_exit=$?
                else
                    timeout "${time_limit}s" bash -c "
                        mono '$executable.exe' > '$output_file' 2>>'$error_file'
                        echo \$? > '$exit_code_file'
                    " 2>/dev/null
                    local timeout_exit=$?
                fi
                
                # Check if timeout occurred
                if [[ $timeout_exit -eq 124 ]]; then
                    echo "TIME_LIMIT_EXCEEDED" > "$output_file"
                    echo "124" > "$exit_code_file"
                fi
                
                # Read actual exit code if available
                if [[ -f "$exit_code_file" ]]; then
                    local actual_exit=$(cat "$exit_code_file" 2>/dev/null || echo "1")
                else
                    local actual_exit=$timeout_exit
                fi
                
                echo "$actual_exit"
            else
                echo "COMPILATION_ERROR" > "$output_file"
                echo "1"
            fi
            ;;
        *)
            echo "UNSUPPORTED_LANGUAGE" > "$output_file"
            echo "1"
            ;;
    esac
}

# Compare actual output with expected output
compare_outputs() {
    local actual_file="$1"
    local expected_file="$2"
    local exit_code="$3"
    local error_file="$4"
    
    # Check if files exist
    if [[ ! -f "$expected_file" ]]; then
        echo "MISSING_EXPECTED_OUTPUT"
        return 1
    fi
    
    # Check for special error conditions first
    if [[ -f "$actual_file" ]]; then
        local actual_content=$(cat "$actual_file" 2>/dev/null)
        
        if [[ "$actual_content" == "COMPILATION_ERROR" ]]; then
            echo "COMPILATION_ERROR"
            return 1
        elif [[ "$actual_content" == "TIME_LIMIT_EXCEEDED" ]]; then
            echo "TIME_LIMIT_EXCEEDED"
            return 1
        elif [[ "$actual_content" == "UNSUPPORTED_LANGUAGE" ]]; then
            echo "UNSUPPORTED_LANGUAGE"
            return 1
        fi
    else
        echo "RUNTIME_ERROR"
        return 1
    fi
    
    # Check exit code for runtime errors
    if [[ "$exit_code" -eq 124 ]]; then
        echo "TIME_LIMIT_EXCEEDED"
        return 1
    elif [[ "$exit_code" -ne 0 ]]; then
        # Non-zero exit code indicates runtime error
        # But check if there's still valid output
        if [[ -s "$actual_file" ]]; then
            # There's output, so it might just be wrong answer
            # Check error file for runtime error indicators
            if [[ -f "$error_file" && -s "$error_file" ]]; then
                local error_content=$(cat "$error_file" 2>/dev/null)
                # Look for common runtime error patterns
                if echo "$error_content" | grep -qi "segmentation fault\|segfault\|core dumped\|exception\|error\|traceback"; then
                    echo "RUNTIME_ERROR"
                    return 1
                fi
            fi
        else
            # No output and non-zero exit = runtime error
            echo "RUNTIME_ERROR"
            return 1
        fi
    fi
    
    # Read and normalize outputs (trim whitespace)
    local actual_output=$(cat "$actual_file" | sed 's/[[:space:]]*$//' | sed '/^$/d')
    local expected_output=$(cat "$expected_file" | sed 's/[[:space:]]*$//' | sed '/^$/d')
    
    # Compare outputs
    if [[ "$actual_output" == "$expected_output" ]]; then
        echo "PASSED"
        return 0
    else
        echo "WRONG_ANSWER"
        return 1
    fi
}

# Execute tests and generate results
run_tests_execution() {
    local problem_dir="$1"
    local solution_file="$2"
    local language="$3"
    
    echo -e "${YELLOW}Compiling and running solution...${NC}" >&2
    echo >&2
    
    local results=""
    local total_tests=0
    local passed_tests=0
    
    # Get time limit from problem.txt
    local time_limit=$(get_time_limit "$problem_dir")
    echo -e "${CYAN}Time limit: ${time_limit} seconds${NC}" >&2
    echo >&2
    
    # Create temporary directory for execution (Windows-compatible)
    local temp_dir
    if [[ -d "/tmp" ]]; then
        temp_dir="/tmp/code_checker_$$"
    else
        # Windows fallback
        temp_dir="$PROJECT_ROOT/temp/code_checker_$$"
    fi
    mkdir -p "$temp_dir"
    
    # Ensure cleanup on exit
    trap "rm -rf '$temp_dir'" EXIT
    
    # Run each test case
    for test_file in "$problem_dir"/test*.in; do
        if [[ -f "$test_file" ]]; then
            ((total_tests++))
            local test_num=$(basename "$test_file" .in | sed 's/test//')
            local expected_output_file="$problem_dir/test${test_num}.out"
            
            echo -e "${CYAN}Running Test ${test_num}...${NC}" >&2
            
            if [[ -f "$expected_output_file" ]]; then
                # Execute the solution with proper time limit
                local exit_code=$(execute_solution "$solution_file" "$language" "$test_file" "$temp_dir" "$time_limit")
                local actual_output_file="$temp_dir/actual_output.txt"
                local error_file="$temp_dir/error.txt"
                
                # Compare outputs
                local result=$(compare_outputs "$actual_output_file" "$expected_output_file" "$exit_code" "$error_file")
                
                case "$result" in
                    "PASSED")
                        ((passed_tests++))
                        results+="\n  Test ${test_num}: PASSED ✓"
                        echo -e "${GREEN}Test ${test_num}: PASSED ✓${NC}" >&2
                        ;;
                    "WRONG_ANSWER")
                        results+="\n  Test ${test_num}: FAILED ✗"
                        results+="\n    Result: Wrong Answer"
                        local expected_content=$(cat "$expected_output_file" 2>/dev/null | head -3)
                        local actual_content=$(cat "$actual_output_file" 2>/dev/null | head -3)
                        results+="\n    Expected: $expected_content"
                        results+="\n    Got: $actual_content"
                        echo -e "${RED}Test ${test_num}: FAILED ✗ - Wrong Answer${NC}" >&2
                        echo -e "${YELLOW}    Expected: $expected_content${NC}" >&2
                        echo -e "${YELLOW}    Got: $actual_content${NC}" >&2
                        ;;
                    "COMPILATION_ERROR")
                        results+="\n  Test ${test_num}: FAILED ✗"
                        results+="\n    Result: Compilation Error"
                        echo -e "${RED}Test ${test_num}: FAILED ✗ - Compilation Error${NC}" >&2
                        ;;
                    "TIME_LIMIT_EXCEEDED")
                        results+="\n  Test ${test_num}: FAILED ✗"
                        results+="\n    Result: Time Limit Exceeded (${time_limit} seconds)"
                        echo -e "${RED}Test ${test_num}: FAILED ✗ - Time Limit Exceeded${NC}" >&2
                        ;;
                    "RUNTIME_ERROR")
                        results+="\n  Test ${test_num}: FAILED ✗"
                        results+="\n    Result: Runtime Error"
                        echo -e "${RED}Test ${test_num}: FAILED ✗ - Runtime Error${NC}" >&2
                        ;;
                    *)
                        results+="\n  Test ${test_num}: ERROR"
                        results+="\n    Result: System Error"
                        echo -e "${RED}Test ${test_num}: ERROR - System Error${NC}" >&2
                        ;;
                esac
            else
                results+="\n  Test ${test_num}: ERROR (missing expected output file)"
                echo -e "${RED}Test ${test_num}: ERROR - Missing expected output file${NC}" >&2
            fi
            
            sleep 0.3  # Brief pause between tests
        fi
    done
    
    # Cleanup
    rm -rf "$temp_dir"
    trap - EXIT
    
    if [[ $total_tests -eq 0 ]]; then
        results="No test cases found for this problem."
        echo -e "${YELLOW}No test cases found for this problem.${NC}" >&2
    else
        results="Summary: $passed_tests/$total_tests tests passed\n$results"
        echo >&2
        echo -e "${CYAN}Summary: $passed_tests/$total_tests tests passed${NC}" >&2
    fi
    
    echo -e "$results"
}

# Main submission function
submit_solution() {
    local username="$1"
    
    while true; do
        clear_screen
        show_header "SUBMIT SOLUTION - Press ESC to go back"
        
        echo -e "${YELLOW}💡 Tip: Press ESC key to return to previous menu${NC}"
        echo -e "${YELLOW}💡 Make sure your solution file is ready before submitting${NC}"
        echo
        
        # Get problem ID
        echo -e "${CYAN}Enter the Problem ID you want to submit for:${NC}"
        echo -e "${YELLOW}Example: P001, P002, etc.${NC}"
        
        local problem_id
        if ! read_input_esc "Problem ID: " problem_id; then
            clear_screen
            return
        fi
        
        if [[ -z "$problem_id" ]]; then
            show_message "Problem ID cannot be empty!" "error"
            sleep 2
            continue
        fi
        
        # Convert to uppercase and validate format
        problem_id=$(echo "$problem_id" | tr '[:lower:]' '[:upper:]')
        if [[ ! "$problem_id" =~ ^P[0-9]{3}$ ]]; then
            show_message "Invalid Problem ID format. Use format like P001, P002, etc." "error"
            sleep 2
            continue
        fi
        
        # Find the problem
        local problem_name
        if problem_name=$(find_problem_by_id "$problem_id"); then
            echo -e "${GREEN}✓ Found problem: $problem_name${NC}"
            sleep 1
        else
            show_message "Problem $problem_id not found!" "error"
            sleep 2
            continue
        fi
        
        local problem_dir="$PROBLEMS_DIR/$problem_name"
        
        # Get solution file
        local solution_file
        if ! prompt_and_validate_solution_file solution_file; then
            case $? in
                1) clear_screen; return ;;  # ESC pressed
                *) continue ;;              # Other errors
            esac
        fi
        
        # Detect language
        local extension=$(get_file_extension "$solution_file")
        local language=$(detect_language "$extension")
        
        # Show submission summary
        clear_screen
        show_header "SUBMISSION SUMMARY"
        
        echo -e "${CYAN}Submission Details:${NC}"
        echo -e "${YELLOW}Problem:${NC} $problem_id - $(echo "$problem_name" | cut -d'_' -f2- | tr '_' ' ')"
        echo -e "${YELLOW}Solution File:${NC} $(basename "$solution_file")"
        echo -e "${YELLOW}Language:${NC} $language"
        echo -e "${YELLOW}File Path:${NC} $solution_file"
        echo
        
        echo -e "${CYAN}Do you want to submit this solution? (y/n):${NC}"
        read -n 1 -s choice
        echo
        
        case $choice in
            [Yy])
                # Generate submission ID
                local submission_id=$(generate_submission_id "$username")
                
                echo -e "${YELLOW}Processing submission...${NC}"
                sleep 1
                
                # Save submission
                if saved_file=$(save_submission "$username" "$problem_id" "$solution_file" "$submission_id"); then
                    echo -e "${GREEN}✓ Solution saved successfully${NC}"
                else
                    show_message "Failed to save submission!" "error"
                    sleep 2
                    continue
                fi
                
                # Run tests (simulation)
                clear_screen
                show_header "RUNNING TESTS"
                test_results=$(run_tests_execution "$problem_dir" "$solution_file" "$language")
                
                # Strip ANSI color codes from test results for clean report
                clean_test_results=$(echo "$test_results" | sed 's/\x1b\[[0-9;]*m//g')
                
                # Create report
                report_file=$(create_submission_report "$username" "$problem_id" "$problem_name" "$solution_file" "$language" "$submission_id" "$clean_test_results")
                
                # Log the submission
                log_action "SUBMIT_SOLUTION" "$username" "Submitted solution for $problem_id (Language: $language, File: $(basename "$solution_file"))"
                
                # Show success message
                echo
                echo -e "${GREEN}✓ Submission completed successfully!${NC}"
                echo -e "${CYAN}Submission ID: $submission_id${NC}"
                echo -e "${CYAN}Report saved to: $(basename "$report_file")${NC}"
                echo
                echo -e "${YELLOW}Press any key to continue...${NC}"
                read -n 1 -s
                
                clear_screen
                return
                ;;
            [Nn])
                show_message "Submission cancelled." "info"
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
