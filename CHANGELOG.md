# Changelog

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
