# Handoffs

How to carry context across sessions when multiple workstreams compete for STATE.md's budget.

## Quick start

1. Read [`HANDOFF-SYSTEM.md`](HANDOFF-SYSTEM.md) — the full spec (~150 lines)
2. Copy [`../../.ai/session/templates/SESSION-HANDOFF.md`](../../.ai/session/templates/SESSION-HANDOFF.md) to your workspace root as a starter router
3. Copy [`../../.ai/session/templates/handoff.md`](../../.ai/session/templates/handoff.md) to `.ai-local/handoffs/<YYYY-MM-DD>-<slug>.md` for each workstream
4. Update both at `/save` time

## When to adopt

- ✓ 3+ concurrent workstreams (clear sign)
- ✓ STATE.md overflows >120 lines regularly
- ✓ You forget what you were doing on stream B when you come back to it
- ✗ Single project, single task, single resumption → STATE.md is enough

## Files in this folder

- [`HANDOFF-SYSTEM.md`](HANDOFF-SYSTEM.md) — Architecture, router format, handoff file format, lifecycle (created → active → closed/deferred), boot/save integration, anti-patterns

## Related

- Templates: [`../../.ai/session/templates/`](../../.ai/session/templates/)
- Memory model: [`../memory/`](../memory/)
