# Extending boot.sh and save.sh

The reference `boot.sh` (~90 lines) and `save.sh` (~60 lines) in `.ai/session/scripts/` are deliberately minimal. They demonstrate the L0-L3 boot/save cycle described in [`memory/MEMORY-SYSTEM.md`](memory/MEMORY-SYSTEM.md) and nothing more.

In production projects, these scripts grow. This doc captures the **patterns** that emerge when they do — not the code, which depends on your project's specifics.

## Why the stubs stay minimal

Three reasons:

1. **Onboarding friction**: a 90-line `boot.sh` is readable in one sitting. A 300-line one isn't.
2. **No false ceremony**: many projects never need machine-aware boot, pipeline counts, or coherence audits. Bundling them would impose unwanted complexity.
3. **Tool-agnostic ethos**: the framework relies on files and folders. Each extension is opt-in, layered on top of the stub, not baked into a monolith.

If your project never grows past the stub, that's a success, not a limitation.

## Extension axes (when you need them)

Below are the patterns observed across mature deployments of this framework. Each one extends `boot.sh` or `save.sh` independently — pick the ones that match your project's pain points.

### 1. Multi-machine awareness

**Pain**: you work on the same project from 2+ machines (laptop, desktop, CI). State drifts. Branches collide.

**Pattern**:
- A `machine.json` file per machine, gitignored, holding `{ "alias": "<name>" }`. The boot script reads it to identify the current machine.
- A branch per machine + `main` as integration point (never commit directly to `main`).
- A registry of detached sub-repos in a tracked `projects.json.template`, materialized to a gitignored `projects.json` at boot.
- Per-machine snapshots in `.ai/machines/<alias>.md` showing git state of each repo on that machine.

**Boot.sh additions** (~30 lines): read `machine.json`, materialize registry, scan sub-repos, render branch table in `CONTEXT.md`.

### 2. Coherence audit

**Pain**: docs go stale silently. Handoffs sit "active" for weeks after the work shipped. STATE.md overflows without anyone noticing.

**Pattern**:
- A `staleness.yaml` config with thresholds (e.g. `fresh: 1d, stale: 7d, expired: 30d`), with per-doc-type overrides.
- A `coherence.py` (or `.sh`) that scans dated artefacts and emits warnings.
- `boot.sh` calls the audit and includes a `## Coherence Warnings` section in `CONTEXT.md`.

**Boot.sh additions** (~20 lines): invoke the audit script, capture stderr, append to context.

### 3. Project registry + sub-repo bootstrap

**Pain**: a fresh clone on a new machine doesn't bring in detached sub-repos. Someone has to remember to clone them.

**Pattern**:
- `projects.json.template` (tracked) declares all detached sub-repos with `repo`, `path`, `location`.
- A `bin/clone-subrepos` helper (~50 lines) reads the template and clones whatever is missing. Idempotent.
- New-PC bootstrap doc references the helper as a single step.

**Boot.sh additions** (~10 lines): warn if registry is stale vs. template, suggest the refresh command.

### 4. External sources (machine-dependent paths)

**Pain**: your project reads from external folders (Obsidian vault, scraping output, large datasets) whose paths differ between machines.

**Pattern**:
- A `sources.json` (per-machine config, gitignored) maps source slugs to absolute paths + availability flags.
- A `sources.py` helper resolves a slug → path or exits 1 if unavailable.
- Scripts never hardcode paths; they always go through the helper.
- `boot.sh` renders a `## Sources` section with [OK]/[DRIFT]/[—] markers.

**Boot.sh additions** (~15 lines): render source table.

### 5. Pipeline stats

**Pain**: your project includes a multi-stage pipeline (extract → analyze → cluster → publish). You want to see at boot how many items sit in each stage.

**Pattern**:
- Each pipeline stage produces files in a known directory.
- A helper function counts files per stage and reports them in `CONTEXT.md`.

**Boot.sh additions** (~15 lines): file counts per stage directory.

### 6. Handoff router parsing

**Pain**: a complex workspace has many concurrent workstreams. STATE.md alone can't carry all of them.

**Pattern**:
- A root-level `SESSION-HANDOFF.md` lists active and deferred handoffs (cf. Wave 2 of this framework's roadmap).
- `boot.sh` parses this file and renders the list in `CONTEXT.md`.
- `boot.sh <slug>` can optionally inline a specific handoff for the new session.

**Boot.sh additions** (~25 lines): parse router markdown, optional slug lookup.

### 7. Health metrics

**Pain**: you want to spot memory issues before they compound. STATE.md overflows, HISTORY needs rotation, handoffs are aging.

**Pattern**:
- Compute size + age of STATE.md, HISTORY.md, top handoffs.
- Render a `## Health` section with thresholds (cf. [`memory/MEMORY-SYSTEM.md`](memory/MEMORY-SYSTEM.md) overflow table).

**Boot.sh additions** (~15 lines): line counts, age computation, status tags.

### 8. Save-time hygiene

**Pain**: handoffs go stale, STATE drifts from git, lessons learned are forgotten.

**Pattern** (save.sh):
- Show current STATE.md size, prompt user if >80 lines.
- Show git status + diff --stat for context.
- Optional machine sync (commit snapshot, push branch).
- Optional rotation trigger if HISTORY.md > 300 lines.

**Save.sh additions** (~40-100 lines depending on hygiene depth).

## When to extract instead of inline

Once `boot.sh` exceeds ~200 lines, consider moving the heavy logic to a Python (or other) helper:

- `boot.sh` stays a thin orchestrator (initialize, call helper, write output).
- A `generate_context.py` (or equivalent) does the work, with one function per section.
- This makes each extension independently testable.

Mature production deployments commonly have a `generate_context.py` of 400-700 lines, decomposed into ~10 small functions (one per `CONTEXT.md` section). The shell script remains a 50-line wrapper.

## Anti-patterns

| Anti-pattern | Fix |
|---|---|
| Inlining all extensions into the stub | Decompose: one function/script per concern |
| Re-injecting structural content (project identity) into `CONTEXT.md` at boot | See [`memory/STRUCTURAL-VS-TEMPORAL.md`](memory/STRUCTURAL-VS-TEMPORAL.md) AP1 |
| Hardcoding machine-specific paths in boot scripts | Use a `sources.json` indirection (axis 4) |
| Coupling extensions (axis 2 requires axis 1 to work) | Each extension reads what it needs, gracefully degrades if missing |
| Running expensive checks at every boot | Cache: only re-compute when underlying files change |

## Reference implementations

- **Stub**: `.ai/session/scripts/boot.sh` and `save.sh` in this repo (~150 lines total)
- **Production example**: extensions 1-8 are fully wired in the parent knowledge-base workspace this framework was extracted from. The implementation isn't promoted here because it's deeply coupled to that project's domain, but the patterns above match it 1:1.

## When not to extend

Most projects don't need any extension. Signs you should resist:

- "Wouldn't it be nice if boot showed X?" — but you'd only use X once a week
- "Let's add a section just in case" — boot output already at 200 lines, more is friction
- "We could automate the rotation" — see [`memory/MEMORY-SYSTEM.md`](memory/MEMORY-SYSTEM.md): rotation is AI-judgment, not script-judgment

When in doubt: keep the stub, write a tiny ad-hoc script, see if it gets used. If yes, promote to a boot extension. If no, delete it.
