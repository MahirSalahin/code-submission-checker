# Logs Directory

This directory contains system logs and activity tracking files.

## Files

- `system.log` - Main system log file (auto-created)
  - Contains timestamped entries for all system activities
  - Format: `[timestamp] [action] [username] message`

## Log Levels

- **SIGNIN/SIGNOUT** - User authentication events
- **REGISTER** - User registration events  
- **SUBMIT** - Code submission events
- **COMPILE** - Compilation activities
- **TEST** - Test execution events
- **REPORT** - Report generation activities
- **ERROR** - System errors
- **INFO** - General information
- **SYSTEM** - System-level events

## Maintenance

- Logs are automatically rotated to prevent excessive disk usage
- Old logs are backed up before cleanup
- Use the built-in logging utilities for consistent formatting

## Analysis

The system provides built-in tools for log analysis:
- View recent activity
- Filter by user or action type
- Generate summary reports
