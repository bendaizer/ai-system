# Testing the AI System

Test scenarios to validate the system works with different tools.

## Prerequisites

1. Copy example project or set up your own
2. Ensure `.ai/session/scripts/*.sh` are executable

## Test 1: Boot from Fresh State

**Setup:** Remove `.ai-local/` if it exists

**Steps:**
1. Run `/boot` (or equivalent for your tool)
2. Verify boot script creates STATE.md and HISTORY.md
3. Verify CONTEXT.md is generated

**Expected:**
- `.ai-local/STATE.md` exists with template content
- `.ai-local/HISTORY.md` exists with template content
- `.ai-local/CONTEXT.md` contains both files + git status
- AI summarizes "no previous sessions"

## Test 2: Boot with Existing State

**Setup:** Ensure `.ai-local/STATE.md` has content

**Steps:**
1. Run `/boot`
2. Verify AI reads existing state

**Expected:**
- AI summarizes current objective
- AI lists open loops
- AI mentions recent activity

## Test 3: Save Session

**Steps:**
1. After doing some work, run `/save`
2. Review proposed updates to STATE.md
3. Review proposed entry for HISTORY.md

**Expected:**
- STATE.md updated with session details
- HISTORY.md has new timestamped entry
- Commit proposed if changes exist

## Test 4: Memory Rotation

**Setup:** STATE.md has >50 lines of "Recent Work"

**Steps:**
1. Run `/save`
2. Check if older entries moved to HISTORY.md

**Expected:**
- STATE.md trimmed to ~3 sessions
- Moved content compressed in HISTORY.md

## Test 5: Cross-Session Continuity

**Steps:**
1. Start session, make note of objective
2. Save and close
3. Start new session
4. Verify previous context loaded

**Expected:**
- Previous objective shown
- Open loops preserved
- History available

## Tool-Specific Tests

### Claude Code

1. Copy `adapters/claude/.claude/` to project
2. Run `/boot` command
3. Verify it reads from `.ai/skills/boot.md`

### Cursor

1. Copy `adapters/cursor/.cursorrules` to project
2. Start Cursor, ask about "boot" command
3. Verify it follows `.cursorrules` instructions

### OpenAI Codex

1. Ensure `AGENTS.md` is in project root
2. Open in Codex
3. Run `boot` command

### GitHub Copilot

1. Copy `adapters/copilot/copilot-instructions.md` to `.github/`
2. Ask Copilot about session commands
3. Verify it references the instructions
