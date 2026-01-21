# Session Management

Memory layers for persistent AI context across sessions.

## Problem

AI assistants lose context between sessions. Starting fresh every time means:
- Repeating context
- Re-explaining decisions
- Losing track of progress

## Solution: Memory Layers

Four layers of memory with different retention periods:

```
L0: Chat          [current session]
    ↓
L1: STATE.md      [~3 sessions]
    ↓
L2: HISTORY.md    [all sessions]
    ↓
L3: Git commits   [forever]
```

## Layer Details

### L0 - Working Memory (Chat)

The current conversation. Full detail, no compression.

- **Retention**: Current session only
- **Location**: Tool's context window
- **Managed by**: Tool automatically

### L1 - Short-term Memory (STATE.md)

Recent session state. Enough detail to resume work.

- **Retention**: ~3 sessions (rotate older to L2)
- **Location**: `.ai-local/STATE.md`
- **Updated**: On `/save`

**Contains:**
- Current objective
- Recent accomplishments
- Key decisions (with rationale)
- Open loops / blockers
- Files modified

### L2 - Long-term Memory (HISTORY.md)

Compressed session history. Key milestones and patterns.

- **Retention**: All sessions
- **Location**: `.ai-local/HISTORY.md`
- **Updated**: On `/save` (rotate from L1)

**Contains:**
- Session summaries (1-2 lines each)
- Major decisions
- Architectural patterns established
- Problems solved (for reference)

### L3 - Permanent Memory (Git)

Code changes and meaningful commits.

- **Retention**: Forever
- **Location**: Git history
- **Updated**: On commit

**Contains:**
- Actual code changes
- Commit messages explain "why"

## Workflow

### /boot - Load Context

```
1. Read L1 (STATE.md) → current state
2. Read L2 (HISTORY.md) → patterns, context
3. Generate CONTEXT.md → combined summary
4. AI reads CONTEXT.md → ready to work
```

### /save - Save Context

```
1. AI summarizes session → what happened
2. Update L1 (STATE.md) → current state
3. Rotate old L1 → L2 (HISTORY.md)
4. Propose commit if milestone → L3
```

## Files

| File | Location | Git | Purpose |
|------|----------|-----|---------|
| `STATE.md` | `.ai-local/` | ignored | Current state |
| `HISTORY.md` | `.ai-local/` | ignored | Session history |
| `CONTEXT.md` | `.ai-local/` | ignored | Generated context |

## Templates

Templates in `templates/` provide structure:

- `STATE.md` - Session state template
- `CONTEXT.md` - Generated context template
- `HISTORY.md` - History log template
