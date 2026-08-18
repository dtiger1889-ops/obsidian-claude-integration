# Rules that stuck

Every rule below is load-bearing in a system that's been running daily since
mid-2026. Each one exists because something specific went wrong. They are
grouped by what they protect, and each says what it cost — a rule without a
story attached is a rule nobody follows.

The ones marked **★** are the ones I'd port to any agent-maintained system,
notes or otherwise.

---

## Filing and organizing

### ★ Dated provenance, always

Every consolidated entry keeps its source title and creation date:
`## <Title> — <YYYY-MM-DD>`. Never synthesized thematic prose that drops dates.

**Cost:** a mid-migration pass consolidated several categories into genuinely
better-reading prose with the dates stripped. It destroyed the only signal that
distinguishes a live reference from a decade-old one, and had to be rebuilt from
originals. The date is the spine of a personal archive — staleness, timeline,
trust all hang off it. An agent optimizing for readable output will drop it
every time unless told not to.

### ★ One situation per file (why / when / what / who)

A file answers ONE retrieval situation. Notes sharing a tag but used in
different moments go in separate files. Split, don't cram, and don't hedge on
"borderline" — if the situation differs, it's two files.

**Cost:** two junk-drawer documents. One held home-maintenance specs next to
clothing sizes; the other held passwords next to PC repair history. Both were
"organized" by a vague theme. Split into four and five real files. The test that
works isn't "are these related?" — everything is related to something. It's
"would I ever open this file looking for both of these?"

### Atomic by default

Consolidate only same-*type* reference facts. Discrete units — ideas, logs,
individual lists — each keep their own note.

**Cost:** ideas, packing lists, and a set of medical notes got merged because a
shorter file list feels like progress. It isn't; it's information loss that
looks like tidiness. Agents default hard toward merging. Say "atomic by default"
explicitly or you'll get a tidy vault with the distinctions sanded off.

### ★ Collect from the source, never from a previous pass's output

When rebuilding a consolidated document, enumerate the live folder. Never
assemble from an earlier flat file.

**Cost:** the rebuilt reference documents were assembled from an earlier pass's
subset. Notes carrying the same tags that had never made it into that subset
were silently missed — six here, eleven there. **Anything derived from a derived
list inherits its omissions invisibly**, and the failure produces no error, no
warning, and a plausible-looking result. This one generalizes well past notes.

### ★ File by function, not by topic

Where a note lives is decided by **what you do with it**, not by what it is
about. A note you actively maintain belongs with your other maintained
life-domain notes; a note you look things up in belongs in reference.

**Cost:** a credentials-and-keys note filed by topic into the technical
reference folder, because it is "about" technology. It is not a reference — it
is a thing the human edits whenever an account changes, and reference is where
he goes to *read*. Same failure in the other direction: a checklist that had
stopped being used got left in the active-lists folder for months because its
subject hadn't changed. **The question that sorts correctly is "what will I be
doing when I open this?"** — not "what is this about?"

### Archive the origin note when it is spent

A note that generated tasks is done when its tasks are done. It does not stay in
the working folder as evidence.

**Cost:** a note whose follow-ups had all closed sat in an active project folder
for ten days, reading like live work every time anyone scanned the folder. The
cost of a spent note in a live folder isn't storage, it's that it makes the
folder untrustworthy at a glance — which is the only way anyone reads a folder.

### Archiving is a link operation, not a move

Moving a note into an excluded archive folder breaks every `[[link]]` pointing
at it, and in this app a broken link **creates an empty note when clicked**.
Sever inbound links at archive time; never re-point a live note into the
archive.

**Cost:** weeks of mystery empty notes appearing in the vault, blamed on
everything from sync to the graph view. Eleven live-to-archive entanglements
across eight files, one of them regenerated on a schedule by a script that had
to be fixed too. Full mechanism and the rejected alternatives:
[vault-maintenance.md](../operations/vault-maintenance.md).

### Tags come from a fixed schema; never invent one

A single file lists allowed tags with one-line semantics. Leave a note untagged
rather than force-fit.

**Cost:** low, because the rule went in early — which is the point. An agent
inventing tags produces a vocabulary that looks organized and is unsearchable,
because nothing is tagged consistently enough to filter on.

### ★ Capture lands wherever the capture tool wants; the sweep learns the folder

When a capture tool has its own opinion about where things land, take its
default and teach the processor to sweep that folder too. Do not add a move step
to the human's capture path.

**Cost:** avoided, after three tools were trialled for getting web pages off a
phone and into the vault. The winner was a browser extension that clips the
*rendered* page — which sidesteps every bot wall, because it never re-fetches
the URL — and it drops clips into its own folder, not the inbox. The tempting fix
is to make it land in the inbox. The right fix was one line in the sweep step:
enumerate both folders. **Every extra tap between a thought and a saved note is a
tap where the capture stops happening**, and the whole system is worthless if
capture is annoying.

Runner-up lesson from the same trial: print-to-PDF is the fallback lane, not the
pipeline. It loses structure, and one browser's print path drops comment
authorship entirely — so the archive you build is missing the thing you would
have wanted from it.

---

## What the agent is allowed to touch

### ★ Log, don't run

"Add X to project Y" means *record* X where project Y's own session will find
it: the value in that project's files, an item in its checkpoint, the remaining
steps on its note, an entry in the task index. Execution belongs to that
project's own session.

**Cost:** the loudest incident in the system's history. A captured note said to
add an API key to a price-watcher project. That got read as trivial: the key was
wired inline into a tracked script, the data source was enabled, and the poller
ran, ingesting several thousand rows nobody had asked for. An inbox sweep should
never operate another system's live machinery — it has none of that system's
context, and its safety rails are the wrong ones.

### ★ Personal content is never auto-filed

Journal, venting, relationship, and personal-medical material gets flagged with
a suggestion and left alone.

**Cost:** none yet, deliberately. This is the rule that makes the rest of the
system acceptable to run at all. But the *wording* cost something — see the next
one.

### File INTO the personal folder, never consolidate WITHIN it

The original wording was "agents: hands-off." Agents read that as a blanket ban
and began *refusing to file* new writing that belonged there. The folder became
write-only for the human, and captures piled up in the inbox with nowhere to go.

**Cost:** weeks of a quietly broken lane. The fix draws the line at the
operation, not the folder: **creating a new file there is safe; editing an
existing one is not.** If you write a hands-off rule, name the banned operation
precisely, or the agent will generalize it to "don't touch" and you'll never
find out.

### No unsolicited deletes; deletes go to trash, per-batch approved

**Cost:** a separate incident elsewhere in the same setup, severe enough that
the rule is now enforced by a deny-list rather than by good intentions. The related
discipline that matters here: **never derive a delete target from a glob, a
find, or a variable.** The target is a literal path a human named.

### Resolve the obvious sync conflicts; flag only real merges

Diff the conflict copy against the live file. Pure stale subset → delete the
copy. Live file missing → restore the copy to the live name. Only a genuine
two-sided merge gets escalated.

**Cost:** the original posture was flag-everything, which produced a growing
pile of `*.sync-conflict-*` files the human had to hand-adjudicate. Most were
trivially resolvable. The upgrade also caught a real save: one conflict copy
carried an instruction that had lost the sync race, and the "live" file it
looked stale against had actually vanished. **Diff before you discard —
sometimes the conflict copy is the one with the content.**

---

## How work gets tracked

### ★ Completed items are deleted, not marked done

The task index is a live to-do, not a log. The completion record goes in the
linked note or the project checkpoint — written *first*, then the item is
deleted.

**Cost:** avoided rather than paid. Every "done" checkbox system in this
person's history filled with completed items until the list stopped being
looked at. If the record of what you finished matters, it belongs somewhere
that's built for records.

### ★ Partition by who can act, not by priority

The split that mattered was two views: **my queue** and **the agent's plate**.
Not urgent/normal, not P1/P2.

**Cost:** the priority field. It exists, and it is blank on nearly every item,
because it requires a human to make a comparative judgment at capture time and
nobody does that. "Who can even do this" is answerable instantly and never
decays.

Corollary: **assigned ≠ delegable.** An item that *could* be handed to the agent
but needs a human's green light stays in the human's queue, with the green-light
ask written once. Otherwise the agent's plate fills with things it will pick up
and immediately get stuck on.

### ★ Never add a field a human has to hand-populate

Every signal in the index is agent-stamped or computed.

**Cost:** see the priority field above. This is the single most reliable
predictor of whether a tracking system survives contact with real life.

### ★ Questions go where the human actually looks

A vault-organization question goes in the review queue the human opens on their
phone — never into a project checkpoint file they've said they don't read.

**Cost:** a whole class of questions that were dutifully recorded and never
answered, because they were parked in a file with one reader who wasn't the
human. **A question in a place the human doesn't open is not a question, it's a
note to yourself.**

### ★ The default view IS the interface

Any state the agent can set must be visible in the view the human actually
opens. Adding a *new* view for a new state is not a fix.

**Cost:** two items were normalized from a contradictory state into a clean
"held" state — correct bookkeeping, and both notes were untouched on disk. The
review table's default view filtered for "in review" only, so both items
vanished from the human's queue. From his side that is indistinguishable from
the agent deleting his stuff. The first repair added a separate "Held" tab,
which did nothing, because he opens the default view and always will.
**A state nobody can see is worse than no state**: it converts a tracked item
into a lost one while the record looks perfect.

### An open item needs work that is OWED

Before recording something as an open thread, check the artifact's real state on
disk, then ask: what does someone have to *do*? No answer → no thread.

**Cost:** one session generated six open threads that were all noise: three
named files that had already been deleted or archived, one described files
sitting in a way-station folder (which is what a way station is *for*), and two
restated items that were already live in a review queue. Three failure shapes
worth naming: **already closed**, **normal state of a way station**, and
**already tracked by another surface**.

### Table what you structurally cannot do

Auth flows, physical devices, UI-only clicks: say so and move on. One cheap
probe to confirm it's really blocked is fine; a retry ladder is not.

**Cost:** token budget, repeatedly, on tasks that were always going to need
human hands. Writing "this needs you, here's the one command" in a place the
human sees is the whole deliverable for those items.

---

## How the agent reads and reports

### ★ Classify per chunk, not per note

One five-line phone capture routinely contains a task, a keeper fact, and a
vent. Each is handled separately.

**Cost:** whole notes getting mis-routed on the strength of their first line.

### ★ A note is done only when every chunk is filed or explicitly closed

Never infer "done" from reading it.

**Cost:** five session-dump notes were archived as processed; at least three
held open decisions only the human could make, and had to be restored.
Extracting one task from a multi-decision note does not close the note. Notes
that *summarize* things are the worst offenders — they read as complete because
they're well-written.

### ★ Ambiguous task-or-reference means BOTH

File the reference *and* create the task. Don't require an explicit imperative
verb.

**Cost:** a captured post describing a tool the person didn't yet have, paired
with their own "I should try this," was filed as reference only. The implied
"build this into my setup" sat unnoticed until they asked about it. **Captured
enthusiasm is an action item.** A tweet, an article, a screenshot of a workflow
— if they don't already have it and they commented on it, that's a to-do
wearing a bookmark's clothes.

### ★ A hedge is not a proposal

When staging an item for review, the proposed destination is always a real path.
Never "flag; confirm later" or "small task, do when convenient."

**Cost:** measured. Of eight destination "overrides" in the pilot, four weren't
disagreements at all — the proposal had been a hedge, so the human supplied the
folder himself. **Half the measured error rate was a formatting failure.** If
you're unsure, write the path you'd pick and leave the approve box unticked. An
uncertain proposal is reviewable at a glance; a hedge hands the work back while
appearing to do it. Full numbers: [approval-staging.md](../design/approval-staging.md).

### ★ Trust functional evidence over a file that disagrees

**Cost:** a plugin's auth was declared broken on the strength of an empty config
field, while the human could see the plugin reading his live calendar. The token
was in browser local storage the whole time. If something is demonstrably
working, your model of why it shouldn't be is what's wrong — go find the
mechanism, don't narrate the file.

Same family: **diagnose to root cause before reporting a cause.** The first
comforting explanation ("probably just a backlog", "benign timing") closes the
investigation while the real bug keeps running. Show the mechanism with a
source, or say you don't know yet.

### ★ Never describe your own infrastructure from what you can see running

How your system backs up, syncs, or deploys is a *documented fact*. It is not
inferable from a process list, a running daemon, or a folder that happens to
exist.

**Cost:** asked why the vault felt slow, the agent read the machine's running
processes and announced that four different sync services were all watching the
vault. Three of them weren't — one was disabled system-wide, one had been
removed from the setup months earlier, and one covers an entirely different
folder tree. The correct answer was one file away and had been written down for
exactly this reason. **A running process tells you a program is running; it
tells you nothing about which folder it covers.** The fix wasn't "be more
careful" — it was a hard pointer in the file every session of that project
loads, saying: read the architecture doc before any claim about sync or backup,
never a process list.

### Recompute the number from the fields; don't trust the stamp

When an outcome is recorded by hand in a status field, audit it against the
underlying data before you report a rate built on it.

**Cost:** small, caught early, and it would have been embarrassing. An item in
the approval ledger was stamped "redirected" — counted as a filing error in the
override rate — while its recorded final destination was byte-identical to what
the agent had proposed. The human had approved it after asking for the note's
*contents* to change. One mis-stamp in a small sample moves a headline number by
several points. **Status labels are set by whoever was in a hurry; the fields
are set by what happened.**

### Decide anything decidable

Only genuinely two-sided calls get escalated. "I didn't want to commit" is not
two-sided.

**Cost:** review queues fill with pseudo-questions and the human stops reading
them, at which point the real questions are lost too. An idea that isn't about
writing doesn't go in the writing folder — make the call.

---

## Structural rules about the rules

### ★ One source of truth, thin adapters per runtime

The skill's behavior lives in exactly one platform-agnostic file. Each runtime
gets a thin adapter that only maps abstract actions ("read a note", "archive
it", "add a task") onto its own tools. Change a rule once; both runtimes inherit
it on the next run.

**Cost:** avoided. Full reasoning, including why symlinks are the wrong instinct
here: [cowork-deployment-lessons.md](../operations/cowork-deployment-lessons.md).

### The schema layer is human-owned and wins every conflict

The vault's `HOME.md` rulebook overrides any spec or skill file that disagrees
with it. The agent follows it and never edits it unattended.

**Cost:** avoided, by construction. Without a designated winner, two files
disagree and the agent picks whichever it read most recently — which is a coin
flip that changes between sessions.

### ★ A contradiction inside the rulebook is authoritative permission to be wrong

When a new rule supersedes an old one, **retire the old rule's body**. Adding
the new rule and leaving the old text in place is not a partial fix; it is a
worse state than before.

**Cost:** rule 9 still ended with a routing instruction that rule 11 had
replaced weeks earlier. Both live in the file every session reads *first*, and
that file overrides every other document in the system. So an agent that reads
in order and acts on rule 9 has explicit, authoritative permission to route work
to the wrong place — and it isn't misbehaving, it's obeying. The dangerous
version of a stale rule isn't the one nobody reads. It's the one in your
highest-authority file, sitting above the rule that replaced it.

Practical form: whenever you add a rule that supersedes another, grep the
rulebook for the old behavior before you close the task.

### ★ Any difference between the deployed copy and the source means redeploy

If a runtime runs from an uploaded or copied bundle, the bundle is the artifact
and it must equal the source. The agent does not get to grade the size of the
difference.

**Cost:** twice in one week. First, a fix authored inside the cloud runtime
reached the live skill by upload and **never reached disk** — not the source
project, not the local skill folder. Live and source diverged silently, and the
only copy of the good text was an attachment in a chat window. Second, once
that was merged back, the agent twice declined to re-upload the bundle because
the remaining delta was "only comments." The human's ruling: the bundle exists
so that it *is* what runs; judging whether a diff is worth shipping is not the
agent's call. **"Only comments" is a judgment about content, and the invariant
is about identity.**

### ★ Keep the mandatory read set small, and measure it in bytes

Every rule you add is paid for by every session, forever, before it does any
work.

**Cost:** the files an agent session must read before acting grew to 595 lines /
43,065 bytes without anyone deciding it should — and in a second runtime with an
output cap, a concatenated read of them silently lost its tail, which is exactly
where the newest rules live. Cut 20% with no behavior change by giving each
shared convention one owner file, and by moving the dated incident stories off
the startup path into a separate file the live rules link to. Full method,
numbers, rejected approaches, and how the cut was proven lossless:
[context-budget.md](../operations/context-budget.md).

### Number the rules and cite them by number

Specs say "per rule 11" instead of restating the rule. Retire a rule by
rewriting its body, never by deleting the line and renumbering.

**Cost:** restated rules drift. A rule copied into three specs becomes three
slightly different rules within a month, and nobody can tell which is current.

### ★ Rules earn their place by having cost something

**Cost:** the opposite failure — a speculative rulebook that grows to forty
items nobody reads, at which point you have no rules at all. If you can't name
what went wrong, it's a preference, not a rule. Write it down somewhere else.

### Scope a rule to the session type that needs it

A cap or procedure meant for one kind of run belongs in the thing that *launches*
that kind of run, not in the shared instruction file every session reads.

**Cost:** a "one item per session" cap written for cheap autonomous runs bled
into every interactive session, which then stopped after one item. Shared
instruction files have no conditionals; a scope qualifier only protects you if
the reading model parses it.
