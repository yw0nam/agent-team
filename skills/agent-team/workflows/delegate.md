# Workflow: delegate work to a role

## Quick Reference

| Action | Command |
|---|---|
| Send as a role | `agent-send <role> <session-name> "..."` |
| Continue a conversation | same role/backend + same session name |
| Show configured roles | `agent-send --roles` |
| List sessions for this cwd | `agent-send --list` |
| List live models per backend | `agent-send --models [backend]` |
| Read a session's work log | `agent-send --log <session-name>` |
| Amend a task already running | `agent-send --note <session-name> "..."` |
| Bypass roles (escape hatch) | `agent-send [-w] [-m MODEL] <backend> <name> "..."` |

- Write permission and model come from the role; `-w`/`-m` override per call.
- Sessions are isolated per working directory (worktrees auto-isolate).
- Name sessions by unit of work: one session per review thread / impl task.
- Long tasks: run via Bash `run_in_background: true` — the harness wakes you
  when the process exits; stdout is the reply. Launch independent tasks concurrently.

## Work Logs

Write-enabled roles are told, on every message, to append to
`<repo-root>/.agent-team/<session-name>.md` — the spec you sent copied
verbatim, then their notes (what they did, decisions, rejected alternatives,
commands, anything unfinished) — and to reply with a structured report —
`## Summary` / `## Changes` / `## Verification` / `## Notes` / `## Log`, the
same shape a harness subagent hands back. So:

- The log carries its own acceptance criteria: the spec sits right above the
  notes, so a diff can be checked against what was actually asked — by you, by
  a reviewer role, or by you tomorrow.
- The reply is the report; the log is the transcript. Read the log with
  `agent-send --log <name>` when the summary is too thin to verify against —
  before re-asking the agent, which costs a turn.
- The log is append-only and per session, so a follow-up lands under a new
  heading in the same file and the whole thread stays readable.
- `.agent-team/` ignores itself (a `.gitignore` holding `*`), so logs never
  show up in `git status`. `git add -f` if you want to keep one.
- Read-only roles get no protocol — they cannot write, and their answer is
  already the deliverable.

## Changing Your Mind Mid-Run

The CLIs are one-shot in non-interactive mode: nothing can be injected into a
turn already in flight. `agent-send --note <name> "..."` instead appends to
`.agent-team/<name>.inbox.md`, which write roles are told to re-read before
each major step — they apply it, log it under `### amendment`, and empty the
file.

| Situation | Do this |
|---|---|
| Spec changed, agent is mid-run | `--note`; it lands at the next step boundary |
| Change must take effect now | Kill the run, then send the corrected spec to the SAME session — the id is on disk, so context up to the last completed turn survives |
| Turn already finished | Just send a normal follow-up message |

Cooperative, not preemptive: a note arrives late if the agent is deep inside
one long tool call, and not at all if the turn ended first. Worktrees make
that cheap — wrong work gets reverted, not untangled.

## Standard Cycle

1. Write the spec yourself.
2. Send it to your review role (read-only) and fold in the feedback;
   re-ask in the SAME session until it passes.
3. Delegate execution to write-enabled roles, in the background, in parallel.
4. Verify results yourself (run tests, read diffs; `agent-send --log <name>`
   for the reasoning behind a diff). On failure, send feedback to the SAME
   session so the agent keeps its context.

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
| Assuming your skills travel to the delegated agent | They don't. codex reads `~/.agents/skills`, `~/.codex/skills`, `<repo>/.agents/skills`, `<repo>/.codex/skills` — never `~/.claude/skills`. Symlink the skill into one of those, or inline the rules into the spec |
