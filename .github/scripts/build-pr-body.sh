#!/bin/bash
# Build PR body with consistent formatting
# Usage: build-pr-body.sh <title> <description> <auto-merge-flag>

set -e

TITLE="$1"
DESCRIPTION="$2"
AUTO_MERGE="$3"

if [ -z "$TITLE" ] || [ -z "$DESCRIPTION" ]; then
  echo "Usage: build-pr-body.sh <title> <description> <auto-merge-flag>"
  exit 1
fi

# Get file changes stats
FILE_CHANGES=$(git diff --stat origin/main...HEAD 2>/dev/null || echo "No file changes")

# Build auto-merge message if enabled
AUTO_MERGE_MSG=""
if [ "$AUTO_MERGE" = "true" ]; then
  AUTO_MERGE_MSG="

This PR will automatically merge if all status checks pass."
fi

# Output the PR body
cat <<EOF
## $TITLE

$DESCRIPTION$AUTO_MERGE_MSG

### Files Changed
\`\`\`
$FILE_CHANGES
\`\`\`

---
*This PR is automatically generated and will be updated if new changes are detected.*
*Last updated: $(date -u '+%Y-%m-%d %H:%M UTC')*
EOF
