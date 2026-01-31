# AI System

Tool-agnostic session management and skills for AI-assisted development.

## Philosophy

**Single source of truth**: All definitions live in `.ai/`. Entry points for different tools redirect there.

```
AGENTS.md ─────┐
CLAUDE.md ─────┼──► .ai/  (source of truth)
.cursorrules ──┘
```

## Quick Start

### 1. Copy to your project

```bash
# Clone or copy the .ai folder
cp -r ai-system/.ai your-project/

# Create local state folder (add to .gitignore)
mkdir your-project/.ai-local
echo ".ai-local/" >> your-project/.gitignore

# Copy the universal entry point
cp ai-system/AGENTS.md your-project/
```

### 2. Add adapter for your tool

```bash
# For Claude Code
cp -r ai-system/adapters/claude/.claude your-project/

# For Cursor
cp ai-system/adapters/cursor/.cursorrules your-project/

# For Codex - AGENTS.md is enough

# For GitHub Copilot
mkdir -p your-project/.github
cp ai-system/adapters/copilot/copilot-instructions.md your-project/.github/
```

### 3. Boot your first session

```bash
cd your-project
.ai/session/scripts/boot.sh
```

Or use your tool's command: `/boot`, `boot`, etc.

## Structure

```
.ai/                         # Source of truth (commit this)
├── README.md                # System documentation
├── session/                 # Session management
│   ├── README.md            # Concept: memory layers
│   ├── scripts/
│   │   ├── boot.sh          # Generate context
│   │   └── save.sh          # Save state prompt
│   └── templates/
│       ├── STATE.md
│       ├── CONTEXT.md
│       └── HISTORY.md
├── skills/                  # Skill definitions
│   ├── boot.md
│   └── save.md
└── agents/                  # Agent definitions
    └── README.md

.ai-local/                   # Local state (gitignore this)
├── STATE.md                 # Current session state
├── CONTEXT.md               # Generated context
└── HISTORY.md               # Session history

adapters/                    # Tool-specific wrappers
├── claude/                  # Claude Code adapter
├── cursor/                  # Cursor adapter
├── codex/                   # Codex adapter
└── copilot/                 # GitHub Copilot adapter
```

## Memory Layers

The session system uses 4 memory layers:

| Layer | Storage | Retention | Purpose |
|-------|---------|-----------|---------|
| L0 | Chat | Current session | Working memory |
| L1 | STATE.md | ~3 sessions | Detailed state |
| L2 | HISTORY.md | All sessions | Compressed log |
| L3 | Git commits | Forever | Milestones |

## Skills

| Skill | Purpose |
|-------|---------|
| `/boot` | Start session, load context from memory layers |
| `/save` | Save session state, propose git commit |

## Supported Tools

| Tool | Entry Point | Adapter |
|------|-------------|---------|
| Claude Code | `.claude/` + `CLAUDE.md` | `adapters/claude/` |
| Cursor | `.cursorrules` | `adapters/cursor/` |
| OpenAI Codex | `AGENTS.md` | `adapters/codex/` |
| GitHub Copilot | `.github/copilot-instructions.md` | `adapters/copilot/` |

## Testing

See `TESTING.md` for test scenarios to validate the system works with each tool.

## Documentation

| Document | Purpose |
|----------|---------|
| `PHILOSOPHY.md` | Radical minimalism, declarative over imperative |
| `AGENTS.md` | Universal entry point for AI assistants |
| `TESTING.md` | Test scenarios for each tool |
| `docs/TESTING-WITH-AGENTS.md` | Agent-based testing strategy with subagents |
| `docs/RESEARCH-VALIDATION.md` | Comparison with industry best practices |
| `docs/PROJECT-TAXONOMY.md` | Project naming, directory conventions, types |
| `docs/META-COORDINATION.md` | Multi-project tracking, aggregation, streams |
| `docs/RETRIEVAL-STRATEGIES.md` | Navigation-based retrieval, token budgets, save-time triggers, anti-patterns |
| `docs/PM-INTEGRATION.md` | Syncing AI state with PM tools (Notion, Linear, Jira, GitHub) |

## License

MIT
