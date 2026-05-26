# Memory — Overview

How the ai-system framework persists context across AI sessions.

## The model in 30 seconds

Four layers, from volatile to permanent:

```
L0  Chat context        ~200K tokens   current session only
L1  STATE.md            ~2K tokens     ~3 sessions
L2  HISTORY.md          1K loaded      all sessions (append + rotate)
L3  Git commits         unlimited      forever
```

Plus a fifth dimension: **structural vs temporal**. Some context is stable (architecture, conventions) and lives outside the L0-L3 cycle in always-loaded files (e.g. `AGENTS.md`). The rest is the session snapshot that L1-L2 carry.

## The docs

| Doc | When to read |
|---|---|
| [`MEMORY-SYSTEM.md`](MEMORY-SYSTEM.md) | The full L0-L3 model: layer-by-layer specs, token budgets, boot/save cycle, design rationale, overflow handling, staleness detection. **Start here for the theory.** |
| [`HISTORY-ROTATION.md`](HISTORY-ROTATION.md) | How HISTORY.md grows and rotates into HISTORY-ARCHIVE.md once it exceeds ~300 lines. Includes a reference rotation script. |
| [`STATE-OWNERSHIP.md`](STATE-OWNERSHIP.md) | The ownership matrix between five state systems (auto-memory, handoffs, PM, STATE.md, git). Lifecycle rules + anti-patterns. **Read this when state systems start drifting.** |
| [`STRUCTURAL-VS-TEMPORAL.md`](STRUCTURAL-VS-TEMPORAL.md) | The pattern that separates "what changes rarely and guides navigation" from "what changes every session and needs a timestamp." Prevents bloated boot payloads and stale architecture docs. |

## How they fit together

```
                        ┌─────────────────────────────┐
                        │  STRUCTURAL-VS-TEMPORAL.md  │
                        │  (the meta-pattern)         │
                        └──────────────┬──────────────┘
                                       │
                       splits content into 2 axes
                                       │
                ┌──────────────────────┴──────────────────────┐
                ▼                                             ▼
        Structural layer                              Temporal layer
        (always loaded)                              (boot/save cycle)
                │                                             │
                │                                             ▼
                │                              ┌──────────────────────────┐
                │                              │  MEMORY-SYSTEM.md        │
                │                              │  L0 → L1 → L2 → L3       │
                │                              └──────┬───────────────────┘
                │                                     │
                │              uses                   │ governs
                │                                     ▼
                │                       ┌──────────────────────────┐
                │                       │  HISTORY-ROTATION.md     │
                │                       │  (L2 lifecycle)          │
                │                       └──────────────────────────┘
                │
                │  cuts across all layers
                ▼
        ┌──────────────────────────┐
        │  STATE-OWNERSHIP.md      │
        │  (5 systems, no overlap) │
        └──────────────────────────┘
```

## Quick start

1. Read [`MEMORY-SYSTEM.md`](MEMORY-SYSTEM.md) once. It's the longest doc but answers most questions on first pass.
2. When you wire up your own boot/save scripts, refer to [`STATE-OWNERSHIP.md`](STATE-OWNERSHIP.md) to decide what belongs where.
3. Apply [`STRUCTURAL-VS-TEMPORAL.md`](STRUCTURAL-VS-TEMPORAL.md) when you're tempted to dump architecture into STATE.md (don't).
4. Set up [`HISTORY-ROTATION.md`](HISTORY-ROTATION.md) once HISTORY.md crosses ~150 lines.

## Related

- [`../README.md`](../README.md) — Documentation hub (parent)
- [`../agents/`](../agents/README.md) — Multi-agent coordination (state ownership intersects with the agent registry)
- [`../handoffs/`](../handoffs/README.md) — Cross-session continuation (complements the L1 STATE.md when workstreams multiply)
- [`../skills/`](../skills/README.md) — Skill definitions that read and write these memory layers
- `../../.ai/session/README.md` — Concise session-management entry point in the framework code
- `../../.ai/session/scripts/boot.sh` and `save.sh` — Reference implementations (stubs that demonstrate the L0-L3 cycle)
