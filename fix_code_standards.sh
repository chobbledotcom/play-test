#!/usr/bin/env bash

# fix_code_standards.sh - Automated code standards fixing script
# This script iteratively calls rake code_standards and instructs Claude to fix violations

set -x  # Enable verbose debugging
# Don't exit on error anymore - we'll handle errors manually

echo "🔧 Starting automated code standards fixing..."
echo "================================================"

# Counter for iterations to prevent infinite loops
iteration=0
max_iterations=50

while [ $iteration -lt $max_iterations ]; do
    iteration=$((iteration + 1))
    echo
    echo "🔄 Iteration $iteration"
    echo "------------------------"
    
    # Check current violations
    echo "📊 Checking current code standards violations..."
    echo "🔍 Running: rake code_standards"
    
    # Run rake code_standards and capture the output
    echo "⏳ Executing rake command..."
    violation_output=$(rake code_standards 2>&1)
    rake_exit_code=$?
    
    echo "📋 Rake exit code: $rake_exit_code"
    echo "📏 Output length: ${#violation_output} characters"
    echo "🔍 First 500 chars of output:"
    echo "${violation_output:0:500}"
    echo "..."
    
    # Check if rake actually failed (not just violations found)
    echo "🔍 Checking if output contains 'violations found'..."
    if echo "$violation_output" | grep -q "violations found"; then
        echo "✅ Found 'violations found' in output - rake ran successfully"
    else
        echo "⚠️  Did not find 'violations found' in output"
        if [ $rake_exit_code -ne 0 ]; then
            echo "❌ Error running rake code_standards (exit code: $rake_exit_code)"
            echo "📄 Full output:"
            echo "$violation_output"
            exit 1
        fi
    fi
    
    # Check if there are any violations
    echo "🔍 Checking for completion (TOTAL: 0 violations found)..."
    if echo "$violation_output" | grep -q "TOTAL: 0 violations found"; then
        echo "🎉 SUCCESS! No more code standards violations found!"
        echo "✅ All code standards have been fixed after $iteration iterations"
        exit 0
    else
        echo "📊 Still have violations to fix..."
    fi
    
    # Extract violation count
    echo "🔍 Extracting violation count..."
    violation_count_line=$(echo "$violation_output" | grep "TOTAL:")
    echo "📊 Violation count line: '$violation_count_line'"
    
    if [ -n "$violation_count_line" ]; then
        violation_count=$(echo "$violation_count_line" | sed 's/.*TOTAL: \([0-9]*\) violations found.*/\1/')
        echo "📈 Found $violation_count violations remaining"
    else
        echo "⚠️  Could not find TOTAL line in output"
        echo "📄 Searching for 'TOTAL' in output:"
        echo "$violation_output" | grep -i total || echo "No lines containing 'total' found"
    fi
    
    # Show a sample of violations for context
    echo "📋 Sample violations:"
    echo "$violation_output" | grep -A 10 "LINE LENGTH VIOLATIONS\|METHOD LENGTH VIOLATIONS\|FILE LENGTH VIOLATIONS" | head -15
    
    echo
    echo "🤖 Calling Claude to fix next cluster..."
    echo "----------------------------------------"
    echo "🔍 Current working directory: $(pwd)"
    echo "🔍 Checking if claude command exists..."
    
    if ! command -v claude &> /dev/null; then
        echo "❌ 'claude' command not found in PATH"
        echo "📋 Available commands containing 'claude':"
        compgen -c | grep -i claude || echo "No claude commands found"
        exit 1
    fi
    
    # Truncate violation output to first 50 lines to avoid overwhelming Claude
    echo "🔍 Truncating violation output for Claude (first 50 lines)..."
    truncated_violations=$(echo "$violation_output" | head -50)
    
    # Call Claude with specific instructions including the violation data
    claude_prompt="I need you to fix code standards violations. Here's a sample of the current rake code_standards output (first 50 lines):

$truncated_violations

Based on this output, choose a logical cluster of related violations to fix (e.g., same file, same type of violation, related functionality). 

CRITICAL RULES - NO EXCEPTIONS:
1. ABSOLUTELY NO BACKSLASH CONTINUATION (\\) FOR STRINGS - This is FORBIDDEN
2. Instead of backslash continuation, extract variables: 
   BAD:  \"long string that needs\" \\
         \"to be broken\"
   GOOD: long_desc = \"long string that needs to be broken\"
3. Consult CLAUDE.md before making ANY changes - follow the formatting rules exactly
4. Extract variables for readability when lines are too long
5. Break down methods over 20 lines by extracting private methods
6. Remove WHAT comments, only keep WHY comments
7. Use modern Ruby syntax (endless methods, numbered parameters, etc.)
8. Run tests after changes to ensure no breakage
9. Apply StandardRB linting when done

REMEMBER: If you see \\(backslash) at end of line, that's WRONG. Extract to variables instead.

Pick 3-5 related violations and fix them systematically. Focus on one area at a time for better maintainability.

MANDATORY SELF-CHECK AFTER CHANGES:
After you make any edits, you MUST carefully review each change to verify it follows CLAUDE.md rules:
1. Check for any backslash continuations (\\) - these are FORBIDDEN 
2. Verify variables are extracted instead of long lines
3. Confirm methods are under 20 lines
4. Ensure only WHY comments remain (no WHAT comments)
5. Verify modern Ruby syntax is used where appropriate

If you find any rule violations in your own changes, fix them immediately before proceeding."

    echo "📝 Claude prompt prepared (${#claude_prompt} characters)"
    echo "⏳ Calling Claude Code CLI..."
    
    # Write prompt to file for better handling of large prompts
    prompt_file="/tmp/claude_prompt_$$"
    echo "$claude_prompt" > "$prompt_file"
    echo "📁 Wrote prompt to: $prompt_file"
    
    # Use Claude Code CLI to fix the violations  
    echo "🔍 Calling Claude with Edit tools..."
    echo "📝 Prompt file size: $(wc -c < "$prompt_file") bytes"
    echo "📋 Command: cat $prompt_file | claude --allowedTools Edit --verbose"
    echo "🔄 Starting execution..."
    
    # Use file-based approach for better handling
    cat "$prompt_file" | claude --allowedTools Edit --verbose
    claude_exit_code=${PIPESTATUS[1]}
    
    # Clean up prompt file
    rm -f "$prompt_file"
    
    if [ $claude_exit_code -ne 0 ]; then
        echo "❌ Claude command failed with exit code: $claude_exit_code"
        echo "🔄 Continuing to next iteration..."
        continue
    fi
    
    echo "✅ Claude completed fixing cluster in iteration $iteration"
    
    # Brief pause to avoid overwhelming the system
    sleep 1
done

echo "⚠️  WARNING: Reached maximum iterations ($max_iterations) without completing all fixes"
echo "📊 Running final violation check..."
rake code_standards
echo "🔚 Manual intervention may be required for remaining violations"