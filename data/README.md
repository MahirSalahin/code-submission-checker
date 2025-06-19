# Data Directory

This directory contains all persistent application data for the Code Submission Checker system.

## Directory Structure

```
data/
├── users.txt           # User accounts database (auto-created)
├── problems/           # Problem statements and test cases
│   ├── P001_HelloWorld/
│   │   ├── problem.txt
│   │   ├── test1.in
│   │   ├── test1.out
│   │   └── ...
│   ├── P002_SumNumbers/
│   │   └── ...
│   └── ...
├── submissions/        # Student code submissions
│   ├── P001_HelloWorld/
│   │   ├── student_2021331001/
│   │   │   ├── solution.c
│   │   │   ├── results.txt
│   │   │   └── timestamp.log
│   │   └── ...
│   └── ...
└── reports/           # Generated reports and analytics
    ├── daily_report_20250619.txt
    ├── student_performance_2021331001.txt
    └── system_analytics_202506.txt
```

## File Descriptions

### User Management
- **`users.txt`** - User accounts database
  - Format: `username:role:hashed_password`
  - Permissions: 600 (read/write for owner only)
  - Auto-created on first run

### Problems Directory
- **Problem Storage**: Complete problem packages with ID and title
- **Structure**: `P{ID}_{Title}/` format (e.g., P001_HelloWorld)
- **Contents**: 
  - `problem.txt` - Complete problem statement
  - `test*.in` - Input test cases
  - `test*.out` - Expected outputs
- **Management**: Teachers can add, edit, and delete problems

### Submissions Directory
- **Organization**: Grouped by problem, then by student
- **Structure**: `{ProblemID}/{StudentID}/`
- **Contents**:
  - Source code files (.c, .cpp, .cs, .java, .py)
  - Test results and grading information
  - Submission timestamps and metadata
- **Access Control**: Students see only their own submissions

### Reports Directory
- **Generated Content**: System-generated analytics and reports
- **Types**:
  - Student performance reports
  - Teacher analytics
  - System usage statistics
  - Assignment completion tracking
- **Formats**: TXT, CSV for easy processing

## Security and Permissions

### File Permissions
- **User Database**: 600 (owner read/write only)
- **Problems**: 644 (read for all, write for teachers)
- **Submissions**: 755 (directory access with controlled file access)
- **Reports**: 644 (read for authorized users)

### Access Control
- **Students**: Read problems, read/write own submissions, read own reports
- **Teachers**: Full access to all data except user passwords
- **System**: Automated backup and maintenance access

## Data Management

### Backup Strategy
```bash
# Backup entire data directory
tar -czf backup_$(date +%Y%m%d_%H%M%S).tar.gz data/

# Restore from backup
tar -xzf backup_file.tar.gz
```

### Maintenance
- **Log Rotation**: Automatic cleanup of old submission logs
- **Report Archival**: Monthly archival of old reports
- **Problem Versioning**: Track changes to problem statements
- **User Activity**: Monitor and log all data access

## Development Notes

### Adding New Data Types
When adding new features that require data storage:

1. **Create subdirectory** under `data/`
2. **Update configuration** in `src/config/config.sh`
3. **Set appropriate permissions** in initialization code
4. **Add to backup/restore procedures**
5. **Document in this README**

### Path Configuration
All data paths are centrally configured in `src/config/config.sh`:
```bash
DATA_DIR="$PROJECT_ROOT/data"
PROBLEMS_DIR="$DATA_DIR/problems"
SUBMISSIONS_DIR="$DATA_DIR/submissions"
REPORTS_DIR="$DATA_DIR/reports"
USERS_FILE="$DATA_DIR/users.txt"
```

## Migration and Deployment

### Production Deployment
- **Data Isolation**: Data directory can be mounted separately
- **Database Migration**: Easy to migrate to database backend
- **Scaling**: Directory structure supports horizontal scaling
- **Monitoring**: Centralized logging and metrics collection

### Development Setup
- **Local Testing**: Self-contained data environment
- **Version Control**: Data directory excluded from git
- **Test Data**: Separate test data sets for development

This centralized data structure provides a clean, professional, and scalable foundation for the Code Submission Checker system.
