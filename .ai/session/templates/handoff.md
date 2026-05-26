# Handoff: <topic>

> Created: YYYY-MM-DD · Stream: <name> · Status: Active

<!--
This is a RICH example handoff with all the sections you might want.

Minimum viable handoff = just three things:
  1. Status (active / deferred / closed)
  2. Where we are (2-4 sentences)
  3. Next step (one concrete instruction)

Pick the shape that fits your team. The framework doesn't force a schema —
see docs/handoffs/HANDOFF-SYSTEM.md "Handoff file format" for the rationale.
-->

## Context

Why this work exists. What problem it solves. 2-3 paragraphs max — enough that someone re-entering cold (3 days later, or a different agent) understands the *why* without reading other files.

## Recent work (this handoff's sessions)

- Bullet list of what was done across the sessions that touched this handoff.
- Decisions made and their rationale (move important ones to "Key decisions" below).
- Files created/modified (with paths).

## Open loops

- [ ] Things started but not finished
- [ ] Questions waiting for answers
- [ ] Decisions pending (with context for whoever picks this up)

## Key decisions

| Decision | Choice | Rationale | Date |
|---|---|---|---|
| What was decided | The choice | Why | YYYY-MM-DD |

## Files

- `path/to/file.ext` — what it does, what changed in this handoff
- `path/to/other.ext` — ...

## Next session

The exact first step. Not "continue work on X" but a concrete sentence:
"Implement the validation function in src/auth/validate.ts following the schema in lib/types/auth.ts:42. The handler should reject invalid tokens with 401 (not 403)."

If there are multiple candidate next steps, list them in priority order with a 1-line rationale each.
