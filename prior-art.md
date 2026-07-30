# Prior art: what this was built on, and what was rejected

Almost nothing here is original. The parts that work are borrowed, and the most
useful decisions were about what *not* to build. This is the sourcing — what
each idea came from, what got adopted, and what got evaluated and declined with
the reason.

The standing rule that produced this page: **before designing anything, sweep
for what has already been shipped for the same problem** — repos, published
skills, community writeups — and default to adopting or adapting with a
citation. Greenfield needs a stated reason. This gets skipped constantly,
because researching *how to do X* feels like research while checking *who
already did X* feels like admitting you're not first.

---

## The north star

**Andrej Karpathy's "LLM wiki."** The load-bearing observation: personal wikis
die from **bookkeeping** — filing, linking, keeping things consistent — not from
reading or thinking. Nobody quits because reading their notes is hard; they quit
because maintaining them is. The fix is to hand the bookkeeping to an LLM.

- [Karpathy's LLM-wiki gist](https://gist.github.com/karpathy/442a6bf555914893e9891c11519de94f)
  — the original write-up, and the scale data point that mattered most here: it
  ran at roughly 400k words on plain markdown with **zero retrieval
  infrastructure**.
- [natural20 guide: using Claude Code to set up a second brain](https://natural20.com/using-claude-code-to-setup-a-second-brain-aka-llm-wiki)
  — the plain-markdown pattern as an afternoon's setup. Notably does *not* use a
  vector or graph database.
- [ar9av/obsidian-wiki](https://github.com/ar9av/obsidian-wiki) — the same
  pattern already packaged as `/wiki-update` and `/wiki-query` skills. Found
  *after* this system was underway, which is the argument for doing the sweep
  first. If you want this shape and don't care about the extras below, start
  here rather than with this repo.

**What this system adds beyond Karpathy's model:** the action-item lane. Karpathy's
wiki is a reference system; captures here routinely contain to-dos, so the
pipeline splits each note per chunk and routes the actionable parts into a
tracked index ([vault-bases.md](vault-bases.md)). That bridge is the extension,
and it's where most of the design work went.

## The organizing scheme

**PARA** — Projects / Areas / Resources / Archive.
[Tiago Forte, *The PARA Method*](https://fortelabs.com/blog/para/). Adopted
essentially unmodified, with one addition: a top-level `Writing & Journal/`
folder, because personal writing is a large share of the corpus and needed
rules an agent could not apply to reference material (see rule 5 in
[HOME.example.md](HOME.example.md)).

The reason PARA survives contact with an agent: it sorts by **actionability**,
which is a question an agent can be given a rule for, rather than by topic,
which requires taste it doesn't have.

## The surface

**Obsidian Bases** — a core plugin since 1.9 that renders notes as filterable,
inline-editable tables driven by their frontmatter.

- [Introduction to Bases](https://obsidian.md/help/bases) ·
  [Bases syntax](https://obsidian.md/help/bases/syntax) ·
  [Functions](https://obsidian.md/help/bases/functions)

This is what made an in-vault task index viable at all. Before Bases, the
options were a markdown list (unqueryable, merge-conflicts on every phone sync)
or Dataview (read-only rendering, second syntax to learn, plugin drift). Being
*core* matters for something the whole system leans on.

---

## Evaluated and rejected

### The graph + vector stack

A widely-shared setup pairs the coding harness with
[Graphiti](https://github.com/getzep/graphiti) (a temporal knowledge graph) and
[Qdrant](https://qdrant.tech/documentation/quickstart/) (a vector DB) alongside
Obsidian, kept coherent by a periodic automated audit loop. It comes from
someone tracking dozens of concurrent initiatives and ~150 people, and for that
load it may well be right.
([source thread](https://www.reddit.com/r/ClaudeAI/comments/1uwrxbo/claude_code_and_obsidian_as_an_aimaintained/))

**Declined, for four reasons:**

1. **The scale math says no.** This vault is ~700 notes / ~149k words. Karpathy's
   ran ~400k words with no retrieval infrastructure at all. The only concrete
   breakdown threshold anyone publishes for plain-markdown-plus-agent is "several
   hundred pages." Building retrieval infrastructure at a quarter of the known
   working scale is solving a problem you don't have yet.
2. **The industry moved away from the vector half.** Anthropic removed vector
   search from Claude Code itself and replaced it with grep, reporting that grep
   outperformed the alternatives by a wide margin; an AAAI 2026 Amazon paper
   found agentic keyword search reaching >90% of RAG performance with no vector
   store at all
   ([*Keyword Search Is All You Need*](https://www.amazon.science/publications/keyword-search-is-all-you-need-achieving-rag-level-performance-without-vector-databases-using-agentic-tool-use)).
   A vector DB over a personal markdown vault solves a problem the agent's grep
   already solves, and adds an embedding pipeline you must keep in sync forever.
3. **The graph half is real infrastructure with an unpublished bill.** Neo4j or
   FalkorDB to run and back up permanently, plus LLM and embedding calls on
   *every* ingestion, with cost scaling as the graph grows. No per-episode cost
   figures published.
4. **The audit loop's own inventor wouldn't point it here.** The pattern is
   Geoffrey Huntley's [Ralph loop](https://ghuntley.com/ralph/), and Huntley is
   explicit that it's a greenfield-generation technique he wouldn't run against
   an existing codebase. An unattended loop editing an existing knowledge base
   has an obvious failure mode: a bad edit in iteration N becomes ground truth
   for iteration N+1, with no human gate.

**What was stolen from it anyway:** the *kernel* of that audit loop — "read the
tracking file, find one inconsistency or stale claim, fix it, log it" — is
genuinely good and needs no new infrastructure. It becomes an occasional
maintenance-mode sweep run **attended**, where you see the diffs. Not a cron.

**The two triggers that would reopen the decision**, written down so the choice
can be revisited on evidence rather than vibes: (a) the vault grows past several
hundred substantial pages *and* grep-based recall visibly starts missing things,
or (b) a recurring need appears for point-in-time queries ("what was X *as of*
March?") that dated changelog entries can't answer quickly.

### Agent write-access via the REST API

The [Obsidian Local REST API](https://github.com/coddingtonbear/obsidian-local-rest-api)
plugin (~2.6k stars) has shipped a built-in MCP server since v4.0, exposing
`vault_read` / `vault_patch` / `search_query` as *tools*. That's the clean
option if you want an agent writing to a vault without holding a writable file
handle.

Not adopted here only because direct filesystem access already worked and adding
a running local service is a maintenance cost. It's the right answer for anyone
whose agent can't reach the vault directly — and it removes a whole class of
"the agent clobbered the file while Obsidian had it open" problems.

### Symlinking project docs into repos

The dominant shipped pattern for "agents should read my notes about this
project" is a **narrow per-project symlink**: each repo gets a `docs/notes`
symlink pointing at that project's folder in the vault, with the vault as the
single source of truth
([writeup](https://understandingdata.com/posts/symlinked-project-docs-for-agents/)).

Rejected in favor of plain pointers — a line in each project's checkpoint saying
where its vault notes live — because the vault already sits outside the
workspace's ignore rules and is directly readable. The symlink buys nothing when
the agent can already read the path, and Windows symlinks need Developer Mode
while sync tools and git handle them inconsistently.

Related and worth reading before you reach for a symlink in any agent context:
the [thin-adapter refutation](cowork-deployment-lessons.md) of the same instinct
in a different setting.

---

## Plugin evaluations

These were real comparisons against a specific requirement, and the write-ups
are more useful than the verdicts — the requirement is what makes a verdict
transferable.

### Phone notifications from frontmatter (still unsolved)

The requirement: reminders authored in Obsidian on a phone that fire **without a
PC being on**, reading the `due` property already in the frontmatter.

| Option | Reads `due` frontmatter | Android push | Location | Cost |
|---|---|---|---|---|
| [TaskForge + TaskNotes](https://taskforge.md/tasknotes/) | yes | yes | no | free + premium |
| [obsidian-reminder](https://github.com/uphy/obsidian-reminder) | no (inline emoji only) | no (in-app popup) | no | free |
| [Notifian](https://play.google.com/store/apps/details?id=com.notifian) | unclear | yes | no | free + premium |
| [Notelert](https://forum.obsidian.md/t/notelert-native-android-notification-and-reminders-for-obsidian/109310) | no | yes | **yes** (premium) | freemium |
| [Map View](https://github.com/esm7/obsidian-map-view) | n/a | n/a | tagging/visualization only | free |

Best match for due dates is TaskNotes (native frontmatter `due`, no format
migration). Location-based has exactly one option, it's paid, and it doesn't read
frontmatter. **Nothing does both.**

A path that looked obvious and failed: a Google Calendar sync plugin. Desktop
event creation → calendar → phone ping worked end to end, then the requirement
died on two facts found in the plugin's source — the refresh token lives in
per-device browser local storage (so it doesn't sync), and the plugin explicitly
blocks custom-client OAuth on mobile. **Read the source before declaring an
integration path viable**; the demo working on your desktop proves nothing about
the phone.

### Reusable checklists that behave like Google Keep

The requirement, stated precisely: uncheck **one** item and it returns to the top
of the active list — granular, no destructive "reset the whole document" button.

- [Automatic Shopping List Reorder](https://community.obsidian.md/plugins/shopping-list-automatic-reorder)
  — **adopted.** Check → drops down; uncheck → returns to the active list.
  Exactly the requirement.
- [Auto Sort Checked Items](https://community.obsidian.md/plugins/auto-sort-checked-items)
  — same behavior, applied vault-wide rather than scoped.
- [Checkbox Reorder](https://www.obsidianstats.com/plugins/checkbox-reorder) —
  considered.
- [CheckSorted](https://community.obsidian.md/plugins/checksorted)
  ([source](https://github.com/Esmaeelpour/obsidian-checksorted)) — matches a
  *further* requirement (typing into a new box reactivates the matching completed
  item instead of duplicating it), but ships its own competing completed-item
  mover with no documented scope gate. Under evaluation in a disposable vault
  before it goes anywhere near the real one.
- [Text Autocomplete](https://community.obsidian.md/plugins/text-autocomplete) —
  rejected: desktop-only, and inserts words rather than reactivating rows.

Two transferable lessons. **Scope gates are the whole game**: the adopted plugin
only activates on notes carrying `shopping-list: true` in frontmatter, which is
why it can coexist with everything else — and why it appeared broken for two
weeks until the marker was added to the actual notes. And **check mobile
compatibility first** when the use case happens away from a desk; a plugin that
solves your problem only on the desktop hasn't solved your problem.

---

## Sources

**Pattern and method**
- [Karpathy — LLM wiki gist](https://gist.github.com/karpathy/442a6bf555914893e9891c11519de94f)
- [natural20 — Claude Code second brain / LLM wiki](https://natural20.com/using-claude-code-to-setup-a-second-brain-aka-llm-wiki)
- [ar9av/obsidian-wiki](https://github.com/ar9av/obsidian-wiki)
- [Tiago Forte — The PARA Method](https://fortelabs.com/blog/para/)
- [Obsidian Bases documentation](https://obsidian.md/help/bases)

**Evaluated, declined**
- [Graphiti](https://github.com/getzep/graphiti) · [Qdrant](https://qdrant.tech/documentation/quickstart/) · [Ralph loop (Huntley)](https://ghuntley.com/ralph/)
- [Source thread for the combined stack](https://www.reddit.com/r/ClaudeAI/comments/1uwrxbo/claude_code_and_obsidian_as_an_aimaintained/)
- [Amazon Science, AAAI 2026 — *Keyword Search Is All You Need*](https://www.amazon.science/publications/keyword-search-is-all-you-need-achieving-rag-level-performance-without-vector-databases-using-agentic-tool-use)
- [Obsidian Local REST API (+MCP server)](https://github.com/coddingtonbear/obsidian-local-rest-api)
- [Symlinked project docs for agents](https://understandingdata.com/posts/symlinked-project-docs-for-agents/)

**Plugin comparisons**
- Notifications: [TaskForge/TaskNotes](https://taskforge.md/tasknotes/) · [obsidian-reminder](https://github.com/uphy/obsidian-reminder) · [Notifian](https://play.google.com/store/apps/details?id=com.notifian) · [Notelert](https://forum.obsidian.md/t/notelert-native-android-notification-and-reminders-for-obsidian/109310) · [Map View](https://github.com/esm7/obsidian-map-view)
- Checklists: [Automatic Shopping List Reorder](https://community.obsidian.md/plugins/shopping-list-automatic-reorder) · [Auto Sort Checked Items](https://community.obsidian.md/plugins/auto-sort-checked-items) · [CheckSorted](https://github.com/Esmaeelpour/obsidian-checksorted) · [Checkbox Reorder](https://www.obsidianstats.com/plugins/checkbox-reorder) · [Text Autocomplete](https://community.obsidian.md/plugins/text-autocomplete)

Link rot is real and some of these were evaluated at a point in time — the
versions, star counts, and pricing tiers above were accurate when checked
between June and July 2026, not necessarily now. Re-verify before relying on a
specific claim.
