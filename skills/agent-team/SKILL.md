---
name: agent-team
description: Use when work should be delegated to external coding-agent CLIs (codex, opencode, claude), when the user asks to set up or reconfigure their agent team, or when a follow-up message must reach the same external-agent conversation with its context intact.
compatibility: Requires at least one of the codex/opencode/claude CLIs installed and authenticated, plus jq
---

# agent-team

## Overview

Claude Code orchestrates external CLI coding agents through `agent-send`
(bundled at [bin/agent-send](../../bin/agent-send), on the Bash PATH while
this plugin is enabled), a wrapper that gives each conversation a durable name
and resumes it on every message — like SendMessage, but for external CLIs.
Which agent plays which role is per-user configuration, not hardcoded.

**Core principle:** delegate execution, never judgment. The spec and the final
quality gate always stay with you.

**Models your own harness runs natively don't go through this plugin.**
agent-send exists to reach OTHER agents' CLIs. If the model a role would use
is one the orchestrating harness already speaks — Claude Code with
sonnet/haiku/opus (its Agent tool, `model` option), Codex with GPT models,
opencode with its configured models — spawn the harness's own subagent
instead. Native subagents skip the extra CLI spawn, share the harness (hooks,
permissions, session resume), and cost nothing extra to wire. The same-vendor
backend exists only as an escape hatch for the rare case that genuinely needs
a detached external CLI session.

## Setup (first use or reconfiguration)

If `~/.config/agent-team/config.json` is missing, or the user asks to
set up / change their agent team:

1. Detect installed CLIs: `for c in codex opencode claude; do command -v $c; done`
2. Query the models each installed backend can use right now:
   `agent-send --models`. Model catalogs change too often to trust memory —
   only offer names from this live list.
3. Interview the user with AskUserQuestion: which roles they want (names are
   free-form, e.g. `spec-review`, `impl`, `docs`), which backend serves each
   role, model per role picked from the step-2 list (omit to use the CLI's
   own default), and whether the role may write files. If a proposed role
   targets a model the current harness runs natively, steer it to the
   harness's own subagent mechanism instead of configuring it here.
4. Write the config and confirm with `agent-send --roles`:

```json
{
  "roles": {
    "spec-review": { "backend": "codex",    "model": "gpt-5.5", "write": false },
    "impl":        { "backend": "codex",    "model": "gpt-5.5", "write": true },
    "docs":        { "backend": "opencode", "model": "opencode-go/qwen3.7-plus", "write": true }
  }
}
```

5. Smoke-test each role with a trivial prompt — some models still fail only
   at call time (e.g. ChatGPT-account codex rejects some catalog models with
   a 400).

## When to Use

- Work matches a configured role (review, hard implementation, docs, ...)
- A delegated conversation needs a follow-up that keeps context (feedback, re-review)
- The user asks to set up or reconfigure their agent team

**When NOT to use:** edits you can finish faster yourself; work needing this
conversation's context (external agents only see what you put in the prompt);
work for a model your harness runs natively — use its built-in subagent
mechanism instead (e.g. Claude Code's Agent tool with `model`).

## Quick Reference

| Action | Command |
|---|---|
| Send as a role | `agent-send <role> <session-name> "..."` |
| Continue a conversation | same role/backend + same session name |
| Show configured roles | `agent-send --roles` |
| List sessions for this cwd | `agent-send --list` |
| List live models per backend | `agent-send --models [backend]` |
| Bypass roles (escape hatch) | `agent-send [-w] [-m MODEL] <backend> <name> "..."` |

- Write permission and model come from the role; `-w`/`-m` override per call.
- Sessions are isolated per working directory (worktrees auto-isolate).
- Name sessions by unit of work: one session per review thread / impl task.
- Long tasks: run via Bash `run_in_background: true` — the harness wakes you
  when the process exits; stdout is the reply. Launch independent tasks concurrently.

## Standard Cycle

1. Write the spec yourself.
2. Send it to your review role (read-only) and fold in the feedback;
   re-ask in the SAME session until it passes.
3. Delegate execution to write-enabled roles, in the background, in parallel.
4. Verify results yourself (run tests, read diffs). On failure, send feedback
   to the SAME session so the agent keeps its context.

Prompts must be self-contained: absolute file paths, acceptance criteria,
constraints. External agents see none of your conversation.

## Common Mistakes

| Mistake | Reality |
|---|---|
| Expecting delegated agents to write files with a read-only role | Non-interactive CLIs block or sandbox writes; use a write-enabled role or `-w` |
| Capturing session ids in shell variables | Shell state dies between Bash calls; agent-send persists ids on disk |
| Resume-by-"last" (`codex exec resume --last`) | Races against parallel sessions — always address by session name |
| New session name for a follow-up | Context lost; reuse the exact name |
| Auto-recreating an expired session | agent-send exits non-zero instead — context loss must be visible, not silent |
| Merging delegated work unverified | You are the quality gate: run the tests, read the diff |
| Offering model names from memory | Catalogs move fast (new releases monthly); list live ones with `agent-send --models`, then smoke-test |
| Routing your harness's native models through agent-send (e.g. sonnet via `agent-send claude` from Claude Code) | The harness runs them natively — spawn its built-in subagent; agent-send is for reaching other agents' CLIs |
