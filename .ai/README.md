# AI System - Source of Truth

This folder contains all AI assistant definitions. Tool-specific entry points redirect here.

## Structure

```
.ai/
├── scripts/           # Standalone utility scripts
│   └── statusline.sh  # Claude Code terminal status hook
├── session/           # Session management subsystem
│   ├── README.md      # Memory layer concepts
│   ├── scripts/       # Boot/save scripts
│   └── templates/     # File templates
├── skills/            # Skill definitions (commands)
└── agents/            # Agent definitions (tasks)
```

## Subsystems

| Subsystem | Purpose | Status |
|-----------|---------|--------|
| `scripts/` | Standalone utilities (statusline) | Ready |
| `session/` | Persistent context across sessions | Ready |
| `skills/` | User-invocable commands | Ready |
| `agents/` | Task-specific prompts | Framework |

## Adding New Skills

1. Create `.ai/skills/your-skill.md` following the format
2. Document in `AGENTS.md`
3. Add adapter wrappers if needed

## Adding New Agents

1. Create `.ai/agents/your-agent.md` following the format
2. Add validation script if needed
3. Document in `AGENTS.md`

## Skill Format

```markdown
# Skill Name

One-line description.

## Usage
/skill-name [arguments]

## Process
1. Step one
2. Step two

## Output
What the skill produces.
```

## Agent Format

```markdown
# Agent: Name

## Purpose
One sentence.

## Process
1. Step one
2. Step two

## Output
What the agent produces.

## Validation
How to verify success.
```

## Statusline Hook

The `scripts/statusline.sh` provides a terminal status line for Claude Code.

**Output format:** `[Model] Project/folder | Task | Context%`

**Example:** `[Claude Sonnet] my-project/src/api | Implementing auth | 42%`

### Features

- Auto-detects project from `.ai/` or `.git/` directory
- Extracts task from `.ai-local/STATE.md` or `agent-status.json`
- Shows context window usage percentage
- Compatible with both `.ai-local/` and `.project_local/`

### Global Installation

```bash
# Copy to shared location
cp .ai/scripts/statusline.sh ~/.local/bin/ai-statusline.sh
chmod +x ~/.local/bin/ai-statusline.sh
```

### Configuration

Add to `~/.claude/settings.json`:

```json
{
  "statusLine": {
    "type": "command",
    "command": "~/.local/bin/ai-statusline.sh"
  }
}
```

**Important:** `statusLine` is a top-level setting, NOT a hook. Claude Code sends JSON via stdin with session context (model, workspace, context_window, etc.) and uses the first line of stdout as the status line.

### JSON Input

Claude Code provides:
```json
{
  "session_id": "...",
  "model": {"display_name": "Opus 4.5"},
  "workspace": {"current_dir": "...", "project_dir": "..."},
  "context_window": {"used_percentage": 42, ...}
}
```
