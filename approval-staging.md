# The staging system: how the agent asks permission

An agent that files things into your vault is only useful if you trust it, and
trust needs a review surface. This is the one that worked, why the obvious
version didn't, and what happened when the gate got instrumented and started
producing numbers about its own accuracy.

---

## The version that failed: approve-everything, in chat

v1 of this system was "propose-then-approve **everything**": the sweep ends, the
agent prints a table — chunk, classification, destination, exact text — and you
approve or reject line by line in the conversation.

It reads like the responsible design. It failed for three reasons, all
structural:

1. **It requires you to be in the session at that moment.** Captures happen on a
   phone; approvals happen wherever you are. A chat table is only answerable at
   a keyboard, in that conversation, before it scrolls away.
2. **It doesn't survive the session.** Close the window and the queue is gone.
   Anything unapproved silently reverts to "still sitting in the inbox," with no
   record that it was ever proposed.
3. **Asking about everything trains you to rubber-stamp.** When 80% of a queue
   is obvious, reading the other 20% carefully stops happening. A gate that
   fires on everything is a gate that gets waved through.

The fix was to move the gate **into the vault** and to **stop asking about the
easy lane**.

---

## Two lanes, and the split is the whole design

| Lane | What happens | Asked about? |
|---|---|---|
| **Project / work items** | An item note is created in `Projects/Sprints/`, and the originating inbox note moves to `Projects/`. | **No.** Just done, then reported. |
| **Everything else** | The inbox note is stamped in place with approval frontmatter and left in the inbox for review. | **Yes**, in the Base. |

Project items skip the gate because their destination isn't a judgment call —
work about project X goes with project X. Reserving the gate for the genuinely
ambiguous lane is what keeps the queue short enough to actually read.

Nothing non-project moves into a PARA folder until you approve it or override
the destination.

---

## The staging frontmatter

Stamped directly into the inbox note. The note doesn't move; the frontmatter is
the proposal.

```yaml
approval_stage: review   # review | filed | rejected | held
item_type: reference     # reference | personal | action | resource | project | ephemeral
active_todo: false       # true = has an open action; never auto-file it far away
proposed_dest: Areas/Home & Logistics/Appliances.md   # an ACTUAL path, always
approve: false           # your checkbox
hold: false              # your checkbox
user_dest:               # your override, if the proposal is wrong
claude_note: "One plain line: what it is, why this destination, what I need from you."
pipeline_started: 2026-07-22
```

Then two views over it:

```yaml
views:
  - type: table
    name: Needs review
    filters:
      and:
        - file.inFolder("00 Inbox")
        - approval_stage == "review"
    order:
      - file.name
      - item_type
      - active_todo
      - proposed_dest
      - approve
      - hold
      - user_dest
      - claude_note
      - pipeline_started
      - created
      - due
      - file.tags
    columnSize:
      file.name: 307
  - type: table
    name: Pipeline history
    filters:
      or:
        - approval_stage == "review"
        - approval_stage == "filed"
        - approval_stage == "rejected"
        - approval_stage == "held"
    order:
      - file.name
      - approval_stage
      - item_type
      - proposed_dest
      - final_dest
      - pipeline_started
      - pipeline_finished
      - pipeline_outcome
      - claude_note
```

**Needs review** is the queue: checkboxes you can tick on your phone, on a
couch, three days later. **Pipeline history** is the audit trail — proposed vs
actual, start to finish.

Because the checkboxes are inline-editable Base columns, resolving eight items
is eight taps. That is the entire reason this works and the chat table didn't.

### Rules that fell out of running it

- **You may edit those fields while a sweep is running.** The agent re-reads
  each note before acting and treats the file on disk as authoritative over
  anything it proposed. An `approve` that flips back to false is a withdrawal:
  leave the note alone.
- **Personal content still isn't moved without approval** — but that's about
  not *acting*. It never excuses refusing to *name* a destination.
- **A question about the vault goes in this Base or nowhere.** Parking it in a
  project checkpoint the human doesn't read is a question that never gets asked.
- **Decide anything decidable.** Only genuinely two-sided calls get staged.
  "I didn't want to commit" is not two-sided.

---

## Closing the lifecycle

Filing an approved item and leaving `approval_stage: review` is half a job: it
corrupts the history view and every number computed from it.

On filing, stamp all four:

```yaml
approval_stage: filed          # or rejected | held
pipeline_finished: 2026-07-27
final_dest: Areas/Games/Backlog.md    # the REAL path, not the proposed one
pipeline_outcome: redirected-and-filed
```

`pipeline_outcome` is one of `approved-and-filed` (went where proposed),
`redirected-and-filed` (a `user_dest` override sent it elsewhere),
`approved-and-deleted` (agreed it was junk), or `rejected`.

Audit for stragglers — anything carrying `review` that is no longer in the inbox
was filed and never closed out:

```bash
grep -rl "^approval_stage: review" --include="*.md" . | grep -v "^./00 Inbox/"
```

That command found five on its first run.

---

## The ledger, and why frontmatter alone isn't the record

The obvious way to measure this is to query the vault for approval frontmatter.
It doesn't work, and the failure is silent: **resolving an item destroys its own
data point.** A filed note moves out of the inbox to somewhere the "Needs
review" filter can't see. A rejected note gets deleted. What survives in the
vault is a biased sample — the unresolved ones.

So the record lives outside the vault, in an **append-only ledger**. A script
scans every note carrying `approval_stage` frontmatter, merges each into
`approval_ledger.json` keyed on title + creation stamp, and — critically —
**never removes a record**. A record whose note has vanished stays, flagged
`vanished: true`.

```
pwsh -File ./extract_approvals.ps1
```

Run it at the end of every sweep and again after you resolve a batch. It prints
the split:

```
notes scanned with approval frontmatter : 15
ledger records  : 16  (was 16)
resolved        : 14   in review: 2   vanished-but-retained: 1
agreed          : 5
overridden      : 8  (57% of resolved)
```

"Vanished-but-retained" is the line that proves the design: that record's note no
longer exists anywhere in the vault, and its data point is still here.

The script is in this repo: [extract_approvals.ps1](extract_approvals.ps1).

---

## What the numbers said

**14 items resolved: 5 filed exactly as proposed, 8 redirected to a different
folder, 1 approved and then deleted — a 57% override rate.**

A 57% override rate on a filing agent sounds like the agent is bad at filing.
Reading all eight overrides individually said something more useful.

**Four of the eight were not disagreements at all.** In each, `proposed_dest`
wasn't a destination — it was a hedge. "Flag; confirm project vs keep-fact."
"Small task, do when convenient." "Stays its own standalone note." The human
then had to supply the folder himself, which the pipeline scored as an override.
**Half the override rate was really a non-proposal rate.**

That produced a rule with teeth: **`proposed_dest` must be a real path, every
time.** If you're unsure, write the path you'd pick and leave `approve: false`.
An uncertain proposal is reviewable in one glance; a hedge makes the human do
the work the gate exists to save.

**Three were genuine destination errors, and all three had the same shape.**
They went `Projects → Resources`, `Resources/Media → Areas/Games`, and
`Resources/Ideas → Writing & Journal/Writing`. The through-line: **the agent
reaches for the filing-cabinet folders, the human routes by what the thing IS to
them.** An ongoing life domain is an `Area`, not a `Resource`. Anything creative
is `Writing`, not an `Idea`. The strongest pushback in the whole pilot was on
exactly this axis.

Second rule: **check `Areas/` and `Writing & Journal/` before defaulting to
`Resources/`.**

**The eighth wasn't an override** — it was a question, mis-stamped.

### Caveats, stated plainly

This is n=8 overrides out of 14 resolved items, analyzed by a model, on one
person's vault. It's a hypothesis to re-test at ~20 resolved, not a settled
finding. Both rules are cheap and low-risk, which is why they shipped early; the
open question is whether the two patterns actually shrink now that they're
encoded. Acceptance rate, hold rate, time-to-resolution, and later corrections
are still unmeasured.

---

## The generalizable part

1. **Put the gate in the tool the human already opens, not in the conversation.**
   Approval that requires them to be in your session at your moment isn't
   approval, it's a bottleneck with good intentions.
2. **Don't gate the lane that isn't ambiguous.** A gate that fires on everything
   gets rubber-stamped, and then it's decoration.
3. **Record the proposal AND the actual outcome, outside the system being
   changed.** Otherwise resolving an item erases the evidence you'd need to
   improve.
4. **Instrument the gate, then read the disagreements one at a time.** The
   aggregate said "57% wrong." The individual reads said "half of that is a
   formatting failure, and the rest is one specific mental-model mismatch" —
   which is the difference between an unactionable number and two rules that
   changed behavior the same day.
5. **A hedge is not a proposal.** This generalizes past filing: an agent that
   answers "it depends" is handing the work back while appearing to do it.
