# Deploying one skill to two runtimes: Cowork device-bridge lessons

Context: the ask was to build a Cowork (Claude desktop/cloud) plugin that "matches" an existing Claude Code CLI skill — the vault-processing skill these design docs describe — so the same second-brain workflow runs in both runtimes. The build surfaced that a core, long-standing assumption was false, plus a clean reusable pattern for running one skill across two runtimes.

Observed first-hand on 2026-07-17 against a live machine. Cowork and the desktop app are moving targets; re-verify tool names and behavior before relying on specifics.

---

## Headline

**The old rule "Cowork is a cloud sandbox and can't see the local machine" is dead.** A connected Claude desktop app now exposes a device bridge (`mcp__remote-devices__*`) that lets a cloud Cowork session read, write, move, and search files on the user's actual computer, run shell commands in a local Linux workspace over the connected folders, and call the user's locally-installed MCP servers. Local-first workflows that were previously "Claude Code CLI only" (a local Obsidian vault, a local SQLite task DB, anything living on disk) are now reachable from Cowork too.

Anywhere a doc says "this is a local-Claude-Code-only feature," re-check it.

## Lesson 1 — What the device bridge actually gives you

When a desktop is connected, Cowork gains:

- **Filesystem tools** (`mcp__remote-devices__Filesystem__*`): read, write, edit, move, and filename-search files, scoped to folders the user has connected.
- **`device_bash`**: a shell in a local Linux workspace with the connected folders mounted under `mnt/<folder-name>`. This is separate from the cloud container's own `bash`; the two filesystems do not share state. Use it for content search (`grep -ril`) and anything the Filesystem tools can't express. Note it cannot delete files (move them into a `_to_delete/` folder instead).
- **Proxied local MCP servers**: the user's own local MCP servers appear as `mcp__remote-devices__<server>__*`. In the build session, the local task-system MCP was directly callable, so a Cowork skill can add a task with an MCP tool instead of shelling to a script.

Path convention gotcha: the Filesystem tools speak the host's native paths (Windows `C:\...` on this machine), while `device_bash` speaks the Linux mount paths (`mnt/<folder>`). Same files, two path languages; keep them straight.

## Lesson 2 — One skill, two runtimes: single-source + thin adapters, NOT symlinks

The task was to make a Cowork skill "match" an existing Claude Code CLI skill. The two cannot be byte-identical because they bind different tools (the CLI uses Read/Grep/Bash and a python CLI; Cowork uses the device-bridge Filesystem tools and MCPs). The durable answer:

- **Put all behavior in one platform-agnostic core file on disk** (the modes, the pipeline, the decision rules) that both runtimes read at runtime.
- **Each runtime gets a thin adapter** that only maps the core's abstract actions ("read a note", "move to archive", "add a task") onto its own tools.
- Change a rule once in the core, and both platforms inherit it on their next run. No copies, no re-packaging.

**Why symlinks are the wrong tool here** (this came up as the first instinct, worth refuting cleanly):

1. The two adapters are genuinely different files (different plumbing), so forcing them identical fights the design.
2. Windows symlinks need admin/Developer Mode, and sync tools (Syncthing) and git handle them inconsistently.
3. An installed Cowork plugin's skill is registered content, not a live editable file on disk, so there is nothing to point a symlink at, and a cloud session cannot resolve a local-disk symlink anyway.

The generalizable principle: when the same capability must exist in two runtimes with different tool surfaces, separate *behavior* (single-sourced data on disk) from *tool bindings* (thin per-runtime adapters). This applies well beyond this one skill.

## Lesson 3 — Folder access and protected locations

- **Folders must be explicitly connected** to a Cowork session before the bridge can touch them. You can programmatically request access to a normal grantable folder (a dialog opens on the device), or the user adds it via the desktop "Add folder" button.
- **Protected locations refuse connection AND writes.** Config directories like `~/.claude` (and, at the home root, dotfolders generally) are blocked. You cannot connect them and cannot write into them via the bridge.
- **Workaround for protected reads/writes:** shuttle the file through an already-connected normal folder. Copy the protected file out with a one-line command into a shared folder to read it; write the new version into that shared folder and copy it back with a second command. Slightly clumsy, fully reliable.
- **Git commits need the repo root connected.** If only a subfolder is shared, `.git` sitting in a parent directory is unreachable and git fails at the mount boundary. Either connect the repo root, or hand the user the commit command to run themselves.

## Lesson 4 — Building the matching plugin

A Cowork plugin is a small bundle: `.claude-plugin/plugin.json` (name is the only hard requirement) plus `skills/<name>/SKILL.md`. Zip it as a `.plugin` file and deliver it; it renders in chat as an installable card. Design notes that worked:

- Keep the skill a **thin adapter** that reads the shared core at runtime (see Lesson 2), so the plugin rarely needs re-packaging.
- Have the skill **self-request its folders on startup** and refuse to proceed until they are connected, so a fresh session degrades gracefully.
- **Verify every binding live** against the real target before claiming parity. A different tool surface means re-testing each action: read, filename search vs content search, move, and the MCP task-add all had to be confirmed against the actual data, not assumed.

---

## Sources

Grounded in direct tool behavior against a live machine (device bridge Filesystem + `device_bash` calls, folder-access request results, the protected-location refusal on `~/.claude`, and the plugin build/verify pass), plus the Cowork plugin-authoring skill for the bundle format. No external web sources; this is first-hand runtime observation from 2026-07-17.
