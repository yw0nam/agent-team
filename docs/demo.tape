# Renders docs/demo.gif from the repo root: `vhs docs/demo.tape`.
# Needs `impl` and `impl2` roles, and /tmp/fizzbuzz trusted in Claude Code once.
Output docs/demo.gif
Set Shell bash
Set FontSize 15
Set Width 1200
Set Height 700
Set Theme "Catppuccin Mocha"
Set TypingSpeed 20ms

Hide
# a fresh project, a fresh pi session, and no env leaking from a parent Claude Code
Type `export PS1='$ ' R=$PWD && unset CLAUDECODE CLAUDE_PID CLAUDE_EFFORT ${!CLAUDE_CODE_*} && rm -rf /tmp/fizzbuzz ~/.pi/agent/sessions/--private-tmp-fizzbuzz-- && mkdir -p /tmp/fizzbuzz/.claude && cd /tmp/fizzbuzz && git init -q && echo '{"permissions":{"allow":["Bash","Read","Edit","Write","Skill"]}}' > .claude/settings.json && clear`
Enter
Type `clear; claude --setting-sources project --strict-mcp-config --plugin-dir "$R"`
Enter
Sleep 8s
Show

Type "With any-subagent, in parallel in the background: impl writes fizzbuzz.py, impl2 writes pytest tests for it in test_fizzbuzz.py. When both finish, run the tests."
Sleep 0.5s
Enter
Sleep 1.5s
# Claude reads the skill and dispatches both roles
Hide
Wait+Screen@300s /Running in the background[\s\S]*Running in the background/
Show
Sleep 2s
# open the background-task list while both roles run
Down
Sleep 1s
Enter
Sleep 4s
Escape
Sleep 1s
Hide
# vhs reads the top of the buffer, not the scrolled view, so the rest is timed:
# both roles and the test run take about 2 minutes
Sleep 240s
Show
Sleep 6s
