# Agent Communication — Inter-Process and Inter-Machine Patterns

## Problem

When multiple AI agents need to coordinate, the file-based approach (see [CONCURRENT-AGENTS.md](CONCURRENT-AGENTS.md)) is sufficient for single-machine, cooperative scenarios. But it breaks down when:

- Agents run on different machines (or different WSL distros, containers, VMs)
- Latency matters (request/reply patterns)
- Many small messages need ordering or persistence
- Agents need discovery (who is available, what can they do)

This document compares the protocols and brokers available for inter-agent communication and provides a decision framework.

---

## Network Topology Considerations

Before choosing a transport, understand your topology:

| Topology | Examples | Characteristics |
|----------|----------|----------------|
| **Single process** | Subagents in Claude Code | Shared memory, no protocol needed |
| **Single machine, multiple processes** | Multiple CLI agents | Localhost only, filesystem available |
| **Single machine, multiple namespaces** | WSL2 distros, Docker containers | Same IP often, filesystem may be shared via mounts |
| **Single LAN** | Multiple workstations | DNS or static IPs, latency <1ms |
| **Internet** | Distributed agents | Authentication required, latency variable |

The right protocol depends on the topology. A pattern that works for distributed agents (HTTP+JSON) is overkill for single-machine localhost.

### Special case: WSL2

On Windows with multiple WSL2 distros, all distros share the same network namespace. They have the same IP and can reach each other via `localhost:PORT`. The filesystem is isolated by default, but `/mnt/wsl/` is a shared ext4 mount accessible from all distros.

**Implication**: file-based + localhost is the simplest cross-distro coordination on WSL2.

---

## Protocol Comparison

### NATS — Single-binary message broker

- **What**: open-source broker (CNCF), single binary ~20MB, zero dependencies
- **Patterns**: pub/sub, request/reply, persistent streaming (JetStream)
- **Python client**: `nats-py` (async/await native)
- **Setup**: run `nats-server` on one machine, others connect via `nats://host:4222`
- **Pros**: 5-min setup, sub-millisecond latency, optional persistence, industry standard
- **Cons**: external binary to install, generic protocol (not agent-specific)
- **Use when**: you need a real broker but don't want infrastructure heaviness
- **Refs**: https://nats.io / https://github.com/nats-io/nats.py

### A2A (Agent-to-Agent Protocol)

- **What**: open standard (Linux Foundation, 50+ partners including Google, Anthropic, Microsoft) for inter-agent communication
- **Patterns**: Agent Cards (discovery), tasks, messages, streaming, request/reply
- **Python client**: `python-a2a` (minimal, depends on `requests`) or official `a2a-python` SDK
- **Setup**: each agent exposes an HTTP server with an Agent Card describing its capabilities
- **Pros**: emerging standard, agent-native semantics (capabilities, tasks, artifacts), MCP-compatible
- **Cons**: protocol is young (spec 0.2), more verbose than NATS for simple messaging
- **Use when**: you want a standard that other tools will eventually support
- **MCP/A2A distinction**: MCP = agent ↔ tools (vertical), A2A = agent ↔ agent (horizontal)
- **Refs**: https://github.com/a2aproject/a2a-python / https://python-a2a.readthedocs.io

### Built-in tool features (Claude Code Agent Teams)

- **What**: experimental feature (v2.1.32+) where a lead agent spawns teammates
- **Patterns**: internal mailbox, shared task list
- **Setup**: enable via `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1`
- **Pros**: zero setup, native tool integration
- **Cons**: same-session only, no cross-machine support, no session resumption
- **Use when**: you need quick multi-agent within a single Claude Code session
- **Refs**: https://code.claude.com/docs/en/agent-teams

### ZeroMQ (brokerless)

- **What**: high-performance socket library, no central server
- **Patterns**: pub/sub, push/pull, request/reply, dealer/router
- **Python client**: `pyzmq`
- **Pros**: minimal latency, maximum throughput, no broker to manage
- **Cons**: more orchestration code, no persistence, manual topology management
- **Use when**: you need maximum performance and can manage topology yourself
- **Refs**: https://zeromq.org

### Redis Pub/Sub + Streams

- **What**: in-memory cache/broker with pub/sub + persistent streams
- **Pros**: standard, multi-purpose (cache + queue), Stream persistence
- **Cons**: heavier than NATS, daemon to maintain
- **Use when**: you already use Redis for other purposes
- **Refs**: https://redis.io

### Custom HTTP + SQLite

- **What**: home-rolled Python HTTP server with SQLite persistence
- **Pros**: total control, zero external dependencies, custom-sized
- **Cons**: reinvents what NATS/A2A already do, maintenance burden
- **Use when**: you have very specific needs no standard tool covers (rare)

### MCP (Model Context Protocol)

- **What**: protocol for exposing tools to AI agents
- **Note**: MCP is **not** an inter-agent protocol. It's agent-to-tool. Listed here for clarity.
- **Use when**: you want to expose external tools to your agent

---

## Comparison Matrix

| Criterion | NATS | A2A | Agent Teams | ZeroMQ | Redis | Custom HTTP |
|-----------|:----:|:---:|:-----------:|:------:|:-----:|:-----------:|
| Cross-machine | ✓ | ✓ | ✗ | ✓ | ✓ | ✓ |
| Setup time | 5min | 15min | 2min | 30min | 15min | 2h+ |
| Open standard | CNCF | Linux Fdn | ✗ | ✓ | ✓ | ✗ |
| Agent-native semantics | ✗ | **native** | native | ✗ | ✗ | custom |
| Persistence | JetStream | non-native | ✗ | ✗ | Streams | SQLite |
| External deps | binary | pip | none | pip | binary | pip |
| File sharing | external | external | built-in | external | external | custom |
| Auth | TLS+JWT | OAuth | local | curve | ACL | custom |

---

## Recommendation Patterns

### Pattern 1: Single-machine cooperation (start here)

If your agents run on the same machine, use the file-based approach:

```
.ai-local/AGENTS.json   # Agent registry (see AGENT-REGISTRY.md)
TMP/handoffs/           # Inter-agent handoffs
shared/                 # Shared work area
```

Combined with safety rules from [CONCURRENT-AGENTS.md](CONCURRENT-AGENTS.md), this handles 80% of cases.

### Pattern 2: Cross-namespace coordination (WSL2, containers)

If agents run in different namespaces but on the same host:

```
Host
├── Namespace A (Agent Alpha)         ┌──────────────┐
│   ├── /home/user/projects/a         │ NATS server  │
│   └── /mnt/shared/                  │ localhost    │
│                                     │ :4222        │
├── Namespace B (Agent Beta)          └──────┬───────┘
│   ├── /home/user/projects/b                │
│   └── /mnt/shared/  (same mount)            │
│                                              │
└── Both connect to nats://localhost:4222 ◄───┘
```

Files via shared mount, messages via NATS on localhost.

### Pattern 3: Distributed agents (different machines)

For agents on different machines (or even different cloud regions):

```
Agent Alpha (machine A)              Agent Beta (machine B)
┌──────────────────┐                 ┌──────────────────┐
│ HTTP Server      │                 │ HTTP Server      │
│ Agent Card       │                 │ Agent Card       │
│ POST /tasks      │                 │ POST /tasks      │
└────────┬─────────┘                 └────────┬─────────┘
         │                                    │
         │  ◄─── A2A protocol over HTTPS ───► │
         │       (with auth)                  │
```

Use A2A for cross-machine. Each agent exposes a card describing what it can do, and other agents discover and call it.

### Pattern 4: High-throughput pipelines

If you need high message throughput (>1000 msg/sec) and don't need a broker:

```
Producer ──ZMQ PUSH──► Worker 1
                       Worker 2
                       Worker 3
```

Use ZeroMQ push/pull. No broker, near-line-rate throughput.

---

## File-Based Coordination (Default)

For single-machine scenarios, the simplest pattern is a shared filesystem with conventions:

### Layout

```
/mnt/shared/agent-bus/             # Shared filesystem (could be tmpfs, ext4, etc.)
├── shared/                        # Files exchanged between agents
│   ├── 20260410-data-export.csv
│   └── ...
├── registry/                      # Who is who
│   ├── agent-alpha.json           # {"name": "alpha", "host": "...", "workdir": "..."}
│   └── agent-beta.json
└── log.jsonl                      # Append-only journal of exchanges
```

### Cross-namespace path resolution

Paths like `/home/user/...` are namespace-specific. Convention:

- **Files to share** → copy to `/mnt/shared/agent-bus/shared/`
- **Local references** → prefix with namespace name in messages: `alpha:/home/user/path`
- The receiver knows it can't read directly but understands the context

### Wrapper CLI

A simple Python wrapper provides a clean API:

```bash
# Agent Alpha sends a message to Agent Beta
bus.py send beta "Please process file X"

# Agent Beta polls its inbox
bus.py inbox

# Agent Beta replies
bus.py reply <msg-id> "Done, output at shared/result.csv"

# Share a file
bus.py share /home/user/data.csv
# → Copies to /mnt/shared/agent-bus/shared/data.csv
# → Returns the shared path
```

---

## Discovery and Capability Negotiation

When agents are dynamic (not hardcoded to know about each other), discovery becomes important.

### A2A Agent Cards

A2A standardizes this with **Agent Cards** — JSON documents describing what an agent can do:

```json
{
  "name": "data-processor",
  "version": "1.0",
  "capabilities": ["csv-cleaning", "json-validation", "report-generation"],
  "endpoints": {
    "tasks": "https://host/api/tasks",
    "status": "https://host/api/status"
  },
  "auth": {
    "type": "oauth2",
    "issuer": "..."
  }
}
```

Other agents fetch the card, parse the capabilities, and decide whether to call it.

### Lightweight discovery

If you don't need full A2A, a simple JSON registry works:

```json
[
  {"name": "alpha", "host": "alpha.local", "port": 8000, "skills": ["analyze", "report"]},
  {"name": "beta", "host": "beta.local", "port": 8000, "skills": ["clean", "validate"]}
]
```

Each agent updates the registry on boot/save.

---

## Authentication and Security

### Local-only

If agents communicate only on localhost or via shared filesystem, no auth needed. Use OS file permissions to scope access.

### LAN

For agents on the same LAN, use shared secrets or self-signed TLS:

```python
# NATS with shared secret
nats.connect("nats://localhost:4222", token="shared-secret")
```

### Internet / production

For agents reachable over the internet:

- Use TLS (mandatory)
- Use OAuth2 / JWT for agent identity
- Allow-list specific peers (not "any agent can call any agent")
- Rate limit per peer

A2A handles much of this via its OAuth2 patterns. NATS supports JWT-based auth out of the box.

---

## Reliability Patterns

### Idempotent messages

Every message should be safe to deliver more than once. Add a unique ID to each message and have the receiver track which IDs it has processed.

```json
{
  "id": "msg-2026-04-10-001",
  "from": "alpha",
  "to": "beta",
  "task": "process-csv",
  "args": {"file": "shared/data.csv"}
}
```

If `beta` receives `msg-2026-04-10-001` twice, it processes it once.

### Acknowledgments

For request/reply patterns, the requester should:
1. Send the request
2. Wait for ack with timeout
3. If no ack, retry with exponential backoff
4. After N failures, mark as failed and surface to user

NATS request/reply handles this automatically. With files, you implement it manually.

### Persistent queues

For tasks that must not be lost, use a persistent queue:

- **NATS JetStream** — built-in persistence, replay support
- **Redis Streams** — persistent log structure
- **File-based** — append-only `tasks/pending/` directory, agents `mv` to `tasks/done/` on completion

---

## When NOT to Use Inter-Agent Communication

Sometimes the simplest answer is "don't communicate at all":

- **Sequential pipelines** — agent A writes a file, agent B reads it. No protocol needed, just `cron` or a watch script.
- **Single-coordinator pattern** — one agent (the coordinator) calls everything else as subagents within its own session. No inter-process communication required.
- **Independent work** — agents don't actually need to coordinate; they work on different parts of the same project. Use [CONCURRENT-AGENTS.md](CONCURRENT-AGENTS.md) safety rules.

The most common mistake is reaching for distributed coordination when single-process subagents would work fine.

---

## Decision Framework

```
Do agents need to coordinate at all?
├── No → Use independent execution + safety rules
└── Yes → Are they on the same machine?
    ├── Yes → Are they in the same process?
    │   ├── Yes → Use subagents (no protocol)
    │   └── No → Use file-based coordination
    │           (filesystem + AGENT-REGISTRY)
    └── No → Are they on the same LAN?
        ├── Yes → Use NATS (5min setup)
        └── No → Use A2A protocol (HTTP + Agent Cards)
```

---

## Migration Path

### Starting from nothing

1. **Phase 1**: file-based + AGENT-REGISTRY for single-machine agents
2. **Phase 2**: NATS broker if you need cross-namespace or higher throughput
3. **Phase 3**: A2A wrapper around NATS messages if you want standard semantics
4. **Phase 4**: full distributed deployment with TLS + OAuth2

Each phase reuses the previous infrastructure. NATS + A2A is a common production combination: NATS for transport, A2A semantics on top.

---

## Related

- [CONCURRENT-AGENTS.md](CONCURRENT-AGENTS.md) — Multi-agent safety rules (file-level coordination)
- [AGENT-REGISTRY.md](AGENT-REGISTRY.md) — Agent registration and discovery
- `META-COORDINATION.md` (companion doc, to be added) — Cross-project aggregation
- `BRIDGE-PATTERN.md` (companion doc, to be added) — Cross-tool sync via filesystem mailbox (single-machine pattern)

## References

- [NATS](https://nats.io)
- [NATS Python client](https://github.com/nats-io/nats.py)
- [A2A Protocol](https://github.com/a2aproject/a2a-python)
- [A2A Python docs](https://python-a2a.readthedocs.io)
- [ZeroMQ](https://zeromq.org)
- [Redis](https://redis.io)
- [Claude Code Agent Teams](https://code.claude.com/docs/en/agent-teams)
