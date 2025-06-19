# =============================================================================
# Logging Utilities
# =============================================================================
# Functions for system logging and activity tracking
# =============================================================================

source "$(dirname "${BASH_SOURCE[0]}")/../config/config.sh"

# =============================================================================
# Logging Functions
# =============================================================================

# Initialize logging system
init_logging() {
    # Create log directory if it doesn't exist
    mkdir -p "$LOG_DIR"
    
    # Create log file if it doesn't exist
    touch "$LOG_FILE"
    
    # Set proper permissions
    chmod 644 "$LOG_FILE"
}

# Log an action with timestamp
log_action() {
    local action="$1"
    local username="$2"
    local message="$3"
    local timestamp
    
    # Initialize logging if not done
    init_logging
    
    # Generate timestamp
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    # Format log entry
    local log_entry="[$timestamp] [$action] [$username] $message"
    
    # Write to log file
    echo "$log_entry" >> "$LOG_FILE"
    
    # Also write to system log if available
    if command -v logger &> /dev/null; then
        logger -t "CodeChecker" "$log_entry"
    fi
}

# Log system events
log_system() {
    local event="$1"
    local message="$2"
    
    log_action "SYSTEM" "system" "$event: $message"
}

# Log error events
log_error() {
    local component="$1"
    local error_message="$2"
    local username="${3:-system}"
    
    log_action "ERROR" "$username" "$component: $error_message"
}

# Log info events
log_info() {
    local component="$1"
    local info_message="$2"
    local username="${3:-system}"
    
    log_action "INFO" "$username" "$component: $info_message"
}

# Get recent logs
get_recent_logs() {
    local lines="${1:-50}"
    
    if [[ -f "$LOG_FILE" ]]; then
        tail -n "$lines" "$LOG_FILE"
    else
        echo "No log file found."
    fi
}

# Get logs for specific user
get_user_logs() {
    local username="$1"
    local lines="${2:-50}"
    
    if [[ -f "$LOG_FILE" ]]; then
        grep "\[$username\]" "$LOG_FILE" | tail -n "$lines"
    else
        echo "No log file found."
    fi
}

# Get logs for specific action
get_action_logs() {
    local action="$1"
    local lines="${2:-50}"
    
    if [[ -f "$LOG_FILE" ]]; then
        grep "\[$action\]" "$LOG_FILE" | tail -n "$lines"
    else
        echo "No log file found."
    fi
}

# Clean old logs (keep last N days)
clean_old_logs() {
    local days_to_keep="${1:-30}"
    local backup_file="$LOG_DIR/system_backup_$(date '+%Y%m%d').log"
    
    if [[ -f "$LOG_FILE" ]]; then
        # Create backup
        cp "$LOG_FILE" "$backup_file"
        
        # Keep only recent logs
        local cutoff_date
        cutoff_date=$(date -d "$days_to_keep days ago" '+%Y-%m-%d')
        
        # Create temporary file with recent logs
        local temp_file
        temp_file=$(mktemp)
        
        awk -v cutoff="$cutoff_date" '
        {
            if (match($0, /\[([0-9]{4}-[0-9]{2}-[0-9]{2})/, date_match)) {
                if (date_match[1] >= cutoff) {
                    print $0
                }
            }
        }' "$LOG_FILE" > "$temp_file"
        
        # Replace original with cleaned logs
        mv "$temp_file" "$LOG_FILE"
        
        log_system "LOG_CLEANUP" "Cleaned logs older than $days_to_keep days, backup saved to $backup_file"
    fi
}

# Generate log report
generate_log_report() {
    local output_file="$1"
    local start_date="${2:-$(date -d '7 days ago' '+%Y-%m-%d')}"
    local end_date="${3:-$(date '+%Y-%m-%d')}"
    
    if [[ ! -f "$LOG_FILE" ]]; then
        echo "No log file found."
        return 1
    fi
    
    {
        echo "==============================================================================="
        echo "                         SYSTEM LOG REPORT"
        echo "==============================================================================="
        echo "Generated: $(date '+%Y-%m-%d %H:%M:%S')"
        echo "Period: $start_date to $end_date"
        echo "==============================================================================="
        echo
        
        echo "SUMMARY:"
        echo "--------"
        local total_entries
        total_entries=$(awk -v start="$start_date" -v end="$end_date" '
        {
            if (match($0, /\[([0-9]{4}-[0-9]{2}-[0-9]{2})/, date_match)) {
                if (date_match[1] >= start && date_match[1] <= end) {
                    count++
                }
            }
        }
        END { print count+0 }' "$LOG_FILE")
        
        echo "Total log entries: $total_entries"
        
        echo
        echo "ACTIVITY BY ACTION:"
        echo "-------------------"
        awk -v start="$start_date" -v end="$end_date" '
        {
            if (match($0, /\[([0-9]{4}-[0-9]{2}-[0-9]{2})/, date_match)) {
                if (date_match[1] >= start && date_match[1] <= end) {
                    if (match($0, /\[([A-Z_]+)\]/, action_match)) {
                        actions[action_match[1]]++
                    }
                }
            }
        }
        END {
            for (action in actions) {
                printf "%-20s: %d\n", action, actions[action]
            }
        }' "$LOG_FILE" | sort -k2 -nr
        
        echo
        echo "RECENT ENTRIES:"
        echo "---------------"
        awk -v start="$start_date" -v end="$end_date" '
        {
            if (match($0, /\[([0-9]{4}-[0-9]{2}-[0-9]{2})/, date_match)) {
                if (date_match[1] >= start && date_match[1] <= end) {
                    print $0
                }
            }
        }' "$LOG_FILE" | tail -20
        
        echo
        echo "==============================================================================="
    } > "$output_file"
    
    log_system "REPORT_GENERATED" "Log report generated: $output_file"
}

# Monitor logs in real-time
monitor_logs() {
    echo "Monitoring system logs (Press Ctrl+C to stop)..."
    echo "==============================================================================="
    
    if [[ -f "$LOG_FILE" ]]; then
        tail -f "$LOG_FILE"
    else
        echo "No log file found. Waiting for log entries..."
        while [[ ! -f "$LOG_FILE" ]]; do
            sleep 1
        done
        tail -f "$LOG_FILE"
    fi
}
