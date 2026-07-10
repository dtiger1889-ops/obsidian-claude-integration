---
created: 2026-07-02
updated: 2026-07-02
tags:
  - obsidian
  - meta
---
# The second-brain system — what we built and how it works

Written to be read in chunks. Each section stands alone; stop anywhere and you
still have a complete idea. Specs with full detail: `capture-loop-spec.md` and
`integration-spec.md`. This doc is the mental model, not the spec.

---

## Chunk 1 — The one-sentence version

You write a note on your phone; Claude does the librarian work — filing the
keeper parts into your Obsidian vault and pushing the to-do parts into life-os —
so the second brain maintains itself instead of rotting like every past notes
system.

---

## Chunk 2 — Two separate worlds, connected one way

There are two systems, and keeping them separate is the load-bearing design
decision:

- **Claude projects** (`~/Documents/Claude/<x>/`) are where *work* happens —
  analysis, pipelines, code, checkpoints. Agent-driven, git-backed.
- **The Obsidian vault** (`~/Documents/Obsidian Vault/`) is where *durable
  personal reference* lives — the stuff future-you looks up. Human-browsed,
  organized by PARA, synced to your phone by Syncthing.

The connection is **one-way: projects point INTO the vault, never the reverse.**
Work artifacts never leak into the vault; vault notes never get buried inside
project folders. Three projects (Health, Career, Financial) now carry a small
"## Obsidian" pointer in their CHECKPOINT telling any future session where
their vault counterpart lives.

Why the vault is even reachable: it sits *outside* the workspace `.gitignore`,
so Claude's search tools work on it normally. That accident of placement is
what makes the whole thing real instead of aspirational.

---

## Chunk 3 — The idea we borrowed (Karpathy's "LLM wiki")

Karpathy's observation: personal wikis die from **bookkeeping** — filing,
linking, keeping things consistent — not from reading or thinking. Nobody quits
because reading their notes is hard; they quit because maintaining them is.
His fix: hand the bookkeeping to an LLM. "Obsidian is the IDE; the LLM is the
programmer; the wiki is the codebase."

Your stack already implemented about 70% of this before we started: PARA vault,
a `00 Inbox` capture folder your phone defaults into, Syncthing sync, and
Claude Code with file access. What was missing was the maintenance loop (the
librarian) and the bridge to life-os for action items — that bridge is your
extension beyond Karpathy's model. That's what we built.

---

## Chunk 4 — The layer model: who owns what

Three layers, one ownership rule each:

| Layer | Owner | Rule |
|---|---|---|
| Your raw notes (inbox captures, journal) | You | Claude reads, never rewrites |
| The organized vault (PARA files, links, tags) | Claude maintains, with your approval | Filed with dated headings, wikilinks, schema tags |
| The rulebook (vault `HOME.md`, tag schema, specs) | You | Claude follows it, never edits it without you |

`HOME.md` at the vault root is the rulebook's front page: a one-screen map of
every folder plus the 9 agent rules (dated headings; one-situation-per-file;
tags only from the schema; personal content never auto-filed; Writing & Journal
untouchable; sync-conflict files flagged not fixed; `status: pinned` means
hands off; processed notes archived never deleted; read the specific note,
never load whole folders).

---

## Chunk 5 — The capture loop, end to end

The daily-life flow the system exists for:

1. **You capture on the phone.** Any thought → a note in `00 Inbox/`. Offline,
   zero organizing effort. Syncthing carries it to the PC.
2. **You (or a schedule, later) say "process my inbox."** Claude sweeps the
   inbox, skipping pinned notes and sync-conflict files.
3. **Each note gets read chunk by chunk** — one note can contain a task, a
   keeper fact, and a vent all in five lines, and each piece is handled
   separately:
   - **Task** ("do X") → pushed into life-os.
   - **Keeper reference** → filed into the right PARA file with a dated heading.
   - **Personal** (journal, rage, medical detail) → flagged to you, never
     auto-filed.
   - **Junk / stale** → proposed for disposal; you decide.
4. **Nothing happens without you.** Claude shows one plain table — this chunk,
   this classification, this destination, this exact text — and you approve or
   reject line by line. (This is v1; trust is earned before anything automates.)
5. **Approved items execute; processed notes move to vault `Archive/`** so the
   inbox stays empty but the original always survives.
6. **You get a report:** what was swept, filed, pushed, skipped, and why.

---

## Chunk 6 — The plumbing choices worth remembering

- **Tasks go through `lifeos.py` directly, not the life-os MCP.** The MCP is a
  Claude *Desktop* extension — invisible to Claude Code — but it just shells to
  the same `lifeos.py` script anyway, so calling the script directly is the
  same engine with zero drift.
- **Dated headings are the spine.** Every filed entry reads
  `## <Title> — <YYYY-MM-DD>`, dated from when you *captured* it, so provenance
  survives consolidation.
- **`status: pinned` is your opt-out lever.** Put it in a note's frontmatter
  and the processor treats the note as furniture (e.g. a pinned
  command that deliberately lives in the inbox).
- **Tags come from `tag-schema.md` only** — the vocabulary was derived from
  your real historical usage; inventing new tags is forbidden.

---

## Chunk 7 — The /obsidian skill: one door, three rooms

Everything user-facing is one skill at `~/.claude/skills/obsidian/`:

- **Query** (default, read-only): "what was that reference detail?" from any project —
  Claude orients via `HOME.md`, finds the one note, answers with the path.
- **Capture**: "note this down" → a dated note dropped into `00 Inbox/`,
  verbatim, sorted later.
- **Process-inbox**: the full loop from Chunk 5.

---

## Chunk 8 — What exists today vs what's next

**Built and live (Phase 1):** vault `HOME.md` · the `/obsidian` skill · the
three CHECKPOINT pointers · the first process-inbox proposal (awaiting your
line-by-line approval).

**The growth ladder:**
- **v1 (now):** everything proposed, you approve every line, runs when you ask.
- **v2 (after a few clean passes):** the obviously-safe classes auto-file;
  personal and ambiguous still flagged.
- **v3 (the full Karpathy):** scheduled runs, an append-only ingest log, and a
  "lint" pass that hunts contradictions, orphans, and stale claims across the
  vault.

**Known unsolved problem:** phone reminders that fire without the PC on.
Best lead is the TaskNotes plugin (reads the `due:` frontmatter you already
use, does native Android push) — see `reminders-research.md`.
