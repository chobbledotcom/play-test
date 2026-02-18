#!/bin/bash
# Create or update an automated PR with standard formatting
# Usage: create-automation-pr.sh <type> <branch-name>
#
# Types: annotations, standardrb, erb-lint

set -e

TYPE="$1"
BRANCH_NAME="$2"

if [ -z "$TYPE" ] || [ -z "$BRANCH_NAME" ]; then
  echo "Usage: create-automation-pr.sh <type> <branch-name>" >&2
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
    LABELS="automerge"
    ;;
    
  standardrb)
    PR_TITLE="Fix StandardRB Linting Issues"
    BODY_TITLE="Daily StandardRB Auto-fix"
    BODY_DESCRIPTION="This PR contains automated Ruby style fixes from StandardRB.

✅ All issues were auto-corrected by StandardRB!"
    LABELS="automerge"
    ;;
    
  erb-lint)
    PR_TITLE="Fix ERB Linting Issues"
    BODY_TITLE="Daily ERB Lint Auto-fix"
    BODY_DESCRIPTION="This PR contains automated ERB template fixes from erb_lint."
    LABELS="automerge"
    ;;
    
  *)
    echo "Unknown type: $TYPE" >&2
    echo "Valid types: annotations, standardrb, erb-lint" >&2
    exit 1
    ;;
esac

# Build complete PR body
PR_BODY=$(cat <<EOF
## $BODY_TITLE

$BODY_DESCRIPTION

### Files Changed
\`\`\`
$FILE_CHANGES
\`\`\`

---
*This PR is automatically generated and will be updated if new changes are detected.*
*Last updated: $(date -u '+%Y-%m-%d %H:%M UTC')*
EOF
)

# Check if PR already exists
PR_NUMBER=$(gh pr list --head "$BRANCH_NAME" --json number --jq '.[0].number' 2>/dev/null || echo "")

if [ -z "$PR_NUMBER" ]; then
  echo "Creating new PR..." >&2
  
  # Create PR and get URL
  PR_URL=$(gh pr create \
    --title "$PR_TITLE" \
    --body "$PR_BODY" \
    --base main \
    --head "$BRANCH_NAME")
  
  # Extract PR number from URL
  PR_NUMBER="${PR_URL##*/}"
  
  # Add label if specified
  if [ -n "$LABELS" ]; then
    echo "Adding label: $LABELS" >&2
    gh pr edit "$PR_NUMBER" --add-label "$LABELS" || {
      echo "Warning: Failed to add label '$LABELS' - creating it first" >&2
      gh label create "$LABELS" --description "Automatically merge when ready" --color "0E8A16" 2>/dev/null || true
      gh pr edit "$PR_NUMBER" --add-label "$LABELS"
    }
  fi
else
  echo "PR #$PR_NUMBER already exists, updating..." >&2
  
  # Update PR body
  gh pr edit "$PR_NUMBER" --body "$PR_BODY"
  
  # Update labels based on current state
  if [ -n "$LABELS" ]; then
    echo "Adding label: $LABELS" >&2
    gh pr edit "$PR_NUMBER" --add-label "$LABELS" || {
      echo "Warning: Failed to add label '$LABELS' - creating it first" >&2
      gh label create "$LABELS" --description "Automatically merge when ready" --color "0E8A16" 2>/dev/null || true
      gh pr edit "$PR_NUMBER" --add-label "$LABELS"
    }
  else
    echo "Removing automerge label" >&2
    gh pr edit "$PR_NUMBER" --remove-label "automerge" 2>/dev/null || true
  fi
fi

echo "$PR_NUMBER"
