# Workflow: delegate work to a role

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
