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
│       ├── HISTORY.md
│       ├── SESSION-HANDOFF.md   # Router template
│       └── handoff.md           # Individual handoff template
├── skills/                  # Skill definitions
│   ├── boot.md
│   ├── save.md
│   └── iterate-html.md      # Agentic loop for HTML rendering fixes
└── agents/                  # Agent definitions
    └── README.md

docs/                        # Patterns + deep-dive documentation
├── README.md                # Navigation hub
├── memory/                  # 4-layer memory model + ownership + rotation
├── agents/                  # Multi-agent coordination
├── handoffs/                # Cross-session continuation pattern
├── skills/                  # Skills index + per-skill supporting docs
├── RESEARCH-VALIDATION.md
└── TESTING-WITH-AGENTS.md

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
| `/iterate-html` | Agentic loop for iterating on an HTML rendering until visual criteria are met (capture → diagnose → fix → re-capture) |

## Documentation

The `docs/` folder contains pattern specs and deep-dives that complement the source-of-truth in `.ai/`. Read these when you need to extend the framework, understand the rationale, or wire up a more sophisticated setup.

| Section | What's inside |
|---------|---------------|
| [`docs/memory/`](docs/memory/README.md) | 4-layer memory model (L0-L3), HISTORY rotation, state ownership matrix, structural vs temporal pattern |
| [`docs/agents/`](docs/agents/README.md) | Multi-agent coordination: safety rules, file-locked registry, inter-process communication, coherence audit workflow |
| [`docs/handoffs/`](docs/handoffs/README.md) | Cross-session continuation pattern (router + per-workstream handoff files) |
| [`docs/skills/`](docs/skills/README.md) | Skills index and how to add new skills |
| [`docs/RESEARCH-VALIDATION.md`](docs/RESEARCH-VALIDATION.md) | Alignment with published research on agent memory + testing |
| [`docs/TESTING-WITH-AGENTS.md`](docs/TESTING-WITH-AGENTS.md) | Sub-agent orchestration patterns for test workflows |

Navigate by hopping from README to README. Each section's README links to its children, parent, and lateral siblings — no global index needed.

## Supported Tools

| Tool | Entry Point | Adapter |
|------|-------------|---------|
| Claude Code | `.claude/` + `CLAUDE.md` | `adapters/claude/` |
| Cursor | `.cursorrules` | `adapters/cursor/` |
| OpenAI Codex | `AGENTS.md` | `adapters/codex/` |
| GitHub Copilot | `.github/copilot-instructions.md` | `adapters/copilot/` |

## Testing

See `TESTING.md` for test scenarios to validate the system works with each tool.

## License

MIT
