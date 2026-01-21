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

### /save - Save Session

Persist current session state to memory layers.

**Process:**
1. Run `.ai/session/scripts/save.sh`
2. Update `.ai-local/STATE.md`
3. Add entry to `.ai-local/HISTORY.md`
4. Propose git commit if milestone reached

## Memory Layers

| Layer | File | Retention |
|-------|------|-----------|
| L1 | `.ai-local/STATE.md` | ~3 sessions |
| L2 | `.ai-local/HISTORY.md` | All sessions |
| L3 | Git commits | Forever |

## Documentation

- `.ai/README.md` - System overview
- `.ai/session/README.md` - Memory concepts
- `.ai/skills/` - Skill definitions
