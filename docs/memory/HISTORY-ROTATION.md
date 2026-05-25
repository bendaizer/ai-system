# History Rotation — Managing HISTORY.md Growth

## Problem

HISTORY.md is append-only. At ~200 tokens per session, it grows predictably:

| Duration | Lines | Tokens |
|----------|-------|--------|
| 1 month | ~150 | ~6K |
| 6 months | ~900 | ~36K |
| 1 year | ~1,800 | ~72K |

While only 50 lines are loaded at boot, the file becomes unwieldy for manual review and on-demand reads. More importantly, in intensive workspaces with multiple sessions per day, the 1-year mark can arrive in months.

## Solution: Archive Rotation

When HISTORY.md exceeds a threshold, move older entries to HISTORY-ARCHIVE.md.

```
.ai-local/
├── STATE.md              ← Current session (volatile)
├── HISTORY.md            ← Recent sessions (active, loaded at boot)
└── HISTORY-ARCHIVE.md    ← Older sessions (reference, never loaded at boot)
```

## Rotation Protocol

### Trigger

Check HISTORY.md line count during `/save`:

```bash
HISTORY_LINES=$(wc -l < "$LOCAL_DIR/HISTORY.md" 2>/dev/null || echo 0)
if [ "$HISTORY_LINES" -gt 300 ]; then
    echo "HISTORY.md: $HISTORY_LINES lines — rotation recommended"
fi
```

**Threshold**: 300 lines (~60 sessions). This keeps ~2 months of daily sessions in the active file.

### Process

1. **Identify the cut point**: Keep the most recent N entries (e.g., last 100 lines), move the rest.

2. **Append to archive**: Older entries go to the top of HISTORY-ARCHIVE.md (maintaining newest-first order within the archive).

3. **Trim active file**: HISTORY.md retains only the recent entries.

```bash
# Rotation script (run manually or from save.sh)
HISTORY="$LOCAL_DIR/HISTORY.md"
ARCHIVE="$LOCAL_DIR/HISTORY-ARCHIVE.md"
KEEP_LINES=100

if [ "$(wc -l < "$HISTORY")" -gt 300 ]; then
    # Lines to archive (everything except the last KEEP_LINES)
    TOTAL=$(wc -l < "$HISTORY")
    ARCHIVE_LINES=$((TOTAL - KEEP_LINES))

    # Prepend older entries to archive
    head -n "$ARCHIVE_LINES" "$HISTORY" > "$LOCAL_DIR/HISTORY-rotate-tmp.md"
    if [ -f "$ARCHIVE" ]; then
        cat "$ARCHIVE" >> "$LOCAL_DIR/HISTORY-rotate-tmp.md"
    fi
    mv "$LOCAL_DIR/HISTORY-rotate-tmp.md" "$ARCHIVE"

    # Keep only recent entries
    tail -n "$KEEP_LINES" "$HISTORY" > "$LOCAL_DIR/HISTORY-temp.md"
    mv "$LOCAL_DIR/HISTORY-temp.md" "$HISTORY"

    echo "Rotated: $ARCHIVE_LINES lines → HISTORY-ARCHIVE.md"
fi
```

## Archive Compression (Optional)

For very old entries (>6 months in the archive), further compress by merging daily entries into weekly summaries:

**Before** (5 entries):
```markdown
### 2025-10-15 — Implemented user auth
### 2025-10-14 — Set up database schema
### 2025-10-13 — Configured CI pipeline
### 2025-10-12 — Project scaffolding
### 2025-10-11 — Initial planning session
```

**After** (1 entry):
```markdown
### 2025-W42 (Oct 11-15) — Project bootstrap
- Set up project: scaffolding, CI, database schema
- Implemented user authentication
- Key decision: JWT over sessions (stateless)
```

This is an AI-driven operation: the agent reads the old entries, compresses them, and writes the result. No script can reliably judge what to keep.

## Boot Behavior

| File | Loaded at boot | Purpose |
|------|:--------------:|---------|
| HISTORY.md | Last 50 lines | Recent context for session continuity |
| HISTORY-ARCHIVE.md | Never | On-demand reference only |

The agent can read HISTORY-ARCHIVE.md when needed (e.g., "What did we decide about auth 3 months ago?") but it is never automatically loaded.

## Gitignore

Both files live in `.ai-local/` and are gitignored. They are local session state, not project artifacts.

## When to Rotate

| HISTORY.md size | Action |
|:---------------:|--------|
| <150 lines | No action |
| 150-300 lines | Normal growth, no action needed |
| 300-500 lines | Rotate: move older entries to archive |
| >500 lines | Overdue rotation — rotate immediately |

## Related

- [MEMORY-SYSTEM.md](MEMORY-SYSTEM.md) — Four-layer memory architecture (HISTORY.md is L2)
- `../handoffs/HANDOFF-SYSTEM.md` — Handoff router (complementary to history, added in Wave 2)
- `SEED-PATTERN.md` — Static context that never needs rotation (companion doc, to be added in a later wave)
