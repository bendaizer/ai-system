# Session Handoff Router

Handoff files live in `.ai-local/handoffs/`. This file indexes active and deferred
handoffs and serves as the entry point for `/boot <slug>`.

See `docs/handoffs/HANDOFF-SYSTEM.md` for the full spec.

## Active

| Date | Topic | Stream | Status | Handoff |
|------|-------|--------|--------|---------|
| YYYY-MM-DD | <slug> | <stream> | <2-3 sentences: where we are + what's next> | `handoffs/<YYYY-MM-DD>-<slug>.md` |

## Deferred

| Date | Topic | Stream | Status | Handoff |
|------|-------|--------|--------|---------|
| YYYY-MM-DD | <slug> | <stream> | **Blocked**: <reason> | `handoffs/<YYYY-MM-DD>-<slug>.md` |

## Recent (closed)

| Date | Topic | Closed |
|------|-------|--------|
| YYYY-MM-DD | <slug> | <one-liner: shipped, subsumed, abandoned> |
