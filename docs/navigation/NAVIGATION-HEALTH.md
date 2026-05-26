# Navigation Health — Automated Graph Integrity Checks

> **Companion:** [`RETRIEVAL-STRATEGIES.md`](RETRIEVAL-STRATEGIES.md) — the broader navigation philosophy.

## Problem

The navigation graph (README.md files linking to children, neighbors, and cross-references) degrades silently as files are added, moved, or deleted. Over time:

- New directories appear without README.md — invisible to the navigation graph
- Links in README.md files point to renamed or deleted files — dead ends
- Recently changed files are not referenced in their parent README — undiscoverable

Without automated checks, navigation quality erodes to the point where agents waste tokens exploring dead links or missing context.

## Solution: Three Checks at Save Time

Run three lightweight checks during `/save` to surface navigation issues before they compound.

### Check 1: Missing READMEs

Directories with 3+ files but no README.md are navigation blind spots.

```bash
# Scan depth 1-2, skip hidden/temp directories
while IFS= read -r dir; do
    dirname=$(basename "$dir")
    case "$dirname" in
        .*|TMP*|node_modules|__pycache__|site|*.egg-info) continue ;;
    esac
    relpath="${dir#$PROJECT_ROOT/}"
    case "$relpath" in
        .ai/*|.ai-*|.git/*|.claude/*) continue ;;
    esac
    if [ ! -f "$dir/README.md" ]; then
        file_count=$(find "$dir" -maxdepth 1 -not -name '.*' -not -type d 2>/dev/null | wc -l)
        if [ "$file_count" -ge 3 ]; then
            echo "  - ${relpath}/ ($file_count files, no README)"
        fi
    fi
done < <(find "$PROJECT_ROOT" -mindepth 1 -maxdepth 2 -type d 2>/dev/null | sort)
```

**Threshold**: 3 files is the minimum for a README to be useful. Single-file directories don't need one.

**Exclusions**: Hidden directories, temp folders, dependency directories, and the `.ai/` infrastructure itself (which has its own README structure).

### Check 2: Broken Links in READMEs

Markdown links in README.md files that point to non-existent targets.

```bash
# Scan READMEs up to depth 3
while IFS= read -r readme; do
    readme_dir=$(dirname "$readme")
    while IFS= read -r link; do
        [ -z "$link" ] && continue
        target="$readme_dir/$link"
        if [ ! -e "$target" ]; then
            rel_readme="${readme#$PROJECT_ROOT/}"
            echo "  - ${rel_readme} → ${link} (broken)"
        fi
    done < <(grep -oP '\[.*?\]\(\K[^)]+(?=\))' "$readme" 2>/dev/null \
             | grep -v '^http' | grep -v '^#' | sed 's/#.*//' | sed 's/%20/ /g')
done < <(find "$PROJECT_ROOT" -maxdepth 3 -name 'README.md' \
         -not -path '*/.git/*' -not -path '*/.ai-local/*' \
         -not -path '*/node_modules/*' 2>/dev/null)
```

**Scope**: Only checks local (relative) links. External URLs are not validated (too slow, may need network). Anchor-only links (`#section`) are skipped.

### Check 3: Unreferenced Recent Files

Files changed in the last commit that are not mentioned in their parent README.

```bash
if git -C "$PROJECT_ROOT" rev-parse HEAD~1 >/dev/null 2>&1; then
    while IFS= read -r changed_file; do
        [ -z "$changed_file" ] && continue
        case "$changed_file" in
            .*|*README.md|*.jsonl) continue ;;
        esac
        [ ! -f "$PROJECT_ROOT/$changed_file" ] && continue
        parent_dir=$(dirname "$PROJECT_ROOT/$changed_file")
        parent_readme="$parent_dir/README.md"
        if [ -f "$parent_readme" ]; then
            base=$(basename "$changed_file")
            if ! grep -qF "$base" "$parent_readme" 2>/dev/null; then
                echo "  - ${changed_file} (not in parent README)"
            fi
        fi
    done < <(git -C "$PROJECT_ROOT" diff --name-only HEAD~1 2>/dev/null)
fi
```

**Why recent files**: Checking all files would be too noisy. Focusing on recently changed files catches the most common drift — new files added without updating the README.

## Integration in save.sh

Add the checks as a section in the save script output:

```bash
echo "=== Navigation Health ==="

# Check 1
echo "Missing READMEs:"
# ... (check code) ...
# If none: echo "All directories with 3+ files have README.md [ok]"

# Check 2
echo "Broken links:"
# ... (check code) ...
# If none: echo "All README links resolve [ok]"

# Check 3
echo "Unreferenced files:"
# ... (check code) ...
# If none: echo "All recent files referenced [ok]"
```

## Output Examples

### Clean output

```
=== Navigation Health ===
All directories (depth 1-2) with 3+ files have README.md [ok]
All README links resolve [ok]
All recent files referenced in READMEs [ok]
```

### Issues detected

```
=== Navigation Health ===
Missing README.md (dirs with 3+ files):
  - src/utils/ (5 files, no README)
  - tests/fixtures/ (3 files, no README)
Broken links in READMEs:
  - docs/README.md → old-guide.md (broken)
Recently changed files not referenced in parent README:
  - src/auth/validate.ts (not in parent README)
```

## Response to Issues

These are **advisory warnings**, not blockers. The save completes regardless.

The agent (or human) decides how to respond:

| Issue | Typical response |
|-------|-----------------|
| Missing README | Create a minimal README (3-5 lines: title + file list) |
| Broken link | Fix the link or remove it |
| Unreferenced file | Add to parent README or ignore (not all files need listing) |

**Do not auto-fix.** Navigation decisions require judgment. A missing README might be intentional (temp directory). A broken link might point to a file about to be created.

## Performance

All three checks use `find` and `grep` — no external tools, no network, no dependencies.

**Typical runtime**: <1 second for projects with 50-100 directories and 20-30 READMEs.

**Scaling**: For very large monorepos (1000+ directories), restrict depth or sampling. The checks are designed for depth 1-3, which covers the navigation-relevant layer without scanning deep dependency trees.

## Related

- [RETRIEVAL-STRATEGIES.md](RETRIEVAL-STRATEGIES.md) — Navigation-based retrieval and link types
- [PROJECT-TAXONOMY.md](PROJECT-TAXONOMY.md) — Directory conventions (README per directory with 3+ files)
- [MEMORY-SYSTEM.md](MEMORY-SYSTEM.md) — Save cycle (where checks run)
