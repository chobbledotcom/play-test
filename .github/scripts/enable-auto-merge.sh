#!/bin/bash
# Enable auto-merge for a pull request
# Usage: enable-auto-merge.sh <pr-number>

set -e

PR_NUMBER="$1"

if [ -z "$PR_NUMBER" ]; then
  echo "Usage: enable-auto-merge.sh <pr-number>"
  exit 1
fi

echo "Enabling auto-merge for PR #$PR_NUMBER..."
gh pr merge "$PR_NUMBER" --auto --squash --delete-branch
