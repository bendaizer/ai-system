# CLAUDE.md — Public ai-system framework

> **CONTEXTE MAIN_KNOWLEDGE** : ce dossier est un sub-repo détaché poussant sur `git@github.com:bendaizer/ai-system.git`. Ce que vous écrivez ici est **public**.

## Règle absolue : NE PAS ÉDITER DIRECTEMENT ICI

Toutes les modifications doivent être faites dans `_ai-system-private/` (bac à sable), puis **promues fichier par fichier** vers ce dossier après validation manuelle.

Édition directe = risque de fuite (paths absolus MK, secrets, références skills MK-spécifiques) et perte du gate de validation.

## Workflow strict

### 1. Édit privé d'abord
```bash
# Toujours dans _ai-system-private/
$EDITOR _ai-system-private/<chemin>
```

### 2. Diff manuel avant promotion
```bash
diff -ruN _ai-system-private/<chemin> _ai-system-public/<chemin>
```
Vérifier ligne par ligne. Aucune référence à :
- Paths absolus MK (`/home/a-d-mine/WIP_WSL/MAIN_KNOWLEDGE/...`)
- Secrets, credentials, clés API
- Skills MK-spécifiques (`radar-*`, `podcast-analyze`, `knowledge-pipeline`, etc.)
- Noms de personnes, clients, projets internes
- Anciens dossiers archivés (`_DOCS/_archive/...`)

### 3. Copie ciblée
```bash
cp _ai-system-private/<chemin> _ai-system-public/<chemin>
```
Une copie globale (`cp -a`, `rsync`) est **interdite**.

### 4. Commit dans le sub-repo
```bash
cd _ai-system-public
git add <chemin>
git commit -m "..."
```

### 5. Push protégé
```bash
touch _ai-system-public/.promote-ok   # token de validation explicite
git -C _ai-system-public push          # le hook pre-push vérifie .promote-ok
                                       # le hook post-push le supprime
```

Sans `.promote-ok`, le hook `pre-push` refuse le push avec message d'erreur.

## Garde-fous installés

| Couche | Mécanisme | Installation |
|---|---|---|
| 1 | Ce CLAUDE.md (auto-chargé par Claude Code) | Tracké dans le sub-repo |
| 2 | Hook `pre-push` (exige `.promote-ok`) + `post-push` (le supprime) | Par PC via `.ai/bin/install-ai-system-hooks` |
| 3 | Hook Claude Code post-Write (avertit si édition directe) | Par PC via `.claude/settings.json` |

`.promote-ok` est gitignoré côté MK et ne doit jamais être committé dans le sub-repo.

## Si vous êtes vraiment forcé d'éditer ici

Cas légitime : fix urgent d'un fichier `.git/`-managed (ex. `.gitignore` du sub-repo). Dans ce cas :
1. Faire le changement
2. **Documenter pourquoi le bac à sable n'a pas été utilisé** dans le commit message
3. **Reporter le changement manuellement dans `_ai-system-private/`** ensuite pour garder les 2 miroirs alignés

## Spec complète

`../_DOCS/ai-system/06-infrastructure/AI-SYSTEM-MIRRORS.md` (côté MK uniquement, pas de chemin absolu).
