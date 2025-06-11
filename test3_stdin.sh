#!/usr/bin/env bash

echo "=== Test 3: Stdin Method ==="
echo "Trying: echo 'say hello' | claude"
echo "say hello" | claude
echo "Exit code: $?"