# Project Management Integration

## Problem

AI sessions generate state (STATE.md, HISTORY.md, git commits) that overlaps with project management tools (Notion, Linear, Jira, GitHub Issues). Without integration:
- Status is tracked in two places (PM tool + STATE.md)
- Tasks drift out of sync
- Session handoffs lose PM context
- Reporting requires manual reconciliation

## Principle: PM Tool is Source of Truth for Business; `.ai/` is Source of Truth for Sessions

These serve different audiences:

| Aspect | PM Tool (Notion, Linear, etc.) | `.ai/` System |
|--------|--------------------------------|---------------|
| Audience | Stakeholders, managers, team | AI agent, developer |
| Content | Business status, milestones, blockers | Technical state, session memory |
| Update frequency | Daily/weekly by humans | Every session by AI |
| Format | Database records, boards, timelines | Markdown files |
| Persistence | Cloud-hosted | Git-committed or local |

Neither replaces the other. They sync at defined touchpoints.

## Sync Touchpoints

### 1. Session Boot -> Pull from PM

On `/boot`, the session script can optionally pull context from the PM tool:

```
PM Tool                          .ai-local/
+---------------+               +----------------+
| Active tasks  | ---- pull --> | CONTEXT.md     |
| Blockers      |               | (PM section)   |
| Sprint goals  |               |                |
+---------------+               +----------------+
```

**Implementation**: A sync script reads from the PM API and appends a `## PM Context` section to CONTEXT.md. This is informational -- the AI reads it but does not modify PM state.

### 2. Session Save -> Push to PM

On `/save`, the session script can optionally push status back:

```
.ai-local/                      PM Tool
+----------------+              +---------------+
| STATE.md       | ---- push -> | Task status   |
| (summary)      |              | Comments      |
|                |              | Time logged   |
+----------------+              +---------------+
```

**Implementation**: A sync script reads STATE.md, extracts completed items and blockers, and updates corresponding PM records via API.

### 3. Meta Sync -> Dashboard Reconciliation

The meta layer can reconcile its STATUS.md with the PM tool:

```
_meta/pm/STATUS.md  <---- compare ----> PM Dashboard
                            |
                     Discrepancy report
```

## Integration Patterns

### Pattern A: File-Based Sync (Simplest)

Export PM data to markdown files. Import status from markdown files.

```
pm/
├── STATUS.md          # Manually maintained or auto-generated
├── imports/           # Pulled from PM tool (read-only)
│   └── sprint.md      # Current sprint exported as markdown
└── exports/           # Pushed to PM tool
    └── session-log.md # Session summary for PM import
```

**Pros**: No API dependency, debuggable with cat, works offline
**Cons**: Manual trigger, can drift

### Pattern B: Script-Based Sync (Recommended)

Shell scripts in `.ai/session/scripts/` that call PM APIs:

```
.ai/session/scripts/
├── boot.sh            # Standard boot
├── save.sh            # Standard save
├── pm-pull.sh         # Pull sprint/tasks from PM tool
└── pm-push.sh         # Push session status to PM tool
```

Each script is:
- Optional (boot/save work without them)
- Tool-specific (one per PM tool: notion-pull.sh, linear-pull.sh)
- Idempotent
- Fail-safe (PM tool down? Continue without sync)

**Pros**: Automated, consistent, still file-based at the edges
**Cons**: Requires API credentials, tool-specific scripts

### Pattern C: Adapter-Based Sync (Most Flexible)

Like AI tool adapters, PM tool adapters translate between `.ai/` state format and PM tool format:

```
.ai/
└── pm/
    ├── adapter.sh     # Selected PM tool adapter
    ├── adapters/
    │   ├── notion.sh  # Notion-specific sync
    │   ├── linear.sh  # Linear-specific sync
    │   ├── github.sh  # GitHub Issues/Projects sync
    │   └── jira.sh    # Jira sync
    └── config.md      # PM tool config (which adapter, project IDs)
```

**Pros**: Swap PM tools without changing workflow, clean separation
**Cons**: More structure to maintain

## What Gets Synced

Not everything. Only the intersection:

| From PM -> `.ai/` (on boot) | From `.ai/` -> PM (on save) |
|-----------------------------|-----------------------------|
| Active sprint/iteration tasks | Tasks completed this session |
| Current blockers | New blockers discovered |
| Sprint goal / focus | Session summary (for PM comments) |
| Assigned items for current user | Time spent (if tracked) |

**Never synced**:
- Full session transcripts (too verbose for PM)
- Code diffs (that's git's job)
- Internal AI reasoning (not useful for stakeholders)

## Configuration

PM integration is opt-in. A project without PM integration works identically -- boot and save just skip the PM sync step.

Configuration lives in `.ai/pm/config.md` (or a simple `.env`-style file):

```markdown
# PM Integration Config

- **Tool**: notion | linear | github | jira | none
- **Project ID**: abc123
- **Sync on boot**: yes | no
- **Sync on save**: yes | no
- **API credentials**: Use environment variable `PM_API_TOKEN`
```

## Relationship to Meta PM

The meta layer's PM system (STATUS.md, BLOCKERS.md, DECISIONS.md) can itself sync with a PM tool. This creates a two-level sync:

```
PM Tool (Notion/Linear)
    | sync
Meta PM (STATUS.md, BLOCKERS.md)
    | aggregation (read-only)
Project 1 STATE.md
Project 2 STATE.md
Project 3 STATE.md
```

The meta PM is the "AI-native" view. The PM tool is the "stakeholder-native" view. Sync keeps them aligned.

## Implementation Priority

1. **Start with nothing** -- boot/save work without PM integration
2. **Add file-based sync** -- export/import markdown files manually
3. **Add script-based sync** -- automate with PM API scripts
4. **Add adapters** -- if you need to support multiple PM tools

Most teams need only levels 1-2. Level 3 is for teams with established PM workflows. Level 4 is for frameworks and products.
