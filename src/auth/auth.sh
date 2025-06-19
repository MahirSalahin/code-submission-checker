# =============================================================================
# Authentication Module
# =============================================================================
# Functions for user registration, login, and session management
# =============================================================================

source "$(dirname "${BASH_SOURCE[0]}")/../config/config.sh"
source "$(dirname "${BASH_SOURCE[0]}")/../utils/logging.sh"

# =============================================================================
# User Management Functions
# =============================================================================

# Check if user exists
user_exists() {
    local username="$1"
    
    if [[ ! -f "$USERS_FILE" ]]; then
        return 1
    fi
    
    grep -q "^$username:" "$USERS_FILE" 2>/dev/null
}

# Hash password using sha256sum
hash_password() {
    local password="$1"
    echo -n "$password" | sha256sum | cut -d' ' -f1
}

# Register a new user
register_user() {
    local username="$1"
    local role="$2"
    local password="$3"
    
    # Validate input
    if [[ -z "$username" || -z "$role" || -z "$password" ]]; then
        return 1
    fi
    
    # Check if user already exists
    if user_exists "$username"; then
        return 1
    fi
    
    # Validate role
    if [[ "$role" != "student" && "$role" != "teacher" ]]; then
        return 1
    fi
    
    # Hash the password
    local hashed_password
    hashed_password=$(hash_password "$password")
    
    # Save user to file
    echo "$username:$role:$hashed_password" >> "$USERS_FILE"
    
    return 0
}

# Authenticate user
signin_user() {
    local username="$1"
    local password="$2"
    
    # Check if user exists
    if ! user_exists "$username"; then
        return 1
    fi
    
    # Get stored user data
    local user_line
    user_line=$(grep "^$username:" "$USERS_FILE" 2>/dev/null)
    
    if [[ -z "$user_line" ]]; then
        return 1
    fi
    
    # Extract stored password hash
    local stored_hash
    stored_hash=$(echo "$user_line" | cut -d':' -f3)
    
    # Hash the provided password
    local provided_hash
    provided_hash=$(hash_password "$password")
    
    # Compare hashes
    if [[ "$stored_hash" == "$provided_hash" ]]; then
        log_action "SIGNIN" "$username" "User signed in successfully"
        return 0
    else
        log_action "SIGNIN_FAILED" "$username" "Failed login attempt"
        return 1
    fi
}

# Get user role
get_user_role() {
    local username="$1"
    
    if ! user_exists "$username"; then
        return 1
    fi
    
    local user_line
    user_line=$(grep "^$username:" "$USERS_FILE" 2>/dev/null)
    
    echo "$user_line" | cut -d':' -f2
}

# Get user information
get_user_info() {
    local username="$1"
    
    if ! user_exists "$username"; then
        return 1
    fi
    
    grep "^$username:" "$USERS_FILE" 2>/dev/null
}

# Change user password
change_password() {
    local username="$1"
    local old_password="$2"
    local new_password="$3"
    
    # Verify old password
    if ! signin_user "$username" "$old_password" &>/dev/null; then
        return 1
    fi
    
    # Get user role
    local role
    role=$(get_user_role "$username")
    
    # Create new user entry
    local new_hash
    new_hash=$(hash_password "$new_password")
    local new_entry="$username:$role:$new_hash"
    
    # Create temporary file
    local temp_file
    temp_file=$(mktemp)
    
    # Write all users except the one being updated
    grep -v "^$username:" "$USERS_FILE" > "$temp_file" 2>/dev/null || true
    
    # Add updated user entry
    echo "$new_entry" >> "$temp_file"
    
    # Replace original file
    mv "$temp_file" "$USERS_FILE"
    
    log_action "PASSWORD_CHANGE" "$username" "Password changed successfully"
    return 0
}

# Validate username format
validate_username() {
    local username="$1"
    
    # Check length (3-20 characters)
    if [[ ${#username} -lt 3 || ${#username} -gt 20 ]]; then
        return 1
    fi
    
    # Check for valid characters (alphanumeric, underscore, hyphen)
    if [[ ! "$username" =~ ^[a-zA-Z0-9_-]+$ ]]; then
        return 1
    fi
    
    return 0
}

# Validate password strength
validate_password() {
    local password="$1"
    
    # Check minimum length
    if [[ ${#password} -lt $MIN_PASSWORD_LENGTH ]]; then
        return 1
    fi
    
    # Check for at least one letter and one number (optional, can be enabled)
    # if [[ ! "$password" =~ [a-zA-Z] || ! "$password" =~ [0-9] ]]; then
    #     return 1
    # fi
    
    return 0
}

# List all users (admin function)
list_users() {
    local role_filter="${1:-}"
    
    if [[ ! -f "$USERS_FILE" ]]; then
        echo "No users found."
        return 1
    fi
    
    echo "Username:Role:RegisterDate"
    echo "=========================="
    
    while IFS=':' read -r username role hash; do
        if [[ -z "$role_filter" || "$role" == "$role_filter" ]]; then
            echo "$username:$role"
        fi
    done < "$USERS_FILE"
}

# Delete user (admin function)
delete_user() {
    local username="$1"
    local admin_username="$2"
    
    # Check if user exists
    if ! user_exists "$username"; then
        return 1
    fi
    
    # Check if admin is actually a teacher/admin
    local admin_role
    admin_role=$(get_user_role "$admin_username")
    
    if [[ "$admin_role" != "teacher" ]]; then
        return 1
    fi
    
    # Create temporary file
    local temp_file
    temp_file=$(mktemp)
    
    # Write all users except the one being deleted
    grep -v "^$username:" "$USERS_FILE" > "$temp_file" 2>/dev/null || true
    
    # Replace original file
    mv "$temp_file" "$USERS_FILE"
    
    log_action "USER_DELETE" "$admin_username" "Deleted user: $username"
    return 0
}
