# Workflow: setup / reconfigure the agent team

Run this when `~/.config/agent-team/config.json` is missing, or the user asks
to set up or change their roles.

1. Detect installed CLIs: `for c in codex opencode claude pi; do command -v $c; done`
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
    "docs":        { "backend": "opencode", "model": "opencode-go/qwen3.7-plus", "write": true },
    "research":    { "backend": "pi",       "model": "anthropic/claude-sonnet-5", "write": false }
  }
}
```

   For pi, a reasoning level can be appended to the model —
   `"zai/glm-5.3-flash:high"` (off/minimal/low/medium/high/xhigh/max).
   pi has no sandbox: `write: false` there only removes its `edit`/`write`
   tools, and `bash` can still modify files — put roles that must not touch
   the tree on codex.

5. Smoke-test each role with a trivial prompt — some models still fail only
   at call time (e.g. ChatGPT-account codex rejects some catalog models with
   a 400).
