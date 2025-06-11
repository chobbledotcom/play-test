#!/usr/bin/env bash

echo "=== Test 2: Simple Prompt ==="
echo "Trying: claude -p 'say hello'"
claude -p "say hello"
echo "Exit code: $?"