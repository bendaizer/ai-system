# Agents

Task-specific AI prompts for complex operations.

## Concept

Agents are pre-defined prompts for common tasks that benefit from structured guidance. Unlike skills (user commands), agents are invoked programmatically or by the AI itself.

## Format

```markdown
# Agent: Name

## Purpose
One sentence describing when to use this agent.

## Trigger
When/how this agent is invoked.

## Process
1. Step one
2. Step two

## Output
What the agent produces.

## Validation
How to verify success.
```

## Built-in Agents

_None yet - add project-specific agents as needed._

## Example Agents

### Code Review Agent

```markdown
# Agent: Code Review

## Purpose
Review code changes for quality and issues.

## Trigger
Before committing significant changes.

## Process
1. Read the diff
2. Check for:
   - Security issues
   - Performance problems
   - Code style violations
   - Missing error handling
3. Summarize findings

## Output
List of issues found, or "No issues found".

## Validation
All issues addressed or acknowledged.
```

### Refactor Agent

```markdown
# Agent: Refactor

## Purpose
Safely refactor code while preserving behavior.

## Trigger
When code needs restructuring.

## Process
1. Understand current behavior
2. Identify test coverage
3. Plan refactoring steps
4. Execute incrementally
5. Verify tests still pass

## Output
Refactored code with passing tests.

## Validation
All tests pass, behavior unchanged.
```

## Adding Agents

1. Create `.ai/agents/your-agent.md`
2. Follow the format above
3. Document in this README
