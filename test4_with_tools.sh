#!/usr/bin/env bash

echo "=== Test 4: With Tools Flag ==="
echo "Trying: claude -p 'say hello' --allowedTools Edit"
claude -p "say hello" --allowedTools Edit
echo "Exit code: $?"