# Concurrent Agent Access

## Problem

Multiple AI coding agents (Claude Code, Cursor, Copilot) can run simultaneously on the same workspace. There is no built-in locking mechanism. File writes are last-write-wins. Git operations are not atomic across agents.

This document defines mandatory safety rules and an optional repo-locking mechanism.

## Risk Matrix

| Scenario | Risk | Impact |
|----------|------|--------|
| Two agents edit different state files | NONE | Separate paths, no conflict |
| Two agents edit the same shared file | HIGH | Last write silently wins, first agent's changes lost |
| Two agents `git commit` on the same repo | HIGH | Second commit may include unexpected staged files |
| Two agents `git add` overlapping files | MEDIUM | Staging area is shared, unpredictable commit content |
| Agent A reads file while Agent B writes it | LOW | Read gets partial/stale content (unlikely in practice) |

## Rules (MANDATORY)

### Rule 1: One writer per repo

At any given time, only ONE agent may perform write operations (Edit, Write, git add, git commit) on a given git repo. Other agents may read freely.

```
ALLOWED:
  Agent A writes to project-alpha/     Agent B reads from project-alpha/
  Agent A writes to project-alpha/     Agent B writes to project-beta/

NOT ALLOWED:
  Agent A writes to project-alpha/     Agent B writes to project-alpha/
```

### Rule 2: State files are scoped

Each agent writes ONLY to its own state directory:
- Project Alpha sessions → `project-alpha/.ai-local/`
- Project Beta sessions → `project-beta/.ai-local/`

Never write to another project's state directory.

### Rule 3: Shared content requires coordination

Files under shared directories (documentation, PM artifacts, templates) may be referenced by multiple projects. When a project agent needs to update shared files:

1. The project agent creates or modifies the files
2. The project agent does NOT commit to the shared repo
3. The owning agent (or user) reviews and commits

When a meta agent and a project agent are both active:
- Project agent: commits only in its own git repo
- Meta agent: commits only in the meta git repo
- If both need to modify meta-repo files, the meta agent takes priority

### Rule 4: Commit scope

Each agent commits only within its designated repo. Exception: a meta agent may commit files created by a project agent in the meta repo, provided the project agent has finished writing.

### Rule 5: File naming for parallel work

When two agents might create files in the same directory, use prefixed naming to avoid collisions:

```
# Instead of both writing to the same file:
2026-02-18-analysis-synthesis.md          ← collision risk

# Use distinct names:
2026-02-18-analysis-meeting-synthesis.md  ← meta agent
2026-02-18-analysis-data-sources.md       ← project agent
```

## Repo Locking (Optional)

Registry-based repo claims prevent two agents from writing to the same git repo simultaneously. The system is **advisory by default** (warns on conflict) with an optional enforcement hook.

### How it works

Each agent's registry record includes a `write_repos` field listing the repos it claims for writing. Claims are made at boot, released at save, and checked before granting new claims.

```json
{
  "agent_id": "hostname-1708123456-12345",
  "project": "project-alpha",
  "write_repos": ["project-alpha"],
  "last_heartbeat": "2026-02-17T10:30:00Z"
}
```

### Boot: claim a repo

At boot, each agent registers and claims its primary repo. If another active agent already holds the repo, boot prints a warning but continues (advisory mode).

```bash
# In boot.sh:
agent_register.py register "$AGENT_ID" "$PROJECT"
agent_register.py claim-repo "$AGENT_ID" "$REPO_NAME"
```

### Save: release the repo

At save, each agent releases its repo claim and unregisters.

```bash
# In save.sh:
agent_register.py release-repo "$AGENT_ID" "$REPO_NAME"
agent_register.py unregister "$AGENT_ID"
```

### Manual check

Query who holds a repo:

```bash
uv run python3 scripts/agent_register.py check-repo project-alpha
# {"available": true}
# or: {"available": false, "claimed_by": "...", "task": "...", "since": "..."}
```

### Stale lock recovery

Agents with no heartbeat for 30+ minutes are considered stale. The `prune` command (run automatically at boot) removes stale agents and their repo claims. No manual intervention needed for crashed agents.

### Optional enforcement hook

A PreToolUse hook can block Write/Edit operations on repos claimed by another agent. It is NOT activated by default.

To activate, add to `.claude/settings.json`:

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

### Limitations

- **No file-level locking**: two agents can still write different files in the same repo. The lock is repo-level.
- **No merge conflict detection**: that is a separate problem, out of scope.
- **No automatic resolution**: if two agents conflict, the human decides.
- **No worktrees**: for small-to-medium repos, repo-level claims are sufficient.

## Reference

- [AGENT-REGISTRY.md](AGENT-REGISTRY.md) — registry implementation pattern and example script
- [AGENT-COMMUNICATION.md](AGENT-COMMUNICATION.md) — inter-process and inter-machine transport options
- [../memory/MEMORY-SYSTEM.md](../memory/MEMORY-SYSTEM.md) — state file architecture (`.ai-local/`)
- `META-COORDINATION.md` (companion doc, to be added in a later wave) — meta-layer aggregation and sync protocol
