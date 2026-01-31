# Meta-Coordination

## Problem

When working across multiple projects, you need:
- A single dashboard showing all project states
- Cross-project dependency tracking
- Aggregated status for reporting
- Session context that spans projects

No single project's `.ai/` can provide this. The meta layer does.

## The Meta Project

The meta layer is itself a project with `.ai/` and `.ai-local/`. What makes it special:

1. **It reads sibling project state** -- on boot, it scans other projects' `.ai-local/STATE.md` files
2. **It aggregates** -- compiles a cross-project dashboard
3. **It does not modify** -- meta never writes to project `.ai-local/` directories
4. **It has its own PM artifacts** -- STATUS.md, BLOCKERS.md, DECISIONS.md

## Directory Layout

```
workspace/
├── _meta/                        # Meta-coordination project
│   ├── .ai/
│   │   └── session/
│   │       └── scripts/
│   │           ├── boot.sh       # Reads all sibling STATE.md files
│   │           └── save.sh       # Saves meta state only
│   ├── .ai-local/
│   │   ├── STATE.md              # Meta-level state
│   │   ├── CONTEXT.md            # Aggregated from all projects
│   │   └── HISTORY.md            # Meta session history
│   └── pm/                       # Project management artifacts
│       ├── STATUS.md             # Cross-project dashboard
│       ├── BLOCKERS.md           # Active blockers
│       └── DECISIONS.md          # Pending decisions
└── project-alpha/
    └── .ai-local/STATE.md        # <- Meta reads this on boot
```

## Aggregation Flow

```
META BOOT:

1. Read _meta/.ai-local/STATE.md          (own state)
2. For each sibling project:
   a. Read {project}/.ai-local/STATE.md   (project state)
   b. Extract: progress, blockers, last update
3. Generate _meta/.ai-local/CONTEXT.md    (aggregated view)
4. Present cross-project dashboard

META SAVE:

1. Update _meta/.ai-local/STATE.md        (meta state only)
2. Rotate to HISTORY.md if needed
3. Propose commit for meta-level changes
```

## Sync Protocol

Meta aggregation is **read-only and pull-based**:

| Principle | Rule |
|-----------|------|
| Direction | Meta pulls from projects; never pushes |
| Timing | On boot and on explicit sync command |
| Scope | Reads STATE.md only; never reads project code |
| Failure mode | If a project has no STATE.md, report "no state" and continue |

## Organizing Work: Streams

For complex multi-project programs, meta can organize work into streams:

```
pm/
├── STATUS.md                     # Dashboard with stream summary
├── BLOCKERS.md                   # Cross-project blockers
├── DECISIONS.md                  # Pending decisions
└── roadmap/
    ├── streams/
    │   ├── A-stream-name.md      # Stream detail
    │   ├── B-stream-name.md
    │   └── ...
    └── roadmap.md                # Master roadmap
```

Streams are thematic groupings that may span multiple projects. A stream has:
- Owner
- Progress %
- Theme breakdown (Theme > Epic > Task)
- Dependencies on other streams

## Implementation Notes

The meta boot script should:
1. Find all sibling directories with `.ai-local/STATE.md`
2. Extract summary info (first 20 lines or a structured header)
3. Compile into CONTEXT.md
4. Be idempotent and fast (< 2 seconds)

This is a pattern, not a rigid implementation. Adapt to your workspace.
