#!/usr/bin/env bash

# Claude Code post-edit hook for running StandardRB, RSpec, and code standards checking

# Read JSON input from stdin
input=$(cat)

# Log that hook was triggered
echo "$(date): Hook triggered with input: $input" >> /tmp/claude-hook.log

# Parse the JSON input to get the file path
file_path=$(jq -r ".tool_input.file_path" <<< "$input")

# Log the parsed file path
echo "$(date): Parsed file path: $file_path" >> /tmp/claude-hook.log

# Check if it's a Ruby file
if [[ "$file_path" == *.rb ]]; then
    # Run RuboCop with our custom cops first
    echo "$(date): Running RuboCop on $file_path..." >> /tmp/claude-hook.log
    bundle exec rubocop "$file_path" --autocorrect-all 2>&1
    echo "$(date): RuboCop completed for $file_path" >> /tmp/claude-hook.log
    
    # Run StandardRB to ensure it has the final say
    echo "$(date): Running StandardRB on $file_path..." >> /tmp/claude-hook.log
    bundle exec standardrb --fix "$file_path"
    echo "$(date): StandardRB completed for $file_path" >> /tmp/claude-hook.log
    
    # Run code standards check
    echo "$(date): Running code standards check on $file_path..." >> /tmp/claude-hook.log
    standards_output=$(bin/code-standards-check "$file_path" 2>&1)
    standards_exit_code=$?
    
    echo "$(date): Code standards check completed with exit code $standards_exit_code" >> /tmp/claude-hook.log
    
    # If code standards failed, pass the failure back to Claude
    if [ $standards_exit_code -ne 0 ]; then
        echo "$(date): Code standards violations found, passing to Claude" >> /tmp/claude-hook.log
        echo "Code standards violations in $file_path:" >&2
        echo "$standards_output" >&2
        exit 2
    fi
    
    # If it's a spec file, also run rspec on it
    echo "$(date): Checking if '$file_path' contains '/spec/' pattern..." >> /tmp/claude-hook.log
    if [[ "$file_path" == */spec/* ]]; then
        echo "$(date): YES - Running RSpec on $file_path..." >> /tmp/claude-hook.log
        
        # Run RSpec and capture output and exit code
        rspec_output=$(bundle exec rspec "$file_path" 2>&1)
        rspec_exit_code=$?
        
        echo "$(date): RSpec completed for $file_path with exit code $rspec_exit_code" >> /tmp/claude-hook.log
        
        # If RSpec failed, pass the failure back to Claude
        if [ $rspec_exit_code -ne 0 ]; then
            echo "$(date): RSpec failed, passing error to Claude" >> /tmp/claude-hook.log
            echo "RSpec test failure in $file_path:" >&2
            echo "$rspec_output" >&2
            exit 2
        fi
    else
        echo "$(date): NO - '$file_path' does not contain '/spec/' pattern" >> /tmp/claude-hook.log
    fi
fi
