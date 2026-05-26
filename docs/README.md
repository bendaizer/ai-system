# docs/

Patterns, deep-dives and supporting docs that complement the operational source-of-truth in `.ai/`.

Read these when you want to **extend** the framework, **understand the rationale** behind a choice, or **wire up a more sophisticated setup**. For everyday operation, `.ai/README.md` is enough.

## Sections

| Folder | What's inside |
|---|---|
| [`memory/`](memory/README.md) | The 4-layer memory model (L0-L3), HISTORY rotation, ownership matrix between state systems, and the structural-vs-temporal pattern |
| [`agents/`](agents/README.md) | Multi-agent coordination: safety rules, file-locked registry, inter-process communication, coherence audit workflow |
| [`handoffs/`](handoffs/README.md) | Cross-session continuation: a router file + per-workstream handoff files for multi-stream workspaces |
| [`skills/`](skills/README.md) | Skills index + how to add a new skill |

## Standalone docs

| File | Purpose |
|---|---|
| [`RESEARCH-VALIDATION.md`](RESEARCH-VALIDATION.md) | Alignment with published research on agent memory + testing |
| [`TESTING-WITH-AGENTS.md`](TESTING-WITH-AGENTS.md) | Sub-agent orchestration patterns for test workflows |

## Navigation

This documentation set follows a **hop-by-hop navigation** pattern. From any README, you can reach related content in 1-2 hops via the "Related" section at the bottom of each file. You don't need to load a global index.

Three entry points depending on what you're after:
- **"I want to set up the framework in a new project"** → start from the top-level `../README.md` and `../AGENTS.md`
- **"I want to understand a specific pattern"** → enter directly into the relevant section (e.g. `memory/MEMORY-SYSTEM.md`)
- **"I want to extend an existing setup"** → start from the section README, follow links

## Related

- `../README.md` — Top-level repo entry point
- `../AGENTS.md` — Universal entry point for AI coding assistants
- `../.ai/README.md` — Source-of-truth operational docs
