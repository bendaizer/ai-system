# Multi-Agent Coordination

Specs for running multiple AI agents on the same workspace without stepping on each other's toes.

## The four concerns

| Concern | Doc | When to read |
|---|---|---|
| **Safety**: prevent silent data loss when 2+ agents write to the same files | [`CONCURRENT-AGENTS.md`](CONCURRENT-AGENTS.md) | Before running any concurrent setup. Mandatory rules. |
| **Awareness**: agents know about each other (who's working on what, who holds which repo) | [`AGENT-REGISTRY.md`](AGENT-REGISTRY.md) | When advisory warnings aren't enough and you need an enforceable registry. |
| **Communication**: agents talk to each other (single-machine or cross-machine) | [`AGENT-COMMUNICATION.md`](AGENT-COMMUNICATION.md) | When file-based coordination breaks (different machines, request/reply patterns, discovery). |
| **Coherence**: spot drift across the workspace using parallel read-only agents | [`COHERENCE-AUDIT-WORKFLOW.md`](COHERENCE-AUDIT-WORKFLOW.md) | Periodically, before releases, or when state systems start contradicting each other. |

## How they fit together

```
                  ┌─────────────────────┐
                  │  CONCURRENT-AGENTS  │  ← mandatory baseline (rules only, no infra)
                  └──────────┬──────────┘
                             │
                             │ enforced by
                             ▼
                  ┌─────────────────────┐
                  │   AGENT-REGISTRY    │  ← optional: file-locked JSON registry
                  └──────────┬──────────┘
                             │
                             │ communicates via
                             ▼
                  ┌─────────────────────┐
                  │  AGENT-COMMUNICATION │  ← protocol comparison (NATS, A2A, ZeroMQ, …)
                  └──────────┬──────────┘
                             │
                             │ audited by
                             ▼
                  ┌─────────────────────┐
                  │ COHERENCE-AUDIT-WF  │  ← 4-phase workflow: parallel exploration → triage
                  └─────────────────────┘
```

You can adopt the four independently. The mandatory baseline is `CONCURRENT-AGENTS.md` (no infra, just rules). The other three are opt-in capabilities you reach for when you hit specific pain.

## Quick start

Pick the smallest version of the system that solves your current pain:

| Pain | Solution |
|---|---|
| Two Claude Code sessions clobbered each other's state | Apply `CONCURRENT-AGENTS.md` Rule 2 (state files scoped per project) |
| You don't know which agent holds which repo | Stand up the registry from `AGENT-REGISTRY.md` (~200L Python script) |
| Agents need to coordinate across machines | Read `AGENT-COMMUNICATION.md`, pick a transport (NATS for most cases) |
| Cross-doc / cross-state contradictions sneak in | Run the 4-phase audit from `COHERENCE-AUDIT-WORKFLOW.md` |

## Related

- [`../memory/STATE-OWNERSHIP.md`](../memory/STATE-OWNERSHIP.md) — Ownership matrix between state systems (agent registry is one of them)
- [`../handoffs/HANDOFF-SYSTEM.md`](../handoffs/HANDOFF-SYSTEM.md) — Cross-session continuation (complements multi-agent within-session coordination)
- [`../TESTING-WITH-AGENTS.md`](../TESTING-WITH-AGENTS.md) — Testing patterns using sub-agents (separate concern from this folder, but uses similar primitives)
