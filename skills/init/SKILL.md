---
name: init
description: Install the SDD harness (AGENTS.md, CLAUDE.md, Specifier/Implementer/Reviewer/Researcher subagents, the git guard hook and the docs/sdd/ skeleton) into the current project. Manual use only.
disable-model-invocation: true
---

# init — install the SDD harness

Copy the SDD harness templates into the current project. This skill **only copies files** (and moves aside the files it would replace, step 4): it creates no branches, makes no commits and never pushes. Ask the user as little as possible: only the questions below, one at a time, with options, waiting for each answer. Talk to the user in their language.

## Template layout

Templates live in `${CLAUDE_SKILL_DIR}`:

- `core/` — agent-neutral content:
  - `core/AGENTS.md`
  - `core/docs/sdd/` (`MAIN.md`, `CONVENTIONS.md`, `CHANGELOG.md`, `DEVIATIONS.md`, `_TEMPLATE.md`)
  - `core/roles/<role>.md` — body of each subagent role (`specifier`, `implementer`, `reviewer`, `researcher`)
- `adapters/claude-code/` — Claude Code adapter:
  - `CLAUDE.md`
  - `agents/<role>.frontmatter.md` — frontmatter of each subagent
  - `settings.json` — registers the git guard hook
  - `hooks/sdd-git-guard.sh` — the git guard hook (`AGENTS.md` §5)

## Target files

| Target (project root) | Source |
|---|---|
| `AGENTS.md` | `core/AGENTS.md` |
| `CLAUDE.md` | `adapters/claude-code/CLAUDE.md` |
| `.claude/agents/<role>.md` | `adapters/claude-code/agents/<role>.frontmatter.md` immediately followed by `core/roles/<role>.md` (concatenated, byte for byte) |
| `.claude/hooks/sdd-git-guard.sh` | `adapters/claude-code/hooks/sdd-git-guard.sh` (executable) |
| `.claude/settings.json` | `adapters/claude-code/settings.json`; if the project already has one, it is merged instead (step 4) |
| `docs/sdd/MAIN.md`, `CONVENTIONS.md`, `DEVIATIONS.md` | `core/docs/sdd/` |
| `docs/sdd/_TEMPLATE.md` | `core/docs/sdd/_TEMPLATE.md` |
| `docs/sdd/CHANGELOG.md` | `core/docs/sdd/CHANGELOG.md`, replacing `{{DATE}}` with today's date (`YYYY-MM-DD`), `{{VERSION}}` with the `version` in `${CLAUDE_SKILL_DIR}/../../.claude-plugin/plugin.json`, and `{{MODE}}` with the project mode (`new` or `existing`, step 3) |

No other placeholder exists; every other file is copied unchanged.

## Steps

0. **Already installed.** If `docs/sdd/CHANGELOG.md` holds an entry `SDD harness installed (sdd-harness v<X>…`, the harness is already installed: installing it again would move its own files aside as `.pre-sdd` and migrate them as if they were the project's docs. Tell the user, recommend `/sdd-harness:update` to bring it to the latest version, and stop.
1. **Welcome.** Greet the user and explain in two or three lines what is about to happen: the harness (a Spec Driven Development workflow with a Manager and four subagents) is installed by copying files; nothing is committed; after restarting Claude Code, `/sdd-harness:bootstrap` starts the bootstrap task. Then ask the only mode question:
   - **New project** — starting from scratch: the harness templates are applied as they are.
   - **Existing project** — the project already has code or documentation: in the bootstrap the existing docs are rewritten in the harness format as the first SDD task, for the user's approval, and code no document describes is specified the first time a task touches it. No information is lost.
2. **Git check.** Run `git rev-parse --is-inside-work-tree` and `git rev-parse HEAD` in the project root. Only if the project is not a git repository, or has no commits, ask one question: run `git init` and/or make an initial commit before continuing (recommended), or stop. Do only what the user chooses.
3. **Mode check.** List the project's files with `git ls-files --cached --others --exclude-standard` (or, without git, every file except `.git/`). Any file that is not a target file means the project already has content.
   - Mode `new` with existing content: tell the user what was found (a short summary, not the full list) and that the project is therefore treated as existing, so nothing they already have is lost. Do not ask again; the mode is `existing`.
   - Otherwise the mode is the one the user chose.
4. **Conflicts.** `.claude/settings.json` holds the project's own settings and is never moved aside: if it exists, add the template's `PreToolUse` entry to its `hooks.PreToolUse` array (creating `hooks` and the array if missing), unless an entry already runs `sdd-git-guard.sh`, and keep everything else as it is. For every other target file that already exists, do not ask: rename it to `<file>.pre-sdd` in the same directory (e.g. `CLAUDE.md` → `CLAUDE.md.pre-sdd`, `.claude/agents/reviewer.md` → `.claude/agents/reviewer.md.pre-sdd`). The suffix keeps Claude Code from loading it as guidance or as an agent, and keeps the harness from reading it as a spec. Any existing target file means the mode is `existing`. The bootstrap migrates the content of these files and deletes them at its close (`AGENTS.md` §10.2).
5. **Copy.** Create the target files as described in the table above (create directories as needed). Do not modify any other file.
6. **Verify.** Confirm every target file exists, that each `.claude/agents/<role>.md` starts with its frontmatter and contains its role body, that `.claude/settings.json` is valid JSON with exactly one hook entry running `sdd-git-guard.sh`, that the hook script is executable, that no `{{` placeholder remains in `docs/sdd/CHANGELOG.md`, and that every renamed file exists with its `.pre-sdd` suffix.
7. **Report** to the user, briefly:
   - the mode (and, if it changed from the user's choice, why);
   - the files created, and any file renamed to `.pre-sdd`;
   - that nothing was committed and no branch was created;
   - the next step: restart Claude Code in this project (the subagents and `AGENTS.md` load only in a new session) and run `/sdd-harness:bootstrap`;
   - what the bootstrap does (`AGENTS.md` §10): in a new project, the Manager commits the harness files on `chore/sdd-bootstrap` after the user's OK; in an existing project, the Specifier takes an inventory of the repository, reads the docs and the code they describe, and rewrites the docs in the harness format, asking the user only about divergences; code no document describes is specified later, the first time a task touches it; everything is committed after a single approval of the result.
