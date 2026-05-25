# Agent Registry Pattern

> **Status**: Specification (no reference implementation shipped yet). The pattern below is extracted from a production registry used to coordinate 2-4 concurrent agents across a multi-repo workspace.

When multiple AI agents work concurrently on the same workspace, they need to know about each other. The agent registry is a shared JSON file where agents register, declare their current task, claim repos for writing, and detect conflicts.

---

## Why a Registry

| Problem | Without Registry | With Registry |
|---------|-----------------|---------------|
| Two agents edit same repo | Silent last-write-wins | Conflict detected at boot |
| Agent crashes mid-session | Stale locks forever | Auto-pruned after 30 min |
| "Who's working on what?" | Ask each agent | `agent_register.py list` |
| CI needs to check safety | No visibility | `agent_register.py check-repo X` |

The registry enforces the **one writer per repo** rule from [CONCURRENT-AGENTS.md](CONCURRENT-AGENTS.md).

---

## Architecture

```
.ai-local/
├── AGENTS.json        # Registry file (JSON, file-locked)
└── agents.lock        # fcntl lock file
```

The registry lives in `.ai-local/` (gitignored, mutable state). All access goes through a single script that acquires a file lock before reading or writing.

---

## Registry Schema

```json
{
  "version": 1,
  "updated_at": "2026-02-23T14:30:00",
  "agents": [
    {
      "agent_id": "hostname-1708123456-12345",
      "project": "my-project",
      "task": "implementing auth module",
      "status": "active",
      "write_repos": ["my-project"],
      "started_at": "2026-02-23T14:00:00",
      "last_heartbeat": "2026-02-23T14:30:00"
    }
  ]
}
```

| Field | Purpose |
|-------|---------|
| `agent_id` | Unique ID (hostname + timestamp + PID) |
| `project` | Which project the agent is working on |
| `task` | Current task description (human-readable) |
| `status` | `active`, `idle`, `blocked`, `stale` |
| `write_repos` | Repos this agent claims for writing |
| `started_at` | When the agent registered |
| `last_heartbeat` | Last activity timestamp |

---

## Commands

### Lifecycle

| Command | When | Effect |
|---------|------|--------|
| `register <id> <project>` | At boot | Add agent to registry |
| `unregister <id>` | At save | Remove agent from registry |
| `heartbeat <id>` | Periodically | Update last_heartbeat timestamp |
| `set-task <id> <desc>` | On task change | Update task field + heartbeat |

### Repo Claims

| Command | Effect |
|---------|--------|
| `claim-repo <id> <repo>` | Claim write access; fails if another active agent holds it |
| `release-repo <id> <repo>` | Release write claim |
| `check-repo <repo>` | Query: who holds this repo? (JSON output) |

### Maintenance

| Command | Effect |
|---------|--------|
| `list [--active-only]` | Show all registered agents |
| `prune [--dry-run]` | Remove agents with no heartbeat for >30 min |
| `status` | Registry summary (count, projects) |

---

## Boot/Save Integration

### At boot

```bash
# Generate a unique agent ID
AGENT_ID="$(hostname)-$(date +%s)-$$"

# Register and claim repo
python3 scripts/agent_register.py register "$AGENT_ID" "$PROJECT"
python3 scripts/agent_register.py claim-repo "$AGENT_ID" "$REPO_NAME"

# Prune stale agents from previous crashed sessions
python3 scripts/agent_register.py prune
```

### At save

```bash
python3 scripts/agent_register.py release-repo "$AGENT_ID" "$REPO_NAME"
python3 scripts/agent_register.py unregister "$AGENT_ID"
```

### During work

```bash
# Update task description (also refreshes heartbeat)
python3 scripts/agent_register.py set-task "$AGENT_ID" "fixing auth bug"
```

---

## Stale Lock Recovery

Agents that crash or disconnect leave orphaned entries. The registry handles this automatically:

- **Stale threshold**: 30 minutes without heartbeat
- **Detection**: `list` marks stale agents; `claim-repo` ignores stale claims
- **Cleanup**: `prune` removes stale entries (run at boot)
- **No manual intervention needed** for normal crashes

---

## Optional Enforcement Hook

By default, the registry is **advisory** — it warns on conflicts but doesn't block. For strict enforcement, add a PreToolUse hook that checks repo claims before allowing Write/Edit:

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Write|Edit",
        "hooks": [
          {
            "type": "command",
            "command": "scripts/check_repo_lock.sh"
          }
        ]
      }
    ]
  }
}
```

---

## Limitations

- **Repo-level, not file-level**: two agents can still write different files in the same repo if they bypass the registry
- **No merge conflict resolution**: that's a separate problem (use git worktrees for isolation)
- **fcntl-based locking**: works on Linux/macOS, not Windows
- **Single machine**: the lock file doesn't span network boundaries

---

## Reference Implementation

A working implementation (`agent_register.py`, ~200L) is not bundled with this framework. The schema and command surface above are sufficient to write one in the language of your choice. The shape we recommend: a single Python (or Node) script that takes a `<command> <args>` invocation, acquires an `fcntl`/`flock` lock on `.ai-local/agents.lock`, reads `.ai-local/AGENTS.json`, mutates it, and writes back atomically.

---

## Related Documents

| Document | Relevance |
|----------|-----------|
| [CONCURRENT-AGENTS.md](CONCURRENT-AGENTS.md) | Mandatory safety rules (one writer per repo, state scoping) |
| [AGENT-COMMUNICATION.md](AGENT-COMMUNICATION.md) | Inter-process and inter-machine transport options |
| `META-COORDINATION.md` (companion doc, to be added) | Multi-project aggregation that reads agent state |
| `IMPLEMENTATION-GUIDE.md` (companion doc, to be added) | Full framework setup, references registry as optional |
