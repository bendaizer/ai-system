---
name: iterate-html
description: Agentic loop for iterating on an HTML rendering until visual criteria are met — screenshot → diagnose → fix → re-screenshot. Invoke after modifying any HTML or its underlying data/style, or before marking a visual task done. Covers any local HTML (file://, http://127.0.0.1, dev server), with three capture modes depending on context.
---

# /iterate-html — Agentic loop for HTML rendering fixes

A procedure for iterating on an HTML rendering until it passes visual validation. **Distinct from a one-shot visual diagnostic**: this skill orchestrates the *correction loop*, not just the analysis.

## When to invoke

- After a Write/Edit on an `.html` file that needs to render
- After modifying the data feeding a rendered HTML (JSON, MDX, etc.)
- After touching a CSS or a templating engine that affects multiple renderings
- Before marking a visual task done in your state files
- When the user says "look at the rendering", "fix the visual", "does it pass", "iterate on it"

Do **not** invoke for: simple file reads, one-shot diagnostics, or full UX audits — use the appropriate dedicated tool instead.

## Prerequisites

A Playwright MCP server configured in your AI tool (see your tool's MCP documentation for installation). Without Playwright MCP, the loop is degraded (no native vision over the rendering).

If the HTML is served by a local server, start one at the repo root before the loop:

```bash
python3 -m http.server 8088
```

Then use `http://127.0.0.1:8088/<path>`. For standalone HTML (no JSON fetch), `file://<absolute-path>` is enough.

## Capture mode — pick based on context

| Mode | When to use | How |
|---|---|---|
| **MCP on-demand** (default) | One-shot, 1-3 captures, exploration, first diagnostic | Direct call to `mcp__playwright__browser_take_screenshot` with `file://` or `http://` URL — PNG output to your chosen directory |
| **Node batch script** | Cross-rendering audit (e.g. multiple deliverables, multiple tabs of the same rendering) | Direct Playwright Node script (outside MCP) — click each navigation element + `waitForTimeout(900)` + `screenshot({ fullPage: true })`. Output to a dedicated folder per run. |

**Reasonable default**: MCP on-demand. Switch to the Node script only for a batch audit.

For long iterations on the same file with auto-capture after every Edit, an opt-in hook+queue pattern exists (PostToolUse hook drops a request into a queue file, the AI consumes it on the next turn). Implementation depends on your AI tool's hook system.

## The loop — 5 steps, repeat until OK

### 1. CAPTURE

Take the screenshot via the chosen mode. For renderings with tabs or multiple views, capture **each view**: click the navigation element, wait ~900 ms (transitions + any chart render), screenshot full-page. In MCP mode, make one call per view with explicit navigation.

Default viewport: 1280×900, deviceScaleFactor 1. Also test 375×812 (mobile) if the deliverable is responsive.

### 2. ANALYZE

Read the screenshot(s) via the native vision modality. Generic analysis checklist:

- **Truncation**: tab labels, card titles, bar labels, source captions, chart axes
- **Horizontal scroll**: no H-bar at 1280px. Inspect every wide block
- **Overflow**: text leaving its container, image exceeding bounds, chart clipped
- **Contrast and palette**: if your project has a design system, verify against its tokens. Otherwise, WCAG AA minimum.
- **Column balance**: multi-column layouts shouldn't have one column 3× longer than another
- **Visual variety**: at least one graphical block per view if the rendering relies on visualisations
- **Label legibility**: every visible text must be readable without zoom
- **Cross-view consistency**: navigation stable, header constant, footer present

Enumerate **each gap** with: view concerned, gap type, severity (FAIL / WARN), location (block index or CSS selector).

### 3. DIAGNOSE

For each gap, identify the **layer to touch**, preferring the highest layer possible:

| Layer | Typical symptom | Target file |
|---|---|---|
| **Data** (preferred) | Text too long, title 50 chars, verbose source, unbalanced column | The data source (JSON, MDX, etc.) — shorten, rewrite, rebalance |
| **Structure** | Wrong block type, badly distributed columns, missing voice | The structure (data shape, component composition) — change types, redistribute |
| **Style** | Insufficient contrast, inconsistent padding, palette not respected | Your design system CSS or local CSS — targeted patch |
| **Template** | Renderer bug, systemic overflow, unhandled prop | Your templating engine — fix with cross-deliverable impact |

Prefer data > structure > style > template: a template fix can regress N deliverables.

### 4. FIX

Apply the fix at the right layer via Edit. **One correction per gap** when possible — avoids coupled corrections that mask regressions.

### 5. RE-CAPTURE + RE-ANALYZE

Re-screenshot after every non-trivial correction (never "I edited, it must be fine"). Compare to the previous. Exit the loop when:

- (a) All initial gaps are resolved, **AND**
- (b) No new gap introduced by the corrections

Document in your session notes (state file, handoff, or wherever your project keeps session continuity): number of iterations, final captures (path), list of corrections applied.

## Exit criteria (definition of done)

- Zero visible truncation on the captured views
- Zero horizontal scroll at 1280px
- Zero card/column overflow
- Palette respected (escalate to a dedicated palette/UX audit if your project has one)
- At least 1 graphical block per view if the rendering relies on visualisations
- Labels legible without zoom

**Safety net**: if the same criterion fails after 3 iterations on the same point, escalate to the user — do not loop indefinitely. Describe what was tried and why the fix doesn't hold.

## Anti-patterns

- Editing the HTML without re-capturing (open loop → you don't know if you fixed or broke)
- Calling a one-shot diagnostic skill instead of this one (a diagnostic doesn't correct — use its checklist but not its scope)
- Fixing in CSS what belongs in the data (the fix regresses on the next deliverable using the same template)
- Fixing in the template what belongs in the CSS (cross-deliverable impact not acknowledged)
- Looping without documenting iterations in your session notes
- If you opt into the hook pattern (advanced setup), forgetting to disable it after the session → spurious captures on unrelated HTML.

## Related

- `../../docs/memory/STATE-OWNERSHIP.md` — Where to document iteration notes
