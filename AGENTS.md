# AI Assistants

Universal entry point for AI coding assistants.

> **All definitions are in `.ai/`** - This file redirects there.

## Session Management

Start every work session with a boot, end with a save.

### /boot - Start Session

Load context from memory layers and prepare for work.

**Process:**
1. Run `.ai/session/scripts/boot.sh`
2. Read generated `.ai-local/CONTEXT.md`
3. Summarize: current state, open loops, recent activity
4. Confirm ready and wait for instruction

**Or read:** `.ai/skills/boot.md`

### /save - Save Session

Persist current session state to memory layers.

**Process:**
1. Run `.ai/session/scripts/save.sh`
2. Update `.ai-local/STATE.md` with:
   - Summary of accomplishments
   - Files modified
   - Key decisions
   - Open loops
3. Archive previous state to `.ai-local/HISTORY.md`
4. Propose git commit if milestone reached

**Or read:** `.ai/skills/save.md`

## Memory Layers

| Layer | File | Retention | Detail |
|-------|------|-----------|--------|
| L1 | `.ai-local/STATE.md` | ~3 sessions | Full detail |
| L2 | `.ai-local/HISTORY.md` | All sessions | Compressed |
| L3 | Git commits | Forever | Milestones |

## Workflow

```
/boot          → Load context, understand state
   ↓
[work]         → Do tasks, make decisions
   ↓
/save          → Persist state, commit if needed
```

## Documentation

- `.ai/README.md` - System overview
- `.ai/session/README.md` - Memory layer concepts
- `.ai/skills/` - Detailed skill definitions
- `.ai/agents/` - Agent definitions

## Tool-Specific Setup

This file works for Codex. For other tools:

| Tool | Additional Setup |
|------|------------------|
| Claude Code | Copy `adapters/claude/.claude/` to project |
| Cursor | Copy `adapters/cursor/.cursorrules` to project |
| GitHub Copilot | Copy `adapters/copilot/` to `.github/` |
