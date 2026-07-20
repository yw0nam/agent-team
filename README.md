# agent-team

![License](https://img.shields.io/github/license/yw0nam/agent-team.svg?style=flat-square)
![Version](https://img.shields.io/badge/version-1.1.0-blue.svg?style=flat-square)
![Backends](https://img.shields.io/badge/backends-codex%20%C2%B7%20opencode%20%C2%B7%20claude-8A2BE2?style=flat-square)

**Turn one Claude Code into a tech lead with a team.** agent-team lets Claude
delegate work to external coding-agent CLIs — [codex](https://github.com/openai/codex),
[opencode](https://opencode.ai), or another `claude` — through
**session-persistent, role-based conversations**. Claude writes the spec,
farms out execution, sends review feedback to the *same* conversation, and
keeps the final quality gate.

Think of it as `SendMessage` for external CLIs: every delegated conversation
gets a durable name, and every follow-up resumes it with full context intact.

```
You ──► Claude Code  (orchestrator: spec, judgment, quality gate)
              │
              │  agent-send spec-review parser-spec "Review this spec ..."
              ├────► codex      session "parser-spec"   read-only
              │  agent-send impl parser "Implement per SPEC ..."
              ├────► codex      session "parser"        write-enabled
              │  agent-send docs parser-docs "Document the module ..."
              └────► opencode   session "parser-docs"   write-enabled
```

## Why

Multi-agent setups usually break down in one of three ways: the delegated
agent forgets everything between messages, parallel tasks race each other, or
the orchestrator quietly outsources its judgment. agent-team is built around
fixes for all three:

- **Conversations, not fire-and-forget prompts.** Session ids are persisted on
  disk per working directory, so "tests failed, fix it" reaches the agent that
  wrote the code — with its context.
- **Sessions are addressed by name, never by "last".** Parallel delegations
  can't hijack each other's threads. Git worktrees isolate automatically.
- **Delegate execution, never judgment.** The skill hard-codes the cycle:
  Claude writes the spec, external agents execute, Claude verifies. An expired
  session fails loudly instead of silently starting a fresh one.

## How it works

You just talk to Claude. A typical session:

> **You:** Build the tokenizer module. Get the spec reviewed first, then
> implement it, and have the docs written up.

Claude, with this plugin enabled:

1. Writes the spec itself, then sends it to your read-only review role:
   `agent-send spec-review tokenizer-spec "Review this spec: ..."`
2. Folds feedback in and re-asks **in the same session** until it passes —
   the reviewer remembers its previous objections.
3. Delegates implementation and docs to write-enabled roles **in parallel,
   in the background**: `agent-send impl tokenizer "..."`,
   `agent-send docs tokenizer-docs "..."`
4. Runs the tests itself. On failure, sends the failing output back to the
   `impl` session — the agent that wrote the code debugs it with full context.

Which CLI plays which role is **your configuration, not hardcoded** — roles
are free-form names you define once, per user.

## What's inside

| Component | What it does |
|---|---|
| `skills/agent-team/` | The skill: `SKILL.md` routes to `workflows/setup.md` (config interview) or `workflows/delegate.md` (cycle, quick reference, common mistakes) |
| `bin/agent-send` | ~160-line bash wrapper; on the Bash tool's PATH automatically while the plugin is enabled |
| `.claude-plugin/marketplace.json` | This repo doubles as its own plugin marketplace |

No MCP server, no daemon, no polling. `agent-send` maps each
`(cwd, backend, session-name)` to the backend's native session id and resumes
it — the CLIs themselves keep the real conversation history.

## Requirements

- [Claude Code](https://code.claude.com) v2.x or later
- At least one backend installed and authenticated:
  `codex` · `opencode` · `claude`
- `jq`

## Installation

Register the marketplace and install, inside Claude Code:

```
/plugin marketplace add yw0nam/agent-team
/plugin install agent-team@yw0nam
```

Or from the shell:

```bash
claude plugin marketplace add yw0nam/agent-team
claude plugin install agent-team@yw0nam
```

## Setup

Ask Claude:

> set up my agent team

Claude detects installed CLIs, queries the models each backend can use
**right now** (`agent-send --models` — codex and opencode expose live
catalogs, so new releases show up without a plugin update), interviews you —
which roles you want, which backend and model per role, write permission per
role — writes `~/.config/agent-team/config.json`, and smoke-tests each role.
Example:

```json
{
  "roles": {
    "spec-review": { "backend": "codex",    "model": "gpt-5.5", "write": false },
    "impl":        { "backend": "codex",    "model": "gpt-5.5", "write": true },
    "docs":        { "backend": "opencode", "model": "opencode-go/qwen3.7-plus", "write": true }
  }
}
```

Role names are free-form. `model` is optional (backend default when omitted).
`write: true` maps to each backend's write mode — codex `--full-auto`,
opencode `--auto`, claude `--permission-mode acceptEdits`.

## Usage

Mostly you don't touch `agent-send` yourself — Claude drives it. The command,
for when you do:

```bash
# Send as a role; first call creates the session
agent-send impl parser "Implement the tokenizer per /abs/path/SPEC.md ..."

# Follow-up to the SAME conversation: same role + same session name
agent-send impl parser "Tests fail: expected X got Y. Fix it."

# Introspection
agent-send --roles     # configured roles
agent-send --list      # sessions for this directory
agent-send --models    # models each backend can use right now

# Escape hatch: bypass roles, talk to a backend directly
agent-send -w -m gpt-5.5 codex quickfix "..."
```

## Design notes

- **Session state** lives in `/tmp/agent-team/<cwd-hash>/` — one plain-text
  file per conversation holding the backend's session id. Delete a file to
  start that conversation over; delete the directory to reset everything.
- **Worktree-safe by construction.** State is keyed on the working directory,
  so parallel git worktrees get independent sessions with zero setup.
- **Failures don't poison state.** A failed first call writes no session
  file; a failed resume exits non-zero and tells you which file to delete.
  Context loss is always visible, never silent.
- **Completion notification is free.** Each `agent-send` call is a normal
  process that exits when the reply is complete — run it in the background
  and your harness wakes Claude up. No hooks, no marker files.

## Philosophy

- **Delegate execution, never judgment** — the spec and the merge decision stay with the orchestrator
- **Conversations over prompts** — feedback goes to the agent that did the work
- **Fail loud** — an expired session is an error, not a fresh start
- **No infrastructure** — three CLIs, one bash script, files on disk

## Uninstall

```
/plugin uninstall agent-team@yw0nam
```

Config (`~/.config/agent-team/`) and session state (`/tmp/agent-team/`) are
plain files — delete them anytime.

## License

[MIT](LICENSE)
