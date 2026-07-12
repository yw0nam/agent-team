# agent-team

A Claude Code plugin that lets Claude delegate work to **external coding-agent
CLIs** — [codex](https://github.com/openai/codex),
[opencode](https://opencode.ai), or another `claude` — through
**session-persistent, role-based conversations**.

Think of it as SendMessage for external CLIs: each delegated conversation gets
a durable name, and every follow-up resumes the same session with its full
context intact. You define roles (`spec-review`, `impl`, `docs`, ...) once;
Claude picks the right agent, model, and write permission per task.

```
You ──► Claude Code (orchestrator: spec, judgment, quality gate)
              │ agent-send impl parser "Implement per SPEC ..."
              ├──► codex     (session "parser", write-enabled)
              │ agent-send spec-review parser-spec "Review this spec ..."
              ├──► codex     (session "parser-spec", read-only)
              │ agent-send docs parser-docs "Document the module ..."
              └──► opencode  (session "parser-docs", write-enabled)
```

**Core principle: delegate execution, never judgment.** The spec and the final
quality gate always stay with Claude (and you).

## Requirements

- [Claude Code](https://code.claude.com) v2.x or later
- At least one of the backends installed and authenticated:
  - `codex` (OpenAI Codex CLI)
  - `opencode` (OpenCode CLI)
  - `claude` (a second Claude Code, used non-interactively)
- `jq`

## Installation

From within Claude Code:

```
/plugin marketplace add yw0nam/agent-team
/plugin install agent-team@yw0nam
```

Or from the shell:

```bash
claude plugin marketplace add yw0nam/agent-team
claude plugin install agent-team@yw0nam
```

While the plugin is enabled, the bundled `agent-send` command is on the Bash
tool's PATH automatically — nothing else to wire up.

## Setup

Ask Claude to set up your agent team:

> set up my agent team

Claude detects which CLIs are installed, interviews you (which roles, which
backend and model per role, write permission per role), writes
`~/.config/agent-team/config.json`, and smoke-tests each role. Example config:

```json
{
  "roles": {
    "spec-review": { "backend": "codex",    "model": "gpt-5.5", "write": false },
    "impl":        { "backend": "codex",    "model": "gpt-5.5", "write": true },
    "docs":        { "backend": "opencode", "model": "opencode-go/qwen3.7-plus", "write": true }
  }
}
```

Role names are free-form. `model` is optional (omit to use the backend's
default). `write: true` maps to each backend's write mode (codex
`--full-auto`, opencode `--auto`, claude `--permission-mode acceptEdits`).

## Usage

Mostly you just talk to Claude — "have impl build this, then get it
reviewed" — and Claude drives `agent-send`. The command itself:

```bash
# Send as a role; first call creates the session
agent-send impl parser "Implement the tokenizer per /abs/path/SPEC.md ..."

# Follow-up to the SAME conversation: same role + same session name
agent-send impl parser "Tests fail: expected X got Y. Fix it."

# Show configured roles / list sessions for this directory
agent-send --roles
agent-send --list

# Escape hatch: bypass roles, talk to a backend directly
agent-send -w -m gpt-5.5 codex quickfix "..."
```

Sessions are keyed by working directory, so parallel git worktrees never
collide. Session state lives under `/tmp/agent-team/` — one file per
conversation holding the backend's session id; the real history stays with
each CLI.

## Uninstall

```
/plugin uninstall agent-team@yw0nam
```

Config (`~/.config/agent-team/`) and session state (`/tmp/agent-team/`) are
plain files you can delete anytime.

## License

[MIT](LICENSE)
