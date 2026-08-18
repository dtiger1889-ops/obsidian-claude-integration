# Silent rot: maintaining a synced, plugin-heavy vault

Everything in this file is a failure mode that produces **no error message**. The
vault keeps working, the sync keeps running, the agent keeps reporting success,
and something underneath is quietly wrong. Each one below was found by noticing
a symptom that looked like something else entirely.

Grouped into three: the link graph, the plugins, and the sync layer.

---

## Part 1 — The link graph

### Archiving a note breaks every link pointing at it

The archive folder is excluded from the vault's index. That means a `[[link]]`
from a live note to an archived one stops resolving — it renders grey, and
**clicking it creates a brand-new empty note at that name**. So archiving one
note quietly arms a trap in every note that referenced it, and the trap fires
weeks later as mystery junk files appearing in the vault.

This was the single largest source of broken links here: nine of the dangling
links traced to notes confirmed present in the archive.

**The rule that came out of it: archiving is a link operation, not a move.**
Before a note is archived, grep for inbound links and **sever** them — drop the
brackets, keep the text, so the sentence still reads. Never re-point a live note
*into* the archive; that defeats the isolation the archive exists for.

The first version of this rule said the opposite ("re-point inbound links at the
archived path"), which is the instinct — preserve the reference — and it is
wrong if your archive is meant to be sealed. Decide which one your archive is
before you write the rule.

**The alternative that was rejected:** moving the archive to a separate vault
entirely. It solves the problem completely and costs you the ability to search
your own history without switching vaults. The excluded-folder approach is a
leaky seal by design — excluded notes can still be linked *to*, they just can't
be found — but an agent can run the de-link pass on every archive operation,
which is exactly the discipline a human archiving by hand will never keep up.

### Malformed link-valued frontmatter spawns junk notes too

A frontmatter property holding two links written as one string:

```yaml
source: "[[Note A]], [[Note B]]"
```

parses as **one** link target with a mangled name. It renders as a single grey
node, and clicking it creates a file named after the mangled string. Three notes
had this shape and had been quietly spawning junk for weeks.

**Rule: any link-valued property is a YAML list, never one scalar.**

```yaml
source:
  - "[[Note A]]"
  - "[[Note B]]"
```

Written at the field's definition in the schema, not in a general style note —
the place a session actually looks when it is about to write that field.

### Grey nodes are a review bucket, not a purge list

The investigation started from "something is deleting my notes." It wasn't.
Most dangling links are **intentional**: cross-references to notes not written
yet, provenance pointers, deliberate stubs. Of the dangling links found, about
half were archive breakage (a real bug), a quarter were pointers into a
deliberately-excluded folder, and the rest were stubs that should stay.

If your auditor presents dangling links as a cleanup queue, you will "fix" your
own future notes out of existence. Present them as a bucket to read.

### Build the auditor, and make it config-aware

A report-only, rerunnable script that sorts every link into one of four buckets:
malformed, dangling, pointing into an ignored folder, or a broken embed.

The detail that makes it useful: **it reads the app's own config** — the user
ignore-filters and the attachment display setting — so its idea of the graph
matches the graph the human is looking at. An auditor that disagrees with the UI
gets ignored within a week.

Run it after any bulk archive or folder restructure. Zero malformed links and
zero archive entanglements is an achievable steady state; it just isn't a
self-maintaining one.

### Pointers that live outside the vault rot silently

The vault repairs its own `[[links]]` on rename. Nothing repairs a filename
written into a file **outside** the vault — a project's own docs, a script, a
config. Those pointers break on the first rename and nothing tells you.

**Fix: anchor external pointers on a stable index note**, and resolve the target
through that index's links and section names rather than naming the leaf file.
The index is maintained as part of ordinary work, so it survives renames a
hardcoded filename doesn't. The residual risk collapses to one file instead of
dozens.

---

## Part 2 — The plugins

### A linter set to run on file *change* rewrites timestamps when you merely open a note

Symptom: opening a note to read it bumped its `updated` property. Every note the
human had recently *looked at* claimed to have been *edited*.

Mechanism, proven rather than guessed: the linter was configured to lint on file
change, and its timestamp rule used the filesystem as the source of truth for
`updated`. Switching to a note triggered a lint; the lint's own write bumped the
file's mtime past the value it had just written; the next open saw a mismatch and
re-bumped it. **A self-feeding loop between a rule and the file it writes.**

The tell that identified the writer: every recently-viewed note had
`updated == mtime`, while a note edited only by an outside script kept its old
stamp. If the plugin had been innocent, that second note would have been bumped
too.

Fix: lint on **save**, not on change. Damage: every historical `updated` value
records a *view*, not an edit, and is unrecoverable beyond the backup window. A
restore script recovered 10 notes from nightly backups; 301 were already correct,
17 had been genuinely edited, and the rest never had the field.

Two things generalize:

- **Any automation that writes a file it also watches will feed itself.** Check
  the trigger before you check the logic.
- **Before you trust a timestamp field, find out what writes it.** A metadata
  field maintained by a plugin is a plugin output, not an observation.

### Plugin settings can be per-device and invisible in the synced config

New notes silently stopped receiving their template frontmatter — no error, no
warning, just notes arriving bare.

The cause: the template plugin auto-updated, and in the new version the master
switch that fires templates on file creation became a **per-device local
setting**, stored in browser local storage, **absent from the synced settings
file**, defaulting to off, and not inheriting the old value across the update.

The synced config looked perfect. It *was* perfect. It also proved nothing,
because the switch that mattered wasn't in it.

**Generalizable: when a synced config disagrees with observed behavior, look for
a per-device settings store before you doubt the behavior.** And when you find
one, it has to be re-enabled on every device separately, forever — which belongs
in your gotchas file the day you find it, not in a session's memory.

---

## Part 3 — The sync layer

### A conflict can resolve the wrong way and leave *both* devices on the stale copy

Two plugins were installed and enabled on the desktop; the phone never picked
them up. The obvious read — "the plugin files didn't sync" — was wrong. The
files had synced fine.

What actually happened: the enabled-plugins list hit a sync conflict, and the
**stale** version won the live filename while the correct version was demoted to
a `.sync-conflict` copy. So neither device was reading a config that enabled the
new plugins, and both were internally consistent about it.

**When a config change "didn't take", check for conflict copies of the config
file before you re-do the change.** And diff before discarding — sometimes the
conflict copy is the one holding the content.

### Config files conflict because both devices rewrite them on launch

Worth knowing before you conclude you have a sync problem: the app re-serializes
its own settings files on launch and on close, on every device. So config
conflicts appear on days when nobody edited anything anywhere, which makes them
look like a much scarier fault than they are.

**Considered and rejected: excluding the config directory from sync.** It ends
the conflicts and costs you identical settings across devices, which was the
reason to sync config in the first place. Occasional conflict cleanup is the
cheaper side of that trade. Write it down as a decision so the next person
doesn't re-litigate it at 1am.

### Scripted writes into the vault can miss the file watcher

Copying files into a plugin directory or deleting notes with a shell script
sometimes fails to register with the sync daemon's watcher, so the change never
propagates and nothing reports an error.

**After any scripted or bulk change to the vault, force a rescan** through the
sync tool's own API. One line, no downside, and it removes an entire class of
"why is my phone different" investigation.

---

## The pattern across all of them

Every failure here shares a shape: **an observation got substituted for the
documented mechanism.** The config looked right, so the behavior must be a
fluke. The processes were running, so the sync must be covering that folder. The
link was grey, so the note must be gone.

The check that catches all of them is the same one: *name the mechanism, and
point at the evidence that shows it.* If you can't, you haven't diagnosed
anything — you've picked the most comfortable story that fits the symptom.
