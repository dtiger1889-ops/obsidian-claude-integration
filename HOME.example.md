# HOME.example.md — the vault rulebook

This is a depersonalized copy of the file that sits at the vault root and does
more work than anything else in the system. Every agent session reads it first;
it is the schema layer, and it wins over any spec or skill file that disagrees
with it.

Copy it into your own vault root as `HOME.md`, swap the folder map for yours,
delete the rules you don't want, and keep it under one screen. **The human owns
this file. The agent follows it and never edits it unattended.**

Two structural notes before the copy:

- **Rules earn their place by having cost something.** Nearly every numbered
  rule below is the scar tissue from one specific failure. A rulebook written
  speculatively grows to forty rules nobody reads.
- **The rules are numbered and referenced by number** — specs and skill files
  say "rule 11" rather than restating the rule. One authority, cited from
  everywhere else, so a change lands in exactly one place.

The commentary blocks marked `>` are notes for you and are not part of the file.

---

```markdown
---
created: 2026-07-09
updated: 2026-07-29
---
# HOME — vault map & conventions

Single-screen orientation for this vault (PARA structure). Humans: browse from
here. Agents: read this file first, then open the ONE note you need. This file
is the human-owned schema layer — don't edit it without me.

## Map

| Folder | What lives there |
|---|---|
| `00 Inbox/` | Capture entry point. New phone notes land here (Syncthing). Emptied by `/obsidian process-inbox`. |
| `Projects/` | Notes tied to active efforts, one subfolder per effort, plus loose project notes. |
| `Areas/` | Ongoing life domains: Career · Finances · Health · Home & Logistics · Hobbies · Relationships. |
| `Resources/` | Topic reference: Food & Recipes · How-tos · Ideas · Lists · Media · Tech · Travel. |
| `Archive/` | Inactive/completed notes. Processed inbox notes are moved here (originals preserved). |
| `Writing & Journal/` | Personal writing, journal, trip logs. See rule 5. |
| `Templates/` | Obsidian templates, including the archive/unarchive Templater scripts. |

## Agent conventions (the 12 rules)

1. **Dated provenance** — every consolidated entry gets a
   `## <Title> — <YYYY-MM-DD>` heading; the date comes from the source note's
   `created` frontmatter. The date is the spine.

2. **Retrieval-context organization** — a file answers ONE situation
   (why / when / what / who). Notes sharing a tag but used in different moments
   go in separate files. Split, don't cram.

3. **Tags come from the schema only** — a single file lists the allowed tags with
   one-line semantics. Never invent tags; leave a note untagged rather than
   force-fit.

4. **Personal content is my call** — journal / venting / relationship /
   personal-medical detail is NEVER auto-filed or restructured. Flag it with a
   suggestion and stop.

5. **`Writing & Journal/`: file INTO it freely, never CONSOLIDATE within it.**
   New personal writing, story ideas, and trip logs belong here and get filed as
   their OWN separate notes. What is banned: merging separate notes into one,
   appending a capture into an existing collection file, and reorganizing or
   renaming what is already there. The line is consolidation, not contact. When
   unsure: creating a new file here is safe; editing an existing one is not.

6. **Sync conflicts: resolve the obvious, flag the ambiguous** — diff the
   conflict copy against the live file. Pure stale subset → delete the copy;
   live file missing → restore the copy to the live name; either way the
   conflict-named file goes. Only a genuine two-sided merge (both sides hold
   unique content) gets flagged. Check the trash folder too — trashed conflict
   files still count on the phone.

7. **`status: pinned` = leave it alone** — a pinned frontmatter status means the
   note lives where it is on purpose. The inbox processor skips it.

8. **Processed inbox notes move to `Archive/`** — never deleted, never
   stamped-and-left. Deletes happen only with explicit per-file approval. Every
   archived note gets an appended `**Archived <date>:**` line saying where its
   content went — the archive copy is a pointer, not a dead end. Archiving by
   ANY path (Templater button or agent) stamps the same trio:
   `archived: YYYY-MM-DD`, `archived_from: <original folder>`, `status: archived`;
   unarchiving restores to `archived_from` and deletes all three. **A note with
   any open to-do is not "processed" and is never archived while the action is
   open.**

9. **One-way integration, light touch** — work artifacts stay in the code
   workspace and never enter the vault; read the specific note you need, never
   load whole folders into context.

10. **`status: Hey Claude` = flag for active agent involvement, not a "knock it
    out this pass" order.** It marks the note as needing judgment about *how* to
    handle it, distinct from a generic `to-do` tag (a standing reminder I track
    with or without the agent). On hitting one, route it into exactly one of:
    - **Trivial to knock out now** (a one-line config change, no design
      decision) → just do it. Never trivial: operating another project's live
      system (running its code, enabling a source, touching its database).
      "Add X to project Y" means LOG X in that project's files, checkpoint,
      project note, and sprint item; execution happens in that project's own
      session.
    - **Action item, existing project** → add it as a to-do on that project's note.
    - **Action item, new project idea** → its own note under `Projects/`.
    - **Action item needing real implementation work** → its own item note in
      `Projects/Sprints/`, surfaced via `[[Sprints.base]]` (rule 11).

    Close the loop the same way regardless of route: one-off → flip
    `status: Hey Claude` → `archived` and move to `Archive/`; ongoing effort →
    move the note into `Projects/`. Never leave a handled note in the inbox —
    but "handled" means correctly routed, not always fully built.

11. **Action items → a note in `Projects/Sprints/`, surfaced via
    `[[Sprints.base]]`.** One note per item; frontmatter schema and the
    completion rule live with the Base. Add one note per action — do NOT append
    a bullet to a list file. **Completed items are DELETED, never marked
    done-and-kept** — the Base is a live to-do, not a log; the completion record
    lives in the linked note or project checkpoint. If a small verification step
    remains, set `status: verify` and trim the body to just that step. The
    landing note that embeds the Base stays pinned (rule 7). **If a separate
    list exists for chores and errands, it stays for chores and errands ONLY** —
    project, work, and research tasks stay in the Sprints Base.

12. **Two bases index in-flight items; nothing non-project is filed into a PARA
    folder without approval.** `[[Todo base.base]]` is the live surfacing net for
    every open to-do (any non-archived note tagged `to-do`), so an open action
    lives there, never buried in a folder. `[[Approval base.base]]` is the
    staging gate for the inbox sweep: each non-project item is stamped with a
    proposed destination plus approve/hold checkboxes and left for me to approve,
    override, or hold before anything is filed. Project and work items skip the
    approval base; they become a note in `Projects/Sprints/` and any originating
    inbox note moves to `Projects/`.

## Related
- Capture→action pipeline spec: <wherever you keep it>
- Two-lanes integration model: <wherever you keep it>
- Phone sync details: <wherever you keep it>
```

> Keep the `## Related` pointers pointing at files that actually exist. A
> rulebook citing a doc that was renamed or never written teaches the agent that
> pointers here are decorative.

---

## Notes on adapting it

**Rule 4 and rule 5 are a matched pair, and getting the wording wrong is
expensive.** Rule 5 originally read "`Writing & Journal/`: agents hands-off."
Agents read that as a blanket ban and started *refusing to file* things that
belonged there — the folder became write-only for the human. The corrected
wording draws the line at **consolidation, not contact**: creating a new file in
a personal folder is safe, editing an existing one is not. If you write a
hands-off rule, say precisely which operation is banned.

**Rule 9 is the one that keeps the vault from becoming a second workspace.** Work
artifacts (analysis, code, checkpoints) stay in the project that owns them. The
vault holds durable reference. Without this, every agent session helpfully drops
its output into your vault and you now have two rotting systems.

**Rule 10's "never trivial" clause is worth stealing verbatim.** An inbox note
saying "add this API key to the deal watcher" was read as trivial: the key got
wired into a tracked script, the data source was enabled, and the poller ran,
ingesting several thousand rows nobody asked for. "Add X to project Y" means
*log* X where project Y's own session will find it. **Log, don't run.** An inbox
sweep should never operate another system's live machinery.

**Rules 11 and 12 came last and changed the most.** The original design pushed
every action item out to a separate task tool. That turned out to be wrong for
anything project-shaped — those items need to sit next to the notes that explain
them, and to be `[[linkable]]` from them. See [vault-bases.md](vault-bases.md)
for what replaced it.

**Watch for a superseded clause left behind in an old rule.** When rule 11
changed where action items go, the *earlier* rule that mentioned task routing in
passing kept its original wording — so the rulebook contradicted itself, in the
one file that overrides everything else and gets read first. A session that
stops at the earlier rule has authoritative permission to do the wrong thing.
When you change a rule, grep the rest of the file for the old behavior.

**Keep the numbering stable.** Renumbering breaks every "per rule 8" reference in
your specs, skill files, and past decisions. Retire a rule by rewriting its body
rather than deleting the line.
