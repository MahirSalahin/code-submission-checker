# =============================================================================
# Teacher Reports Module
# =============================================================================
# Functions for teachers to view and manage submission reports
# =============================================================================

source "$(dirname "${BASH_SOURCE[0]}")/../config/config.sh"
source "$(dirname "${BASH_SOURCE[0]}")/../utils/ui.sh"
source "$(dirname "${BASH_SOURCE[0]}")/../utils/logging.sh"

# Load the problems module to reuse problem lookup functions
source "$(dirname "${BASH_SOURCE[0]}")/../problems/problems.sh"

# =============================================================================
# Report Management Functions
# =============================================================================

# Get all reports for a specific problem ID
get_reports_for_problem() {
    local problem_id="$1"
    local -a reports=()
    
    # Find all report files that contain the problem ID
    if [[ -d "$REPORTS_DIR" ]]; then
        for report_file in "$REPORTS_DIR"/*_report.txt; do
            if [[ -f "$report_file" ]]; then
                # Check if this report is for the specified problem
                if grep -q "Problem ID: $problem_id" "$report_file" 2>/dev/null; then
                    reports+=("$(basename "$report_file")")
                fi
            fi
        done
    fi
    
    # Sort reports by timestamp (newest first)
    if [[ ${#reports[@]} -gt 0 ]]; then
        IFS=$'\n' reports=($(sort -r <<< "${reports[*]}"))
        printf '%s\n' "${reports[@]}"
    fi
}

# Extract submission details from report filename and content
get_submission_details() {
    local report_file="$1"
    local report_path="$REPORTS_DIR/$report_file"
    
    if [[ ! -f "$report_path" ]]; then
        return 1
    fi
    
    # Extract details from report content
    local username=$(grep "Username:" "$report_path" | cut -d':' -f2 | xargs)
    local timestamp=$(grep "Timestamp:" "$report_path" | cut -d':' -f2- | xargs)
    local language=$(grep "Language:" "$report_path" | cut -d':' -f2 | xargs)
    local submission_id=$(grep "Submission ID:" "$report_path" | cut -d':' -f2 | xargs)
    
    # Extract test results summary
    local summary=""
    if grep -q "Summary:" "$report_path"; then
        summary=$(grep "Summary:" "$report_path" | head -1 | cut -d':' -f2 | xargs)
    else
        summary="No summary available"
    fi
    
    echo "$username|$timestamp|$language|$submission_id|$summary"
}

# Format submission timestamp for display
format_report_timestamp() {
    local timestamp="$1"
    
    # Try to parse different timestamp formats
    if [[ "$timestamp" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}[[:space:]][0-9]{2}:[0-9]{2}:[0-9]{2}$ ]]; then
        # Already in readable format (YYYY-MM-DD HH:MM:SS)
        echo "$timestamp"
    else
        # Return as-is if format is unexpected
        echo "$timestamp"
    fi
}

# Display reports with pagination
show_reports_for_problem() {
    local problem_id="$1"
    local page="${2:-1}"
    local reports_per_page=10
    
    # Get all reports for the problem
    local -a all_reports=()
    while IFS= read -r report; do
        if [[ -n "$report" ]]; then
            all_reports+=("$report")
        fi
    done < <(get_reports_for_problem "$problem_id")
    
    local total_reports=${#all_reports[@]}
    
    if [[ $total_reports -eq 0 ]]; then
        echo "No reports found for problem '$problem_id'"
        return 1
    fi
    
    # Calculate pagination
    local total_pages=$(( (total_reports + reports_per_page - 1) / reports_per_page ))
    local start_index=$(( (page - 1) * reports_per_page ))
    local end_index=$(( start_index + reports_per_page - 1 ))
    
    if [[ $end_index -ge $total_reports ]]; then
        end_index=$((total_reports - 1))
    fi
    
    # Display reports for current page
    echo -e "${CYAN}Reports for Problem $problem_id:${NC}"
    echo
    printf "%-4s %-12s %-20s %-10s %-16s %-20s\n" "No." "Username" "Timestamp" "Language" "Result" "Submission ID"
    show_separator "-" 80
    
    for ((i=start_index; i<=end_index; i++)); do
        local report_file="${all_reports[$i]}"
        local details=$(get_submission_details "$report_file")
        
        if [[ -n "$details" ]]; then
            IFS='|' read -r username timestamp language submission_id summary <<< "$details"
            local formatted_time=$(format_report_timestamp "$timestamp")
            local short_time=$(echo "$formatted_time" | cut -d' ' -f1,2 | cut -c1-19)
            local short_submission_id=$(echo "$submission_id" | cut -c1-19)
            
            # Extract pass/fail info from summary
            local result="N/A"
            if [[ "$summary" =~ ([0-9]+)/([0-9]+) ]]; then
                local passed="${BASH_REMATCH[1]}"
                local total="${BASH_REMATCH[2]}"
                if [[ "$passed" == "$total" ]]; then
                    result="PASS"
                else
                    result="FAIL"
                fi
                result="$result ($passed/$total)"
            fi
            
            # Format result with colors for display
            local colored_result="$result"
            if [[ "$result" =~ ^PASS ]]; then
                colored_result="${GREEN}$result${NC}"
            elif [[ "$result" =~ ^FAIL ]]; then
                colored_result="${RED}$result${NC}"
            fi
            
            printf "%-4s %-12s %-20s %-10s %-16s %-20s\n" \
                "$((i+1))" \
                "$(echo "$username" | cut -c1-11)" \
                "$short_time" \
                "$language" \
                "$result" \
                "$short_submission_id"
        fi
    done
    
    echo
    echo -e "${CYAN}Page $page of $total_pages (Showing $((start_index + 1))-$((end_index + 1)) of $total_reports reports)${NC}"
    
    # Export pagination info for caller
    export CURRENT_PAGE=$page
    export TOTAL_PAGES=$total_pages
    export TOTAL_REPORTS=$total_reports
    export DISPLAYED_REPORTS=()
    
    # Store displayed reports for selection
    for ((i=start_index; i<=end_index; i++)); do
        DISPLAYED_REPORTS+=("${all_reports[$i]}")
    done
    
    return 0
}

# View a specific report
view_report() {
    local report_file="$1"
    local report_path="$REPORTS_DIR/$report_file"
    
    if [[ ! -f "$report_path" ]]; then
        show_message "Report file not found: $report_file" "error"
        sleep 2
        return
    fi
    
    clear_screen
    show_header "SUBMISSION REPORT - $(basename "$report_file" _report.txt)"
    
    echo -e "${CYAN}Report Content:${NC}"
    echo -e "${GRAY}$(printf '=%.0s' {1..80})${NC}"
    echo
    
    # Display the report with some formatting
    while IFS= read -r line; do
        if [[ "$line" =~ ^=+$ ]]; then
            echo -e "${CYAN}$line${NC}"
        elif [[ "$line" =~ ^[A-Z][A-Za-z\ ]+:$ ]]; then
            echo -e "${YELLOW}$line${NC}"
        elif [[ "$line" =~ Test\ [0-9]+:\ PASSED ]]; then
            echo -e "${GREEN}$line${NC}"
        elif [[ "$line" =~ Test\ [0-9]+:\ FAILED ]]; then
            echo -e "${RED}$line${NC}"
        elif [[ "$line" =~ Summary:.*passed ]]; then
            if [[ "$line" =~ ([0-9]+)/([0-9]+) ]]; then
                local passed="${BASH_REMATCH[1]}"
                local total="${BASH_REMATCH[2]}"
                if [[ "$passed" == "$total" ]]; then
                    echo -e "${GREEN}$line${NC}"
                else
                    echo -e "${YELLOW}$line${NC}"
                fi
            else
                echo "$line"
            fi
        else
            echo "$line"
        fi
    done < "$report_path"
    
    echo
    echo -e "${GRAY}$(printf '=%.0s' {1..80})${NC}"
    echo
    echo -e "${YELLOW}Press any key to continue...${NC}"
    read -n 1 -s
}

# Main reports interface for teachers
see_reports() {
    local username="$1"
    
    while true; do
        clear_screen
        show_header "SEE REPORTS"
        
        # Get problem ID from teacher
        echo -e "${CYAN}Enter Problem ID to view reports (or press ESC to go back):${NC}"
        local problem_id
        if ! read_input_esc "Problem ID: " problem_id; then
            clear_screen
            return  # ESC was pressed
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
        
        # Validate problem exists
        local problem_name
        if ! problem_name=$(find_problem_by_id "$problem_id"); then
            show_message "Problem '$problem_id' does not exist!" "error"
            sleep 2
            continue
        fi
        
        # Show reports with pagination
        local current_page=1
        
        while true; do
            clear_screen
            show_header "REPORTS - Problem: $problem_id"
            
            if show_reports_for_problem "$problem_id" "$current_page"; then
                echo
                echo -e "${CYAN}Options:${NC}"
                echo -e "${YELLOW}1.${NC} View specific report"
                
                # Show navigation options if there are multiple pages
                if [[ $TOTAL_PAGES -gt 1 ]]; then
                    if [[ $current_page -gt 1 ]]; then
                        echo -e "${YELLOW}2.${NC} Previous page"
                    fi
                    if [[ $current_page -lt $TOTAL_PAGES ]]; then
                        echo -e "${YELLOW}3.${NC} Next page"
                    fi
                    echo -e "${YELLOW}4.${NC} Go to specific page"
                    echo -e "${YELLOW}5.${NC} Refresh reports"
                    echo -e "${YELLOW}6.${NC} Back to problem selection"
                else
                    echo -e "${YELLOW}2.${NC} Refresh reports"
                    echo -e "${YELLOW}3.${NC} Back to problem selection"
                fi
                echo
                
                read -p "$(echo -e "${CYAN}Enter your choice: ${NC}")" choice
                
                case $choice in
                    1)
                        echo
                        read -p "$(echo -e "${CYAN}Enter report number (1-${#DISPLAYED_REPORTS[@]}): ${NC}")" report_choice
                        if [[ "$report_choice" =~ ^[0-9]+$ ]] && [[ "$report_choice" -ge 1 ]] && [[ "$report_choice" -le ${#DISPLAYED_REPORTS[@]} ]]; then
                            local selected_report="${DISPLAYED_REPORTS[$((report_choice-1))]}"
                            view_report "$selected_report"
                            log_action "VIEW_REPORT" "$username" "Viewed report: $selected_report for problem $problem_id"
                        else
                            show_message "Invalid report number. Please select a number between 1 and ${#DISPLAYED_REPORTS[@]}." "error"
                            sleep 2
                        fi
                        ;;
                    2)
                        if [[ $TOTAL_PAGES -gt 1 && $current_page -gt 1 ]]; then
                            ((current_page--))
                        else
                            # This is "Refresh reports" when there's only one page
                            current_page=1
                        fi
                        ;;
                    3)
                        if [[ $TOTAL_PAGES -gt 1 && $current_page -lt $TOTAL_PAGES ]]; then
                            ((current_page++))
                        else
                            # This is "Back to problem selection" when there's only one page
                            break
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
                            break  # Back to problem selection
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
                echo -e "${YELLOW}No reports found for this problem yet.${NC}"
                echo
                read -p "$(echo -e "${CYAN}Press any key to go back...${NC}")" -n 1
                break
            fi
        done
        
        log_action "VIEW_REPORTS" "$username" "Viewed reports for problem: $problem_id"
    done
}
