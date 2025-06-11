#!/bin/bash

# fix_code_standards.sh - Automated code standards fixing script
# This script iteratively calls rake code_standards and instructs Claude to fix violations

set -e  # Exit on any error

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
    
    # Run rake code_standards and capture the output
    if ! violation_output=$(rake code_standards 2>&1); then
        echo "❌ Error running rake code_standards"
        exit 1
    fi
    
    # Check if there are any violations
    if echo "$violation_output" | grep -q "TOTAL: 0 violations found"; then
        echo "🎉 SUCCESS! No more code standards violations found!"
        echo "✅ All code standards have been fixed after $iteration iterations"
        exit 0
    fi
    
    # Extract violation count
    violation_count=$(echo "$violation_output" | grep "TOTAL:" | sed 's/.*TOTAL: \([0-9]*\) violations found.*/\1/')
    echo "📈 Found $violation_count violations remaining"
    
    # Show a sample of violations for context
    echo "📋 Sample violations:"
    echo "$violation_output" | grep -A 10 "LINE LENGTH VIOLATIONS\|METHOD LENGTH VIOLATIONS\|FILE LENGTH VIOLATIONS" | head -15
    
    echo
    echo "🤖 Calling Claude to fix next cluster..."
    echo "----------------------------------------"
    
    # Call Claude with specific instructions
    claude_prompt="Based on the rake code_standards output above, choose a logical cluster of related violations to fix (e.g., same file, same type of violation, related functionality). 

IMPORTANT REQUIREMENTS:
1. Consult CLAUDE.md before making ANY changes - follow the formatting rules exactly
2. NEVER use backslash continuation for strings - extract variables instead  
3. Extract variables for readability when lines are too long
4. Break down methods over 20 lines by extracting private methods
5. Remove WHAT comments, only keep WHY comments
6. Use modern Ruby syntax (endless methods, numbered parameters, etc.)
7. Run tests after changes to ensure no breakage
8. Apply StandardRB linting when done

Pick 3-5 related violations and fix them systematically. Focus on one area at a time for better maintainability."

    # Use Claude Code CLI to fix the violations
    if ! echo "$claude_prompt" | claude code; then
        echo "❌ Error calling Claude Code CLI"
        exit 1
    fi
    
    echo "✅ Claude completed fixing cluster in iteration $iteration"
    
    # Brief pause to avoid overwhelming the system
    sleep 1
done

echo "⚠️  WARNING: Reached maximum iterations ($max_iterations) without completing all fixes"
echo "📊 Running final violation check..."
rake code_standards
echo "🔚 Manual intervention may be required for remaining violations"