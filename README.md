# obsidian-claude-integration

Design docs for wiring **Claude Code to an Obsidian vault** as a second-brain system: the vault is the durable reference layer (PARA structure, phone capture via Syncthing), Claude is the librarian that files things, and action items get pushed to whatever task system you use. Modeled on the "LLM-maintained wiki" idea, adapted to PARA.

These are lightly-anonymized copies of the real, running system's design docs — not a polished tutorial. Read them as a worked example to adapt: where they say `life-os` / `lifeos.py`, substitute your own task manager; where they reference a tag-schema file, write your own (the pattern: a single file listing allowed tags with one-line semantics, and a hard rule that the agent never invents tags — untagged beats force-fit).

## The docs

| Doc | What it covers |
|---|---|
| [SYSTEM-OVERVIEW.md](SYSTEM-OVERVIEW.md) | The whole system in one read: what lives where, the daily capture-to-filed flow, design rationale |
| [integration-spec.md](integration-spec.md) | The two-lanes model: which project folders get a vault pointer and which never touch the vault; personal-content rules; the agent skill's phased capabilities |
| [capture-loop-spec.md](capture-loop-spec.md) | The inbox-processing pipeline: sweep phone captures, classify per chunk (action / reference / personal / junk), propose a table, human approves every write, then file + push tasks + archive |

## Design rules that carried the system

- **Propose-then-approve everything** (v1): the agent never writes to the vault or pushes a task without a per-line human approval. Trust is earned by boring proposals, not assumed.
- **Classify per chunk, not per note** — phone captures are mixed; one note can hold a task, a reference, and a vent.
- **Personal content is never auto-filed.** Journal, venting, relationship, and medical material gets flagged with a suggestion and left alone.
- **Archive, never delete**: processed notes move to `Archive/` with a pointer line saying where their content went.
- **Dated provenance**: every consolidated entry carries the capture date from the source note's frontmatter. The date is the spine.
- **A note is done only when every chunk is filed or explicitly closed** — never inferred from reading it.

## License

MIT. See [LICENSE](LICENSE).
