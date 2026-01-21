# /save - Save Session

Persist current session state to memory layers.

## Usage

```
/save
```

## Process

1. **Run save script**
   ```bash
   .ai/session/scripts/save.sh
   ```
   This shows current state and git status for reference.

2. **Update STATE.md**
   Edit `.ai-local/STATE.md` with:
   - Current objective
   - Recent work (this session's accomplishments)
   - Open loops (unfinished tasks)
   - Key decisions made
   - Files modified

3. **Update HISTORY.md**
   Add entry to `.ai-local/HISTORY.md`:
   ```markdown
   ### YYYY-MM-DD HH:MM
   - Session summary
   - Key accomplishments
   ```

4. **Consider git commit**
   If a meaningful milestone was reached:
   - Stage relevant files
   - Write clear commit message
   - Ask user before committing

## Output

Confirmation of updates made, plus commit proposal if applicable.

## Example

```
Session saved.

Updated STATE.md:
- Objective: User authentication
- Completed: JWT token generation
- Open: Password reset, tests

Added to HISTORY.md:
- 2024-01-15: Implemented JWT auth

Propose commit?
- Files: src/auth.ts, src/middleware.ts
- Message: "Add JWT authentication"
```

## Rotation

When STATE.md gets too long (>50 lines of recent work):
1. Move older entries to HISTORY.md
2. Keep only ~3 sessions in STATE.md
3. Compress moved entries to 1-2 lines each
