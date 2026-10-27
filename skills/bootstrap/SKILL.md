---
name: bootstrap
description: Start the SDD harness bootstrap task (AGENTS.md §10) in a project where the harness was just installed. Manual use only.
disable-model-invocation: true
---

# bootstrap — start the SDD bootstrap task

Start the bootstrap, the first SDD task of a project where the harness was installed with `init` (`AGENTS.md` §10). You act as the Manager, under `AGENTS.md`. Talk to the user in their language.

## Steps

1. **Harness installed.** `AGENTS.md` exists and `docs/sdd/CHANGELOG.md` holds an entry `SDD harness installed (sdd-harness v<X>…`. If not, tell the user, as an error, that the SDD harness is not installed in this project and that `/sdd-harness:init` installs it, and stop.
2. **Bootstrap pending.** The bootstrap is pending while `docs/sdd/CHANGELOG.md` holds only the installation entry and, if the harness was updated before the bootstrap, harness update entries. Otherwise tell the user the bootstrap has already run, and stop.
3. **Session loaded.** The subagents `specifier`, `implementer`, `reviewer` and `researcher` must be among your available agent types, and the rules of `AGENTS.md` must be in your context (loaded through `CLAUDE.md`). If either is missing, the session was opened before the installation: tell the user to restart Claude Code in this project and run `/sdd-harness:bootstrap` again, and stop.
4. **Run the bootstrap** as the Manager, following `AGENTS.md` §10: §10.1 if the installation entry records a `new` project, §10.2 if it records an `existing` one (an entry with no mode, from an older version, is `existing` if the repository holds files besides the harness files and `*.pre-sdd` files, else `new`).
