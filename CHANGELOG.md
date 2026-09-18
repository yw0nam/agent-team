# Changelog

## 1.7.0 — 2026-09-18

- **Breaking: read-only roles are gone.** `-w` and the config's `write` key are
  removed; every role runs in its backend's write mode. The reporting protocol
  has each role journal to `.agent-team/<session>.md` — a role that cannot
  write cannot do that, so a review role was getting no protocol and no
  structure at all. Scope a role by the worktree you send it to, not by taking
  its tools away. Existing configs keep working; `write` is ignored.
  Side effect: this removes a cache break. pi implements read-only as a tool
  filter (`-xt edit,write`) and pins a cache breakpoint to the last tool, so
  sending `-w` to an existing read-only pi session invalidated its whole
  prefix — measured at cacheRead 1,664 -> 320.
- `agent-send` returns only the final assistant message. codex emits an
  `agent_message` for every preamble it narrates between tool calls and pi a
  `turn_end` per turn; both filters kept all of them, so a delegation handed
  the orchestrator its entire narration instead of the report the protocol
  asks for — 28 messages / 14,728 characters on one real task. A run that ends
  without a final assistant text now fails loudly instead of returning
  narration; the raw stream still goes to stderr.

## 1.6.0 — 2026-09-16

- Codex is a first-class orchestrator, not just a backend. `codex plugin
  marketplace add yw0nam/agent-team` reads the existing
  `.claude-plugin/marketplace.json` as-is and `codex plugin add` loads the
  skill — the only thing Codex does not do is put the plugin's `bin/` on PATH,
  so `install.sh` links `agent-send` into `~/.local/bin` (and the skill into
  `~/.codex/skills/` for a plain git clone, skipped when the plugin already
  supplies it).
- Skill and workflows are harness-neutral: the interview no longer assumes
  AskUserQuestion, and backgrounding a long delegation is documented per
  harness (Claude Code's background Bash vs. `nohup ... &` plus polling).
- Documented the Codex sandbox trap: a delegated CLI inherits the spawning
  session's sandbox, and the default `workspace-write` blocks the network
  outright and makes the backend's own state dir read-only — so delegation
  either fails or silently loses its sessions. Fix is a profile
  (`~/.codex/agent-team.config.toml`) with `network_access = true` and the
  backends' state dirs in `writable_roots`.

## 1.5.0 — 2026-09-11

- `agent-send --note <session> "..."`: amend a task that is already running.
  Non-interactive CLIs cannot take input mid-turn, so the note is appended to
  `.agent-team/<session>.inbox.md` and write roles are told to re-read that
  file before each major step — they apply the amendment, record it in the log
  under `### amendment`, and truncate the inbox. Cooperative, not preemptive:
  it lands at the next step boundary, or not at all if the turn already ended
  (send a normal follow-up then, or kill the run and re-send the spec to the
  same session).

## 1.4.0 — 2026-09-11

- Work logs. Write-enabled roles are now told, on every message, to append the
  spec they were given plus what they did and why to
  `<repo-root>/.agent-team/<session>.md`, and to reply with a report in fixed
  sections — summary, changes, verification, notes, log path — the same shape
  a harness subagent hands back. Logging the spec next to the notes is
  what makes the log checkable later — the diff has its acceptance criteria
  sitting above it. Delegation
  stops dumping transcripts into the orchestrator's context, and the reasoning
  behind a diff outlives the scrollback. The directory ignores itself, so logs
  never show up in `git status`; read one back with `agent-send --log <name>`.
  Read-only roles are unaffected — they cannot write, and their answer is the
  deliverable.

## 1.3.1 — 2026-09-10

- `agent-send`: pi turns that fail now fail loudly. pi exits 0 even when the
  turn errored (unknown model, provider 400, auth), and the reason only lives
  in the event stream as `stopReason: "error"` — so a broken role printed
  nothing at all and looked like a success. The error message now goes to
  stderr with exit 1.
- Docs: pi carries the reasoning level as a model suffix
  (`"zai/glm-5.3-flash:high"`), so no config key is needed for it.

## 1.3.0 — 2026-09-10

- `agent-send`: new `pi` backend. pi names its own sessions (`--session-id`
  creates the id if missing, resumes it if not), so there is no id to scrape
  and a run killed by a timeout can never be orphaned. `--models` lists pi's
  catalog via `pi --list-models`. pi has no sandbox: `write: false` only drops
  its `edit`/`write` tools, and `bash` can still modify files — keep hard
  read-only roles on codex.

## 1.2.5 — 2026-08-06

- `agent-send`: codex write roles now add the repo's git common dir to
  `sandbox_workspace_write.writable_roots` when it sits outside cwd. The
  sandbox root is cwd, so in a linked worktree — or any subdirectory of a repo
  — every git write failed with "Read-only file system"; codex then asked to
  escalate and `exec` had nobody to answer, so delegated agents reported that
  they could not use git at all. Only added when the git dir is actually
  outside cwd, so a plain repo root is unaffected.
- Skill: note that skills do not travel to delegated agents — codex never reads
  `~/.claude/skills`.

## 1.2.4 — 2026-08-04

- `agent-send`: codex write roles now also pass
  `-c sandbox_workspace_write.network_access=true`. Without it the sandbox
  blocks `socket()`, asyncio cannot build its self-pipe, and any suite using
  starlette's `TestClient` hangs instead of failing — so delegated agents could
  not run pytest at all. Scoped to `-w`; read-only roles and the user's own
  codex keep the default posture.

## 1.2.3 — 2026-07-28

- `agent-send`: use `-c sandbox_mode=workspace-write` instead of `-s` for codex
  write roles. The same flags array feeds `codex exec` and `codex exec resume`,
  and resume rejects `-s`.

## 1.2.2 — 2026-07-23

- `agent-send`: extract the codex session id from the `--json` event stream's
  `thread_id` rather than the human-readable banner, which is not a stable
  contract.
- `agent-send`: persist the opencode session id before the run completes, so a
  killed or timed-out run stays resumable.

## 1.2.0 — 2026-07-20

- Skill: split `SKILL.md` into a router plus `workflows/`.

## 1.1.3 — 2026-07-14

- `agent-send`: redirect codex stdin from `/dev/null`. `codex exec` waits for
  stdin EOF, which a backgrounded caller's open pipe never sends.

## 1.1.2 — 2026-07-12

- Skill: route natively-runnable models to the harness's own subagents instead
  of `agent-send`.

## 1.1.1 — 2026-07-12

- `agent-send`: use POSIX `sed` for session-id extraction.

## 1.1.0 — 2026-07-12

- `agent-send --models`: query live model catalogs per backend.

## 1.0.0 — 2026-07-12

- Initial release: session-persistent, role-based delegation to external
  coding-agent CLIs (codex, opencode, claude).
