#!/bin/bash
# Create or update a pull request
# Usage: create-or-update-pr.sh <branch-name> <pr-title> <pr-body>

set -e

BRANCH_NAME="$1"
PR_TITLE="$2"
PR_BODY="$3"

if [ -z "$BRANCH_NAME" ] || [ -z "$PR_TITLE" ] || [ -z "$PR_BODY" ]; then
  echo "Usage: create-or-update-pr.sh <branch-name> <pr-title> <pr-body>"
  exit 1
fi

# Check if PR already exists
PR_NUMBER=$(gh pr list --head "$BRANCH_NAME" --json number --jq '.[0].number' || echo "")

if [ -z "$PR_NUMBER" ]; then
  echo "Creating new PR..."
  PR_NUMBER=$(gh pr create \
    --title "$PR_TITLE" \
    --body "$PR_BODY" \
    --base main \
    --head "$BRANCH_NAME" \
    --json number --jq '.number')
else
  echo "PR #$PR_NUMBER already exists, updating..."
  gh pr edit "$PR_NUMBER" --body "$PR_BODY"
fi

echo "$PR_NUMBER"
