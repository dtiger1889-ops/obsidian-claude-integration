# Getting out of Google Keep: a 600-note migration

The vault this system runs on didn't start as a vault. It started as ~600 Google
Keep notes accumulated over roughly a decade — the usual mix of genuinely useful
reference, dead one-off tasks, and things that meant something once.

This is what the migration actually took, including the parts that went wrong.
The rubric at the bottom is the reusable part.

---

## Step 0 — Get the data out with its dates intact

Google Takeout exports Keep as one JSON file per note. Importing those into
Obsidian with an off-the-shelf importer produced ~592 markdown files with **no
frontmatter at all** — the importer dropped `createdTimestampUsec` and
`userEditedTimestampUsec`, which are the two fields that make the archive worth
anything.

Without creation dates you cannot tell a live reference note from a dead one.
Everything looks like it was written today, because the OS modification time *is*
today (the import date). **Fix this before you triage anything**, not after.

A ~100-line script re-attached them: read each Takeout JSON, divide the
microsecond timestamps by 1000, write YAML frontmatter to the matching `.md`.

```yaml
---
created: 2023-08-18T01:13:44
updated: 2023-08-18T01:53:44
---
```

Three things that script needed, and any version of it will:

- **Idempotence.** Skip any file already starting with `---`, so a re-run is
  free and a partial run is recoverable.
- **A `--dry-run` flag.** The dry run is what tells you your filename matching
  actually works before you write 592 files.
- **A multi-tier filename resolver.** Takeout and Obsidian disagree about
  special characters — `/` becomes `_` in one and `-` in the other, apostrophes
  are stripped by one and kept by the other, and titled notes pick up a trailing
  underscore. Resolve in order: exact stem → trailing-underscore variant → fuzzy
  title lookup.

Expect a gap between the two counts (616 JSON vs 592 markdown here). Trashed and
image-only notes don't come across. Confirm the gap is the boring explanation,
then move on.

**Keep the Takeout folder.** For the entire migration it is your backstop: any
delete is recoverable from it, which is what makes it safe to be decisive later.

---

## Step 1 — Sort by utility, not by tag

The first attempt at a rubric sorted notes by their existing Keep tags. It was
worthless, because Keep tags describe what a note is *about*, and the question
that matters is what a note is *good for*.

The rubric that worked asks one question per note: **"what is this good for?"**

| Bucket | Meaning |
|---|---|
| **KEEP** | Useful today or going forward. Gets consolidated into a clean, typed file. |
| **ARCHIVE** | A past incident you might genuinely need to review later. Last resort; keep this bucket tiny. |
| **DELETE** | Everything else: empties, fragments, dead links, finished tasks, spent context. |

Two rules make it work:

- **Age is a prior, content decides.** Older notes are much more likely to be
  worthless, but you don't get to skip reading them. Sorting by metadata is what
  produced the unusable first pass.
- **Read the note before you propose a disposition for it.** This sounds
  obvious. It is the single rule that gets broken most, because classifying 400
  notes by tag takes minutes and reading them takes hours.

A timeline document — when you moved, when you changed jobs, when you graduated,
when your insurance changed — pays for itself immediately. Nearly every
staleness call reduces to "was this before or after X?", and an agent that
doesn't have your timeline will ask you the same question forty times.

## Step 2 — Route things that don't belong in a vault at all

A meaningful slice of the notes were not vault material:

- **People and contacts** belong in whatever contact system you actually use.
  The rule that saved data here: *verify presence in the destination system
  before deleting the note.* Present → the note is redundant, delete it. Absent
  → add it there first, then delete.
- **Task-shaped notes** belong in your task system, not as reference files.
- **Active project material** belongs in that project's own workspace, not in
  the reference vault. An active job search lives in the job-search project; the
  reusable interview-prep material is what goes in the vault.

## Step 3 — Consolidate with dates, atomically

Two rules, both learned the hard way (see the failures below).

**Dated provenance is mandatory.** Every consolidated entry keeps its source
note's title and creation date as its heading:

```markdown
## Grocery run checklist — 2021-04-02

<the original body, verbatim>
```

Never collapse notes into synthesized thematic prose. The date is the spine —
it's what carries staleness, timeline, and trust. Prose that reads better and
drops the dates has destroyed the thing you were migrating for.

**Atomic by default.** Only consolidate same-*type* reference facts. Discrete
units — ideas, individual logs, standalone lists — each keep their own note.
Merging them makes the folder look tidier and makes the contents worse.

**Organize by retrieval context, not theme** (why / when / what / who). A file
should answer ONE situation: when would I open this, what for, who for. Notes
that share a tag but get used in different moments belong in separate files —
"going out" and "volunteering" are both `local` notes and are never opened for
the same reason. Split, don't cram, and don't hedge on "borderline": if the
situation differs, it's two files.

---

## What went wrong (the useful part)

Every one of these is now a standing rule.

**Dropped the dates.** Mid-migration, several categories got consolidated into
clean thematic prose with the creation dates stripped. It read beautifully and
destroyed the project's whole point. Had to be rebuilt from originals — which
only worked because nothing had been hard-deleted. This is why the format rule
above is written in capital letters in the source docs.

**Over-merged to look tidy.** Ideas, packing lists, and a set of medical notes
got merged into single documents because a shorter file list feels like
progress. The correction — atomic by default — had to be applied retroactively,
splitting them back out.

**Junk-drawer files.** Two consolidated documents ("Home & General Info", "Tech
notes") turned out to be theme-shaped, not type-shaped: home-maintenance specs
sitting next to clothing sizes, passwords sitting next to PC repair history.
Both were split
into four and five real files respectively. Vague themes are how junk drawers
get built.

**Silent under-collection.** The rebuilt reference documents were assembled from
an earlier flat-file subset rather than from the live folder. Notes carrying the
same tags but never folded into those flat files were silently missed — six
here, eleven there, including an entire directory of information nobody noticed
was gone. The fix: **histogram the live folder and collect from the full tag
set**, never from a previous pass's output. Anything derived from a derived list
inherits its omissions invisibly.

**Assumed instead of verifying.** A contact got mis-identified from memory
rather than checked against the contact system, and a "no auth token exists"
conclusion was drawn from an empty config file while the plugin was visibly
working — the token was in browser local storage the whole time. **Trust
functional evidence over a file that seems to say otherwise.** If the thing is
demonstrably working, your model of why it shouldn't be is what's wrong.

**Cryptic delete lists.** Early proposals listed filenames only. Nobody can
approve the deletion of forty notes they can't remember. Proposals need enough
of each note's content to be evaluable, or the human just says "no" to all of
them and the migration stalls.

---

## The numbers

| | |
|---|---|
| Takeout JSON files exported | 616 |
| Markdown notes imported | 592 |
| Notes facing triage at the start | 434 |
| Notes left in the import folder at the end | 0 |
| Originals preserved in `.trash` (recoverable) | 397 |

The import folder came down in four sessions — 434 → 305 → 153 → 106 → 0 — over
about ten days. Everything that left is either a consolidated entry in a
reference file, an atomic note somewhere in the tree, a record in another system,
or a recoverable original in `.trash` with the Takeout export behind it.

The bottleneck was never the mechanics. It was reading 400 notes and making a
call on each one.

---

## If you're about to do this

1. **Patch the dates first.** Everything downstream depends on them.
2. **Keep the raw export until you're done.** Being able to undo any delete is
   what lets you be decisive, and being decisive is the only way to finish.
3. **Delete to a trash folder, never permanently, and only with explicit
   per-batch approval.** Two recoverable layers beats a careful agent.
4. **Write the timeline document before the triage**, not during.
5. **Consolidate by type, not by theme; keep the dates; keep atomic things
   atomic.**
6. **Do the last mile.** The migration's value shows up when the import folder
   hits zero. A folder sitting at "153 remaining" is not a migration, it's a
   second inbox.

The end state isn't a tidy vault. It's a vault you *trust* — where a note's date
means something, where nothing was silently dropped, and where you know what
happened to everything that isn't there anymore.

---

## Where this leads

A migrated vault decays back into a junk drawer within months unless something
maintains it. That maintenance loop is the rest of this repo:
[SYSTEM-OVERVIEW.md](../SYSTEM-OVERVIEW.md) for the model,
[capture-loop-spec.md](../design/capture-loop-spec.md) for the pipeline,
[approval-staging.md](../design/approval-staging.md) for the gate that keeps the agent's
writes reviewable.
