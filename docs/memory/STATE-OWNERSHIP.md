# State Ownership

How five state systems divide responsibility for session continuity, and the rules that prevent them from drifting apart.

## Problem

Multiple systems manage "what happened" and "what's next." Without clear ownership rules, they drift apart: handoffs stay open after work is committed, memory accumulates volatile facts, PM percentages diverge from handoff claims, and STATE.md duplicates decisions that belong elsewhere.

## The Five State Systems

```
┌─────────────────────────────────────────────────────┐
│  Auto-memory        Stable conventions, preferences  │  Cross-session
│  (tool-managed)     Architecture rules, key paths    │  Permanent
├─────────────────────────────────────────────────────┤
│  Handoffs           Active WIP with exit criteria    │  Cross-session
│  (SESSION-HANDOFF)  Technical context for resumption │  Ephemeral
├─────────────────────────────────────────────────────┤
│  PM                 Progress metrics, blockers,      │  Cross-session
│  (STATUS/BLOCKERS)  action items, stream percentages │  Curated
├─────────────────────────────────────────────────────┤
│  STATE.md           Last 1-3 session snapshots       │  Short-term
│  (.ai-local/)       Immediate resumption context     │  ~3 sessions
├─────────────────────────────────────────────────────┤
│  Git commits        Code changes, decisions as diffs │  Permanent
│                     The "why" in commit messages     │  Immutable
└─────────────────────────────────────────────────────┘
```

## Ownership Matrix

| System | Owns | Does NOT own |
|--------|------|-------------|
| **Auto-memory** | Stable conventions, architecture rules, workflow preferences, key file paths | Volatile numbers, session WIP, blocker lists, handoff pointers |
| **Handoffs** | Active WIP with clear exit criteria, detailed technical context for resumption | Completed work, status metrics, stable conventions |
| **PM** | Progress metrics, blocker tracking, action items, stream percentages | Detailed technical context, conventions, session narratives |
| **STATE.md** | Last 1-3 session snapshots for immediate resumption | Long-term conventions (that's memory), project metrics (that's PM) |
| **Git commits** | Code changes, decisions as diffs | Session continuity, progress summaries |

## Lifecycle Rules

### Auto-memory

Auto-memory is the tool's built-in persistent memory (e.g., Claude Code's `~/.claude/projects/.../memory/`). It stores conventions that survive across sessions without being re-discovered.

- New entries require **2+ session confirmations** before adding, unless the user explicitly requests persistence.
- Entries that duplicate a specific handoff pointer or volatile number must be removed.
- Do not store content derivable from code, AGENTS.md, git history, or commands.
- Organize by topic, not chronologically.

### Handoffs

```
Created (session save) → Active → Closed (archive/) → Deferred (parked)
```

- A handoff enters **Active** when a session creates it.
- A handoff moves to **Closed** when: work is done, subsumed by another handoff, or stale >7 days with no planned resumption. The file moves to `.ai-local/handoffs/archive/`, the router entry updates its link.
- A handoff is **Deferred** when it's parked (not time-sensitive, post-milestone). Stays in `.ai-local/handoffs/` (not archived) since it may resume.

### PM

- PM is the **single source of truth** for progress percentages and blocker status.
- When a handoff identifies residual work, it should reference or create a PM action (not just describe it in prose).
- Stream percentages come from action completion in stream files, not from handoff estimates.

### STATE.md

- Keeps the last 1-3 session snapshots.
- Older sessions are archived (compressed into HISTORY.md).
- Does not duplicate conventions that belong in memory, or metrics that belong in PM.

### Git commits

- Code changes and their rationale.
- Commit messages are memory entries: they capture the "why" at the moment of the decision.
- Not a substitute for STATE.md or handoffs: commits capture code changes, not session continuity.

## Detection at Boot

The boot script (or context generator) should emit warnings when state systems are out of sync:

| Condition | Warning |
|-----------|---------|
| Active handoff marked "Done" but still in Active table | `HANDOFF: entry X marked done, should be closed` |
| Active handoff >7 days old | `HANDOFF: entry X is 7+ days old, review for closure` |
| Active handoff >14 days old | `HANDOFF: entry X is 14+ days old, likely stale` |
| STATE.md >80 lines | `STATE: overflow (N lines), rotate to HISTORY` |
| STATE.md >7 days since last update | `STATE: stale (N days), verify against git log` |
| PM blocker unresolved >14 days | `PM: blocker X unresolved for N days` |

These are advisory warnings, not blocking errors. The agent decides how to act.

## Save-Time Hygiene

The `/save` command should include a state hygiene step:

1. **Handoffs**: Review Active entries. Close any whose work is done, subsumed, or stale >7 days. Move closed files to archive.
2. **Memory**: Check for volatile entries that should be in handoffs or PM instead.
3. **PM**: If handoff references progress or blockers, verify PM is updated.
4. **STATE.md**: Check size. Rotate if >80 lines.

## Anti-Patterns

| Anti-pattern | Correct approach |
|-------------|-----------------|
| Writing a readiness % in auto-memory | Put it in PM stream or tracking |
| Leaving a "Done" handoff in Active | Move to Closed at session save |
| Adding experiment counts to memory | Put counts in the relevant project doc |
| Describing a blocker in a handoff only | Create/update a PM blocker entry |
| Keeping closed handoff files in working dir | Move to archive, update router link |
| STATE.md growing beyond 80 lines | Rotate to HISTORY.md on next save |
| Duplicating architecture rules in STATE.md | Put them in AGENTS.md or auto-memory |

## Related

- [MEMORY-SYSTEM.md](MEMORY-SYSTEM.md) — L0-L3 memory model
- `../handoffs/HANDOFF-SYSTEM.md` — Handoff router pattern (added in Wave 2)
- `PM-INTEGRATION.md` — PM tool sync patterns (companion doc, to be added in a later wave)
