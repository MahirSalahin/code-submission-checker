# Code Submission Checker

A professional CLI-based automated code submission and evaluation system built with Bash shell scripting.

## Overview

This system provides a comprehensive solution for automated code evaluation, supporting multiple programming languages (C, C++, C#, Java, Python) with role-based access control for students and teachers.

## Features

### Authentication System
- **User Registration**: Separate registration for students (using student ID) and teachers (using username)
- **Secure Login**: Password hashing using SHA-256 for security
- **Role-based Access**: Different menu options for students and teachers

### Student Features
- Browse available problems
- Submit solutions
- View personal submission history
- Real-time feedback on submissions

### Teacher Features
- Add new problems and test cases
- Generate and view comprehensive reports
- Manage student submissions

### System Features
- Multi-language support (C, C++, C#, Java, Python)
- Automated compilation and testing
- Detailed logging and reporting
- Professional CLI interface with colors and formatting

## Directory Structure

```
code-submission-checker/
├── main.sh                 # Main entry point
├── src/                    # Source code directory
│   ├── auth/              # Authentication modules
│   │   └── auth.sh        # User management functions
│   ├── config/            # Configuration files
│   │   └── config.sh      # System configuration
│   └── utils/             # Utility modules
│       ├── ui.sh          # User interface functions
│       └── logging.sh     # Logging utilities
├── data/                  # All application data
│   ├── users.txt         # User accounts (auto-created)
│   ├── problems/         # Problem statements and test cases
│   ├── submissions/      # Student code submissions
│   └── reports/          # Generated reports and analytics
├── logs/                  # System logs
│   └── system.log        # Main log file (auto-created)
└── docs/                  # Documentation and guides
```

## Installation

1. **Clone or download the project**:
   ```bash
   git clone <repository-url>
   cd code-submission-checker
   ```

2. **Make the main script executable**:
   ```bash
   chmod +x main.sh
   ```

3. **Install required dependencies** (Ubuntu/Debian):
   ```bash
   sudo apt update
   sudo apt install gcc g++ mono-complete openjdk-11-jdk python3
   ```

## Usage

### Starting the Application

```bash
./main.sh
```

### First Time Setup

1. **Run the application**: `./main.sh`
2. **Choose Sign Up** from the main menu
3. **Select your role**:
   - **Student**: Use your student ID as username
   - **Teacher**: Choose a username
4. **Create a secure password** (minimum 6 characters)
5. **Sign in** with your credentials

### Student Workflow

1. Sign in with your student ID and password
2. Choose from available options:
   - **Browse Problems**: View available assignments
   - **Submit Solution**: Upload your code files
   - **My Submissions**: Review your submission history
   - **Sign Out**: Exit your session

### Teacher Workflow

1. Sign in with your username and password
2. Access teacher features:
   - **Add Problem**: Create new assignments with test cases
   - **See Reports**: View student performance and statistics
   - **Sign Out**: Exit your session

## Security Features

- **Password Hashing**: All passwords are hashed using SHA-256
- **File Permissions**: Sensitive files have restricted access
- **Input Validation**: All user inputs are validated and sanitized
- **Session Management**: Secure login/logout functionality
- **Audit Logging**: All actions are logged with timestamps

## Supported Languages

| Language | Compiler/Interpreter | Execution |
|----------|---------------------|-----------|
| C        | gcc                 | Direct execution |
| C++      | g++                 | Direct execution |
| C#       | mcs (Mono)          | mono runtime |
| Java     | javac               | java runtime |
| Python   | python3             | Direct interpretation |

## Configuration

The system is configured through `src/config/config.sh`. Key settings include:

- **Directory paths**: Customizable storage locations
- **Security settings**: Password requirements, login attempts
- **Language support**: Compiler commands and execution methods
- **File extensions**: Supported file types

## Logging

All system activities are logged to `logs/system.log` with the following information:
- Timestamp
- Action type
- Username
- Detailed message

## Development
- *There might be issues with line endings. To run on unix systems, ensure files have LF endings:*
  ```bash
  find . -type f -exec dos2unix {} +
  ```
### Project Structure Philosophy

- **Modular Design**: Separate modules for different functionalities
- **Configuration Management**: Centralized configuration
- **Error Handling**: Comprehensive error checking and user feedback
- **Professional UI**: Clean, colored CLI interface
- **Security First**: Secure authentication and data handling

### Adding New Features

1. Create new modules in appropriate `src/` subdirectories
2. Update configuration in `src/config/config.sh` if needed
3. Add UI elements using functions from `src/utils/ui.sh`
4. Implement logging using `src/utils/logging.sh`
5. Test thoroughly with different user roles

## Troubleshooting

### Common Issues

1. **Permission Denied**: Ensure `main.sh` is executable
2. **Missing Dependencies**: Install required compilers/interpreters
3. **File Not Found**: Check that all paths are correctly configured
4. **Login Issues**: Verify username/password and check logs

### Log Analysis

Check system logs for detailed error information:
```bash
tail -f logs/system.log
```

## Contributing

1. Follow the existing code style and structure
2. Add appropriate logging for new features
3. Update documentation for any new functionality
4. Test with both student and teacher roles

---

For questions or support, please refer to the system logs or contact the development team.
