# Navigation

How readers (human or AI) find their way around the codebase without loading a global index.

## The two docs

| Doc | When to read |
|---|---|
| [`RETRIEVAL-STRATEGIES.md`](RETRIEVAL-STRATEGIES.md) | The philosophy: **navigation, not search** (O(depth) vs O(n)). Per-folder README format, minimal template, anti-patterns. **Start here for the why and the how.** |
| [`NAVIGATION-HEALTH.md`](NAVIGATION-HEALTH.md) | Three save-time checks that surface drift (missing READMEs, broken links, unreferenced files). Advisory only, no auto-fix. **Read this when you wire the pattern into your boot/save scripts.** |

## TL;DR

- Each directory with ≥3 files gets a `README.md` (~30 lines max)
- Each README lists children + parent + lateral siblings, nothing more
- An AI hops from README to README to reach any file (~3 hops, ~1.5K tokens)
- A save-time script flags blind spots (no README) and dead links — humans fix them

## Adopt this pattern

1. Read [`RETRIEVAL-STRATEGIES.md`](RETRIEVAL-STRATEGIES.md) once
2. Write a README at the root of your project listing top-level directories
3. Add a README per top-level directory listing its children + parent
4. Stop there. Don't pre-create READMEs for empty/leaf directories.
5. When a directory crosses ~3 files, add its README
6. (Optional) wire the [`NAVIGATION-HEALTH.md`](NAVIGATION-HEALTH.md) checks into your save script

## Related

- [`../README.md`](../README.md) — Documentation hub (parent)
- [`../memory/`](../memory/README.md) — Memory layers (different concern: state vs structure)
- [`../agents/`](../agents/README.md) — Multi-agent coordination
- [`../handoffs/`](../handoffs/README.md) — Cross-session continuation
- [`../skills/`](../skills/README.md) — Skill definitions
