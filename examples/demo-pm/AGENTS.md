# AI Assistants

Universal entry point for AI coding assistants.

## Session Management

| Command | Action |
|---------|--------|
| `/boot` | Load context, start session |
| `/save` | Save state, end session |

### /boot

1. Run `.ai/session/scripts/boot.sh`
2. Read `.ai-local/CONTEXT.md`
3. Summarize current state
4. Wait for instruction

### /save

1. Run `.ai/session/scripts/save.sh`
2. Update `.ai-local/STATE.md`
3. Add entry to `.ai-local/HISTORY.md`
4. Propose commit if milestone reached

## Project Management

This demo helps organize ideas into a hierarchy.

### Capture Ideas

Add raw ideas to `INBOX.md`:
```markdown
- 2024-01-15: Need to add user authentication
- 2024-01-15: Consider dark mode support
```

### Organize Ideas

Move refined ideas to `PROJECTS.md` with structure:
```markdown
## Initiative: Product Launch
### Project: MVP Features
#### Epic: User Auth
- [ ] TASK-001: Implement login page
- [ ] TASK-002: Add password reset
```

### AI Can Help

Ask the AI to:
- "Review INBOX and suggest organization"
- "Move this idea to the right project"
- "Break down this epic into tasks"
- "Clean up completed tasks"
