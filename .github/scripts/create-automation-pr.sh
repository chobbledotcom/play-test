#!/bin/bash
# Create or update an automated PR with standard formatting
# Usage: create-automation-pr.sh <type> <branch-name> [has-unfixed-issues]
#
# Types: annotations, standardrb, erb-lint

set -e

TYPE="$1"
BRANCH_NAME="$2"
HAS_UNFIXED="${3:-false}"

if [ -z "$TYPE" ] || [ -z "$BRANCH_NAME" ]; then
  echo "Usage: create-automation-pr.sh <type> <branch-name> [has-unfixed-issues]"
  exit 1
fi

# Get file changes stats
FILE_CHANGES=$(git diff --stat origin/main...HEAD 2>/dev/null || echo "No file changes")

# Build PR content based on type
case "$TYPE" in
  annotations)
    PR_TITLE="Update Attributions & Annotations"
    BODY_TITLE="Weekly Automated Update"
    BODY_DESCRIPTION="This PR contains automated updates for:
- 📝 Model annotations (from database schema)
- 🛣️ Route annotations (from Rails routes)
- 📦 Third-party attributions (from dependencies)"
    AUTO_MERGE="true"
    ;;
    
  standardrb)
    PR_TITLE="Fix StandardRB Linting Issues"
    BODY_TITLE="Daily StandardRB Auto-fix"
    BODY_DESCRIPTION="This PR contains automated Ruby style fixes from StandardRB.

✅ All issues were auto-corrected by StandardRB!"
    AUTO_MERGE="true"
    ;;
    
  erb-lint)
    PR_TITLE="Fix ERB Linting Issues"
    BODY_TITLE="Daily ERB Lint Auto-fix"
    
    if [ "$HAS_UNFIXED" = "true" ]; then
      BODY_DESCRIPTION="This PR contains automated ERB template fixes.

⚠️ **Manual fixes required** - Some issues could not be auto-corrected.
See the comment below for details."
      AUTO_MERGE="false"
    else
      BODY_DESCRIPTION="This PR contains automated ERB template fixes.

✅ All issues were auto-corrected!"
      AUTO_MERGE="true"
    fi
    ;;
    
  *)
    echo "Unknown type: $TYPE"
    echo "Valid types: annotations, standardrb, erb-lint"
    exit 1
    ;;
esac

# Build auto-merge message
AUTO_MERGE_MSG=""
if [ "$AUTO_MERGE" = "true" ]; then
  AUTO_MERGE_MSG="

This PR will automatically merge if all status checks pass."
fi

# Build complete PR body
PR_BODY=$(cat <<EOF
## $BODY_TITLE

$BODY_DESCRIPTION$AUTO_MERGE_MSG

### Files Changed
\`\`\`
$FILE_CHANGES
\`\`\`

---
*This PR is automatically generated and will be updated if new changes are detected.*
*Last updated: $(date -u '+%Y-%m-%d %H:%M UTC')*
EOF
)

# Create or update the PR
PR_NUMBER=$(gh pr list --head "$BRANCH_NAME" --json number --jq '.[0].number' 2>/dev/null || echo "")

if [ -z "$PR_NUMBER" ]; then
  echo "Creating new PR..." >&2
  PR_URL=$(gh pr create \
    --title "$PR_TITLE" \
    --body "$PR_BODY" \
    --base main \
    --head "$BRANCH_NAME")
  # Extract PR number from URL (format: https://github.com/owner/repo/pull/123)
  PR_NUMBER="${PR_URL##*/}"
else
  echo "PR #$PR_NUMBER already exists, updating..." >&2
  gh pr edit "$PR_NUMBER" --body "$PR_BODY"
fi

echo "$PR_NUMBER"
