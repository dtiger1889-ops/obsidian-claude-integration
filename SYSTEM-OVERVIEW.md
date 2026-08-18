---
created: 2026-07-02
updated: 2026-07-02
tags:
  - obsidian
  - meta
---
# The second-brain system — what we built and how it works

Written to be read in chunks. Each section stands alone; stop anywhere and you
still have a complete idea. Specs with full detail: `design/capture-loop-spec.md` and
`design/integration-spec.md`. This doc is the mental model, not the spec.

---

## Chunk 1 — The one-sentence version

You write a note on your phone; Claude does the librarian work — filing the
keeper parts into your Obsidian vault and turning the to-do parts into tracked
items — so the second brain maintains itself instead of rotting like every past
notes system.

> **Doc status.** This overview was written early and describes the shape
> correctly, but two things have since changed in ways worth knowing up front:
> action items now live in a Base *inside* the vault rather than being pushed
> out to a separate task tool ([vault-bases.md](design/vault-bases.md)), and approval
> happens in a staging table rather than an in-chat list
> ([approval-staging.md](design/approval-staging.md)). Both are flagged inline below.

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
project folders. Any project with a vault counterpart carries a small
"## Obsidian" pointer in its checkpoint file telling a future session where
those notes live.

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
librarian) and the bridge that turns captured to-dos into tracked action items —
that bridge is the extension beyond Karpathy's model. That's what we built.

Full sourcing — including the packaged version of this exact pattern that
already existed, and the graph+vector stack that was evaluated and declined —
is in [prior-art.md](design/prior-art.md).

---

## Chunk 4 — The layer model: who owns what

Three layers, one ownership rule each:

| Layer | Owner | Rule |
|---|---|---|
| Your raw notes (inbox captures, journal) | You | Claude reads, never rewrites |
| The organized vault (PARA files, links, tags) | Claude maintains, with your approval | Filed with dated headings, wikilinks, schema tags |
| The rulebook (vault `HOME.md`, tag schema, specs) | You | Claude follows it, never edits it without you |

`HOME.md` at the vault root is the rulebook's front page: a one-screen map of
every folder plus the numbered agent rules (dated headings; one-situation-per-file;
tags only from the schema; personal content never auto-filed; file into the
personal folder but never consolidate within it; sync conflicts resolved when
obvious; `status: pinned` means hands off; processed notes archived never
deleted; read the specific note, never load whole folders; how flagged notes get
routed; where action items go; what gets staged for approval).

It started at 9 rules and is now 12. A full depersonalized copy, with notes on
which wordings turned out to be load-bearing, is in
[HOME.example.md](design/HOME.example.md).

---

## Chunk 5 — The capture loop, end to end

The daily-life flow the system exists for:

1. **You capture on the phone.** Any thought → a note in `00 Inbox/`. Offline,
   zero organizing effort. Syncthing carries it to the PC. *(Added later: web
   pages come in the same way, via the official browser clipper, which drops
   markdown into its own `Clippings/` folder. The sweep reads both folders —
   the capture tool keeps its default and the processor learns the folder, never
   the other way round.)*
2. **You (or a schedule, later) say "process my inbox."** Claude sweeps the
   inbox, skipping pinned notes and sync-conflict files.
3. **Each note gets read chunk by chunk** — one note can contain a task, a
   keeper fact, and a vent all in five lines, and each piece is handled
   separately:
   - **Task** ("do X") → becomes an item note in the task index. *(Updated: the
     original design pushed these out to a separate task tool. They now live in
     a Base inside the vault, next to the notes that explain them — see
     [vault-bases.md](design/vault-bases.md).)*
   - **Keeper reference** → filed into the right PARA file with a dated heading.
   - **Personal** (journal, venting, medical detail) → flagged to you, never
     auto-filed.
   - **Junk / stale** → proposed for disposal; you decide.
4. **Ambiguous things wait for you.** *(Updated: v1 printed one chat table and
   asked for line-by-line approval. That only works while you're sitting in the
   session, so it was replaced by a staging table inside the vault — checkboxes
   you tick on your phone whenever. Project work no longer gets asked about at
   all. See [approval-staging.md](design/approval-staging.md).)*
5. **Approved items execute; processed notes move to vault `Archive/`** so the
   inbox stays empty but the original always survives.
6. **You get a report:** what was swept, filed, staged, skipped, and why.

---

## Chunk 6 — The plumbing choices worth remembering

- **Dated headings are the spine.** Every filed entry reads
  `## <Title> — <YYYY-MM-DD>`, dated from when you *captured* it, so provenance
  survives consolidation.
- **`status: pinned` is your opt-out lever.** Put it in a note's frontmatter
  and the processor treats the note as furniture (e.g. a pinned
  command that deliberately lives in the inbox).
- **Tags come from one schema file only** — a single list of allowed tags with
  one-line semantics, derived from your own historical usage. Inventing new tags
  is forbidden; untagged beats force-fit.

---

## Chunk 7 — The /obsidian skill: one door, four rooms

Everything user-facing is one skill:

- **Query** (default, read-only): "what was that reference detail?" from any project —
  Claude orients via `HOME.md`, finds the one note, answers with the path.
- **Capture**: "note this down" → a dated note dropped into `00 Inbox/`,
  verbatim, sorted later.
- **Process-inbox**: the full loop from Chunk 5.
- **Sprint-notes** (added later): you type instructions into the `note` column
  of the task table across ten rows in one sitting, then say "act on my sprint
  notes" and hand over the whole batch. Claude answers in a `reply` column and
  clears each note as it goes. Four lines of YAML; the highest-leverage piece of
  the system. See [vault-bases.md](design/vault-bases.md).

The skill's behavior lives in one platform-agnostic file that each runtime's
adapter reads at runtime, so the same modes work from the CLI and from the
desktop app without maintaining two copies —
[cowork-deployment-lessons.md](operations/cowork-deployment-lessons.md).

---

## Chunk 8 — What exists today vs what's next

**Built and live:** vault `HOME.md` · the `/obsidian` skill in two runtimes ·
the vault pointer in every project that has one · the inbox sweep, over both the
typed-capture folder and the web-clipper folder · four Bases (task index, to-do
net, approval queue, idea triage) · the human↔agent message channel · the
append-only approval ledger · a report-only link auditor run after any bulk
restructure.

**The growth ladder, and where it actually went:**
- **v1 (as designed):** everything proposed, you approve every line, runs when
  you ask.
- **v2 (what happened instead):** the ladder turned out not to be a trust
  gradient but a *lane split*. Rather than auto-filing "obviously safe classes"
  after a few clean passes, project work stopped being asked about at all
  (its destination isn't a judgment call), while everything else kept a full
  gate — now a table in the vault instead of a chat prompt. Trust got spent
  where ambiguity was low, not where the history was long.
- **v3 (the full Karpathy):** scheduled runs, and a "lint" pass that hunts
  contradictions, orphans, and stale claims across the vault. Not built.

**Measured, not assumed:** the staging gate records what Claude proposed *and*
where things actually went, in an append-only ledger outside the vault. First 14
resolved items: a 57% override rate, half of which turned out to be a
formatting failure rather than a filing disagreement. Fixing the format cut it
to 8% over the next 12.
[approval-staging.md](design/approval-staging.md) has both passes.

**The maintenance you don't see coming:** in a synced, plugin-heavy vault the
interesting failures are silent — archived notes breaking inbound links (and
spawning junk notes when someone clicks one), a linter rewriting `updated`
whenever you *open* a note, a plugin setting that turns out to be per-device and
absent from the synced config, a sync conflict resolving toward the stale copy.
All of them, with mechanisms and fixes:
[vault-maintenance.md](operations/vault-maintenance.md).

**The tax nobody budgets for:** the files an agent must read before it can act.
That set hit 43 KB here, paid by every session, and silently lost its tail on a
runtime with an output cap. Cutting it 20% without changing behavior:
[context-budget.md](operations/context-budget.md).

**Known unsolved problem:** phone reminders that fire without the PC on.
Best lead is the TaskNotes plugin (reads the `due:` frontmatter you already
use, does native Android push) — the full option comparison, including the
Google Calendar path that looked viable and wasn't, is in
[prior-art.md](design/prior-art.md).
