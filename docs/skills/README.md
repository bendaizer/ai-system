# Skills

Reusable skill definitions that any project using this framework can plug in.

Skills live in `.ai/skills/` (one markdown file per skill). The format follows the standard skill convention: a YAML front-matter with `name` and `description`, then the procedure.

## Current skills

| Skill | Purpose |
|---|---|
| [`iterate-html.md`](../../.ai/skills/iterate-html.md) | Agentic loop for iterating on an HTML rendering until visual criteria are met (capture → analyze → diagnose → fix → re-capture). Requires a Playwright MCP server. |

## Adding a new skill

1. Create `.ai/skills/<name>.md` with a YAML front-matter (`name`, `description`)
2. Write the procedure (when to invoke, prerequisites, steps, exit criteria, anti-patterns)
3. Add an entry to this README
4. If the skill depends on external tooling (MCP server, CLI, library), add a supporting doc here in `docs/skills/`

Keep skills **tool-agnostic where possible** and **focused** (one skill per concern). A skill that needs more than ~200 lines of procedure is probably two skills in disguise.

## Related

- [`../README.md`](../README.md) — Documentation hub (parent)
- [`../memory/`](../memory/README.md) — Memory layers that skills read from and write to
- [`../agents/`](../agents/README.md) — Multi-agent coordination (sub-agents are often invoked from inside a skill)
- [`../handoffs/`](../handoffs/README.md) — Where skills document their iteration notes
- `../../.ai/skills/` — The actual skill definition files (markdown front-matter + procedure)
