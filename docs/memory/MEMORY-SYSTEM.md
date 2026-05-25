# Memory System

How AI sessions persist knowledge across context window boundaries.

## Why Memory Matters

AI agents have no memory between sessions. When a session ends, everything in the context window disappears. Without an external memory system, every session starts from zero -- the agent re-reads files, re-discovers architecture, re-learns decisions made yesterday.

The memory system solves this with files. Four layers, from volatile to permanent. Each layer has a different retention, compression level, and token budget.

## The Four Layers

```
+-------------------------------------------+
| L0: CHAT CONTEXT                          |  Current session only
| Full detail, full reasoning               |  ~200K tokens
| Dies when session ends                    |  Retention: 0
+-------------------------------------------+
| L1: STATE.md                              |  ~3 sessions
| Current objective, recent work,           |  <2K tokens
| open loops, key decisions, files          |  .ai-local/STATE.md
+-------------------------------------------+
| L2: HISTORY.md                            |  All sessions
| Compressed summaries, patterns,           |  Grows ~200 tokens/session
| major decisions, milestones               |  .ai-local/HISTORY.md
+-------------------------------------------+
| L3: GIT                                   |  Forever
| Code changes, commit messages             |  Standard git
| The "why" lives in commit messages        |  Unlimited
+-------------------------------------------+
```

### Why Four Layers

One layer is too rigid. Human memory works in tiers: sensory memory (milliseconds), working memory (seconds), short-term memory (hours), long-term memory (years). AI memory mirrors this:

| Human Analogy | AI Layer | What It Holds | Why Separate |
|---------------|----------|---------------|--------------|
| Working memory | L0 (chat) | Current reasoning chain | Too large and volatile to persist |
| Short-term memory | L1 (STATE.md) | What I'm doing right now | Needs detail but not forever |
| Long-term memory | L2 (HISTORY.md) | What I've done and learned | Needs persistence but not detail |
| Permanent record | L3 (git) | What actually changed | Code is the ultimate truth |

Fewer layers would force a choice: either keep too much detail (bloated state) or lose too much (amnesia). Four layers let each concern live at the right granularity.

## L0: Chat Context

The context window. Everything the AI can "see" right now.

**Size**: ~200K tokens (model-dependent)
**Retention**: Current session only
**Content**: Conversation, file reads, tool outputs, reasoning

**Not managed by the ai-system.** This is the AI tool's responsibility. The ai-system only controls what gets loaded into L0 at boot time (via CONTEXT.md) and what gets extracted from L0 at save time (into STATE.md).

### Budget Allocation

| Purpose | Budget | Notes |
|---------|--------|-------|
| CONTEXT.md (boot payload) | <5K tokens | STATE + HISTORY tail + git status |
| Working files (code reads) | ~60K tokens | Files read during the session |
| Conversation history | ~60K tokens | User messages + AI responses |
| Reasoning headroom | ~60K tokens | AI needs space to think |
| Safety margin | ~20K tokens | Never fill to 100% |

**Key rule**: Keep boot payload under 5K tokens. Every token spent on boot is a token unavailable for work.

## L1: STATE.md

The short-term memory. What the agent needs to resume work.

**Location**: `.ai-local/STATE.md`
**Retention**: ~3 sessions (overwritten on each save)
**Budget**: <2K tokens (~50-80 lines)
**Updated**: On every `/save`

### Structure

```markdown
# State

## Current Objective
{What we're working on and why -- 1-2 sentences}

## Recent Work
- {What was accomplished in this session}
- {And the previous session if still relevant}
- {3-5 bullet points max}

## Open Loops
- {Things started but not finished}
- {Questions waiting for answers}
- {Decisions pending}

## Key Decisions
| Decision | Choice | Rationale | Date |
|----------|--------|-----------|------|
| {What was decided} | {The choice} | {Why} | {When} |

## Files Modified
- `{path}` -- {what changed}
- `{path}` -- {what changed}

## Notes
{Anything else the next session needs to know}
```

### Why ~3 Sessions

After 3 sessions, work either:
- **Completed** -- decisions are in git (L3), details don't matter
- **Ongoing** -- only the current state matters, not how we got there
- **Abandoned** -- should be forgotten, not carried forward

Three sessions is enough to recover from an interruption without accumulating stale context. This is a heuristic, not a hard rule -- adjust if your work cycles are longer.

### Token Budget Rationale

STATE.md at 2K tokens occupies ~1% of a 200K context window. This leaves 99% for actual work. At 5K tokens, it would start competing with file reads. At 10K, it would meaningfully reduce reasoning headroom.

The 2K budget forces compression: you can't dump a session transcript into STATE.md. You must extract what matters. This compression is a feature -- it forces the agent to distinguish signal from noise.

## L2: HISTORY.md

The long-term memory. Compressed summaries of all sessions.

**Location**: `.ai-local/HISTORY.md`
**Retention**: All sessions (append-only)
**Growth rate**: ~200 tokens per session (~3-5 lines)
**Loaded at boot**: Last 50 lines only (~1K tokens)
**Updated**: On rotation from L1

### Structure

```markdown
# History

### 2026-01-30 14:30
- Implemented auth middleware for API routes
- Decision: JWT over session cookies (stateless, scales better)
- Blocker resolved: CORS config was missing allowed origins

### 2026-01-29 10:00
- Set up project structure, initial AGENTS.md
- Decision: TypeScript over JavaScript (type safety for API layer)
- Open: need to decide on database (Postgres vs SQLite)

### 2026-01-28 16:00
- Research phase: evaluated 3 auth libraries
- Chose jose for JWT (zero dependencies, maintained)
```

### Compression Protocol

When STATE.md is rotated to HISTORY.md:

1. **Extract decisions** -- every decision with its rationale (the most valuable signal)
2. **Extract outcomes** -- what was accomplished (not how)
3. **Extract blockers** -- resolved and unresolved (patterns emerge over time)
4. **Drop process details** -- which files were read, which commands ran, what was tried and failed
5. **Drop conversation** -- back-and-forth reasoning is L0 content, not L2

**Compression ratio**: A 2K token STATE.md session should compress to 200 tokens in HISTORY.md (10:1 ratio).

**Format**: Each entry gets a timestamp header and 2-5 bullet points. No prose paragraphs. No code blocks. Just decisions, outcomes, and blockers.

### Why 50 Lines at Boot

HISTORY.md grows indefinitely. Loading all of it would eventually overflow the boot payload budget.

50 lines at ~20 tokens/line = ~1K tokens. This covers approximately 10-15 sessions of history -- enough to see patterns and recall recent decisions, without competing with STATE.md for boot payload space.

For older history, the agent can read the full file on demand (it's still there). The 50-line tail is the default, not a wall.

## L3: Git

The permanent record. Code changes and their rationale.

**Location**: Standard git repository
**Retention**: Forever
**Content**: Commits with meaningful messages
**Loaded at boot**: Last 10 commits in CONTEXT.md

### What L3 Captures That Others Don't

- **Actual code changes** -- not descriptions of changes, but the changes themselves
- **The "why"** -- commit messages explain rationale, not just "what"
- **Sequence** -- git log shows the order of decisions
- **Reversibility** -- any change can be undone

### Commit Message as Memory

A good commit message is a memory entry:

```
Bad:  "fix bug"
Good: "Fix auth timeout: session TTL was 1h, users reported logouts during lunch. Changed to 4h."
```

The good message answers: what changed, why, and what triggered the change. A future agent reading `git log` gets the decision record for free.

## Extended Memory: Practical Additions

Production systems have evolved beyond the core four layers. These additions are optional but proven across hundreds of sessions.

### SEED.md — Static Project Identity (L0.5)

A dedicated file for project context that never changes during sessions: project name, streams, architecture, key paths. Loaded at boot before STATE.md.

**Why separate from STATE.md**: Static context gets rewritten identically every save. During aggressive rotation, it can be accidentally compressed away. SEED.md prevents this by isolating immutable project identity.

See `SEED-PATTERN.md` (companion doc, to be added in a later wave) for the full pattern and template.

### TODO.md — Local Task Backlog (L1.5)

A lightweight task file (Now / Next / Blocked) separate from STATE.md. Human-curated, AI-proposes-only. Only top items loaded at boot (~200 tokens).

**Why separate from STATE.md**: Tasks have a different lifecycle (persist until done) than session state (overwritten each save). Mixing them bloats STATE.md and blurs the boundary between "what am I doing now" and "what needs to happen eventually."

See `TODO-INTEGRATION.md` (companion doc, to be added in a later wave) for the full pattern.

### Handoff Files — Topic-Specific Continuity

For complex workspaces with multiple concurrent workstreams, individual handoff files (one per topic) provide richer context than STATE.md alone. A lightweight router at the workspace root points to detailed handoff files.

See `../handoffs/HANDOFF-SYSTEM.md` (to be added in Wave 2) for the router pattern and lifecycle.

### Extended Boot Sequence

With all additions, the boot sequence becomes:

```
/boot
  1. Read SEED.md          ← L0.5: Who is this project?
  2. Read STATE.md         ← L1: What are we doing now?
  3. Read TODO.md (top 5)  ← L1.5: What's on the backlog?
  4. Read HISTORY.md (50L) ← L2: What have we done?
  5. Read git status/log   ← L3: What changed on disk?
  6. Scan handoff router   ← Active workstreams?
  → Generate CONTEXT.md   ← Combined payload (<5K tokens)
```

### HISTORY-ARCHIVE.md — Rotated History

When HISTORY.md exceeds ~300 lines, older entries rotate to HISTORY-ARCHIVE.md (never loaded at boot, available on demand).

See [HISTORY-ROTATION.md](HISTORY-ROTATION.md) for the rotation protocol.

---

## The Boot/Save Cycle

### Boot: Load Memory into L0

```
/boot
  |
  +-- Run .ai/session/scripts/boot.sh
  |   +-- Read .ai-local/STATE.md          -> L1 (full)
  |   +-- Read .ai-local/HISTORY.md        -> L2 (last 50 lines)
  |   +-- Run git status                   -> L3 (current state)
  |   +-- Run git log --oneline -10        -> L3 (recent commits)
  |   +-- Write .ai-local/CONTEXT.md       -> Combined boot payload
  |
  +-- AI reads CONTEXT.md
  |
  +-- AI confirms: "I see [objective], [recent work], [open loops]. Ready."
```

### Save: Extract Memory from L0

```
/save
  |
  +-- Run .ai/session/scripts/save.sh
  |   +-- Show current STATE.md            (for reference)
  |   +-- Show git status + diff --stat    (what changed)
  |   +-- Prompt AI to update state
  |
  +-- AI updates .ai-local/STATE.md
  |   +-- Current objective (updated)
  |   +-- Recent work (this session's accomplishments)
  |   +-- Open loops (what's unfinished)
  |   +-- Key decisions (new ones from this session)
  |   +-- Files modified (from git diff)
  |
  +-- AI checks: is STATE.md > 80 lines?
  |   +-- YES -> Rotate: compress old entries to HISTORY.md
  |
  +-- AI proposes git commit (if changes warrant it)
```

### Rotation: L1 to L2

When STATE.md exceeds ~80 lines (~2K tokens):

1. Move everything except "Current Objective" and "Open Loops" to HISTORY.md
2. Compress moved entries using the compression protocol (10:1)
3. Append compressed entries to top of HISTORY.md (newest first)
4. Reset STATE.md to current session only

**Trigger**: >80 lines (soft limit). The AI checks during /save and rotates if needed. This is not automated -- the AI makes the judgment call on what to keep vs. rotate.

**Why not automated?** Automated rotation can't judge relevance. A decision made 5 sessions ago might still be critical ("we chose Postgres, don't revisit"). The AI knows this from context; a script doesn't.

## Overflow Handling

### STATE.md Overflow

| Size | Status | Action |
|:----:|--------|--------|
| <50 lines | Normal | No action needed |
| 50-80 lines | Warning | Consider rotating on next save |
| 80-120 lines | Overflow | Rotate now: compress and move to HISTORY |
| >120 lines | Emergency | Hard rotate: keep only current objective + open loops, compress everything else |

### HISTORY.md Growth

HISTORY.md grows ~200 tokens per session. At one session per day:
- After 1 month: ~6K tokens (~150 lines)
- After 6 months: ~36K tokens (~900 lines)
- After 1 year: ~72K tokens (~1,800 lines)

At boot, only 50 lines are loaded. The full file stays available for on-demand reads.

**When to trim**: If HISTORY.md exceeds ~2,000 lines (~3-4 years of daily sessions), consider archiving entries older than 1 year to a separate file:

```bash
# Archive old entries
head -n -500 .ai-local/HISTORY.md > .ai-local/HISTORY-ARCHIVE.md
tail -500 .ai-local/HISTORY.md > .ai-local/HISTORY-temp.md
mv .ai-local/HISTORY-temp.md .ai-local/HISTORY.md
```

This is a rare operation. Most projects don't last 3 years of daily AI sessions.

### CONTEXT.md is Disposable

CONTEXT.md is regenerated on every boot. Never edit it manually. Never rely on its contents between sessions. It's a cache, not a source of truth.

## Cross-Session Handoff Protocol

When ending a session that another agent (or the same agent in a new session) will continue:

### Minimum Viable Handoff

1. Run `/save`
2. Ensure STATE.md captures:
   - What the objective is (not "was")
   - What's done and what's not
   - Any decisions that aren't in git yet
   - The exact next step (not "continue working on X" but "implement the validation function in src/auth/validate.ts")

### Quality Check

A good STATE.md handoff answers these questions without the new session needing to ask:

| Question | Where in STATE.md |
|----------|-------------------|
| What are we building? | Current Objective |
| What's already done? | Recent Work |
| What's left? | Open Loops |
| Why did we make these choices? | Key Decisions |
| Where is the code? | Files Modified |
| What should I do first? | Open Loops (first item) |

If any of these require the new agent to read additional files to answer, the handoff is incomplete.

### Scaling Beyond STATE.md: The Handoff Router

STATE.md works for single-topic sessions. For complex workspaces with multiple concurrent workstreams, a **handoff router** scales better. See `../handoffs/HANDOFF-SYSTEM.md` (to be added in Wave 2) for the full pattern.

The idea: a lightweight index file at the workspace root points to detailed handoff files in a working directory. The next session reads only the router, picks the relevant handoff, and resumes with full context.

## Memory Health Diagnostics

### Quick Health Check (on boot)

Add to CONTEXT.md generation:

```markdown
## Memory Health
- STATE.md: {line_count} lines ({status: ok | warning | overflow})
- HISTORY.md: {line_count} lines, {entry_count} sessions
- Last save: {date from STATE.md header or git log}
- Staleness: {days since last save}
```

**Cost**: ~100 tokens. Alerts the agent to memory issues before they compound.

### Staleness Detection

| Days Since Last Save | Status | Implication |
|:----:|--------|-------------|
| 0-1 | Fresh | Normal operation |
| 2-7 | Stale | STATE.md may not reflect current code (git changes happened outside AI sessions) |
| 8-30 | Very stale | STATE.md is unreliable. Start with git log instead. |
| >30 | Expired | STATE.md is historical artifact. Boot should rely on git + AGENTS.md only. |

When STATE.md is stale, the boot script should still load it but flag the staleness. The agent then decides: trust state and continue, or discard state and start fresh from git history.

### Save Script Health Output

The save script should report:

```
MEMORY HEALTH:
  STATE.md: 47 lines (ok)
  HISTORY.md: 234 lines (15 sessions)
  Navigation: 2 dirs without README (src/utils/, tests/fixtures/)
  Last commit: 2h ago
```

This gives the agent (and the human) a snapshot of memory system status without requiring a separate diagnostic tool.

## Design Decisions

### Why Files, Not a Database

| Aspect | Files | Database |
|--------|-------|----------|
| Read | `cat STATE.md` | SQL query + connection |
| Debug | Open in editor | DB client + schema knowledge |
| Version | Git tracks changes | Custom migration system |
| Portability | Copy the file | Export + import + schema |
| Dependencies | None | Runtime, driver, connection |
| Failure mode | File not found (obvious) | Connection timeout, corruption (opaque) |

Files are worse at queries (you can't "SELECT decisions WHERE date > last_week" efficiently). But AI agents don't need queries -- they read the whole file and understand it. A 2K token file is nothing for a 200K context window.

### Why Markdown, Not JSON/YAML

- Markdown renders in GitHub, editors, browsers
- Markdown diffs cleanly in git (line-based changes)
- Markdown is writable by humans AND AI without format errors
- JSON requires escaping, closing brackets, strict syntax
- YAML is whitespace-sensitive and error-prone

STATE.md is read and written dozens of times. Every read/write should be zero-friction.

### Why Claude Code Auto-Memory Is Disabled

Claude Code includes a built-in auto-memory system (`~/.claude/projects/<hash>/memory/`). This system is disabled by default in ai-system projects (`"autoMemoryEnabled": false` in `~/.claude/settings.json`).

**Why:**

- **No sync**: auto-memory lives in `~/.claude/` on one machine. Our system syncs via git.
- **No compression**: auto-memory entries accumulate without rotation or budget. Our system compresses 10:1 and enforces token budgets.
- **No scope isolation**: one auto-memory namespace per working directory. Our system has one `.ai-local/` per project.
- **Tool-specific**: auto-memory only works in Claude Code. Our system works with any AI tool that reads markdown files.
- **Context cost**: auto-memory injects ~800 lines of instructions into every session. Our system loads <5K tokens total at boot.

**What auto-memory does that we replicate:**

| Auto-memory type | Our equivalent |
|------------------|----------------|
| `user` (profile) | `.ai-local/PROFILE.md` |
| `feedback` (lessons) | `.ai-local/LESSONS.md` |
| `project` (state) | `.ai-local/STATE.md` |
| `reference` (pointers) | `.ai-local/STATE.md` or `handoffs/` |

If using Claude Code, ensure `autoMemoryEnabled` is `false` in user-level settings. The CLAUDE.md at project root should reference `.ai-local/` as the memory system.

### Why the AI Manages Rotation, Not a Script

Automated rotation would need rules like "keep entries newer than X days" or "keep entries with keyword Y." These rules can't capture relevance:

- A decision from 3 months ago might be the most important thing in STATE.md
- A task completed yesterday might be completely irrelevant today
- An open loop from last week might have been silently resolved by someone else

The AI reads STATE.md in context and judges: "this is still relevant" or "this can be compressed." No script can do this reliably.

The save script provides the trigger (">80 lines, consider rotating") and the tools (HISTORY.md append). The AI provides the judgment.

## Summary

1. **Four layers**: Chat (volatile) -> STATE.md (sessions) -> HISTORY.md (all time) -> Git (forever)
2. **Token budgets are hard constraints**: STATE < 2K, HISTORY loaded < 1K, CONTEXT < 5K
3. **Compression is 10:1**: A 2K session compresses to 200 tokens in HISTORY
4. **Rotation is AI-driven**: Script triggers, AI judges what to keep
5. **Boot loads minimal context**: STATE + 50 lines HISTORY + git status = <5K tokens
6. **Save extracts signal from noise**: Decisions, outcomes, blockers -- not process
7. **Staleness is tracked**: Days since last save determines trust level
8. **Files, not databases**: `cat STATE.md` is the debugging tool
