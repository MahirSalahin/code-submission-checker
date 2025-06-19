# =============================================================================
# Problems Module
# =============================================================================
# Functions for browsing and managing programming problems
# =============================================================================

source "$(dirname "${BASH_SOURCE[0]}")/../config/config.sh"
source "$(dirname "${BASH_SOURCE[0]}")/../utils/ui.sh"
source "$(dirname "${BASH_SOURCE[0]}")/../utils/logging.sh"

# =============================================================================
# Problem Browsing Functions
# =============================================================================

# Find problem directory by ID
find_problem_by_id() {
    local problem_id="$1"
    
    for problem_dir in "$PROBLEMS_DIR"/P[0-9][0-9][0-9]_*; do
        if [[ -d "$problem_dir" ]]; then
            local dir_name=$(basename "$problem_dir")
            local dir_id=$(echo "$dir_name" | cut -d'_' -f1)
            
            if [[ "$dir_id" == "$problem_id" ]]; then
                echo "$dir_name"
                return 0
            fi
        fi
    done
    
    return 1
}

# List all available problems with pagination
list_problems() {
    local search_term="${1:-}"
    local page="${2:-1}"
    local problems_per_page=10
    
    if [[ ! -d "$PROBLEMS_DIR" ]]; then
        echo "No problems directory found."
        return 1
    fi
    
    # Collect all matching problems first
    local -a matching_problems=()
    
    for problem_dir in "$PROBLEMS_DIR"/P[0-9][0-9][0-9]_*; do
        if [[ -d "$problem_dir" ]]; then
            local problem_name=$(basename "$problem_dir")
            
            # Apply search filter if provided (case-insensitive)
            if [[ -n "$search_term" ]]; then
                local problem_name_lower=$(echo "$problem_name" | tr '[:upper:]' '[:lower:]')
                local search_term_lower=$(echo "$search_term" | tr '[:upper:]' '[:lower:]')
                if [[ ! "$problem_name_lower" =~ $search_term_lower ]]; then
                    continue
                fi
            fi
            
            matching_problems+=("$problem_name")
        fi
    done
    
    local total_problems=${#matching_problems[@]}
    
    if [[ $total_problems -eq 0 ]]; then
        if [[ -n "$search_term" ]]; then
            echo "No problems found matching '$search_term'"
        else
            echo "No problems available"
        fi
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
    for ((i=start_index; i<=end_index; i++)); do
        local problem_name="${matching_problems[$i]}"
        local problem_id=$(echo "$problem_name" | cut -d'_' -f1)
        local problem_title=$(echo "$problem_name" | cut -d'_' -f2- | tr '_' ' ')
        printf "%-8s %-50s\n" "$problem_id" "$problem_title"
    done
    
    # Show pagination info
    echo
    echo -e "${CYAN}Page $page of $total_pages (Showing $((start_index + 1))-$((end_index + 1)) of $total_problems problems)${NC}"
    
    # Return pagination info for caller
    export CURRENT_PAGE=$page
    export TOTAL_PAGES=$total_pages
    export TOTAL_PROBLEMS=$total_problems
    
    return 0
}

# Show problem details
show_problem_details() {
    local input="$1"
    local problem_name=""
    
    # Check if input is a problem ID (P001, P002, etc.) or full name
    if [[ "$input" =~ ^P[0-9][0-9][0-9]$ ]]; then
        # It's a problem ID, find the corresponding directory
        problem_name=$(find_problem_by_id "$input")
        if [[ -z "$problem_name" ]]; then
            show_message "Problem not found with ID: $input" "error"
            return 1
        fi
    else
        # It's a full problem name
        problem_name="$input"
    fi
    
    local problem_path="$PROBLEMS_DIR/$problem_name"
    
    if [[ ! -d "$problem_path" ]]; then
        show_message "Problem not found: $problem_name" "error"
        return 1
    fi
    
    local problem_file="$problem_path/problem.txt"
    if [[ ! -f "$problem_file" ]]; then
        show_message "Problem description not found" "error"
        return 1
    fi
    
    clear_screen
    show_header "PROBLEM DETAILS"
    
    # Display problem content
    cat "$problem_file"
    
    echo
    show_separator
    echo
    
    # Show available test cases
    local test_count=$(find "$problem_path" -name "test*.in" | wc -l)
    echo -e "${CYAN}Test Cases Available: ${YELLOW}$test_count${NC}"
    
    echo
    echo -e "${YELLOW}Press any key to continue...${NC}"
    read -n 1 -s
}

# Browse problems interface
browse_problems() {
    local username="$1"
    local current_page=1
    
    while true; do
        clear_screen
        show_header "BROWSE PROBLEMS"
        
        echo -e "${CYAN}Available Problems:${NC}"
        echo
        printf "%-8s %-50s\n" "ID" "TITLE"
        show_separator "-" 60
        
        if list_problems "" "$current_page"; then
            echo
            echo -e "${CYAN}Options:${NC}"
            echo -e "${YELLOW}1.${NC} View problem details"
            echo -e "${YELLOW}2.${NC} Search problems"
            
            # Show navigation options if there are multiple pages
            if [[ $TOTAL_PAGES -gt 1 ]]; then
                if [[ $current_page -gt 1 ]]; then
                    echo -e "${YELLOW}3.${NC} Previous page"
                fi
                if [[ $current_page -lt $TOTAL_PAGES ]]; then
                    echo -e "${YELLOW}4.${NC} Next page"
                fi
                echo -e "${YELLOW}5.${NC} Go to specific page"
                echo -e "${YELLOW}6.${NC} Refresh list"
                echo -e "${YELLOW}7.${NC} Back to dashboard"
            else
                echo -e "${YELLOW}3.${NC} Refresh list"
                echo -e "${YELLOW}4.${NC} Back to dashboard"
            fi
            echo
            
            read -p "$(echo -e "${CYAN}Enter your choice: ${NC}")" choice
            
            case $choice in
                1)
                    echo
                    read -p "$(echo -e "${CYAN}Enter problem ID (e.g., P001): ${NC}")" problem_input
                    if [[ -n "$problem_input" ]]; then
                        show_problem_details "$problem_input"
                        log_action "VIEW_PROBLEM" "$username" "Viewed problem: $problem_input"
                    fi
                    ;;
                2)
                    search_problems "$username"
                    current_page=1  # Reset to first page after search
                    ;;
                3)
                    if [[ $TOTAL_PAGES -gt 1 && $current_page -gt 1 ]]; then
                        ((current_page--))
                    else
                        # This is "Refresh list" when there's only one page
                        current_page=1
                    fi
                    ;;
                4)
                    if [[ $TOTAL_PAGES -gt 1 && $current_page -lt $TOTAL_PAGES ]]; then
                        ((current_page++))
                    else
                        # This is "Back to dashboard" when there's only one page
                        clear_screen
                        return
                    fi
                    ;;
                5)
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
                6)
                    if [[ $TOTAL_PAGES -gt 1 ]]; then
                        current_page=1
                    fi
                    ;;
                7)
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
            echo -e "${YELLOW}No problems available yet.${NC}"
            echo
            read -p "$(echo -e "${CYAN}Press any key to go back...${NC}")" -n 1
            clear_screen
            return
        fi
    done
}

# Search problems interface
search_problems() {
    local username="$1"
    
    while true; do
        clear_screen
        show_header "SEARCH PROBLEMS"
        
        local search_term
        echo -e "${CYAN}Enter search term (problem ID or title keywords):${NC}"
        if ! read_input_esc "Search: " search_term; then
            clear_screen
            return
        fi
        
        if [[ -z "$search_term" ]]; then
            show_message "Search term cannot be empty!" "error"
            sleep 2
            continue
        fi
        
        # Search with pagination
        local current_page=1
        
        while true; do
            clear_screen
            show_header "SEARCH RESULTS"
            
            echo -e "${CYAN}Search Results for: ${YELLOW}$search_term${NC}"
            echo
            printf "%-8s %-50s\n" "ID" "TITLE"
            show_separator "-" 60
            
            if list_problems "$search_term" "$current_page"; then
                echo
                echo -e "${CYAN}Options:${NC}"
                echo -e "${YELLOW}1.${NC} View problem details"
                
                # Show navigation options if there are multiple pages
                if [[ $TOTAL_PAGES -gt 1 ]]; then
                    if [[ $current_page -gt 1 ]]; then
                        echo -e "${YELLOW}2.${NC} Previous page"
                    fi
                    if [[ $current_page -lt $TOTAL_PAGES ]]; then
                        echo -e "${YELLOW}3.${NC} Next page"
                    fi
                    echo -e "${YELLOW}4.${NC} Go to specific page"
                    echo -e "${YELLOW}5.${NC} New search"
                    echo -e "${YELLOW}6.${NC} Back to browse problems"
                else
                    echo -e "${YELLOW}2.${NC} New search"
                    echo -e "${YELLOW}3.${NC} Back to browse problems"
                fi
                echo
                
                read -p "$(echo -e "${CYAN}Enter your choice: ${NC}")" choice
                
                case $choice in
                    1)
                        echo
                        read -p "$(echo -e "${CYAN}Enter problem ID (e.g., P001): ${NC}")" problem_input
                        if [[ -n "$problem_input" ]]; then
                            show_problem_details "$problem_input"
                            log_action "VIEW_PROBLEM" "$username" "Viewed problem: $problem_input (via search: $search_term)"
                        fi
                        ;;
                    2)
                        if [[ $TOTAL_PAGES -gt 1 && $current_page -gt 1 ]]; then
                            ((current_page--))
                        else
                            # This is "New search" when there's only one page
                            break
                        fi
                        ;;
                    3)
                        if [[ $TOTAL_PAGES -gt 1 && $current_page -lt $TOTAL_PAGES ]]; then
                            ((current_page++))
                        else
                            # This is "Back to browse problems" when there's only one page
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
                            break  # New search
                        fi
                        ;;
                    6)
                        if [[ $TOTAL_PAGES -gt 1 ]]; then
                            clear_screen
                            return  # Back to browse problems
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
                echo -e "${YELLOW}Try different keywords or check the spelling.${NC}"
                echo
                read -p "$(echo -e "${CYAN}Press any key to continue...${NC}")" -n 1
                break
            fi
        done
        
        log_action "SEARCH_PROBLEMS" "$username" "Searched for: $search_term"
    done
}
