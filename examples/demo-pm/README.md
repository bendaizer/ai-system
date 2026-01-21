# Project Management Demo

A minimal demo of AI-assisted project management.

## Concept

Organize ideas into a hierarchy:

```
INBOX (raw ideas)
    ↓
Initiative (strategic direction)
    └── Project (deliverable scope)
            └── Epic (themed work)
                    └── Task (actionable item)
```

## Usage

1. **Boot session**: `.ai/session/scripts/boot.sh`
2. **Capture ideas**: Add to `INBOX.md`
3. **Organize**: AI helps move ideas to `PROJECTS.md`
4. **Save session**: `.ai/session/scripts/save.sh`

## Files

| File | Purpose |
|------|---------|
| `INBOX.md` | Raw idea capture |
| `PROJECTS.md` | Organized hierarchy |
| `.ai/` | Session management |
| `.ai-local/` | Local state (gitignored) |

## Try It

```bash
# Start a session
.ai/session/scripts/boot.sh

# Read the generated context
cat .ai-local/CONTEXT.md

# Add some ideas to INBOX.md, then save
.ai/session/scripts/save.sh
```
