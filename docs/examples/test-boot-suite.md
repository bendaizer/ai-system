# Test Suite: Boot Script

Copy-paste prompts for testing the boot script with subagents.

## Test 1: Fresh Boot

**Subagent type:** Bash

**Prompt:**
```
Test the boot script from a clean state.

Working directory: /home/a-d-mine/WIP_WSL/_dillygence/ai-system/examples/my-project

Setup:
1. Remove existing .ai-local/ directory: rm -rf .ai-local/

Execute:
1. Run: .ai/session/scripts/boot.sh
2. Capture output

Verify (check each):
- [ ] Script exits with code 0
- [ ] .ai-local/STATE.md exists
- [ ] .ai-local/HISTORY.md exists
- [ ] .ai-local/CONTEXT.md exists
- [ ] Output contains "Created STATE.md from template"
- [ ] Output contains "Created HISTORY.md from template"
- [ ] Output contains "Generated"

Report as table:
| Check | Result | Evidence |
|-------|--------|----------|

End with: **OVERALL: PASS/FAIL**
```

---

## Test 2: Idempotent Boot

**Subagent type:** Bash

**Prompt:**
```
Test that boot script preserves existing state files.

Working directory: /home/a-d-mine/WIP_WSL/_dillygence/ai-system/examples/my-project

Precondition: .ai-local/ already exists with STATE.md and HISTORY.md

Execute:
1. Record timestamps: ls -la .ai-local/
2. Run: .ai/session/scripts/boot.sh
3. Record new timestamps: ls -la .ai-local/

Verify:
- [ ] STATE.md timestamp unchanged
- [ ] HISTORY.md timestamp unchanged
- [ ] CONTEXT.md timestamp is new (regenerated)
- [ ] Output does NOT contain "Created STATE.md"

Report as table with before/after timestamps.
End with: **OVERALL: PASS/FAIL**
```

---

## Test 3: Context Structure

**Subagent type:** Bash

**Prompt:**
```
Verify CONTEXT.md contains all required sections.

Working directory: /home/a-d-mine/WIP_WSL/_dillygence/ai-system/examples/my-project

Execute:
1. Run: cat .ai-local/CONTEXT.md

Verify these sections exist (grep for each):
- [ ] "# Session Context"
- [ ] "## Current State"
- [ ] "## History Summary"
- [ ] "## Git Status"
- [ ] "## Recent Commits"

Also verify:
- [ ] Contains a timestamp (Generated: YYYY-MM-DD)
- [ ] Git commits section shows commit hashes

Report each check with PASS/FAIL and the matching line.
End with: **OVERALL: PASS/FAIL**
```

---

## Test 4: Template Content

**Subagent type:** Bash

**Prompt:**
```
Verify STATE.md matches the template structure.

Working directory: /home/a-d-mine/WIP_WSL/_dillygence/ai-system/examples/my-project

Execute:
1. Run: cat .ai-local/STATE.md

Verify these sections exist:
- [ ] "# Session State"
- [ ] "## Current Objective"
- [ ] "## Recent Work"
- [ ] "## Open Loops"
- [ ] "## Key Decisions"
- [ ] "## Files Modified"

Report each check.
End with: **OVERALL: PASS/FAIL**
```

---

## Test 5: Error Handling - Missing .ai/

**Subagent type:** Bash

**Prompt:**
```
Test boot script behavior when .ai/ folder is missing.

Working directory: /tmp/test-boot-error

Setup:
1. Create empty directory: mkdir -p /tmp/test-boot-error
2. cd to it

Execute:
1. Try to run: /home/a-d-mine/WIP_WSL/_dillygence/ai-system/examples/my-project/.ai/session/scripts/boot.sh

Expected: Script should handle missing templates gracefully (create defaults or error clearly)

Report:
- Exit code
- Any error messages
- Whether .ai-local/ was created
- Whether STATE.md has default content

End with: **OVERALL: PASS/FAIL** (PASS if graceful handling, FAIL if crash)
```

---

## Running the Full Suite

Main agent prompt:
```
Run all 5 boot script tests using Bash subagents.
Collect results and provide summary.

Tests are defined in: docs/examples/test-boot-suite.md

For each test:
1. Spawn a Bash subagent with the test prompt
2. Collect the PASS/FAIL result

Final report format:
| Test | Result |
|------|--------|
| 1. Fresh Boot | PASS/FAIL |
| 2. Idempotent Boot | PASS/FAIL |
| 3. Context Structure | PASS/FAIL |
| 4. Template Content | PASS/FAIL |
| 5. Error Handling | PASS/FAIL |

**Suite Result: X/5 PASS**
```
