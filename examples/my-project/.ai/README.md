# AI System - Source of Truth

This folder contains all AI assistant definitions. Tool-specific entry points redirect here.

## Structure

```
.ai/
├── session/           # Session management subsystem
│   ├── README.md      # Memory layer concepts
│   ├── scripts/       # Shell scripts
│   └── templates/     # File templates
├── skills/            # Skill definitions (commands)
└── agents/            # Agent definitions (tasks)
```

## Subsystems

| Subsystem | Purpose | Status |
|-----------|---------|--------|
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
