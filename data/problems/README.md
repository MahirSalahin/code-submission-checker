# Problems Directory

This directory contains programming problems with test cases added by teachers.

## Structure

```
problems/
├── P001_HelloWorld/
│   ├── test1.in          # Input for test case 1
│   ├── test1.out         # Expected output for test case 1
│   ├── test2.in          # Input for test case 2
│   ├── test2.out         # Expected output for test case 2
│   └── problem.txt       # Problem description and details
├── P002_SumNumbers/
│   ├── test1.in
│   ├── test1.out
│   ├── test2.in
│   ├── test2.out
│   ├── test3.in
│   ├── test3.out
│   └── problem.txt
├── P003_Palindrome/
│   ├── test1.in
│   ├── test1.out
│   ├── test2.in
│   ├── test2.out
│   └── problem.txt
└── templates/
    ├── input_template.txt
    └── output_template.txt
```

## Problem Organization

### Problem Naming Convention
- **Format**: `P{ID}_{Title}`
- **ID**: 3-digit zero-padded number (P001, P002, P003, etc.)
- **Title**: CamelCase descriptive name (HelloWorld, SumNumbers, Palindrome)
- **Examples**:
  - P001_HelloWorld
  - P002_SumNumbers
  - P003_Palindrome
  - P004_FibonacciSequence
  - P005_BinarySearch

### Problem Structure
Each problem directory contains:
- **Test files**: `test1.in`, `test1.out`, `test2.in`, `test2.out`, etc.
- **Problem description**: `problem.txt` with complete problem statement
- **Metadata**: Difficulty level, time limits, memory constraints

## File Format

### Problem Description (problem.txt)
```
PROBLEM ID: P001
TITLE: Hello World
DIFFICULTY: Easy
TIME LIMIT: 1 second
MEMORY LIMIT: 64 MB

DESCRIPTION:
Write a program that prints "Hello, World!" to the console.

INPUT FORMAT:
No input required.

OUTPUT FORMAT:
Print "Hello, World!" followed by a newline.

SAMPLE INPUT:
(empty)

SAMPLE OUTPUT:
Hello, World!

NOTES:
- This is a basic introduction problem
- Make sure to include the newline character
```

### Input Files (.in)
- Plain text files containing test input data
- One test case per file
- Follow problem-specific input format
- Can include multiple lines of data
- Named sequentially: test1.in, test2.in, test3.in, etc.

### Output Files (.out)
- Plain text files containing expected output
- Must match exactly with program output
- Include proper formatting (spaces, newlines)
- Case-sensitive comparison
- Named corresponding to input: test1.out, test2.out, test3.out, etc.

## Teacher Functions

### Adding New Problems
Teachers can add problems through the system interface:
1. Specify Problem ID (auto-incremented: P001, P002, etc.)
2. Enter Problem Title (descriptive name)
3. Write problem description with input/output format
4. Add multiple test cases (input/output pairs)
5. Set difficulty level and constraints

### Problem Management
- **Browse Problems**: View all existing problems
- **Edit Problems**: Modify problem details and test cases
- **Delete Problems**: Remove problems (with confirmation)
- **Test Validation**: Verify test cases work correctly

## Student Access

### Problem Browsing
Students can:
- View problem list with ID, Title, and Difficulty
- Read complete problem statements
- See sample input/output
- Check submission history for each problem

### Problem Selection
- Filter by difficulty level
- Search by title or keywords
- Sort by ID, difficulty, or submission count

## Test Case Guidelines

### Creating Effective Test Cases
1. **Edge Cases**: Include boundary conditions and extreme values
2. **Normal Cases**: Cover typical expected inputs
3. **Error Cases**: Test invalid inputs and error handling
4. **Performance Cases**: Large datasets for efficiency testing

### Test Case Examples

#### Example Problem: P002_SumNumbers
```
test1.in:
5 3

test1.out:
8

test2.in:
-2 7

test2.out:
5

test3.in:
0 0

test3.out:
0
```

## Validation Rules

### Input Validation
- All input files must have corresponding output files
- Input format must match problem specifications
- Files must be readable and properly formatted

### Output Validation
- Output must be exact match (including whitespace)
- Trailing newlines are significant
- Case sensitivity is enforced

### Problem ID Management
- IDs are auto-incremented starting from P001
- Once assigned, IDs cannot be reused
- Deleted problems leave gaps in numbering sequence

## File Permissions
- Teachers: Read/Write access to all problems
- Students: Read-only access to problem statements
- System: Automatic backup and versioning
1. **Edge Cases**: Empty input, boundary values, maximum limits
2. **Normal Cases**: Typical usage scenarios
3. **Corner Cases**: Special conditions, unusual but valid input
4. **Stress Tests**: Large datasets, performance validation

### File Naming
- Use sequential numbering: `test1.in`, `test2.in`, etc.
- Corresponding output files: `test1.out`, `test2.out`, etc.
- Descriptive names for special cases: `empty_input.in`, `max_size.in`

## Validation Process

1. Student code is compiled (if necessary)
2. Each `.in` file is fed as input to the program
3. Program output is captured and compared with corresponding `.out` file
4. Differences are reported with detailed analysis
5. Pass/fail status is recorded for each test case

## Management

- Teachers can add/modify test cases through the system
- Automatic validation of test case format
- Bulk import/export capabilities
- Version control for test case changes
