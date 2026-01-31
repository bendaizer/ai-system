# Retrieval Strategies

How AI agents navigate code and docs without wasting context.

## The Problem

AI agents have large but finite context windows (~200K tokens). A medium project has 500+ files. Reading everything is impossible. Reading randomly is wasteful. Complex RAG infrastructure violates the minimalism principle.

The solution: **navigable file topology** -- well-placed files that link to neighbors, parents, and children, letting agents walk the graph instead of searching blindly.

## Core Principle: Navigation, Not Search

Traditional approach:
```
Agent needs info -> full-text search -> read 20 candidates -> find 3 relevant -> 50K tokens spent
```

Navigation approach:
```
Agent needs info -> read nearest index -> follow 2 links -> arrive at target -> 3K tokens spent
```

The difference: **search is O(n) on project size. Navigation is O(depth) on link hops.**

RAG systems solve this with embeddings, vector databases, and retrieval pipelines. We solve it with files that point to other files. Every AI tool can follow a markdown link. No infrastructure required.

## File-Based Navigation Network

### The Idea

Every directory in a project should have a file that:
1. Says what this directory contains (purpose)
2. Links to its children (what's inside)
3. Links to its parent (where it fits)
4. Links to related directories (cross-references)

This creates a **navigable graph** using only markdown files and relative links. An agent arriving at any node can orient itself and move toward its target without searching.

### Navigation File Types

| File | Scope | Content | Analogy |
|------|-------|---------|---------|
| `AGENTS.md` (root) | Project | Purpose, structure overview, entry points | Front door |
| `README.md` (per directory) | Directory | What's here, links to children and siblings | Room sign |
| `STATE.md` (.ai-local) | Session | Current focus, recent files, open loops | Breadcrumb trail |
| `INDEX.md` (optional) | Domain | Cross-cutting index of a specific concern | Table of contents |

### The Navigation Graph

```
project/
├── AGENTS.md ────────────────────────── Project entry point
│   Links to: src/, docs/, .ai/          (children)
│
├── src/
│   ├── README.md ────────────────────── Source entry point
│   │   Links to: auth/, api/, models/   (children)
│   │   Links to: ../docs/architecture.md (cross-ref)
│   │   Links to: ../AGENTS.md           (parent)
│   │
│   ├── auth/
│   │   ├── README.md ────────────────── Auth module entry
│   │   │   Links to: login.ts, session.ts (children)
│   │   │   Links to: ../api/middleware.ts  (neighbor)
│   │   │   Links to: ../README.md         (parent)
│   │   ├── login.ts
│   │   └── session.ts
│   │
│   └── api/
│       ├── README.md
│       │   Links to: routes.ts, middleware.ts
│       │   Links to: ../auth/README.md    (neighbor)
│       └── ...
│
├── docs/
│   ├── README.md ────────────────────── Docs entry point
│   │   Links to: architecture.md, decisions/
│   │   Links to: ../src/README.md        (cross-ref)
│   └── architecture.md
│       Links to: ../src/auth/README.md   (implementation)
│
└── .ai-local/
    └── STATE.md ─────────────────────── Session breadcrumbs
        Recent files: src/auth/login.ts, docs/architecture.md
```

### Link Types

Three types of links create the navigation topology:

| Link Type | Direction | Purpose | Example |
|-----------|-----------|---------|---------|
| **Hierarchical (parent)** | Up | "Where does this fit?" | `See [project overview](../AGENTS.md)` |
| **Hierarchical (children)** | Down | "What's inside?" | `Contains: [auth](auth/), [api](api/)` |
| **Lateral (neighbor)** | Sideways | "What's related?" | `Auth middleware: [middleware.ts](../api/middleware.ts)` |
| **Transversal (cross-ref)** | Across trees | "What depends on this?" | `Architecture doc: [architecture](../../docs/architecture.md)` |

An agent following these links performs a **graph walk**, not a search. Each hop costs ~500 tokens (reading a README). Three hops = 1,500 tokens to reach any file in a well-linked project.

### Minimal README.md Template

Every directory with 3+ files should have a README.md. Keep it under 30 lines:

```markdown
# {Directory Name}

{One sentence: what this directory contains and why.}

## Contents

- [{file-or-dir}]({path}) -- {one-line description}
- [{file-or-dir}]({path}) -- {one-line description}
- [{file-or-dir}]({path}) -- {one-line description}

## Related

- [{related-thing}]({path}) -- {why it's related}
- [{parent}]({parent-path}) -- parent context
```

No boilerplate. No badges. No installation instructions in subdirectory READMEs. Just navigation.

## Retrieval Decision Tree

When an agent needs information:

```
START
│
├─ Do I know the file path?
│  └─ YES -> Read it directly (cost: file size in tokens)
│
├─ Do I know the directory?
│  └─ YES -> Read its README.md -> follow links (cost: ~500 tokens + target)
│
├─ Do I know the domain/concept?
│  └─ YES -> Read AGENTS.md -> find relevant section -> follow link (cost: ~1K + target)
│
├─ Is it a cross-cutting concern?
│  └─ YES -> Check INDEX.md files if they exist -> follow links
│
├─ Am I completely lost?
│  └─ YES -> Glob for file patterns -> read first match's README -> navigate from there
│
└─ Will this investigation touch 5+ files?
   └─ YES -> Delegate to a subagent (cost: isolated, returns summary only)
```

## Token Budgets

### Per Memory Layer

| Layer | Budget | Rationale |
|-------|--------|-----------|
| L0 (chat) | ~140K tokens | Reserve 60K for reasoning + output |
| L1 (STATE.md) | <2K tokens | ~50 lines of structured state |
| L2 (HISTORY.md loaded) | <1K tokens | Last 50 lines, compressed |
| CONTEXT.md total | <5K tokens | STATE + HISTORY tail + git status + git log |
| Navigation overhead | <2K tokens per hop | README.md files should be <30 lines each |

### Per Operation

| Operation | Typical Cost | Max Budget |
|-----------|-------------|------------|
| Read a README.md | 200-500 tokens | 1K |
| Glob query | 50-200 tokens | 500 |
| Grep query | 100-500 tokens | 2K |
| Read a source file | 500-5K tokens | 10K |
| Full investigation (inline) | 5-15K tokens | 25K |
| Subagent investigation | 0 main context (1-2K summary returned) | 3K summary |

### Warning Thresholds

| Context % Used | Action |
|:-:|---|
| <50% | Normal operation |
| 50-70% | Be selective -- stop pre-loading, use targeted reads |
| 70-85% | Compact -- summarize conversation, persist findings to STATE.md |
| >85% | Emergency -- write findings to file, consider fresh session |

## Tool Selection

| Need | Tool | Why | Not This |
|------|------|-----|----------|
| Find files by name pattern | **Glob** | Returns paths only, minimal tokens | Not `find` in bash |
| Find code by content | **Grep** | Returns matching lines, not whole files | Not reading every file |
| Read a known file | **Read** with line limits | Direct, controlled size | Not `cat` in bash |
| Understand directory | **Read** its README.md | Navigation link, not raw listing | Not `ls -R` in bash |
| Investigation spanning 5+ files | **Subagent** | Isolated context, condensed return | Not inline exploration |

## Navigation Maintenance: Save-Time Triggers

The navigation network must stay current. Stale links are worse than no links. The `/save` process should include navigation maintenance triggers.

### What to Check on Save

| Trigger | Condition | Action |
|---------|-----------|--------|
| **New directory created** | Directory exists without README.md | Prompt: "Create README.md for {dir}" |
| **File count changed** | Files added/removed in a directory | Prompt: "Update README.md in {dir}" |
| **Cross-reference broken** | Link target no longer exists | Prompt: "Fix broken link in {file}" |
| **STATE.md mentions new files** | Recent files list has paths not in any README | Prompt: "Add {file} to its directory README" |

### Implementation

The save script checks for navigation staleness:

```bash
# In .ai/session/scripts/save.sh (or a post-save hook)

# 1. Find directories with 3+ files but no README.md
find "$PROJECT_ROOT" -mindepth 1 -type d \
  -not -path '*/.ai*' -not -path '*/.git*' -not -path '*/node_modules*' | while read dir; do
  file_count=$(find "$dir" -maxdepth 1 -type f | wc -l)
  if [ "$file_count" -ge 3 ] && [ ! -f "$dir/README.md" ]; then
    echo "NAVIGATION: $dir has $file_count files but no README.md"
  fi
done

# 2. Find broken markdown links in README.md files
grep -rn '\[.*\](.*\.md)' "$PROJECT_ROOT" --include="README.md" | while read match; do
  file=$(echo "$match" | cut -d: -f1)
  link=$(echo "$match" | grep -oP '\]\(\K[^)]+')
  dir=$(dirname "$file")
  target="$dir/$link"
  if [ ! -f "$target" ]; then
    echo "NAVIGATION: Broken link in $file -> $link"
  fi
done

# 3. Check if recently modified files are referenced in their directory README
git diff --name-only HEAD~1 2>/dev/null | while read changed; do
  dir=$(dirname "$changed")
  readme="$dir/README.md"
  base=$(basename "$changed")
  if [ -f "$readme" ] && ! grep -q "$base" "$readme"; then
    echo "NAVIGATION: $changed not referenced in $readme"
  fi
done
```

Output is informational -- the AI decides what to act on. The script does not auto-modify files.

### Navigation Health Report

On boot, optionally generate a navigation health summary in CONTEXT.md:

```markdown
## Navigation Health
- Directories without README: 3 (src/utils/, src/helpers/, tests/fixtures/)
- Broken links: 1 (docs/README.md -> architecture-old.md)
- Unreferenced recent files: 2 (src/auth/oauth.ts, src/api/v2.ts)
```

This costs ~200 tokens in CONTEXT.md and saves thousands by preventing blind exploration later.

## Index Files for Cross-Cutting Concerns

Some information spans multiple directories. A README.md per directory doesn't help when you need "all files related to authentication" spread across src/auth/, src/api/, src/middleware/, and tests/.

### INDEX.md Pattern

Create `INDEX.md` files for cross-cutting concerns:

```markdown
# Authentication Index

Files related to authentication across the codebase.

## Core
- [src/auth/login.ts](src/auth/login.ts) -- Login flow
- [src/auth/session.ts](src/auth/session.ts) -- Session management
- [src/auth/tokens.ts](src/auth/tokens.ts) -- JWT token handling

## Integration Points
- [src/api/middleware.ts](src/api/middleware.ts) -- Auth middleware (lines 45-89)
- [src/api/routes.ts](src/api/routes.ts) -- Protected routes (lines 12-34)

## Configuration
- [config/auth.json](config/auth.json) -- Auth settings
- [.env.example](.env.example) -- Required env vars (AUTH_SECRET, JWT_TTL)

## Tests
- [tests/auth/](tests/auth/) -- Auth test suite
- [tests/api/auth-middleware.test.ts](tests/api/auth-middleware.test.ts) -- Middleware tests
```

### When to Create an INDEX.md

- Concern spans 3+ directories
- Agents repeatedly search for the same cross-cutting topic
- Onboarding a new contributor requires understanding a scattered feature

### Where to Place INDEX.md

| Placement | When |
|-----------|------|
| Project root | Global concerns (auth, logging, error handling) |
| `docs/` directory | Architectural concerns |
| `.ai/` directory | AI-specific navigation aids |

Index files are maintained like READMEs -- checked on save, updated when structure changes.

## Subagent Context Contracts

When delegating to a subagent, specify what context it receives:

### Minimal Contract (exploration)

```
Subagent receives:
- Task description (what to find/investigate)
- Project root path
- AGENTS.md content (project overview)

Subagent returns:
- Findings summary (<2K tokens)
- File paths discovered
- Recommended next reads
```

### Informed Contract (targeted work)

```
Subagent receives:
- Task description
- Specific file paths to examine
- Relevant STATE.md section

Subagent returns:
- Analysis results
- Changes made (if any)
- Updated file list for STATE.md
```

### Rule: Never Pass Full STATE.md to Exploration Subagents

STATE.md contains session-specific context (decisions, open loops) that biases exploration. Give subagents clean scope. Let them discover independently.

## Anti-Patterns

| Anti-Pattern | Why It Fails | Alternative |
|--------------|-------------|-------------|
| **Read every file in src/** | O(n) token cost, most irrelevant | Navigate via README links |
| **Grep for vague terms** | Returns noise (50+ matches for "error") | Narrow with directory scope + specific pattern |
| **Pre-load entire codebase in CONTEXT.md** | Fills context before work begins | Load AGENTS.md + STATE.md, fetch on demand |
| **No READMEs, rely on search** | Every investigation starts from scratch | 10 minutes to write READMEs saves hours of search |
| **Giant monolithic README** | 500-line README defeats navigation purpose | <30 lines per README, use INDEX.md for cross-cutting |
| **Stale navigation files** | Broken links worse than no links | Save-time triggers keep links current |
| **Pass everything to subagent** | Subagent context wasted on irrelevant info | Minimal contract: task + entry point only |
| **Vector database for code** | Infrastructure overhead, breaks minimalism | File-based navigation graph, zero dependencies |

## Comparison: RAG vs. Navigation

| Aspect | RAG System | File-Based Navigation |
|--------|-----------|----------------------|
| Infrastructure | Embedding model + vector DB + retrieval pipeline | None (markdown files) |
| Maintenance | Re-index on every change | Update README on save |
| Debugging | Inspect embeddings, similarity scores | `cat README.md` |
| Accuracy | Depends on embedding quality | Depends on link quality |
| Token cost per query | Low (retrieval is pre-computed) | Low (1-3 file reads) |
| Setup cost | Hours to days | Minutes (write READMEs) |
| Works offline | Usually not | Always |
| Works across AI tools | Tool-specific integration | Universal (markdown) |
| Scales to 100K files | Yes (designed for it) | Partially (needs hierarchy) |
| Survives in 5 years | Maybe (tools change) | Yes (markdown is forever) |

**When RAG wins**: Codebases with 100K+ files, natural language queries, semantic similarity needs.

**When navigation wins**: Most projects (<10K files), structured codebases, multi-tool environments, zero-infra constraint.

The ai-system targets the second category. If you need RAG, add it as an external tool -- don't build it into the framework.

## Summary

1. **Navigate, don't search.** Follow links between files instead of grep-ing blindly.
2. **Every directory gets a README.** 30 lines max. Links to children, parent, neighbors.
3. **INDEX.md for cross-cutting concerns.** Authentication, logging, error handling -- things that span directories.
4. **Save-time triggers maintain the graph.** Check for missing READMEs, broken links, unreferenced files.
5. **Token budgets are real.** STATE.md < 2K, CONTEXT.md < 5K, navigation hop < 1K.
6. **Subagents for deep investigation.** Isolate expensive exploration from main context.
7. **No RAG infrastructure.** Files that link to files. That's the retrieval system.
