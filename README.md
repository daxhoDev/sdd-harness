# sdd-harness

A Claude Code plugin that installs a **Spec Driven Development (SDD)** harness into any project. It ships three manual-only commands: `init` installs the harness, `bootstrap` runs its first task, and `update` brings an installed harness to the latest version.

The harness defines five roles:

- **Manager** — the main session; the only one that talks to the user.
- **Specifier** — checks feasibility, raises every decision to the user, and writes all documentation, including your project's `README.md`.
- **Implementer** — implements exactly what is documented.
- **Reviewer** — writes and runs tests from acceptance criteria, reviews compliance, and commits after the user's OK.
- **Researcher** — the only role that searches the internet or consults external APIs, only when needed and after the user's approval; returns a sourced report and writes no files.

Docs are the single source of truth, and agents never make decisions on their own. The full rules are in [`docs/prompt.md`](docs/prompt.md) and in the installed `AGENTS.md`.

## How it works

Every task follows the same loop:

1. You describe the task; the Manager asks questions, one at a time and with options, until it is clear.
2. The Specifier checks it against the docs and the code, brings you every pending decision with a recommended option, and then writes the specs (requirements, acceptance criteria and implementation phases) in `docs/sdd/`.
3. **Stop 1:** you approve the specs or ask for changes. The Manager then creates a task branch from `development`.
4. The Implementer builds what the specs say, and reports anything that does not fit before writing code.
5. The Reviewer writes and runs tests derived from the acceptance criteria and checks compliance; gaps loop back to the Implementer, and spec errors come back to you.
6. **Stop 2:** you give the OK to close the phase. The Specifier closes it in the docs (CHANGELOG, versions, `README.md`) and the Reviewer commits.

Once the stack is decided, the harness also gets an environment preflight script: before each phase the Manager runs it, and nothing is implemented while the runtime is missing or the tests fail. To save tokens, each subagent is reused across the hand-offs of a phase (it gets only what is new and re-reads only what others changed), and every new phase or task starts with fresh ones. No agent ever pushes or merges; that stays with you. Nothing the agents write (commits, PRs, docs, code) carries an AI co-author or attribution mark.

## Install

Requires [Claude Code](https://claude.com/claude-code). In Claude Code:

```
/plugin marketplace add daxhoDev/sdd-harness
/plugin install sdd-harness@daxhodev
```

The first command adds this GitHub repository as a plugin marketplace; the second installs the plugin from it.

### Update

```
/plugin marketplace update daxhodev
```

Updating the plugin does not touch projects you already initialized: their files were copied and are yours to edit. To update the harness inside a project, see [Update a project](#update-a-project).

### Uninstall

```
/plugin uninstall sdd-harness@daxhodev
/plugin marketplace remove daxhodev
```

### Local development

To try changes from a local clone, add the clone as the marketplace instead:

```
git clone https://github.com/daxhoDev/sdd-harness.git
/plugin marketplace add ./sdd-harness
/plugin install sdd-harness@daxhodev
```

## Use

In the project you want to initialize:

```
/sdd-harness:init
```

The skill only copies files:

- `AGENTS.md`
- `CLAUDE.md`
- `.claude/agents/{specifier,implementer,reviewer,researcher}.md`
- `docs/sdd/` (`MAIN.md`, `CONVENTIONS.md`, `CHANGELOG.md`, `DEVIATIONS.md`, `_TEMPLATE.md`)

It welcomes you and asks one question: new project or existing project. If you choose "new" but the project already has docs or code, it tells you and treats it as existing, so nothing you have is lost. It creates no branches and makes no commits, and asks about git only if the project is not a repository or has no commits. A file it would replace (e.g. an existing `CLAUDE.md`) is renamed to `<file>.pre-sdd` instead of being overwritten.

Then restart Claude Code in the project (the subagents and `AGENTS.md` load only in a new session) and start the bootstrap, the first SDD task (`chore/sdd-bootstrap`):

```
/sdd-harness:bootstrap
```

Until the bootstrap has run, the Manager starts no other task. In a new project it commits the harness files after your OK. In an existing project the Specifier first takes an inventory of the repository, then reads every document (docs, specs from tools such as spec-kit, Kiro or OpenSpec) and the code those documents describe, and rewrites everything in the harness format, keeping all the information you already had. It asks you only about divergences (docs that contradict each other or the code); everything is committed after a single approval of the result. Code that no document describes is not specified up front: its module is marked as pending extraction, and the Specifier writes its specs the first time a task touches that code, approved with the task's own specs. The Reviewer checks that nothing was lost through a migration map that links every section of every original to where its content went. Originals whose content was migrated are deleted at the close (they remain in the git history); files like `README.md` or `LICENSE` are never deleted.

### Your project's README

The Specifier also drafts your project's `README.md` and keeps it in sync with the docs. It is written for your repository's GitHub page: the project name and a one-line description, then only the sections the docs support (features, requirements, installation, usage, configuration, development, license). It describes only what is documented and implemented, never planned work, and carries no harness internals (requirement IDs, spec versions, the SDD workflow). It is updated at the close of every phase or task, so each commit ships a README that matches the code. Screenshots, badges, credits and other content that is not specification are kept as you wrote them.

In an existing project the bootstrap brings your current README in line with these rules, keeping all of its information; if there is none, the Specifier creates one. After a harness update, a README that does not follow them is fixed in the update task.

### Lightweight tasks

For trivial changes (a colour, moving a button a few pixels, renaming a variable), add `sdd: false` to your request: the Manager skips the full flow and calls only the subagents the change needs, and you still give the OK before the commit. If the task looks bigger than that, the Manager warns you and recommends the full flow; if an unmarked task looks trivial, it recommends `sdd: false`. You always decide.

## Update a project

In a project that already has the harness:

```
/sdd-harness:update
```

It downloads the latest version of the harness from this GitHub repository (no marketplace update needed; it needs network and git) and merges it into the project's harness files, keeping your own changes. It asks you only when your changes and the new version touch the same text. Your spec modules are never touched, and `CHANGELOG.md` gets an entry for the update. If the harness is not installed, it says so and offers to install it (the latest version); if you decline, it stops.

Like `init`, it creates no branches and makes no commits. In the next session the Manager runs the `chore/sdd-update-v<version>` task: the Reviewer checks the updated files and your existing docs against the new rules, and everything is committed after your OK.

Each release is tagged `v<version>` so the update can find the version a project was installed with.

## Layout

```
.claude-plugin/
├── plugin.json
└── marketplace.json          # this repo is its own marketplace
skills/
├── init/
│   ├── SKILL.md              # installs the harness
│   ├── core/                 # agent-neutral templates
│   │   ├── AGENTS.md
│   │   ├── docs/sdd/...
│   │   └── roles/<role>.md   # body of each subagent role
│   └── adapters/
│       └── claude-code/      # Claude Code adapter
│           ├── CLAUDE.md
│           └── agents/<role>.frontmatter.md
├── bootstrap/
│   └── SKILL.md              # starts the bootstrap task
└── update/
    └── SKILL.md              # updates an installed harness from GitHub
docs/
└── prompt.md                 # reference prompt the harness was built from
```

Each `.claude/agents/<role>.md` is generated by joining the Claude Code frontmatter with the neutral role body. Support for other agents (e.g. Gemini CLI) is planned as additional adapters.

The subagents are **not** shipped as plugin agents. They are copied into each project, so they are only active in initialized projects.

## Contributing

Issues and pull requests are welcome at <https://github.com/daxhoDev/sdd-harness>.

## License

[MIT](LICENSE)
