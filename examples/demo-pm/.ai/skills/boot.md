# /boot - Start Session

Load context from memory layers and prepare for work.

## Usage

```
/boot
```

## Process

1. **Run boot script**
   ```bash
   .ai/session/scripts/boot.sh
   ```

2. **Read generated context**
   - Open `.ai-local/CONTEXT.md`
   - This contains STATE.md + HISTORY.md + git status

3. **Summarize for user**
   - Current objective (what we're working on)
   - Open loops (unfinished tasks)
   - Recent activity (last session summary)
   - Git status (uncommitted changes)

4. **Confirm ready**
   - State that context is loaded
   - Wait for user instruction

## Output

Brief summary of session context, then ready for work.

## Example

```
Session loaded.

Current: Implementing user authentication
Open loops:
- [ ] Add password reset flow
- [ ] Write tests for login

Last session: Added JWT token generation

Ready. What would you like to work on?
```

## Notes

- If STATE.md doesn't exist, script creates it from template
- If HISTORY.md doesn't exist, script creates empty one
- CONTEXT.md is regenerated every boot (don't edit manually)
