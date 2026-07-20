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

## Workflows

Read the one that matches the situation — each file is self-contained.

| Situation | Read |
|---|---|
| `~/.config/agent-team/config.json` missing, or the user wants to set up / change roles | [workflows/setup.md](workflows/setup.md) |
| Sending work to a role, or following up in an existing session | [workflows/delegate.md](workflows/delegate.md) |

## When to Use

- Work matches a configured role (review, hard implementation, docs, ...)
- A delegated conversation needs a follow-up that keeps context (feedback, re-review)
- The user asks to set up or reconfigure their agent team

**When NOT to use:** edits you can finish faster yourself; work needing this
conversation's context (external agents only see what you put in the prompt);
work for a model your harness runs natively — use its built-in subagent
mechanism instead (e.g. Claude Code's Agent tool with `model`).
