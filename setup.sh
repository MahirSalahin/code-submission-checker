#!/bin/bash

# =============================================================================
# Setup Script for Code Submission Checker
# =============================================================================
# This script sets up the environment and dependencies
# =============================================================================

echo "==============================================================================="
echo "                    CODE SUBMISSION CHECKER SETUP"
echo "==============================================================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Function to print colored messages
print_message() {
    local color="$1"
    local message="$2"
    echo -e "${color}${message}${NC}"
}

# Check if we're on a Unix-like system
if [[ "$OSTYPE" == "linux-gnu"* || "$OSTYPE" == "darwin"* ]]; then
    print_message "$GREEN" "✓ Unix-like system detected"
    
    # Make scripts executable
    chmod +x main.sh
    chmod +x demo.sh
    
    print_message "$GREEN" "✓ Made scripts executable"
    
    # Check for required tools
    print_message "$CYAN" "🔍 Checking for required dependencies..."
    
    MISSING_DEPS=()
    
    # Check for compilers and interpreters
    command -v gcc >/dev/null 2>&1 || MISSING_DEPS+=("gcc")
    command -v g++ >/dev/null 2>&1 || MISSING_DEPS+=("g++")
    command -v python3 >/dev/null 2>&1 || MISSING_DEPS+=("python3")
    command -v java >/dev/null 2>&1 || MISSING_DEPS+=("openjdk-11-jdk")
    command -v javac >/dev/null 2>&1 || MISSING_DEPS+=("openjdk-11-jdk")
    
    # Check for Mono (C# support)
    if command -v mono >/dev/null 2>&1 && command -v mcs >/dev/null 2>&1; then
        print_message "$GREEN" "✓ Mono C# compiler found"
    else
        MISSING_DEPS+=("mono-complete")
    fi
    
    # Check for other tools
    command -v sha256sum >/dev/null 2>&1 || command -v shasum >/dev/null 2>&1 || MISSING_DEPS+=("coreutils")
    command -v diff >/dev/null 2>&1 || MISSING_DEPS+=("diffutils")
    
    if [[ ${#MISSING_DEPS[@]} -eq 0 ]]; then
        print_message "$GREEN" "✓ All dependencies are satisfied!"
    else
        print_message "$YELLOW" "⚠ Missing dependencies: ${MISSING_DEPS[*]}"
        echo
        print_message "$CYAN" "📝 To install missing dependencies on Ubuntu/Debian:"
        echo "   sudo apt update"
        echo "   sudo apt install ${MISSING_DEPS[*]}"
        echo
        print_message "$CYAN" "📝 To install missing dependencies on CentOS/RHEL:"
        echo "   sudo yum install ${MISSING_DEPS[*]}"
        echo
        print_message "$CYAN" "📝 To install missing dependencies on macOS:"
        echo "   brew install ${MISSING_DEPS[*]}"
    fi
    
elif [[ "$OSTYPE" == "msys" || "$OSTYPE" == "cygwin" ]]; then
    print_message "$YELLOW" "⚠ Windows environment detected"
    print_message "$CYAN" "💡 For best experience, use WSL (Windows Subsystem for Linux)"
    print_message "$CYAN" "   Or install Git Bash with Unix tools"
else
    print_message "$RED" "❌ Unsupported operating system: $OSTYPE"
    exit 1
fi

echo
print_message "$GREEN" "🎉 Setup complete!"
print_message "$CYAN" "📚 Next steps:"
echo "   1. Run './demo.sh' to see project overview"
echo "   2. Run './main.sh' to start the application"
echo "   3. Create a test account and explore the features"
echo
print_message "$CYAN" "📖 For detailed information, see README.md"
echo "==============================================================================="
