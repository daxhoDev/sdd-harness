---
name: init
description: Install the SDD harness (AGENTS.md, CLAUDE.md, Specifier/Implementer/Reviewer/Researcher subagents and the docs/sdd/ skeleton) into the current project. Manual use only.
disable-model-invocation: true
---

# init — install the SDD harness

Copy the SDD harness templates into the current project. This skill **only copies files**: it creates no branches, makes no commits and never pushes. Never make a decision on your own — whenever something below says "ask", ask the user one question at a time, with options, and wait for the answer.

## Template layout

Templates live in `${CLAUDE_SKILL_DIR}`:

- `core/` — agent-neutral content:
  - `core/AGENTS.md`
  - `core/docs/sdd/` (`MAIN.md`, `CONVENTIONS.md`, `CHANGELOG.md`, `DEVIATIONS.md`, `_TEMPLATE.md`)
  - `core/roles/<role>.md` — body of each subagent role (`specifier`, `implementer`, `reviewer`, `researcher`)
- `adapters/claude-code/` — Claude Code adapter:
  - `CLAUDE.md`
  - `agents/<role>.frontmatter.md` — frontmatter of each subagent

## Target files

| Target (project root) | Source |
|---|---|
| `AGENTS.md` | `core/AGENTS.md` |
| `CLAUDE.md` | `adapters/claude-code/CLAUDE.md` |
| `.claude/agents/<role>.md` | `adapters/claude-code/agents/<role>.frontmatter.md` immediately followed by `core/roles/<role>.md` (concatenated, byte for byte) |
| `docs/sdd/MAIN.md`, `CONVENTIONS.md`, `DEVIATIONS.md` | `core/docs/sdd/` |
| `docs/sdd/_TEMPLATE.md` | `core/docs/sdd/_TEMPLATE.md` |
| `docs/sdd/CHANGELOG.md` | `core/docs/sdd/CHANGELOG.md`, replacing `{{DATE}}` with today's date (`YYYY-MM-DD`) and `{{VERSION}}` with the `version` in `${CLAUDE_SKILL_DIR}/../../.claude-plugin/plugin.json` |

No other placeholder exists; every other file is copied unchanged.

## Steps

1. **Git check.** Run `git rev-parse --is-inside-work-tree` and `git rev-parse HEAD` in the project root.
   - If the project is not a git repository, or has no commits, tell the user and ask whether to run `git init` and/or make an initial commit before continuing, or to stop. Do only what the user chooses.
2. **Conflict check.** For every target file, check whether it already exists.
   - If any exist, list them all, then ask the user, file by file, what to do (e.g. keep the existing file, overwrite it, or stop the whole installation). Do not touch anything until every conflict is resolved.
3. **Copy.** Create the target files as described in the table above (create directories as needed). Do not modify any other file.
4. **Verify.** Confirm every target file exists, that each `.claude/agents/<role>.md` starts with its frontmatter and contains its role body, and that no `{{` placeholder remains in `docs/sdd/CHANGELOG.md`.
5. **Report** to the user:
   - the files created (and any kept or skipped by the user's choice);
   - that nothing was committed and no branch was created;
   - that the subagents load in a new session (restart Claude Code in this project if they do not appear);
   - that from now on the project follows `AGENTS.md`.
