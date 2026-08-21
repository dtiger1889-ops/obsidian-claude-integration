# obsidian-agent-integration

Design docs for wiring **Claude Code to an Obsidian vault** as a second-brain
system: the vault is the durable reference layer (PARA structure, phone capture
via Syncthing), Claude is the librarian that files things, and action items land
in a task index that lives in the vault itself. Modeled on the "LLM-maintained
wiki" idea, adapted to PARA.

These are lightly-anonymized copies of a real, running system's design docs —
not a polished tutorial. Read them as a worked example to adapt. Where they name
a specific tool or folder, substitute yours; where they cite a rule number,
that's a pointer into the vault rulebook ([HOME.example.md](design/HOME.example.md)).

The system has been in daily use since mid-2026. Most of what's here is scar
tissue.

## Layout

```
SYSTEM-OVERVIEW.md   the whole system in one read — start here
design/              how it is built: the specs, the rulebook, the tables, the sourcing
lessons/             what running it taught, and the one-time migration into it
operations/          keeping it alive: maintenance traps, the agent's read budget, the ledger script
```

## Start here

| If you want to… | Read |
|---|---|
| Understand the whole thing in one sitting | [SYSTEM-OVERVIEW.md](SYSTEM-OVERVIEW.md) |
| Get out of Google Keep (or any notes app) first | [keep-to-obsidian-migration.md](lessons/keep-to-obsidian-migration.md) |
| Copy the rulebook that governs the agent | [HOME.example.md](design/HOME.example.md) |
| See the task/review tables and their YAML | [vault-bases.md](design/vault-bases.md) |
| Understand how the agent asks permission | [approval-staging.md](design/approval-staging.md) |
| Skip to the lessons | [rules-that-stuck.md](lessons/rules-that-stuck.md) |
| Know what will break six months in | [vault-maintenance.md](operations/vault-maintenance.md) |
| Stop your agent's instruction files from bloating | [context-budget.md](operations/context-budget.md) |
| See what this was built on (and what was rejected) | [prior-art.md](design/prior-art.md) |

## The docs

| Doc | What it covers |
|---|---|
| [SYSTEM-OVERVIEW.md](SYSTEM-OVERVIEW.md) | The whole system in one read: what lives where, the daily capture-to-filed flow, design rationale |
| [keep-to-obsidian-migration.md](lessons/keep-to-obsidian-migration.md) | Migrating ~600 Google Keep notes into a PARA vault: recovering the timestamps Takeout drops, the utility-sort triage rubric, and the six ways the consolidation went wrong |
| [HOME.example.md](design/HOME.example.md) | A depersonalized copy of the vault's rulebook — the folder map plus the 12 numbered agent conventions every session reads first, with notes on adapting each |
| [vault-bases.md](design/vault-bases.md) | The four Obsidian Bases the system runs on (task index, to-do net, approval queue, idea triage): full `.base` YAML, the item frontmatter schema, the human↔agent message channel, checkbox properties used as a command surface, and the conventions that took a few rounds |
| [approval-staging.md](design/approval-staging.md) | The staging gate: why in-chat approval failed, the two-lane split, the frontmatter lifecycle, the append-only ledger — what happened when the gate was instrumented and reported a 57% override rate, and the re-test three weeks later that put it at 8% |
| [rules-that-stuck.md](lessons/rules-that-stuck.md) | ~35 rules that are load-bearing today, each with the incident that produced it |
| [vault-maintenance.md](operations/vault-maintenance.md) | The silent failures in a synced, plugin-heavy vault: archiving that breaks inbound links and spawns junk notes, a linter that rewrites `updated` when you merely open a note, per-device plugin settings missing from the synced config, sync conflicts that resolve toward the stale copy |
| [context-budget.md](operations/context-budget.md) | The files an agent must read before it can act, treated as a budget: how a mandatory 43 KB read set got cut 20% with no behavior change, why concatenated reads are where truncation hides, and the four approaches that were rejected |
| [prior-art.md](design/prior-art.md) | Sourcing: the LLM-wiki pattern and PARA this borrows from, the graph+vector stack that was evaluated and declined (with the two triggers that would reopen it), and the plugin comparisons behind each tooling choice |
| [capture-loop-spec.md](design/capture-loop-spec.md) | The inbox-processing pipeline: sweep phone captures, classify per chunk (action / reference / personal / junk), stage, then file + push tasks + archive |
| [integration-spec.md](design/integration-spec.md) | The two-lanes model: which project folders get a vault pointer and which never touch the vault; personal-content rules; the agent skill's phased capabilities |
| [cowork-deployment-lessons.md](operations/cowork-deployment-lessons.md) | Deploying the same skill to a second runtime: what a device bridge gives you, the single-source + thin-adapter pattern (and why symlinks are the wrong instinct), folder-access gotchas, plugin packaging |
| [extract_approvals.ps1](operations/extract_approvals.ps1) | The ledger script: scrapes proposal-vs-actual destinations out of vault frontmatter into an append-only JSON record |

## Design rules that carried the system

- **Two lanes, and only one has a gate.** Project work is filed without asking —
  its destination isn't a judgment call. Everything else is staged for review.
  A gate that fires on *everything* is a gate that gets rubber-stamped.
- **The gate lives in the tool, not in the chat.** Approval happens as
  checkboxes in a table you open on your phone, days later. (v1 printed a chat
  table and asked for line-by-line approval; it only worked while you were
  sitting in the session.)
- **Classify per chunk, not per note** — one phone capture can hold a task, a
  reference, and a vent in five lines.
- **Personal content is never auto-filed.** Journal, venting, relationship, and
  medical material gets flagged with a suggestion and left alone.
- **Archive, never delete**: processed notes move to `Archive/` with a pointer
  line saying where their content went.
- **Dated provenance**: every consolidated entry carries the capture date from
  the source note's frontmatter. The date is the spine.
- **A note is done only when every chunk is filed or explicitly closed** — never
  inferred from reading it.
- **Log, don't run.** An inbox sweep records work for another project's session;
  it never operates that project's live machinery.
- **Completed task items are deleted, not marked done** — the index is a live
  to-do, and the completion record belongs in the linked note.
- **Never add a field a human has to hand-populate.** The one field that needed
  manual entry is blank on nearly every item.
- **The default view is the interface.** A state your agent can set but the
  default view filters out doesn't look like a state — it looks like the agent
  deleted something.
- **A contradiction inside the rulebook is authoritative permission to be
  wrong.** When a rule supersedes another, retire the old body; don't just add
  the new one above it.
- **Every rule you add is paid for by every session.** The mandatory read set is
  a budget, and it should have a number attached.

Full list with the incident behind each: [rules-that-stuck.md](lessons/rules-that-stuck.md).

## What isn't here

The tag schema and personal-context files are deliberately excluded — a tag
vocabulary derived from someone's real usage is their footprint, not a reusable
artifact. The pattern is the transferable part: **one file listing allowed tags
with one-line semantics, and a hard rule that the agent never invents tags —
untagged beats force-fit.**

## License

MIT. See [LICENSE](LICENSE).
