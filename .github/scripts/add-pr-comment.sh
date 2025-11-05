#!/bin/bash
# Add a comment to a PR with unfixed issues
# Usage: add-pr-comment.sh <pr-number> <issues-file>

set -e

PR_NUMBER="$1"
ISSUES_FILE="$2"

if [ -z "$PR_NUMBER" ] || [ -z "$ISSUES_FILE" ]; then
  echo "Usage: add-pr-comment.sh <pr-number> <issues-file>"
  exit 1
fi

if [ ! -f "$ISSUES_FILE" ]; then
  echo "Error: Issues file not found: $ISSUES_FILE"
  exit 1
fi

# Build comment body
COMMENT_BODY=$(cat <<EOF
## 🔧 Manual Fixes Required

The following ERB lint issues could not be auto-corrected and need manual attention:

\`\`\`
$(cat "$ISSUES_FILE")
\`\`\`

Please review and fix these issues manually before merging.
EOF
)

# Post comment to PR
gh pr comment "$PR_NUMBER" --body "$COMMENT_BODY"
