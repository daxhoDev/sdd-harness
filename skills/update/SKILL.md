---
name: update
description: Update the SDD harness installed in the current project to the latest version published on GitHub, merging it with the project's own changes; offers to install it if it is missing. Manual use only.
disable-model-invocation: true
---

# update — update the SDD harness to its latest version

Bring the harness files of the current project up to the latest version of the harness, downloaded from GitHub, without updating the plugin from the marketplace. This skill **only changes files**: it creates no branches, makes no commits and never pushes. The commit happens in the next session, through the `chore/sdd-update-v<NEW>` task (`AGENTS.md` §10.3). Ask the user as little as possible: only the questions below, one at a time, with options, waiting for each answer. Talk to the user in their language.

Repository: `https://github.com/daxhoDev/sdd-harness.git`.

## Files

Paths below are relative to a checkout of the harness repository (`skills/init/...`) and to the project root.

| Kind | Project file | Template |
|---|---|---|
| Harness | `AGENTS.md` | `skills/init/core/AGENTS.md` |
| Harness | `CLAUDE.md` | `skills/init/adapters/claude-code/CLAUDE.md` |
| Harness | `.claude/agents/<role>.md` | `skills/init/adapters/claude-code/agents/<role>.frontmatter.md` immediately followed by `skills/init/core/roles/<role>.md` (concatenated, byte for byte) |
| Harness | `docs/sdd/_TEMPLATE.md` | `skills/init/core/docs/sdd/_TEMPLATE.md` |
| Harness | `.claude/hooks/sdd-git-guard.sh` | `skills/init/adapters/claude-code/hooks/sdd-git-guard.sh` |
| Project doc | `docs/sdd/MAIN.md`, `CONVENTIONS.md`, `DEVIATIONS.md` | `skills/init/core/docs/sdd/` |

- `docs/sdd/CHANGELOG.md` is never merged: the update only adds its entry (step 7).
- `.claude/settings.json` is never merged line by line: it holds the project's own settings. The update only makes sure it registers the hook of the new template (`skills/init/adapters/claude-code/settings.json`): it replaces the entry that runs `sdd-git-guard.sh` with the template's, or adds it to `hooks.PreToolUse` if missing (creating the file if the project has none), and keeps everything else as it is.
- Spec modules (every other `.md` in `docs/sdd/`) are never touched: the `chore/sdd-update-v<NEW>` task adapts them to the new rules if needed.
- `<role>` is every role present in either version of the templates.

## Steps

1. **Detect the harness.** The harness is installed if `docs/sdd/CHANGELOG.md` holds an entry `SDD harness installed (sdd-harness v<X>…`. The installed version is the `<Y>` of the last entry `SDD harness updated (sdd-harness v<X> → v<Y>)`, or else the `<X>` of the installation entry.
   - **Not installed:** tell the user, as an error, that the SDD harness is not installed in this project, and ask whether to install it now (install — recommended, or stop). If they decline, stop. If they accept, download the latest version (step 3) and follow the steps of its `skills/init/SKILL.md`, reading `${CLAUDE_SKILL_DIR}` there as `<checkout>/skills/init`. Then clean up (step 9) and stop.
2. **Working tree.** If `git status --porcelain` shows uncommitted changes, tell the user (a short summary) and ask: continue (the update's changes will mix with theirs in the same commit) or stop so they can commit first (recommended). Do only what they choose.
3. **Download.** Clone the repository into a new temporary directory (`mktemp -d`) with `git clone --filter=blob:none <repo> <checkout>`. If it fails (no network, no git), report the error and stop. The latest version `<NEW>` is the `version` in `<checkout>/.claude-plugin/plugin.json`.
   - `<NEW>` equals the installed version: tell the user the harness is already up to date, clean up (step 9) and stop.
   - `<NEW>` is older than the installed version: report it and stop.
4. **Base version.** The base for the merge is the commit of the installed version `<OLD>`: the tag `v<OLD>` if it exists, or else the oldest commit whose `.claude-plugin/plugin.json` has `"version": "<OLD>"` (walk `git log --format=%H -- .claude-plugin/plugin.json`). Check it out into a second directory with `git worktree add <base> <commit>`. If neither exists, there is no base: step 5 treats every file that differs from the new template as a conflicting file.
5. **Merge.** For every harness file and project doc in the table, build the base and new templates from `<base>` and `<checkout>` (agents: frontmatter + role body), then:
   - Project file missing and template new in `<NEW>`: create it from the new template.
   - Template removed in `<NEW>`: if the project file equals the base template, delete it; otherwise ask (keep it, or delete it).
   - Otherwise run `git merge-file -p <project file> <base template> <new template>` into a temporary file. With no conflicts, it replaces the project file. With conflicts, resolve each conflicting hunk with the user, one at a time: show what the project has and what the new version has, and ask: keep the project's text, take the new version's, or a combined text you propose (recommended when both changes can live together).
   - With no base: if the project file equals the new template, nothing changes; otherwise show a summary of the differences and ask: take the new version (recommended when the project never customized the file), keep the project's file, or a combined version you propose.
   - Then bring `.claude/settings.json` up to date as described under *Files* (only its hook entry).
6. **Verify.** Every harness file exists; each `.claude/agents/<role>.md` starts with its frontmatter and contains its role body; `.claude/settings.json` is valid JSON with exactly one hook entry running `sdd-git-guard.sh`, and the hook script is executable; no conflict marker (`<<<<<<<`, `=======`, `>>>>>>>`) remains in any file.
7. **CHANGELOG entry.** In `docs/sdd/CHANGELOG.md`, under `## [Unreleased]`, add to the `### Changed` category (creating it if missing, in Keep a Changelog order) the line `- <YYYY-MM-DD> · SDD harness updated (sdd-harness v<OLD> → v<NEW>) · <files changed>`.
8. **Report** to the user, briefly:
   - the versions (`v<OLD>` → `v<NEW>`) and the main changes of the harness between them (from the commit subjects in `<checkout>`, `git log --format=%s <base commit>..HEAD`);
   - the files created, merged, kept or deleted, and the conflicts resolved;
   - that nothing was committed and no branch was created;
   - that the new rules and subagents load in a new session (restart Claude Code in this project), where the Manager runs the `chore/sdd-update-v<NEW>` task (`AGENTS.md` §10.3): the Reviewer checks the updated files and the existing docs against the new rules, and everything is committed after the user's OK. If the bootstrap has not run yet, there is no update task: `/sdd-harness:bootstrap` covers the update.
9. **Clean up.** Remove the worktree (`git worktree remove`) and the temporary directory, whatever the outcome.
