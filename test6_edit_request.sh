#!/usr/bin/env bash

echo "=== Test 6: Edit Request ==="

# Create a test file first
echo "line 1" > test_file.txt
echo "line 2" >> test_file.txt

echo "Created test file:"
cat test_file.txt

echo
echo "Asking Claude to edit it:"
claude -p "Please use the Edit tool to change 'line 1' to 'modified line 1' in the file test_file.txt" --allowedTools Edit

echo
echo "Result:"
cat test_file.txt
echo "Exit code: $?"