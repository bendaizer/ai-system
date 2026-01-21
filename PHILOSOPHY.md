# Philosophy: Radical Minimalism

This project is deliberately primitive. That's the point.

## Core Belief

**Files and folders are enough.**

Every AI tool can read files. Every AI tool can run shell scripts. Every AI tool understands markdown. These are the universals. Everything else is optional complexity.

## What We Use

| Layer | Implementation |
|-------|----------------|
| Configuration | Markdown files |
| State | Markdown files |
| Scripts | Bash (POSIX-compatible) |
| Communication | File system |
| Versioning | Git |

That's it. No frameworks. No dependencies. No build steps.

## What We Reject

### No Plugins

Plugins create lock-in. They require installation, maintenance, updates. They break. They differ between tools. A markdown file never breaks.

### No MCP Servers

MCP is powerful, but it's infrastructure. It needs to run somewhere. It needs configuration. It needs debugging when it fails. A shell script just runs.

### No Package Managers

No npm. No pip. No cargo. No gems. Zero dependencies means zero dependency hell. Copy the folder, it works.

### No Databases

SQLite is elegant. Redis is fast. We don't need them. Text files are debuggable with `cat`. They diff cleanly. They merge in git. They work offline.

### No APIs

No REST endpoints. No GraphQL. No webhooks. If two things need to communicate, one writes a file and the other reads it.

### No Custom Protocols

No binary formats. No proprietary encodings. Everything is UTF-8 text that a human can read and edit with any editor.

## Why This Matters

### Portability

```bash
cp -r .ai/ your-project/
```

Done. Works with Claude Code, Cursor, Codex, Copilot, or the next tool that doesn't exist yet.

### Debuggability

When something goes wrong:
```bash
cat .ai-local/STATE.md
```

No log aggregation. No tracing infrastructure. No "please share your session ID with support."

### Longevity

Markdown existed before ChatGPT. Bash existed before the web. They'll exist after the current AI hype cycle. Your session state will still be readable in 10 years.

### Understandability

A new developer can understand the entire system in 15 minutes by reading the files. No documentation required beyond the files themselves.

## The Test

Before adding anything, ask:

1. **Can I avoid this?** Most features are unnecessary.
2. **Can a file do this?** Usually yes.
3. **Will this work in 5 years?** Markdown will. Your plugin won't.
4. **Can I debug this with cat and grep?** If not, it's too complex.

## Complexity Budget

We have a fixed complexity budget of approximately zero.

Every added feature must remove more complexity than it adds. If the system grows, we've failed.

## Prior Art

This philosophy isn't new:

- Unix: "Write programs that do one thing and do it well"
- Markdown: Readable as plain text, structured when rendered
- Git: Distributed, works offline, stores everything as files
- Make: Been building software since 1976 with text files

We're not innovating. We're refusing to regress.

## The Goal

A developer should be able to:

1. Clone this repo
2. Copy `.ai/` to their project
3. Start working

No signup. No API keys. No installation. No configuration wizard. No "please upgrade to Pro for this feature."

Just files.

---

## Declarative Over Imperative

Beyond minimalism, this system embraces declarative control.

### Two Ways to Control Work

| Approach | Control Via | Example |
|----------|-------------|---------|
| **Imperative** | Procedures (steps) | "Run this command, then that command, then check this" |
| **Declarative** | Constraints (goals) | "The system should have these properties" |

We choose declarative.

### Why Declarative?

**Imperative instructions are fragile:**
```
1. Open the config file
2. Find the line with "timeout"
3. Change the value to 30
4. Save and close
```

If the file format changes, the instructions break.

**Declarative specifications are robust:**
```
timeout: 30
```

The "how" can change. The "what" remains stable.

### Applied to AI Assistance

When working with AI, you have a choice:

**Imperative prompting:**
> "First read the file, then find all functions, then check each one for..."

**Declarative prompting:**
> "Ensure all functions have error handling. Report violations."

The declarative version:
- Survives model changes
- Works across different AI tools
- Focuses on outcomes, not paths
- Is easier to verify

### The Three Layers

Any robust system has three layers:

```
┌─────────────────────────────────────┐
│  SPECIFICATION (What/Why)           │
│  Goals, constraints, acceptance     │
│  criteria, definitions of done      │
├─────────────────────────────────────┤
│  EXECUTION (How)                    │
│  AI, scripts, humans, compilers     │
│  — high variance, replaceable —     │
├─────────────────────────────────────┤
│  EVIDENCE (Proof)                   │
│  Tests, verification, state files   │
│  diffs, reproducible outcomes       │
└─────────────────────────────────────┘
```

**Key insight:** When execution has high freedom (AI can do anything), you need strong specification and strong evidence.

### This System's Layers

| Layer | Implementation |
|-------|----------------|
| Specification | Skill definitions in `.ai/skills/` |
| Execution | AI reads specs, runs scripts, does work |
| Evidence | State files, git commits, test reports |

The AI is the high-variance middle layer. The markdown files above and below it are the control.

### Vibe Coding vs Engineering

**Vibe coding:**
- Iterate until it "looks right"
- Weak acceptance criteria
- Hope it works

**Engineering:**
- Explicit contracts (what must be true)
- Verification (prove it's true)
- Reproducibility (prove it again tomorrow)

This system enables engineering by making specification and evidence first-class citizens—as files you can read, diff, and version.

### The Rule

> If you cannot point to a file that defines success, you're vibing.

Every skill has a definition. Every session has state. Every change has a commit. That's the contract.
