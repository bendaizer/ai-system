# Project Taxonomy

## The Word "Project"

The ai-system uses "project" as the generic term for any unit of work that has its own `.ai/` directory. A project can be:

- A client deliverable (industrial app, consulting engagement)
- An internal tool (platform, CLI, library)
- Exploratory work (sandbox, spike, proof of concept)
- Data science work (analysis, notebooks, models)
- Knowledge management (documentation, research, frameworks)
- A meta-coordination layer (tracking multiple projects)

The term was chosen because:
- It covers all types without forcing a category
- Natural in sentences: "boot a project", "project status", "switch project"
- Industry standard -- no learning curve
- Short enough for daily use

## Directory Structure

Each project is a directory with its own `.ai/` system:

```
workspace/                    # Parent directory (optional)
├── project-alpha/            # A project
│   ├── .ai/                  # AI system (committed)
│   ├── .ai-local/            # Local state (gitignored)
│   └── AGENTS.md             # Universal entry point
├── project-beta/             # Another project
│   ├── .ai/
│   ├── .ai-local/
│   └── AGENTS.md
└── _meta/                    # Meta-coordination (also a project)
    ├── .ai/
    ├── .ai-local/
    └── AGENTS.md
```

## Naming Conventions

| Type | Pattern | Examples |
|------|---------|---------|
| Client projects | `{client-name}/` or `{client}-{domain}/` | `acme/`, `acme-welding/` |
| Internal tools | `{org}-{name}/` | `myco-platform/`, `myco-shell/` |
| Exploratory | `{org}-sandbox/` or `sandbox/` | `sandbox/` |
| Data science | `{org}-data-lab/` or `data-lab/` | `data-lab/` |
| Meta coordination | `_meta/` | `_meta/` |

No suffix like `-proto` or `-project` -- the directory IS the project.

## Project Independence

Each project is self-contained:
- Has its own `.ai/` with session scripts, skills, agents
- Has its own `.ai-local/` state
- Has its own `AGENTS.md` entry point
- Can be cloned and worked on independently
- Does not depend on sibling projects or the meta layer

The meta layer aggregates from projects but does not control them.

## Project Types (optional classification)

Projects may optionally declare their type in `.ai/session/templates/STATE.md`:

```markdown
## Project
- **Type**: client-deliverable | internal-tool | exploratory | data-science | knowledge | meta
- **Domain**: brief description
```

This is informational, not enforced. The ai-system treats all projects identically.
