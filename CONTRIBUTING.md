# Contributing to ai-system

This is the public framework repository. Contributions should preserve the framework's defining qualities: **tool-agnostic, minimal, files-and-folders only, no plugins or external dependencies** (see `PHILOSOPHY.md`).

## Workflow

Two paths depending on whether you're an external contributor or a maintainer.

### External contributors

1. Fork the repository
2. Open a pull request against `main`
3. In the PR description, explain the motivation (what pain does this solve?) and how it preserves the minimalist ethos
4. Be ready to discuss whether the change belongs in the core framework or in an optional layer

### Maintainers

1. Work on a branch (not `main`)
2. Open a PR for review even on small changes — the framework's value depends on its narrow surface area, so every addition deserves a second look
3. Squash-merge once approved

## What belongs here

| Belongs | Doesn't belong |
|---|---|
| Generic patterns proven across multiple projects | Patterns specific to one project's domain |
| Tool-agnostic specs (work with Claude Code, Cursor, Codex, etc.) | Tool-specific integrations (those go in `adapters/`) |
| Reference scripts demonstrating the pattern | Production code with project-specific paths or credentials |
| Documentation for the L0-L3 memory model | Documentation for specific products built on top |
| New skills that any project could plug in | Skills tied to one company's internal tools |

When unsure: write the new content first, then ask "would a fresh project I've never seen find this useful unchanged?" If no, it probably belongs in a downstream fork.

## What never lands here

- Absolute paths from contributors' machines (`/home/<user>/...`, `/Users/<user>/...`, `C:\Users\...`)
- Secrets, API keys, credentials of any kind (no exceptions)
- Personal or organisational names, internal project codenames, client identifiers
- References to private repositories, internal documentation, or non-public URLs
- Skills that depend on tools or services not freely available

If a PR contains any of the above, it gets rejected and rewritten — not amended in place.

## Style

- English only (the framework is consumed internationally)
- Markdown for documentation, with code blocks for examples
- Reference scripts: bash for shell, Python for anything more complex, Node only when the ecosystem demands it (e.g. Playwright)
- Each new doc gets an entry in the relevant `docs/<section>/README.md` so the navigation stays current

## Releases

The framework follows no formal release cadence. The `main` branch is the source of truth; consumers pin to a commit hash if they need stability.

## Issues

Open an issue before a large PR. The maintainers may have already considered (and rejected) the approach, or may suggest a different angle that fits the framework better.
