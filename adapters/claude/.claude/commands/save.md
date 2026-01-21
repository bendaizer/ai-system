# Save Session

Persist session state to memory layers.

## Process

1. Run the save script:
```bash
.ai/session/scripts/save.sh
```

2. Update `.ai-local/STATE.md` with:
- Current objective
- Recent work (this session)
- Open loops
- Key decisions
- Files modified

3. Add entry to `.ai-local/HISTORY.md`:
```markdown
### YYYY-MM-DD HH:MM
- Session summary
- Key accomplishments
```

4. If milestone reached, propose git commit:
- Stage relevant files
- Write commit message
- Ask before committing
