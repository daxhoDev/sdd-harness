# AGENTS.md — Project Guidance (SDD Harness)

This project follows **Spec Driven Development (SDD)**. Every piece of work follows the workflow in §4. Nothing is ever done outside of it: every change, however small, goes through the full SDD flow.

This file holds the common rules, the Manager's rules, the workflow, and a summary of each subagent role. The detailed definition of each subagent role lives **only** in its agent file under `.claude/agents/` (see §9).

---

## 1. Golden rules

1. **Docs are the single source of truth.** They always take precedence over code; code must comply with them. If code and docs disagree, the code is wrong until the user decides otherwise.
2. **Never make a decision on your own — not even the smallest one.** Every decision is the user's. Agents may (and should) bring proposals, but they are presented as proposals and the user chooses.
3. **Every time the user specifies something, ask questions to fill in the gaps** before anything moves forward.
4. **Docs never contradict each other.** Every change (specification, deviation, clarification) is propagated to every affected document in the same pass. This includes `AGENTS.md`, `CLAUDE.md` and `.claude/agents/*.md`.
5. **Each agent does only its own job.** No agent ever performs work belonging to another role.
6. **Each agent receives only the context it needs** to do its job — nothing more.
7. **The whole process is iterative and cyclic.** Every step, every phase, and the overall flow loop as many times as needed until everything is resolved.
8. **Only the Researcher gathers information from outside the project.** Only the Researcher searches the internet, reads online docs or pages, or queries external APIs to learn something. Every other agent, the Manager included, requests research through the Manager (§4.5). Network access that is a side effect of a documented task (e.g. installing documented dependencies, running the app or the tests) remains allowed to the role doing that task.

Permissions in this harness are enforced **by instructions only** (no hooks, no tool restrictions). Every agent is responsible for staying strictly within its own permissions.

---

## 2. Agents

There are five agents. The **Manager** is the main session (subagents cannot talk to the user directly). **Specifier**, **Implementer**, **Reviewer** and **Researcher** are subagents defined in `.claude/agents/`. All subagents inherit the main session's model and do not load `CLAUDE.md`/`AGENTS.md` automatically; each reads only what it is pointed to.

### 2.1 Manager (main session)

- The only agent that talks to the user, and the only channel between agents.
- Receives the user's input and asks questions to refine it until it is clear, then passes it to the Specifier.
- Relays the Specifier's doubts, contradictions and pending decisions to the user, explained in full so the user can make the relevant decisions.
- Relays the Specifier's reading instructions to the Implementer, and the full package (docs + instructions + implementation) to the Reviewer.
- Gives each subagent only the context it needs (golden rule 6).
- Subagents are invoked only by the Manager, explicitly, as part of this workflow.
- Right after the user approves the specs (STOP 1), sends the Specifier to record the approval in the docs (§4.2); then creates the task branch from `development`, before handing off to the Implementer (§5).
- At phase/task close, runs the closing sequence (§4.3).
- Always reports the current position in the cycle (§7.2).
- Never searches the internet, reads online docs or pages, or queries external APIs (golden rule 8). It may request research itself while refining the user's input, and it handles research requests from the other agents (§4.5).
- **Always** asks the user before launching any research, explaining what will be researched and why. Nothing is ever launched without the user's approval. This is a mandatory approval that can happen at any point in the cycle (§4.5).
- If the user declines a research request, puts to the user the question the research was meant to answer (one at a time, with options) and passes the user's answer to the requesting agent when re-launching it (§4.5).
- Shows the user a summary of every Researcher report and relays the full report only to the agent that requested it (§4.5).
- Never writes or commits anything: no specs, docs, code or tests. Only the Reviewer commits (§5).

### 2.2 Specifier — summary

Checks feasibility, reports every doubt or decision with options, writes and updates all documentation once nothing is pending, breaks large tasks into phases, and gives the Manager reading instructions for the Implementer. Writes **only** inside `docs/`, plus `AGENTS.md`, `CLAUDE.md` and `.claude/agents/` — nothing else, ever. Never writes code or tests.
Full definition: [`.claude/agents/specifier.md`](.claude/agents/specifier.md).

### 2.3 Implementer — summary

Reads all the documentation it is pointed to, reports anything that does not fit **before** writing code, then implements what is documented. Writes code (including test infrastructure such as runner config and dev dependencies, as specified). Never writes in `docs/`, never writes tests, never commits.
Full definition: [`.claude/agents/implementer.md`](.claude/agents/implementer.md).

### 2.4 Reviewer — summary

Reviews the implementation against the docs and conventions, writes the tests (derived from acceptance criteria) and runs them, reports results, and commits on the task branch after the user's OK. Writes tests only; otherwise does not modify code or docs.
Full definition: [`.claude/agents/reviewer.md`](.claude/agents/reviewer.md).

### 2.5 Researcher — summary

Used only when research is necessary: searching the internet, consulting external APIs, online docs, etc. It is the only agent that does so (golden rule 8), and only after the user's approval (§4.5). It answers the question it is given with a report only: confirmed answers with the URL of an official source, unconfirmed answers, contradictions between sources, date consulted and open questions. It never recommends decisions or options. Writes no files at all (no docs, code or tests), never commits.
Full definition: [`.claude/agents/researcher.md`](.claude/agents/researcher.md).

---

## 3. Approval stops

Approval stops are mandatory:

1. After the Specifier's pass, before implementation: the user approves the specs or requests changes.
2. After review, before closing a phase/task: the user gives the OK. No phase is ever closed without it.

---

## 4. Workflow

### 4.1 Flow

```
User ──► Manager (refine: questions to the user, one at a time)
            │
            ▼
         Specifier (feasibility check)
            │  doubts/contradictions/decisions? ──► Manager ──► User ──► back to Specifier (loop)
            ▼
         Specifier writes/updates docs (+ phases, + reading instructions)
            │
            ▼
   ■ STOP 1 — User approves or requests changes to the specs (loop to Specifier until approved)
            │
            ▼
         Specifier records the approval in the docs (§4.2)
            │
            ▼
         Manager creates task branch from `development`
            │
            ▼
         Implementer reads docs ── doesn't fit? ──► Manager ──► Specifier ──► User approval (loop)
            │
            ▼
         Implementer implements ──► reports to Manager
            │
            ▼
         Reviewer: writes & runs tests, checks docs + conventions
            │  implementation gaps? ──► Manager ──► Implementer (loop)
            │  spec gap/error? ──► STOP, Manager explains to User; if approved:
            │                       Specifier ──► User approval ──► Implementer ──► Reviewer
            ▼
   ■ STOP 2 — User gives OK to close the phase/task
            │
            ▼
         Specifier closes the phase in the docs (§4.3)
            │
            ▼
         Reviewer commits code + tests + docs on the task branch ──► next phase (if any)
```

### 4.2 Recording spec approval

Right after the user approves the specs (STOP 1, or any later approval of a spec change), and **before** the task branch is created, the Manager sends the Specifier to:

- set every newly approved spec to Status `Approved` and version `v1.0`;
- apply the version bump to every already `Approved` spec whose change the user has just approved (§6.3).

### 4.3 Phase/task closing sequence

After the user's OK at STOP 2 and **before** the commit:

1. The Manager sends the Specifier to set the phase status to `Done`, bump the spec version if needed, and add the CHANGELOG entry.
2. The Reviewer commits code, tests and docs together on the task branch.

### 4.4 Blocking issues

- If the Implementer finds that anything does not fit, it reports **before** writing code. The Manager sends the Specifier to fix the docs, with the user's approval. This loops until nothing blocks the work.
- The same applies to problems found mid-implementation, but this must be avoided by all means: everything must be clear before a single line of code is written.

### 4.5 Research requests

Research can be requested at any point in the cycle:

- **By a subagent** (Specifier, Implementer, Reviewer): a research request is always blocking. The agent stops and includes the request in the optional `### Research requests` section of its blocking report (Specifier: Decisions report, writing nothing; Implementer: Blocked report; Reviewer: Review report with verdict `BLOCKED`). Each request has the form `- <n>. Question: <precise question> · Why: <what it unblocks, doc/REQ reference> · Scope: <sources/APIs expected, if known>`.
- **By the Manager**, while refining the user's input.

```
Requester (Specifier | Implementer | Reviewer | Manager)
            │  research request (question · why · scope)
            ▼
         Manager ──► User: what will be researched and why
            │  ■ user approves? (mandatory, nothing is launched without it)
            │  declined? ──► Manager ──► User: the question the research was meant to answer
            │                (one at a time, with options) ──► Requester receives the user's answer
            ▼
         Researcher (question · why · scope only) ──► Research report
            │
            ▼
         Manager ──► User: summary of the report
            │
            ▼
         Requester receives the full report (loop if more research is needed)
```

- The Manager **always** asks the user before launching any research. This is a mandatory approval, not a numbered approval stop (§3), and it can happen at any point in the cycle.
- If the user declines a research request, the Manager puts to the user the question the research was meant to answer, one at a time and with options (§7.1). The user's answer is passed to the requesting agent when it is re-launched.
- The Researcher receives only the question, the why and the scope, plus any repo files the Manager names.
- The Manager shows the user a summary of the Researcher report. The full report goes **only** to the agent that requested it; no other agent receives it. The Manager then re-launches that agent with the report.
- When the Manager is the requester, it uses the report only to ask the user better-informed questions (§7.1). The user's decisions go to the Specifier as part of the refined input.
- Research findings never enter the docs directly. The Specifier turns them into options in a Decisions report, and only the option the user chooses is written. Specs do not record source URLs.

---

## 5. Git

- **Branches**
  - `master`: merged into manually, by the user only.
  - `development`: created from `master`. If it does not exist, the Manager asks the user before creating it. Merged into manually, by the user only.
  - **Task branches**: one per task, created by the Manager from `development` after STOP 1. Naming: `<type>/<short-kebab-description>`, where `<type>` is a Conventional Commits type (e.g. `feat/user-login`, `chore/sdd-bootstrap`).
- **Commits:** only the Reviewer commits, on the task branch, after the user's OK closing a phase/task (§4.3). No other agent ever commits.
- **Commit format:** [Conventional Commits](https://www.conventionalcommits.org/), in English. **No AI co-author trailer** (no `Co-Authored-By` lines for agents).
- **Push:** no agent ever pushes. The user pushes.
- **Merges** to `development` and to `master` are done manually by the user only.

---

## 6. Documentation

### 6.1 Structure

```
docs/sdd/
├── MAIN.md           # Entry point. Index of every doc; every other doc links back to MAIN.md
├── CONVENTIONS.md    # Project conventions (stack, style, structure, testing, etc.)
├── CHANGELOG.md      # Change history — references only
├── DEVIATIONS.md     # Historical record of user-mandated deviations
└── specs/
    ├── _TEMPLATE.md  # Spec module template (a template, not a module)
    └── <module>.md   # One file per module
```

Every doc in `docs/sdd/` except `MAIN.md` starts with a back-link line: `← Back to [MAIN](<relative path>/MAIN.md)`. `MAIN.md` itself has no back-link.

### 6.2 MAIN.md

Central index. Contains a project overview, an index table of every process doc and spec module (with module code, version and status), and a link to this file. Every doc is listed in `MAIN.md` and links back to it; `MAIN.md` itself has no back-link (§6.1). `specs/_TEMPLATE.md` is listed as "template, not a module".

### 6.3 Spec modules (`docs/sdd/specs/<module>.md`)

Every spec follows `docs/sdd/specs/_TEMPLATE.md`:

- **Header:** back-link to MAIN, Module, Version, Status (`Draft` | `Approved`), Last updated (`YYYY-MM-DD`).
- **Module code:** 2–6 uppercase letters, unique per module, listed in `MAIN.md`.
- **Requirements** with stable IDs `REQ-<CODE>-NNN` (e.g. `REQ-AUTH-001`).
- **Acceptance criteria** for every requirement, IDs `AC-<CODE>-NNN-k` (e.g. `AC-AUTH-001-2`), written as Given/When/Then. They must be testable: the Reviewer derives tests from them.
- **Implementation phases** `PH-<n>`, each with a status (`Planned` | `In progress` | `In review` | `Done`) and the REQ-IDs it covers.

**Versioning (specs):**

- A new spec starts at `v0.1` while in `Draft`; approval sets `v1.0`.
- Minor bump (`vX.Y` → `vX.Y+1`): requirements added or clarified.
- Major bump (`vX.Y` → `vX+1.0`): requirements or behaviour changed or removed.
- An `Approved` spec that is being changed stays `Approved`; its version is bumped when the user approves the change (§4.2).

### 6.4 CONVENTIONS.md

Project-wide conventions, filled in as the user decides them. It is the only non-spec doc that is versioned (`vX.Y`), starting at `v0.1`; its version is shown in its header and in its `MAIN.md` index row. Test file locations and naming are defined **only** here.

### 6.5 CHANGELOG.md

[Keep a Changelog](https://keepachangelog.com/) format: an `## [Unreleased]` section using the standard categories (`Added`, `Changed`, `Deprecated`, `Removed`, `Fixed`, `Security`). Following Keep a Changelog practice, only categories that have entries are shown. Release headings are added once the user defines releases.

Each entry is one line holding **references only**, with no duplicated content: date, affected spec(s) with their new version, task/phase, and any related deviation ID. Example:

```
- 2026-10-02 · specs/auth.md → v1.1 · task auth-login / PH-2 · DEV-003
```

### 6.6 DEVIATIONS.md

A historical record of every user decision that contradicts an **already approved** spec. Edits to specs that are not yet approved are plain edits, not deviations. Every deviation is also propagated to all affected docs so that no document contradicts another.

Entry format:

```
### DEV-NNN — <title>
- **Date:** YYYY-MM-DD
- **Spec said:** <what the approved spec said: spec file, REQ-IDs and previous version>
- **User decided:** <the decision>
- **Reason:** <reason>
- **Affected files:** <list>
- **CHANGELOG ref:** <entry reference>
```

---

## 7. Interaction with the user

### 7.1 Questions

Questions are asked **one at a time, with options**. If an agent has a proposal, it is shown as one option marked as recommended — never applied without the user's choice.

### 7.2 Status line

Every Manager message starts with the current position in the cycle:

```
<task> · Phase <n|—> · <agent> · iteration <k>
```

Example: `auth-login · Phase 2 · Specifier · iteration 3`. Use `—` when there is no phase.

While research is being approved, run or reported (§4.5), `<agent>` is `Researcher`; the task name is unchanged, and the iteration keeps the count of the step that requested the research.

---

## 8. Language

- Docs, code comments, identifiers, file names and commit messages: **English**.
- Conversation with the user: the user's language.

---

## 9. Agent guidance files

- **`AGENTS.md`** (repo root) holds the common rules, the Manager's rules, the workflow, and a summary of each subagent role.
- **`.claude/agents/<role>.md`** holds the detailed definition of each subagent role (role, permissions, workflow steps, report format). Role detail lives only there.
- **`CLAUDE.md`** contains only the import of `AGENTS.md` (`@AGENTS.md`) plus one comment line stating that it holds no guidance of its own.
- Subagent files never set `tools` or `model`. They set `omitClaudeMd: true`, and their `description` states that they are used only when the Manager explicitly hands off a task in the SDD workflow.

---

## 10. Bootstrap

The SDD harness was set up as the first SDD task:

1. The Specifier drafts `AGENTS.md`, `CLAUDE.md`, the agent files and the `docs/sdd/` skeleton.
2. **Stop:** the user approves or requests changes.
3. The Manager creates `development` from `master`, then the task branch `chore/sdd-bootstrap` from `development`.
4. The Reviewer verifies the structure against the bootstrap prompt (structure and compliance only: the bootstrap has no testable acceptance criteria, so no tests are written; see `.claude/agents/reviewer.md`) and commits on `chore/sdd-bootstrap` after the user's OK.
5. The Manager then waits for the user's first input, and does not interview the user about the project until they provide it.
