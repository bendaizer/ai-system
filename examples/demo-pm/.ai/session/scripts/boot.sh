#!/bin/bash
# Session boot script
# Generates CONTEXT.md from memory layers

set -e

# Find project root (where .ai/ is)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"

AI_DIR="$PROJECT_ROOT/.ai"
LOCAL_DIR="$PROJECT_ROOT/.ai-local"

# Ensure local directory exists
mkdir -p "$LOCAL_DIR"

# Initialize STATE.md if missing
if [ ! -f "$LOCAL_DIR/STATE.md" ]; then
    if [ -f "$AI_DIR/session/templates/STATE.md" ]; then
        cp "$AI_DIR/session/templates/STATE.md" "$LOCAL_DIR/STATE.md"
        echo "Created STATE.md from template"
    else
        cat > "$LOCAL_DIR/STATE.md" << 'EOF'
# Session State

## Current Objective
_Not set_

## Recent Work
_No previous sessions_

## Open Loops
- [ ] None

## Key Decisions
_None yet_
EOF
        echo "Created empty STATE.md"
    fi
fi

# Initialize HISTORY.md if missing
if [ ! -f "$LOCAL_DIR/HISTORY.md" ]; then
    if [ -f "$AI_DIR/session/templates/HISTORY.md" ]; then
        cp "$AI_DIR/session/templates/HISTORY.md" "$LOCAL_DIR/HISTORY.md"
        echo "Created HISTORY.md from template"
    else
        cat > "$LOCAL_DIR/HISTORY.md" << 'EOF'
# Session History

## Sessions
_No sessions recorded_
EOF
        echo "Created empty HISTORY.md"
    fi
fi

# Generate CONTEXT.md
CONTEXT_FILE="$LOCAL_DIR/CONTEXT.md"

cat > "$CONTEXT_FILE" << EOF
# Session Context

Generated: $(date -Iseconds)

## Current State

$(cat "$LOCAL_DIR/STATE.md")

## History Summary

$(tail -50 "$LOCAL_DIR/HISTORY.md")

## Git Status

\`\`\`
$(cd "$PROJECT_ROOT" && git status --short 2>/dev/null || echo "Not a git repo")
\`\`\`

## Recent Commits

\`\`\`
$(cd "$PROJECT_ROOT" && git log --oneline -10 2>/dev/null || echo "No commits")
\`\`\`
EOF

echo "Generated $CONTEXT_FILE"
echo ""
echo "AI: Read .ai-local/CONTEXT.md to load session context"
