# Bases: making the vault its own task surface

Obsidian **Bases** (core plugin, 1.9+) renders a set of notes as a filterable,
sortable, inline-editable table driven by their frontmatter. A `.base` file is
just YAML: which notes, which properties, which views.

That turns out to matter more than it sounds. It closes the one gap that had
kept action items out of the vault: **a plain markdown list can't be queried,
and a task tool outside the vault can't sit next to the note that explains the
task.** A Base does both — the items are real notes in a folder, and the Base is
a live view over them that works on the phone.

This doc has the four Bases the system runs on, the frontmatter schema behind
them, and the conventions that took a few rounds to get right.

> Naming: these files use `agent` where the live system uses a model nickname,
> and `user_dest` where it uses the owner's first name. Rename freely — the
> property names are yours, but they must match between the `.base` file, the
> notes, and whatever writes them.

---

## 1. The Sprints Base — the in-flight work index

**One note per action item**, all in `Projects/Sprints/`, surfaced through five
views. The note body holds the detail; the frontmatter drives the table.

### Item frontmatter

```yaml
---
summary: "One readable line — this is the table's headline column"
project: vault-tooling       # your project slug, or personal | home | work
complexity: quick            # quick | moderate | heavy
status: open                 # open | in-progress | blocked | verify
agent: false                 # true = on the agent's plate
priority:                    # high | blank
due:                         # optional date
source: "[[origin note]]"    # wikilink back to where this came from
created: 2026-07-22 00:06
updated: 2026-07-29
note:                        # human → agent, batch instructions
reply:                       # agent → human, short dated answer
next:                        # true = one of the ≤3 "Now" picks
picked:                      # date the pick was made
---
```

### The `.base` file

```yaml
properties:
  summary:
    displayName: Summary
  project:
    displayName: Project
  complexity:
    displayName: Effort
  status:
    displayName: Status
  priority:
    displayName: Priority
  agent:
    displayName: Agent
  due:
    displayName: Due
  source:
    displayName: Source
  created:
    displayName: Added
  note:
    displayName: Note to agent
  reply:
    displayName: Agent reply
  next:
    displayName: Now
  picked:
    displayName: Picked
views:
  - type: table
    name: By project
    filters:
      and:
        - file.inFolder("Projects/Sprints")
    groupBy:
      property: project
      direction: ASC
    order:
      - file.name
      - summary
      - complexity
      - status
      - priority
      - agent
      - due
      - source
      - note.note
      - reply
    sort:
      - property: project
        direction: DESC
      - property: complexity
        direction: DESC
    columnSize:
      file.name: 280
      note.summary: 360
  - type: table
    name: Now
    filters:
      and:
        - file.inFolder("Projects/Sprints")
        - next == true
    order:
      - file.name
      - summary
      - reply
      - project
      - complexity
      - status
    sort:
      - property: picked
        direction: ASC
    columnSize:
      file.name: 260
      note.summary: 320
      note.reply: 320
  - type: table
    name: My queue
    filters:
      and:
        - file.inFolder("Projects/Sprints")
        - agent != true
    groupBy:
      property: status
      direction: DESC
    order:
      - file.name
      - summary
      - project
      - complexity
      - priority
      - due
      - note.note
      - reply
    sort:
      - property: project
        direction: ASC
    columnSize:
      file.name: 280
      note.summary: 360
  - type: table
    name: Agent's plate
    filters:
      and:
        - file.inFolder("Projects/Sprints")
        - agent == true
    order:
      - file.name
      - summary
      - project
      - complexity
      - status
      - note.note
      - reply
    sort:
      - property: project
        direction: ASC
    columnSize:
      file.name: 280
      note.summary: 360
  - type: table
    name: Notes
    filters:
      and:
        - file.inFolder("Projects/Sprints")
    order:
      - file.name
      - note.note
      - reply
      - summary
      - project
      - status
    sort:
      - property: note.note
        direction: DESC
      - property: project
        direction: ASC
    columnSize:
      file.name: 260
      note.note: 320
      note.reply: 320
```

### The five views, and why each exists

| View | Filter | Job |
|---|---|---|
| **By project** | everything, grouped by `project` | The full picture. Grouping by project is what makes 40 items legible. |
| **Now** | `next == true` | At most three picks. The answer to "what do I actually do next." |
| **My queue** | `agent != true` | Only what needs a human. |
| **Agent's plate** | `agent == true` | Only what the agent is expected to drain. |
| **Notes** | everything, sorted by `note` | The message channel (below). |

### Conventions that took a few rounds

**Lead every view with `file.name`.** Bases don't make rows clickable — the
`file.name` column is the link into the note. Five views shipped without it and
the Base was read-only-looking for a week: you could see the work and not open
it. Put `file.name` first in every `order` array, always.

**`summary` is a frontmatter property, not the filename.** The filename is the
stable identity and the link target; `summary` is the sentence that changes as
the item evolves. Trying to make the filename carry both means renaming notes
constantly and breaking every `[[wikilink]]` to them.

**Completed items get deleted, not marked done.** The Base is a live to-do, not
a log. A `status: done` value means the table slowly fills with things you've
finished and you stop trusting the count. The completion record belongs in the
linked note or the project's checkpoint — write it there *first*, then delete
the item note. If a small verification step remains, that's `status: verify`
with the body trimmed to just that step.

**Partition by actor, not by priority.** The single highest-value split was
`agent: true/false` — two views, "my queue" and "the agent's plate". Priority
fields decay into noise; "who can even do this" doesn't. `agent: true` means
*assigned*, not merely delegable: work that could be delegated but needs a
human's green light stays `false`, with the green-light ask written once in
`reply`.

**Cap the "Now" view at three, and make picks sticky.** Three items, chosen by a
dumb explainable heuristic (one quick unblocked + one moderate/heavy + the
cheapest high-leverage unblock), each carrying a dated `reply` naming why it was
picked. Sticky means a pick survives until its item is deleted or vetoed —
otherwise every sweep reshuffles your "now" and it stops meaning anything.

**Never add a field a human must hand-populate.** Every signal in the Base is
either agent-stamped or computed. The one field that required manual entry
(`priority`) is blank on nearly every item, which is exactly what you'd predict
and exactly why the rule exists.

**Keep a visible heartbeat.** The landing note that embeds the Base carries a
`**Last swept:** <date>, <count> items, <one clause>` line. If the automation
quietly dies, a stale date is the only signal you'll get.

---

## 2. The message channel: `note` and `reply`

Two frontmatter fields on every sprint item, editable inline as Base columns:

- **`note`** — human → agent. Typed straight into the table.
- **`reply`** — agent → human. One short dated line.

This is the highest-leverage piece of the whole setup and it's four lines of
YAML. You sit with the Notes view, type instructions into ten rows in one
sitting — *"this is blocked on X"*, *"drop this"*, *"what does this actually
need?"* — and then hand the whole batch over with one sentence: **"act on my
sprint notes."**

The protocol:

1. Scan for items with a non-empty `note`.
2. Act on each per what it says: answer a question → answer in `reply`; do the
   work → do it (routing real work to the owning project); update metadata →
   edit the frontmatter; "drop this" → record completion, then delete the item.
3. **Write `reply` (dated), then clear `note`.** The reply is the receipt; the
   cleared note is what empties the queue.
4. Never clear a note you didn't act on.

Two rules keep the channel honest:

- **`note` is the human's voice; only the human writes it.** An agent that
  learns something about an item unprompted may write a dated `reply` — never a
  `note`.
- **Attribute judgments in the reply.** A recommendation reads `suggest: ...`,
  never dressed up as something that happened.

Anything the agent structurally cannot do — an auth flow, a physical device, a
UI-only click — gets **tabled and said so in `reply`**, not attempted. One cheap
probe to confirm it's really blocked is fine; a retry ladder against a login
screen is how you burn an hour of tokens on a task that was always going to
need a human's hands.

---

## 3. The Todo Base — the surfacing net

Small, and does one thing: **no open action can hide in a folder.** Any
non-archived note tagged `to-do` shows up here, wherever it lives.

```yaml
formulas:
  due_in: if(due, due.relative())
properties:
  due:
    displayName: Due
  formula.due_in:
    displayName: Due in
  status:
    displayName: Status
  created:
    displayName: Captured
  updated:
    displayName: Updated
views:
  - type: table
    name: All to-dos
    filters:
      and:
        - file.hasTag("to-do")
        - '!file.inFolder("Archive")'
        - note.status != "archived"
    order:
      - file.name
      - due
      - formula.due_in
      - status
      - updated
      - created
      - file.tags
    sort:
      - property: due
        direction: ASC
      - property: created
        direction: DESC
  - type: table
    name: No due date
    filters:
      and:
        - file.hasTag("to-do")
        - '!file.inFolder("Archive")'
        - note.status != "archived"
        - "!note.due"
    order:
      - file.name
      - status
      - updated
      - created
      - file.tags
    sort:
      - property: created
        direction: DESC
```

Two details worth copying:

- **The double exclusion** (`!file.inFolder("Archive")` *and*
  `note.status != "archived"`) catches both archive paths — a note moved to the
  folder, and a note stamped archived that hasn't moved yet.
- **The "No due date" view is the useful one.** Items with dates surface
  themselves; items without dates are where a to-do system silently rots. Giving
  them their own tab makes the rot visible.

---

## 4. The Approval Base — the staging gate

The third Base is the review queue for the inbox sweep, and it's the piece with
the most design behind it. It has its own doc:
**[approval-staging.md](approval-staging.md)**.

---

## 5. The idea-triage Base — checkboxes as a command surface

The fourth Base came later, and it is the one that changed what a Base is *for*.

The task index tracks work that has already been decided on. A batch of
overnight-generated ideas is a different animal: most should die, a few deserve
a stress-test before anyone commits, and deciding which is which is a two-second
judgment the human can make on a phone — if the interface asks the right
question.

So instead of a status field, each idea note carries **a set of boolean
properties, one per action the agent can take**:

```yaml
stage: triage          # triage | instructed | results | archived | promoted
archive_idea: false    # kill it
stress_test: false     # one adversarial pass, is this actually wrong
prior_art: false       # has someone already built this
write_spec: false      # turn it into a real spec
```

The human ticks any combination of boxes in the table view, on the phone,
without opening a note. The agent's next run treats **a ticked box as a queued
command**: it runs the action, writes a receipt into the `reply` field, clears
the box, and advances `stage`. Exactly the message-channel pattern from section
2, with checkboxes instead of prose — and the same invariant, that the agent
clears its own queue so a ticked box always means "not done yet."

Three conventions this one needed:

- **Multi-select is the point.** "Prior art *and* stress test" is a common
  answer, and forcing a single status field would have lost it. Booleans compose;
  a status enum doesn't.
- **Outputs land outside the vault**, in the working folder of whatever project
  the run belongs to. The vault gets the verdict, not the research dump.
- **Processed items stay in the folder as history.** Killed and promoted ideas
  keep their notes, stamped, rather than being archived — a **deliberate
  exception** to the archive-when-spent rule, because the entire value of an
  idea queue is the record of what was already tried and rejected. Exceptions
  like this are fine; undocumented exceptions are not, so it is written next to
  the rule it breaks.

The general lesson: **a Base column that the agent reads as an instruction turns
a table into a control panel.** Any property you can tick on a phone is an API,
and it is a far better one than a chat message, because it survives you closing
the app.

---

## Why Bases rather than the alternatives

| Alternative | Why it lost |
|---|---|
| A single markdown list file | Can't filter, group, or partition by actor. Two agents editing it collide. Merge conflicts on every phone sync. |
| Dataview queries | Powerful, but read-only rendering: you can't edit a value from the table, and the syntax is a second language. Bases edit in place and are core (no plugin drift). |
| A task app outside the vault | Fine for chores. Wrong for project work — the item can't live next to the note that explains it, and nothing can `[[link]]` to it. |
| Tasks-plugin checkboxes | Great for dated reminders inside a note. No per-item metadata, so no actor partition and no message channel. |

If you also keep a chores-and-errands list somewhere else, draw the line by
**shape, not by size**: anything you'd want to open a note about belongs in the
Base; anything you'd want to tick off while standing in a hallway doesn't.
Mixing them in either direction means one of the two lists fills with items
you're not in the right context to act on, and you stop opening it.

---

## Gotchas

- **Property names must match exactly** across the `.base` file, the note
  frontmatter, and whatever writes the notes. A typo doesn't error — the column
  just renders empty, which reads as "no data" rather than "wrong key".
- **`note.` vs `file.`** — `file.name`, `file.tags`, `file.inFolder(...)` are
  file properties; frontmatter is addressed bare or as `note.<prop>` depending
  on position. Copy the working examples above rather than guessing.
- **Verify on the phone before you rely on it.** Column widths, view tabs, and
  inline editing behave differently on mobile, and a Base you can only use at
  your desk defeats the point of capturing on your phone.
- **The default view is the only view.** Whatever state your agent can set, the
  *default* view has to show it. Two items were once normalized into a valid
  "held" state that the default view's filter excluded, and they disappeared from
  the human's queue with both notes intact on disk — which from his side looks
  exactly like the agent deleting his work. Adding a separate "Held" tab fixed
  nothing, because nobody switches tabs. Use a nested filter on the default view
  (`folder AND (state = review OR state = held)`) rather than a new view.
- **A Base is a view, not a store.** Delete a `.base` file and you lose the
  table, not the work — the items are ordinary notes in a folder. That's a
  feature: it means you can restructure your views without migrating anything.
