# Submissions Directory

This directory stores student code submissions organized by assignment and user.

## Structure

```
submissions/
├── assignment_name/
│   ├── student_id_1/
│   │   ├── solution.c
│   │   ├── results.txt
│   │   └── timestamp.log
│   └── student_id_2/
│       ├── solution.cpp
│       ├── results.txt
│       └── timestamp.log
└── incoming/           # For batch processing
    ├── file1.c
    ├── file2.cpp
    └── file3.py
```

## Organization

- **Assignment folders**: Created automatically when problems are added
- **Student folders**: Individual directories for each student's submission
- **Incoming folder**: For batch processing of multiple submissions
- **Results files**: Contain test results and grading information

## File Types

Supported submission file types:
- `.c` - C source files
- `.cpp` - C++ source files  
- `.cs` - C# source files
- `.java` - Java source files
- `.py` - Python source files

## Processing

1. Files are validated for correct extension
2. Code is compiled (if required)
3. Tests are executed against provided test cases
4. Results are stored with the submission
5. Files are moved to appropriate assignment/student directory

## Access Control

- Students can only access their own submissions
- Teachers can access all submissions
- System maintains audit trail of all access
