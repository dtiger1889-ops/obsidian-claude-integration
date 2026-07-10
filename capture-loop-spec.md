---
created: 2026-07-01
updated: 2026-07-01
tags:
  - spec
  - obsidian
  - meta
---
# Capture → action-items loop — `/process-inbox` spec

> Goal: a note written on the phone (lands in `00 Inbox/` via Syncthing) becomes
> **durable reference filed into the PARA vault** + **to-dos pushed into life-os**,
> with Claude doing the bookkeeping and the user approving every write (v1 scope).
> This is the "ingest" op of the Karpathy LLM-wiki model, extended with the
> life-os action bridge. Companion doc: `integration-spec.md` (the two-lanes model).

## The pipeline (one processing pass)

```
00 Inbox/*.md ──sweep──> parse ──classify──> PROPOSAL TABLE ──the user approves──> execute ──report
                                                                    │
                                              reference ──> PARA vault (dated, [[linked]], tagged)
                                              action     ──> lifeos.py add-task (CLI)
                                              personal   ──> flag only, never auto-file
                                              junk       ──> propose disposition, the user decides
```

### 1. Sweep
- Enumerate `00 Inbox/*.md`.
- **Skip** `*.sync-conflict-*` (flag, don't act — standing rule).
- **Skip** notes with `status: pinned` in frontmatter — pinned means "lives in the
  inbox on purpose" (e.g. a quick-reach command note). This is
  the opt-out lever: the user pins anything the processor should leave alone.

### 2. Parse
- YAML frontmatter observed in real inbox notes: `created`, `updated`, `due`,
  `tags`, `status`. `created` supplies the dated-provenance date when filing;
  `due` carries into the life-os task (and stays TaskNotes-compatible for the
  phone-reminders thread — don't strip it).
- Body may be **mixed** — the real `Todos.md` contains a wikilink, two tasks, and
  a complaint in five lines. Classification is per-chunk, not per-note.

### 3. Classify (per chunk)
| Class | Test | Destination |
|---|---|---|
| **Action item** | "do X" — a verb the user must perform, incl. `Dispatch:` items | life-os task (text, `--due` from frontmatter/inline, `--context` if obvious) |
| **Durable reference** | useful again later, answers a future situation | PARA file per retrieval-context rule; tag from `tag-schema.md` (never invent tags) |
| **Personal** (journal / rage / relationship / medical detail) | your tag-schema personal-content territory | NEVER auto-file. Leave in inbox, flag to the user with a suggestion |
| **Ephemeral / junk** | stale one-liner, done already, fragment | propose leave-or-delete; the user decides (no unsolicited deletes — hard rule) |

Ambiguity rule: when a chunk could be task or reference, it's **both** — file the
reference AND push the task (e.g. "do X after shipping Y
calendar exporter" = a task with a dependency note).

### 4. Propose (the v1 gate)
One plain-language table per pass: `note → chunk → class → exact destination →
exact text to be written`. the user approves / edits / rejects per line. Nothing is
written before this. Options must be short and jargon-free.

### 5. Execute (approved items only)
- **Reference →** append `## <Title> — <YYYY-MM-DD>` (date = note's `created`) to
  the target vault file, or create a new file when the situation is new (split,
  don't cram). Add `[[wikilinks]]` to related notes; tags per schema.
- **Tasks →** `python <WORKSPACE>\life-os\homebase\lifeos.py
  add-task "<text>" [--priority p] [--due YYYY-MM-DD] [--context c]`
  — **CLI direct, not the MCP.** The lifeos MCP is a Claude *Desktop* extension
  (`.mcpb` in AppData) and is not registered in Claude Code; but the MCP server
  itself just shells to `lifeos.py` per call (`mcp-extensions/life-os/server/index.js:715`),
  so the CLI is the same engine with zero drift. Verify the exact invocation
  (python vs py, arg quoting) once at build time.
- **Processed-note disposition →** per the approved plan (open decision below).

### 6. Report
End-of-pass summary in chat: N notes swept, M filed, K tasks pushed, what was
skipped/flagged and why. A vault `log.md` (append-only, `## [date] ingest — …`)
is the Karpathy-op version — add it when the loop runs regularly, not v1.

## Worked example — three hypothetical inbox notes and how each routes
- **A mixed to-do note**: an actionable line ("do X after deploying Y") → task
  system. A dispatch-style line pointing at a `[[topic note]]` to investigate →
  task with context attached. A line that's feedback about a past assistant
  session → flag to the user, don't file (it's not vault reference material).
  A bare `[[wikilink]]` with no verb → context only, nothing to do.
- **A scratchpad tip** (a durable how-to the user jotted down) → reference note
  under the matching `Areas/` folder, tagged, dated section.
- **A pinned command note**: `status: pinned` → skipped, stays put.

## Skill packaging
- **`~/.claude/skills/obsidian/`** (user-level, per integration-spec): the umbrella
  skill — orient via vault `HOME.md`, query/read, capture-to-inbox.
- **`/process-inbox`** = a mode/argument of that skill (`/obsidian process-inbox`
  or its own thin SKILL.md that shares the conventions file). Shared conventions
  (PARA map, dated provenance, tag pointer, personal-content gate) live ONCE —
  in vault `HOME.md` or a vault-level agent doc — and both read it.
- **`HOME.md` is a build prerequisite** (the processor's orientation input):
  single-screen PARA map + conventions. Build it first, same work session
  (~20 min, also closes spec Phase 1 along with the 3 CHECKPOINT pointers).

## Scope ladder (v1 → later)
1. **v1 (build now): propose-then-approve.** Every vault write and every task push
   shown before execution. Runs manually (the user invokes when at the PC).
2. v2: auto-file the *safe* classes (clear reference, clear tasks), still flag
   personal/ambiguous. Needs a few clean v1 passes as evidence first.
3. v3: scheduled/dispatch runs + `log.md` + lint op (contradictions, orphans,
  stale claims) — the full self-maintaining wiki.

## Decisions (settled 2026-07-01 — model-recommended defaults, the user accepted)
1. **Processed-note disposition: move to vault `Archive/`.** Inbox stays clean;
   the original survives in case a filing went wrong. Not stamp-and-leave, not delete.
2. **Skill shape: ONE `/obsidian` skill** with process-inbox as a mode
   (`/obsidian process-inbox`), alongside query/read and capture.
3. **Conventions home: `HOME.md` carries both** — human folder map on top,
   agent rules (filing conventions, tag pointer, personal-content gate) below.
   No separate vault CLAUDE.md.

## Open decisions (the user)
- Is `status: pinned` the right opt-out convention, or prefer a different marker?
