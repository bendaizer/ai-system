# Handoff System

How to carry cross-session context for complex workspaces where `STATE.md` alone isn't enough.

## When you need this

`STATE.md` (see [`../memory/MEMORY-SYSTEM.md`](../memory/MEMORY-SYSTEM.md)) is sufficient for **single-topic sessions** — one project, one task, one resumption thread.

It breaks down when you have **multiple concurrent workstreams**: a session might touch the payments module on Monday, the marketing site on Tuesday, the data pipeline on Wednesday. STATE.md can't carry detailed context for all three. Either it bloats and overflows, or important context gets compressed away.

The handoff system solves this with two artifacts:

1. A **router** (one file, root of the workspace, ~50-100 lines): an index of active workstreams with one-line status each.
2. **Detailed handoffs** (one file per workstream, in `.ai-local/handoffs/`): full context for resuming that specific stream.

## Architecture

```
<workspace>/
├── SESSION-HANDOFF.md                ← router (tracked in git or .ai-local)
└── .ai-local/
    └── handoffs/
        ├── 2026-05-20-payments-stripe-webhook.md
        ├── 2026-05-22-marketing-site-redesign.md
        ├── 2026-05-24-data-pipeline-cluster-fix.md
        └── archive/
            └── 2026-04-30-old-completed-thing.md
```

| Artifact | Role | Loaded at boot |
|---|---|---|
| `SESSION-HANDOFF.md` | Router/index: list of active + deferred handoffs, one line each | Yes (auto-parsed) |
| `.ai-local/handoffs/<slug>.md` | Full detailed context for one workstream | No (on demand: `/boot <slug>`) |
| `.ai-local/handoffs/archive/<slug>.md` | Closed handoffs (kept for history) | Never |

The router stays small (~5-30 active entries × 1 line each = lightweight to scan). The detailed handoffs can be as long as needed; only the relevant one gets loaded per session.

## Router format

```markdown
# Session Handoff Router

Handoff files live in `.ai-local/handoffs/`. This file indexes active handoffs
and serves as the entry point for `/boot <slug>`.

## Active

| Date | Topic | Stream | Status | Handoff |
|------|-------|--------|--------|---------|
| 2026-05-20 | payments-stripe-webhook | Backend | **Webhook signature verification done, idempotency layer next.** Test cases drafted; retry policy decision deferred. | `handoffs/2026-05-20-payments-stripe-webhook.md` |
| 2026-05-22 | marketing-site-redesign | Frontend | **Hero section + 3 sections done.** Validation by design lead pending. | `handoffs/2026-05-22-marketing-site-redesign.md` |

## Deferred

| Date | Topic | Stream | Status | Handoff |
|------|-------|--------|--------|---------|
| 2026-04-15 | analytics-dashboard | Data | **Blocked**: waiting on BI tool choice from leadership | `handoffs/2026-04-15-analytics-dashboard.md` |

## Recent (closed)

| Date | Topic | Closed |
|------|-------|--------|
| 2026-05-18 | auth-jwt-rotation | Shipped to prod |
| 2026-05-15 | docs-onboarding-flow | Superseded by 2026-05-22-marketing-site-redesign |
```

Three sections:

- **Active**: handoffs with work in progress. Status column is a 2-3 sentence summary written for the next session.
- **Deferred**: parked workstreams (blocked, post-milestone, on-hold). Stay listed but not actively worked.
- **Recent (closed)**: light audit trail of what shipped or got subsumed. Last 5-10 entries; older ones rotate out.

## Handoff file format

A single handoff lives in `.ai-local/handoffs/<YYYY-MM-DD>-<slug>.md`. Suggested structure (adapt to your needs):

```markdown
# Handoff: <topic>

> Created: 2026-05-20 · Stream: <name> · Status: Active

## Context

Why this work exists. What problem it solves. 2-3 paragraphs max.

## Recent work (this handoff's sessions)

- Bullet list of what was done across the sessions that touched this handoff.
- Decisions made and their rationale.
- Files created/modified (with paths).

## Open loops

- [ ] Things started but not finished
- [ ] Questions waiting for answers
- [ ] Decisions pending (with context for whoever picks this up)

## Key decisions

| Decision | Choice | Rationale | Date |
|---|---|---|---|

## Files

- `path/to/file.ext` — what it does, what changed
- `path/to/other.ext` — ...

## Next session

The exact first step. Not "continue work on X" but "implement the validation function in src/auth/validate.ts following the schema in lib/types/auth.ts:42".
```

Keep handoffs **conversational and concrete**. They're notes you write to the next agent (which might be you in 3 days, or someone else, or both). Optimize for someone re-entering cold.

## Lifecycle

```
Created (during session save) → Active → Closed (archive/) or Deferred (parked)
```

### Created

A handoff is created when:
- A session starts work on a new workstream that won't finish in this session, OR
- A session forks: existing work pauses, new work begins, the old work needs a handoff so the new work doesn't lose it.

### Active

While the handoff is being actively progressed across sessions, it stays in Active and gets updated at each `/save`.

### Closed

A handoff moves to Closed when:
- Work is done (shipped, merged, validated)
- Subsumed by another handoff (e.g. broader refactor absorbs the smaller task)
- Stale >7 days with no planned resumption

When closing: move the file to `.ai-local/handoffs/archive/`, update the router (remove from Active table, add a 1-line entry under Recent).

### Deferred

A handoff moves to Deferred when:
- Blocked on an external decision/dependency
- Post-milestone (will resume after Y ships)
- On-hold (parked but might revive)

Stays in `.ai-local/handoffs/` (not archived). Router shows it in the Deferred table. May come back to Active later.

## Boot integration

The boot script (see [`../EXTENDING-BOOT-SAVE.md`](../EXTENDING-BOOT-SAVE.md) axis 6) parses the router and renders the Active + Deferred tables in `CONTEXT.md`. Two modes:

- `boot` (no argument): show the router index. Agent picks one if needed.
- `boot <slug>`: inline the full content of `.ai-local/handoffs/<slug>.md` into `CONTEXT.md`, so the agent resumes with full context immediately.

## Save integration

At `/save`, the save script (see [`../EXTENDING-BOOT-SAVE.md`](../EXTENDING-BOOT-SAVE.md) axis 8) prompts the user to:

1. Update the relevant handoff(s) with this session's work
2. Update the router status line for each touched handoff
3. Move any closed handoffs to archive
4. Promote deferred handoffs back to active if unblocked

This is judgment work — a script can't decide what to update. The save hook surfaces the question; the user/agent answers it.

## Why not just keep everything in STATE.md?

| Approach | Pro | Con |
|---|---|---|
| STATE.md only | Simple, one file, always loaded | Overflows fast on multi-stream workspaces; oldest context gets silently compressed away |
| Handoff system | Each stream keeps full context, scales to N streams | More files, more discipline at save time |

Use STATE.md only for projects with 1-2 concurrent workstreams. Adopt handoffs once you find yourself losing context across streams (typical threshold: 3+ active workstreams).

## Why a router?

Without the router, the next session would need to scan `.ai-local/handoffs/` and read each file to understand what's active. The router is a **digest**: status line per handoff, scannable in seconds.

It's also what makes `/boot <slug>` meaningful: the router is the menu of slugs to pick from.

## Relationship to STATE.md

| Question | Where it lives |
|---|---|
| "What did this session do?" | STATE.md (current session) |
| "What's open across all streams?" | Router (one line per stream) |
| "What's the full context of the payments work?" | `handoffs/payments-*.md` |

STATE.md is the **session lens**: snapshot of what just happened. Handoffs are the **workstream lens**: longitudinal view per topic. They complement, they don't compete.

## Anti-patterns

| Anti-pattern | Fix |
|---|---|
| Detailed handoff content duplicated in STATE.md | Reference: STATE.md says "see `handoffs/payments-...md`", handoff carries the detail |
| Router status column too short ("Active") or too long (full prose) | 2-3 sentences: where we are + what's next |
| Closed handoffs left in Active | Save hygiene: close them, move to archive |
| Handoffs created for trivial work | If it fits in one STATE.md line, don't make a handoff |
| Handoff file > 300 lines | Likely needs a split (the workstream has bifurcated) |

## Templates

- [`../../.ai/session/templates/SESSION-HANDOFF.md`](../../.ai/session/templates/SESSION-HANDOFF.md) — Router template (copy to your workspace root)
- [`../../.ai/session/templates/handoff.md`](../../.ai/session/templates/handoff.md) — Individual handoff template (copy to `.ai-local/handoffs/`)

## Related

- [`../memory/MEMORY-SYSTEM.md`](../memory/MEMORY-SYSTEM.md) — L0-L3 memory model (handoffs are a complement, not a replacement)
- [`../memory/STATE-OWNERSHIP.md`](../memory/STATE-OWNERSHIP.md) — Where handoffs sit in the 5-system ownership matrix
- [`../EXTENDING-BOOT-SAVE.md`](../EXTENDING-BOOT-SAVE.md) — How boot/save scripts integrate the router (axes 6 and 8)
- [`../agents/COHERENCE-AUDIT-WORKFLOW.md`](../agents/COHERENCE-AUDIT-WORKFLOW.md) — Phase 4 audits stale handoffs
