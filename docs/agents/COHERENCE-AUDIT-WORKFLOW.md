# Coherence Audit Workflow — Multi-Agent Review

> **Status**: Workflow specification. A reference implementation script is not part of this framework — projects wire their own audit script (e.g. `coherence.py`) that follows the 4-phase structure below.

## Problem

Individual tools detect individual problems: a coherence checker catches metric drift, a per-domain playbook catches local issues, handoff audits catch stale sessions. But nobody orchestrates these into a single pass that answers: **"Is the whole workspace consistent right now?"**

Without a structured workflow, coherence audits are ad-hoc: an agent notices a contradiction, fixes it, but misses the 11 others. Worse, fixes in one system create new contradictions in another (updating a percentage in STATUS without propagating to a stream file).

This document describes a 4-phase workflow that uses parallel agents and cross-verification to systematically detect and resolve coherence issues.

---

## Workflow Overview

```
Phase 1                    Phase 2              Phase 3            Phase 4
PARALLEL EXPLORATION  →   CROSS-VERIFY    →   TRIAGE (SWIPE)  →  EXECUTE & PROPAGATE
(N agents, read-only)     (independent      (user validates    (phased, with tools)
                          model)            each finding)
```

**Total time**: 20-40 min (exploration) + 5-10 min (triage) + variable (execution).

---

## Phase 1 — Parallel Exploration

Launch N read-only sub-agents simultaneously, each covering a non-overlapping scope:

| Agent | Scope | Key questions |
|-------|-------|---------------|
| **Content** | Documents, deliverables, citations | Completion %, readiness, cross-refs, recent changes |
| **Data/Lab** | Experiments, registries, notebooks | Registry coverage, uncommitted work, currency |
| **PM** | STATUS, BLOCKERS, DECISIONS, streams, handoffs | Dashboard accuracy, overdue items, stale handoffs |
| **Git** | All repos — commit history, unpushed work, branches, untracked files | Loose ends, push status, untracked artifacts |

Each agent returns a structured report. They do **NOT** write files.

### Why N agents instead of 1

Context window. A single agent reading all files would consume 80%+ of context before producing any analysis. Parallel agents each get a fresh window, explore deeply, and return a compressed summary.

Typical N: 3-5 depending on workspace complexity. More than 5 starts to overlap and produce duplicate findings.

### Anti-patterns

- **Don't let review agents fix issues**. Read-only exploration produces cleaner findings.
- **Don't duplicate agent work in the main thread**. Wait for results.
- **Don't launch agents for scopes a deterministic tool can answer**. Use the tool first, agents for what the tool cannot detect.

### Sub-agent prompts

Each sub-agent should receive:

1. **Scope definition** — exact directories/files to examine
2. **Key questions** — what to look for
3. **Output format** — structured report (e.g., findings table)
4. **Constraints** — read-only, time budget, max findings

Example prompt:

```
You are a read-only audit agent. Scope: {directory}.

Look for:
- {specific issue type 1}
- {specific issue type 2}
- {specific issue type 3}

Return a structured report:
| Severity | Finding | Evidence (file:line) | Suggested action |
|----------|---------|---------------------|------------------|

Do NOT modify any files. Do NOT exceed {N} findings. Time budget: {M} min.
```

---

## Phase 2 — Cross-Verification

Findings from Phase 1 are summaries. They may contain errors: hallucinations, stale reads, misinterpretation. Phase 2 verifies them.

### Step 2a — Automated checks

Run deterministic tools that catch known patterns:

```bash
# Drift detection (extract metrics from all files, compare)
coherence_audit --format terminal

# Staleness check (file dates vs git dates)
coherence_freshness --days 7

# Link integrity
navigation_health
```

These catch: metric drift, terminology violations, stale files, overdue decisions, broken links. The output is deterministic and fast.

### Step 2b — Independent model cross-check

Extract specific claims from agent reports. Formulate as falsifiable statements:

```
CLAIM 1: Domain X has no FACT-REGISTRY.md
CLAIM 2: Project Y data work is uncommitted
CLAIM 3: Decision Z is 13 days overdue
```

Submit to an **independent model** (different from the one that produced the original reports) with direct file access. The independent model returns verdicts:

| Verdict | Meaning |
|---------|---------|
| **CONFIRMED** | The claim is accurate |
| **CONTRADICTED** | The claim is wrong |
| **NUANCE** | The claim is partially correct |
| **UNVERIFIABLE** | Insufficient information |

### Why an independent model

Agent reports are summaries. They may:
- Hallucinate details
- Read stale `STATE.md` files (e.g., "uncommitted work" reported when git is actually clean)
- Misinterpret cross-references
- Confabulate plausible-sounding but wrong claims

A second model with direct file access provides a sanity check that catches these errors.

### What Phase 2 catches that Phase 1 misses

- Agent reports based on stale session state (`STATE.md` ≠ git reality)
- Counts that look right individually but conflict across agents
- Items marked as pending that are actually committed
- Metrics that drift between document tiers

### What Phase 1 catches that Phase 2 misses

- Qualitative inconsistencies (framing contradictions, tone mismatches)
- Missing content (absent files — no file = nothing to diff)
- Stale handoffs (handoff says "pending" but work is committed)
- Cross-repo sync issues

---

## Phase 3 — Triage (Swipe Navigation)

All findings from Phases 1-2 are consolidated into a single triage list. Each item gets a **swipe verdict**: the user validates, dismisses, or defers each finding before any action is taken.

### Triage categories

| Verdict | Meaning | Action |
|---------|---------|--------|
| **FIX** | Confirmed issue, fix now | Goes to Phase 4 execution queue |
| **DEFER** | Real issue, not critical | Add to PM backlog or handoff for later |
| **DISMISS** | False positive or already handled | Drop from list, no action |
| **ESCALATE** | Requires human decision (not AI-fixable) | Flag for user with options |

### Swipe navigation pattern

Present findings grouped by severity, with the most impactful first:

```
URGENT (fix today)
  [1] 10 commits unpushed → FIX / DEFER / DISMISS
  [2] DEC-004 deadline tomorrow → ESCALATE (human decision)
  [3] DG-002 13 days overdue → ESCALATE (human action)

STALE (cleanup)
  [4] Handoff X marked READY but work done → FIX / DISMISS
  [5] STATE.md stale (>7d) → FIX / DEFER

GAPS (missing content)
  [6] Domain Y no registry → FIX / DEFER
  [7] Status dates 3 weeks old → FIX / DEFER

DRIFT (deterministic checks)
  [8]  Metric A: 65% vs 75% → FIX
  [9]  Metric B: 55% vs 45% → FIX
  [10] Terminology: 3 occurrences old name → FIX
```

The user swipes through each item. This ensures:

- No AI-initiated action without human validation
- Clear priority ordering (urgent → stale → gaps → drift)
- Deferred items get captured (not lost)
- False positives get dismissed (not re-flagged next session)

### Presenting swipe items

Use a question/answer pattern with multi-select for batch triage:

```
"Which items should we fix now?"
Options: [list of FIX-able items]
MultiSelect: true
```

Items marked ESCALATE get individual questions with decision options:

```
"DEC-004 deadline is tomorrow. What do you want to do?"
Options:
- Decide now (provide answer)
- Extend deadline by 1 week
- Mark as blocker, escalate to stakeholder
```

---

## Phase 4 — Execute & Propagate

Execute approved fixes following a structured order to minimize ripple effects.

### Execution order

```
1. Git operations (push, commit) — unblocks collaboration
2. Handoff cleanup (mark done, close stale) — reduces noise
3. PM updates (BLOCKERS, DECISIONS, dates) — accuracy
4. Content creation (missing registries, new docs) — parallel agent
5. Tier 1 corrections (source-of-truth values) — authoritative
6. Tier 2 propagation (derived files) — automated tooling
7. Terminology fixes (sweep + replace) — automated scan
```

### Using deterministic tools for propagation

After Tier 1 corrections, run propagation:

```bash
coherence_audit propagate --dry-run   # preview
coherence_audit propagate              # apply
coherence_audit audit                  # verify
```

This automatically updates Tier 2 files to match Tier 1 values. Tier 3 (deliverables, partner-facing docs) requires manual review because partner-facing content has style constraints that automated tools cannot enforce.

### Parallel execution

Independent fixes can run as parallel agents:

| Agent | Scope | Writes to |
|-------|-------|-----------|
| A | Handoff cleanup + PM updates | meta repo |
| B | Content creation (e.g., new registry) | data-lab repo |

Rule: one writer per repo (see [CONCURRENT-AGENTS.md](CONCURRENT-AGENTS.md)).

---

## Update Strategy

### When to run a full coherence audit

| Trigger | Scope | Frequency |
|---------|-------|-----------|
| Session start (boot) | `coherence freshness` only | Every session |
| Weekly milestone | Full 4-phase workflow | Weekly |
| Post-bulk-edit (terminology sweep, archive pass) | `coherence audit` + selective agent review | After bulk ops |
| Pre-delivery (milestone) | Full workflow + independent verification | Before milestone |
| On demand (`/audit`) | `coherence audit` quick check | Anytime |

### Boot-time integration

The boot script can include lightweight checks that surface critical issues at session start without running a full audit:

- Stale handoffs (Active entries older than 7 days)
- Overdue decisions
- Unpushed commits (git status ahead of origin)
- Recently modified files not in any README

### Incremental updates between audits

Between full audits, maintain coherence through the propagation protocol:

1. **Change a Tier 1 value** (e.g., update a metric in source-of-truth file)
2. **Same session**: update all Tier 2 files referencing that value, or run `coherence propagate`
3. **Mark Tier 3 as stale**: if the change affects deliverables, add a note in the relevant doc ("L3 needs refresh: metric X changed")
4. **Next milestone**: refresh Tier 3 files

### Handoff hygiene

Per [STATE-OWNERSHIP.md](../memory/STATE-OWNERSHIP.md):

- Active handoffs older than 7 days get reviewed for closure
- Active handoffs with all files committed move to Recent
- Recent table keeps at most 5 entries

### Context overflow strategy

If a coherence audit session exceeds 80% of context window:

1. Write a handoff file (`TMP/handoffs/{date}-coherence-audit.md`) with findings so far
2. List remaining unchecked items in the handoff
3. Start a new session to continue from the handoff
4. Never discard partial findings — they are the most expensive to reproduce

---

## Connection to Other ai-system Patterns

| Pattern | Role in this workflow | Phase |
|---------|----------------------|-------|
| `coherence_audit` (deterministic tool) | Drift detection (metrics, terminology, deliverables) | 2a |
| `coherence freshness` | Staleness report | 2a, boot |
| `coherence propagate` | Auto-fix Tier 2 from Tier 1 | 4 |
| Independent model verification | Cross-check claims from Phase 1 | 2b |
| `TRACEABILITY-PATTERN.md` (companion doc, to be added) | Number provenance from raw data to deliverable | 4 (validation) |
| [STATE-OWNERSHIP.md](../memory/STATE-OWNERSHIP.md) | Defines who owns what (informs triage) | 3 |
| `FAILURE-PATTERNS.md` (companion doc, to be added) | Catalog of issues to look for | 1 (agent prompts) |
| [CONCURRENT-AGENTS.md](CONCURRENT-AGENTS.md) | Multi-agent safety rules | 1, 4 |

---

## Observed Results

A first full audit using this workflow on a multi-project workspace produced:

**Phase 1 findings**: 10 unpushed commits, 5 stale handoffs, 1 missing fact registry, 3 overdue items, 1 untracked artifact.

**Phase 2 corrections**: independent model contradicted 1 of 7 claims (an agent had read a stale STATE.md when git was actually clean). Nuanced 1 claim (handoff written before execution, now stale).

**Phase 3 triage**: user selected "Push + cleanup + missing registry creation" + "gitignore extra artifact".

**Phase 4 execution**: 10 commits pushed, 5 handoffs cleaned, BLOCKERS updated, .gitignore updated, missing registry created (~40 facts, committed).

**Post-execution audit**: 12 drifts remaining (Tier 1 ↔ Tier 2 drifts that required source corrections first).

Total time: ~3 hours for a workspace of ~5 projects.

---

## When NOT to Use This Workflow

This workflow has overhead. Don't use it for:

- **Single-project, single-task sessions** — STATE.md handoff is sufficient
- **Routine commits** — git hooks and pre-commit checks are enough
- **Quick bug fixes** — too much process for too little scope
- **Sessions <30 min** — the workflow itself takes 30+ min

Use it when:

- Multiple projects need coordinated state
- Pre-milestone validation is required
- Suspected drift between systems
- Onboarding a new team member (shows them how to verify everything)
- After a major refactor or terminology change

---

## Sub-Agent Coordination Tips

### Limit concurrent reads

Even read-only agents can race. If 4 agents all read the same `STATUS.md` simultaneously, one might catch a half-written state from a 5th process. Mitigation:

- Run audits when no other agents are actively working
- Stagger agent launches by 1-2 seconds
- Use snapshot-based reads when possible (git show vs file read)

### Standardize the report format

All sub-agents return reports in the same format. This makes consolidation in Phase 3 trivial:

```markdown
## Findings — {agent name}

| ID | Severity | Type | Finding | Evidence | Suggested action |
|----|----------|------|---------|----------|------------------|
```

### Avoid agent-to-agent communication

Sub-agents in Phase 1 should not talk to each other. Each agent has a clean context. Cross-references happen in Phase 2 (cross-verification) and Phase 3 (triage).

This prevents cascading errors: if Agent A's hallucination informs Agent B's analysis, both reports are wrong.

---

## Related

- [CONCURRENT-AGENTS.md](CONCURRENT-AGENTS.md) — Multi-agent safety rules
- [STATE-OWNERSHIP.md](../memory/STATE-OWNERSHIP.md) — Defines who owns what
- [../handoffs/HANDOFF-SYSTEM.md](../handoffs/HANDOFF-SYSTEM.md) — Handoff router (referenced in Phase 4)
- [../TESTING-WITH-AGENTS.md](../TESTING-WITH-AGENTS.md) — Testing patterns that complement audit
- `FAILURE-PATTERNS.md` (companion doc, to be added) — Catalog of patterns to look for during audit
- `TRACEABILITY-PATTERN.md` (companion doc, to be added) — Number provenance
