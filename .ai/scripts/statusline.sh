#!/bin/bash
# Generic AI status line for Claude Code
# Shows: [Model] Project/folder | Task | Context%
#
# Input: JSON from stdin (Claude Code status line hook)
# Output: Formatted status string

input=$(cat)

# Extract fields from JSON
CWD=$(echo "$input" | jq -r '.workspace.current_dir // empty')
PROJECT_DIR=$(echo "$input" | jq -r '.workspace.project_dir // empty')
MODEL=$(echo "$input" | jq -r '.model.display_name // "Claude"')
SESSION_ID=$(echo "$input" | jq -r '.session_id // empty' | cut -c1-8)

# Context window - use pre-calculated percentage
CONTEXT_PCT=""
USED_PCT=$(echo "$input" | jq -r '.context_window.used_percentage // empty')
if [[ -n "$USED_PCT" && "$USED_PCT" != "null" ]]; then
    CONTEXT_PCT=" ${USED_PCT}%"
fi

# Detect project name from directory
# Strategy: Use project_dir basename, or find .ai/ directory and use its parent
PROJECT="?"
PROJECT_ROOT=""

if [[ -n "$PROJECT_DIR" && "$PROJECT_DIR" != "null" ]]; then
    PROJECT_ROOT="$PROJECT_DIR"
    PROJECT=$(basename "$PROJECT_DIR")
else
    # Walk up to find .ai/ or .git/ as project root indicator
    CHECK_DIR="$CWD"
    while [[ "$CHECK_DIR" != "/" && "$CHECK_DIR" != "" ]]; do
        if [[ -d "$CHECK_DIR/.ai" || -d "$CHECK_DIR/.git" ]]; then
            PROJECT_ROOT="$CHECK_DIR"
            PROJECT=$(basename "$CHECK_DIR")
            break
        fi
        CHECK_DIR=$(dirname "$CHECK_DIR")
    done
fi

# Get relative folder within project (shortened to last 2 components)
FOLDER=""
if [[ -n "$PROJECT_ROOT" && "$CWD" != "$PROJECT_ROOT" ]]; then
    FOLDER="${CWD#$PROJECT_ROOT}"
    if [[ -n "$FOLDER" ]]; then
        # Shorten to last 2 components max, ensure leading slash
        FOLDER=$(echo "$FOLDER" | rev | cut -d'/' -f1-2 | rev)
        [[ "$FOLDER" != /* ]] && FOLDER="/$FOLDER"
    fi
fi

# Find task from .ai-local/STATE.md or agent-status.json
# Walk up from CWD looking for .ai-local/
TASK=""
CHECK_DIR="$CWD"
while [[ "$CHECK_DIR" != "/" && "$CHECK_DIR" != "" ]]; do
    AI_LOCAL="$CHECK_DIR/.ai-local"
    if [[ -d "$AI_LOCAL" ]]; then
        # Try agent-status.json first (session-specific, then shared)
        if [[ -n "$SESSION_ID" && -f "$AI_LOCAL/agent-status-${SESSION_ID}.json" ]]; then
            TASK=$(jq -r '.task // empty' "$AI_LOCAL/agent-status-${SESSION_ID}.json" 2>/dev/null)
        elif [[ -f "$AI_LOCAL/agent-status.json" ]]; then
            TASK=$(jq -r '.task // empty' "$AI_LOCAL/agent-status.json" 2>/dev/null)
        fi

        # Fallback: extract current objective from STATE.md
        if [[ -z "$TASK" || "$TASK" == "null" ]] && [[ -f "$AI_LOCAL/STATE.md" ]]; then
            # Get first non-empty, non-placeholder line after "## Current Objective"
            # Handle both Unix (LF) and Windows (CRLF) line endings
            TASK=$(tr -d '\r' < "$AI_LOCAL/STATE.md" | grep -A5 "^## Current Objective" | tail -n +2 | grep -v "^$" | grep -v "^##" | grep -v "^_" | head -1)
            # Truncate to 50 chars
            if [[ ${#TASK} -gt 50 ]]; then
                TASK="${TASK:0:47}..."
            fi
        fi
        break
    fi

    # Also check .project_local/ for compatibility with dillygence system
    PROJECT_LOCAL="$CHECK_DIR/.project_local"
    if [[ -d "$PROJECT_LOCAL" ]]; then
        if [[ -n "$SESSION_ID" && -f "$PROJECT_LOCAL/agent-status-${SESSION_ID}.json" ]]; then
            TASK=$(jq -r '.task // empty' "$PROJECT_LOCAL/agent-status-${SESSION_ID}.json" 2>/dev/null)
        elif [[ -f "$PROJECT_LOCAL/agent-status.json" ]]; then
            TASK=$(jq -r '.task // empty' "$PROJECT_LOCAL/agent-status.json" 2>/dev/null)
        fi
        break
    fi

    CHECK_DIR=$(dirname "$CHECK_DIR")
done

# Format output: [Model] Project/folder | Task | Context%
OUTPUT="[$MODEL] $PROJECT$FOLDER"

if [[ -n "$TASK" && "$TASK" != "null" && "$TASK" != "booting" ]]; then
    OUTPUT="$OUTPUT | $TASK"
fi

if [[ -n "$CONTEXT_PCT" ]]; then
    OUTPUT="$OUTPUT |$CONTEXT_PCT"
fi

echo "$OUTPUT"
