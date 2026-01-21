#!/bin/bash
# Session save script
# Prompts AI to update STATE.md and rotate history

set -e

# Find project root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"

LOCAL_DIR="$PROJECT_ROOT/.ai-local"

# Ensure local directory exists
mkdir -p "$LOCAL_DIR"

# Show current state for reference
echo "=== Current STATE.md ==="
if [ -f "$LOCAL_DIR/STATE.md" ]; then
    cat "$LOCAL_DIR/STATE.md"
else
    echo "(no STATE.md found)"
fi
echo ""

# Show what's changed
echo "=== Files Changed ==="
cd "$PROJECT_ROOT"
git status --short 2>/dev/null || echo "Not a git repo"
echo ""

# Show recent git diff summary
echo "=== Changes Summary ==="
git diff --stat 2>/dev/null | tail -10 || echo "No changes"
echo ""

cat << 'EOF'
=== AI Instructions ===

Please update the session state:

1. Update .ai-local/STATE.md with:
   - Current objective (what we're working on)
   - Recent work (what was accomplished this session)
   - Open loops (unfinished tasks, blockers)
   - Key decisions (important choices made)

2. Add a session entry to .ai-local/HISTORY.md:
   ```
   ### YYYY-MM-DD HH:MM
   - Brief summary of session
   - Key accomplishments
   ```

3. If a meaningful milestone was reached, propose a git commit:
   - Stage relevant files
   - Write a clear commit message
   - Ask before committing

Reply with the updates you'll make.
EOF
