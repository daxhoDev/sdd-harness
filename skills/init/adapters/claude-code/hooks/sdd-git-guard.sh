#!/usr/bin/env bash
# SDD harness git guard (AGENTS.md §5): no agent pushes or merges, and only the
# Reviewer subagent commits. PreToolUse hook for the Bash tool.

input=$(cat)

# The Bash command (tool_input.command), still JSON-escaped.
command=$(printf '%s' "$input" | grep -oE '"command"[[:space:]]*:[[:space:]]*"([^"\\]|\\.)*"' | head -n 1 \
  | sed -E 's/^"command"[[:space:]]*:[[:space:]]*"//; s/"$//')
# The subagent running the command; empty in the main session.
agent=$(printf '%s' "$input" | grep -oE '"agent_type"[[:space:]]*:[[:space:]]*"[^"]*"' | head -n 1 | sed -E 's/.*"([^"]*)"$/\1/')

# `git <sub>` (optionally `git -C <dir> <sub>`) at the start of a command or after a separator.
runs() {
  printf '%s' "$command" | grep -qE "(^|[;&|(\`[:space:]]|\\\\n)git([[:space:]]+-C[[:space:]]+[^[:space:]]+)?[[:space:]]+$1([^[:alnum:]_-]|$)"
}

deny() {
  printf '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny","permissionDecisionReason":"%s"}}\n' "$1"
  exit 0
}

runs push && deny "SDD harness: no agent pushes; the user pushes (AGENTS.md §5)."
runs merge && deny "SDD harness: merges are done manually by the user only (AGENTS.md §5)."
if runs commit && [ "$agent" != "reviewer" ]; then
  deny "SDD harness: only the Reviewer commits, after the user's OK (AGENTS.md §5)."
fi
exit 0
