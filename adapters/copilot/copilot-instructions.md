# GitHub Copilot Instructions

This project uses a unified AI system for session management.

## Session Commands

### /boot - Start Session
1. Run `.ai/session/scripts/boot.sh`
2. Read `.ai-local/CONTEXT.md`
3. Summarize: objective, open loops, recent activity
4. Confirm ready

### /save - Save Session
1. Run `.ai/session/scripts/save.sh`
2. Update `.ai-local/STATE.md` with session details
3. Add entry to `.ai-local/HISTORY.md`
4. Propose commit if milestone reached

## Memory Layers

| Layer | File | Purpose |
|-------|------|---------|
| L1 | `.ai-local/STATE.md` | Current state |
| L2 | `.ai-local/HISTORY.md` | Session history |
| L3 | Git commits | Milestones |

## Documentation

- `AGENTS.md` - Universal entry point
- `.ai/README.md` - System overview
- `.ai/skills/` - Skill definitions
