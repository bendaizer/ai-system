# Testing AI Systems with Claude Code Agents

Strategy for testing AI commands and skills using independent subagents.

## Concept

```
┌─────────────────────────────────────────────────────┐
│  MAIN AGENT (Orchestrator)                          │
│                                                     │
│  1. Define test suite (inputs, expected outputs)    │
│  2. Spawn subagents for each test                   │
│  3. Collect reports                                 │
│  4. Analyze results                                 │
└──────────────┬──────────────────────────────────────┘
               │
       ┌───────┴───────┬───────────────┐
       ▼               ▼               ▼
┌─────────────┐ ┌─────────────┐ ┌─────────────┐
│  Subagent 1 │ │  Subagent 2 │ │  Subagent 3 │
│  (isolated) │ │  (isolated) │ │  (isolated) │
│             │ │             │ │             │
│  - Run test │ │  - Run test │ │  - Run test │
│  - Report   │ │  - Report   │ │  - Report   │
└─────────────┘ └─────────────┘ └─────────────┘
```

## Why Subagents?

| Benefit | Description |
|---------|-------------|
| **Isolation** | Each test runs in clean context, no bleed-through |
| **Parallelism** | Multiple tests can run simultaneously |
| **Independence** | Subagent failures don't crash main agent |
| **Clean reports** | Structured output for analysis |
| **Memory control** | Test with or without session memory |

## Test Definition Format

Main agent defines tests as structured prompts:

```markdown
## Test: [Test Name]

**Purpose:** What we're testing

**Setup:**
- Working directory: /path/to/project
- Prerequisites: [list any setup needed]
- Clean state: [yes/no - whether to reset before test]

**Steps:**
1. [Action to perform]
2. [Action to perform]

**Verification:**
- [ ] [Condition to check]
- [ ] [Condition to check]

**Expected Output:**
[What success looks like]

**Report Format:**
[How subagent should structure its response]
```

## Subagent Types for Testing

### 1. Bash Agent (Script Execution)
Best for: Testing shell scripts, file operations, git commands

```
Task(subagent_type="Bash", prompt="...")
```

### 2. General-Purpose Agent (Complex Scenarios)
Best for: Multi-step tests, tests requiring reasoning

```
Task(subagent_type="general-purpose", prompt="...")
```

### 3. Explore Agent (Verification)
Best for: Checking file contents, structure validation

```
Task(subagent_type="Explore", prompt="...")
```

## Example: Boot Script Test Suite

### Test Suite Definition (Main Agent)

```python
BOOT_SCRIPT_TESTS = [
    {
        "name": "Fresh Boot",
        "setup": "rm -rf .ai-local/",
        "command": ".ai/session/scripts/boot.sh",
        "verify": [
            "STATE.md exists",
            "HISTORY.md exists",
            "CONTEXT.md exists",
            "Output shows 'Created STATE.md from template'"
        ]
    },
    {
        "name": "Existing State Boot",
        "setup": None,  # Keep previous state
        "command": ".ai/session/scripts/boot.sh",
        "verify": [
            "STATE.md unchanged",
            "HISTORY.md unchanged",
            "CONTEXT.md regenerated",
            "Output does NOT show 'Created STATE.md'"
        ]
    },
    {
        "name": "Context Contains Sections",
        "setup": None,
        "command": "cat .ai-local/CONTEXT.md",
        "verify": [
            "Contains '## Current State'",
            "Contains '## History Summary'",
            "Contains '## Git Status'",
            "Contains '## Recent Commits'"
        ]
    }
]
```

### Subagent Prompt Template

```markdown
Test the boot script and report results.

**Working directory:** /path/to/examples/my-project

**Test: Fresh Boot**

Setup:
1. Remove .ai-local/ if exists: `rm -rf .ai-local/`

Execute:
1. Run `.ai/session/scripts/boot.sh`
2. Capture all output

Verify:
- [ ] .ai-local/STATE.md exists
- [ ] .ai-local/HISTORY.md exists
- [ ] .ai-local/CONTEXT.md exists
- [ ] Output contains "Created STATE.md from template"

**Report Format:**

| Check | Result | Details |
|-------|--------|---------|
| STATE.md exists | PASS/FAIL | file size or error |
| ... | ... | ... |

End with: **OVERALL: PASS/FAIL**
```

## Running Tests

### Sequential (One at a Time)

```
Main Agent:
  → Spawn Test 1 subagent
  ← Receive Report 1
  → Spawn Test 2 subagent
  ← Receive Report 2
  → Analyze all reports
```

### Parallel (Simultaneous)

```
Main Agent:
  → Spawn Test 1 subagent ─┐
  → Spawn Test 2 subagent ─┼─ (single message, multiple Task calls)
  → Spawn Test 3 subagent ─┘
  ← Receive all reports
  → Analyze results
```

### Background (Non-blocking)

```
Main Agent:
  → Spawn Test 1 (background=true)
  → Continue other work...
  → Check output file when ready
```

## Memory Modes

### Stateless Tests (Recommended)

Subagent has no memory of previous tests. Each test is isolated.

```markdown
Test the boot script. You have no prior context.
Working directory: /path/to/project
...
```

### Stateful Tests (Session Simulation)

Subagent simulates a user session with memory.

```markdown
You are simulating a developer session.

Session 1:
1. Run /boot
2. Make some changes
3. Run /save

Session 2 (new subagent, reads previous state):
1. Run /boot
2. Verify previous state is loaded
```

## Report Aggregation

Main agent collects and summarizes:

```markdown
## Test Suite Results: Boot Script

| Test | Result | Duration |
|------|--------|----------|
| Fresh Boot | PASS | - |
| Existing State Boot | PASS | - |
| Context Contains Sections | PASS | - |

**Overall: 3/3 PASS**

### Issues Found
None

### Recommendations
None
```

## Best Practices

1. **Clear prompts** - Subagents need unambiguous instructions
2. **Structured reports** - Use tables, checklists for easy parsing
3. **Isolated tests** - Each test should be independent
4. **Explicit verification** - Tell subagent exactly what to check
5. **Error handling** - Ask subagent to report errors, not hide them
6. **Working directory** - Always specify absolute paths

## Anti-patterns

| Don't | Do Instead |
|-------|------------|
| Assume subagent remembers context | Provide full context each time |
| Use vague success criteria | Use specific, checkable conditions |
| Run dependent tests in parallel | Run sequentially or use setup steps |
| Ignore subagent errors | Require explicit error reporting |
