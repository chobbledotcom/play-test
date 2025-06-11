#!/usr/bin/env bash

echo "=== Test 5: With Timeout ==="
echo "Trying: timeout 30 claude -p 'say hello'"
timeout 30 claude -p "say hello"
echo "Exit code: $?"