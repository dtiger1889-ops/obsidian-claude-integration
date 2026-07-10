---
created: 2026-06-23
updated: 2026-06-23
tags:
  - spec
  - obsidian
  - meta
---
# Obsidian × Claude projects — integration spec

> Goal: make the Obsidian vault a first-class, **searchable** reference layer for the Claude workspace projects, without blurring the line between *work* (projects) and *durable reference* (vault).

## The model — two systems, separate lanes

| | Claude projects | Obsidian vault |
|---|---|---|
| Path | `~/Documents/Claude/<x>/` | `~/Documents/Obsidian Vault/` |
| Holds | active work: analysis, pipelines, artifacts | durable personal reference + writing |
| Driven by | agent + `CHECKPOINT.md` | human browsing, PARA |
| Backup | git (workspace repo) | Obsidian Sync |
| Agent can Grep/Glob it? | **No** — workspace `.gitignore` blinds search | **Yes** — it's outside the workspace |

The vault sitting **outside** the workspace gitignore is the key enabler: an agent can Grep/Read it freely (workspace project content it cannot). That's what makes a read skill real rather than clever.

Integration is **one-way: projects point into the vault.** The project does the work; the vault holds the reference it draws on. New durable reference is *written to* the vault; work artifacts stay in the project. Don't merge the two.

## Domain mappings

Only some projects have a vault counterpart:

- **Health** → `Areas/Health/`
- **Career** → `Areas/Career/`
- **Financial** → `Areas/Finances/`

Everything else (all other projects) has no vault side and gets **no pointer**. Personal vault areas (`Hobbies`, `Relationships`, `Home & Logistics`, `Writing & Journal`) have no project and are reached only via the skill.

## Components

### 1. Vault `HOME.md` index
A single-screen map at the vault root (currently missing — the root holds only stray leftovers). Contains:
- The PARA structure, one line per Area/Resource folder (what's in it, when you'd open it).
- The vault conventions (below).

It's the cheap orientation entry point — read HOME → drill to the specific note (progressive disclosure). Doubles as a personal dashboard inside Obsidian.

### 2. CHECKPOINT pointer convention
Each mapped project's `CHECKPOINT.md` gets one block:

```
## Obsidian
Domain reference: ~/Documents/Obsidian Vault/Areas/Health/
(Medical · Workouts · etc.). Read the
specific note when the task needs it; don't load the folder.
```

Lives in the startup read path, so any session in that project learns the pointer automatically. Zero new machinery — highest leverage-to-effort piece.

### 3. `/obsidian` skill (user-level)
Lives in `~/.claude/skills/obsidian/` so it's available in every project and standalone. Capabilities, phased by risk:

- **Query / read** (safe core): orient via HOME, Grep the vault, read the relevant note, answer. the pattern: one question, one note, answered from any session.
- **Capture**: drop a dated note into `00 Inbox/` (the existing Obsidian inbox; sort later).
- **Routed write** (careful): file straight into the right Area file by the retrieval-context rule, appending `## <Title> — <YYYY-MM-DD>`. Gated for personal content.

The skill encodes (or reads from HOME): vault root, PARA map, the conventions below.

## Conventions (rules that writes + the skill follow)
- **Dated provenance** — every consolidated entry keeps `## <Title> — <YYYY-MM-DD>` (created date). The date is the spine.
- **Retrieval-context organization (why / when / what / who)** — a file answers ONE situation. Notes sharing a tag but used in different moments go in separate files. Don't cram; don't hedge "borderline" — if the situation differs, split.
- **Personal content is the user's call** — journal / relationship / rage / personal-medical: never auto-write or restructure; capture to Inbox or ask.
- **Skip sync-conflicts** — ignore `*.sync-conflict-*` files on read; flag, don't act on them.
- **Don't load wholesale** — read the specific note, never a whole folder, into context.

## Build order
1. **Phase 1 (now, ~20 min, low-risk):** `HOME.md` + the 3 CHECKPOINT pointers. Immediately makes the vault discoverable from mapped projects.
2. **Phase 2:** `/obsidian` skill, read/query only.
3. **Phase 3:** capture-to-Inbox.
4. **Phase 4:** routed writes (gated for personal content).

## Caveats
- **Cowork can't see the vault** — it's local; cloud/scheduled sessions won't have it mounted. This is a local-Claude-Code feature.
- **Backup is separate** — vault = Obsidian Sync, workspace = git. Both covered, different domains.

## Open decisions
- How far the skill should go: read-only / +capture / +routed writes.
- Whether conventions live in `HOME.md`, or a dedicated vault `CLAUDE.md` (agent rules) with HOME as the human index.
- Any project beyond Health/Career/Financial that should map — e.g. do other project folders map to vault Areas?
- Minor: stray notes at the vault root → `00 Inbox/` or file them.
