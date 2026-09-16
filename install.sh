#!/usr/bin/env bash
# Install agent-team for harnesses that don't do it themselves.
#
# Claude Code needs none of this: `/plugin install` puts bin/ on the Bash PATH
# and loads skills/ for you. Codex (and opencode, pi, a bare shell) discovers
# the skill but never touches PATH, so `agent-send` has to be linked by hand.
set -euo pipefail

root=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)
bindir=${AGENT_TEAM_BIN:-$HOME/.local/bin}

mkdir -p "$bindir"
ln -sfn "$root/bin/agent-send" "$bindir/agent-send"
echo "linked $bindir/agent-send -> $root/bin/agent-send"

# The skill. Skipped when `codex plugin add` already installed it — its copy
# lives in the plugin cache, and linking on top of that lists the skill twice.
codex_home=${CODEX_HOME:-$HOME/.codex}
shopt -s nullglob
from_plugin=("$codex_home"/plugins/cache/*/agent-team)
shopt -u nullglob
if command -v codex >/dev/null && [[ ${#from_plugin[@]} -eq 0 ]]; then
  mkdir -p "$codex_home/skills"
  ln -sfn "$root/skills/agent-team" "$codex_home/skills/agent-team"
  echo "linked $codex_home/skills/agent-team -> $root/skills/agent-team"
elif [[ ${#from_plugin[@]} -gt 0 ]]; then
  echo "skill: already installed as a codex plugin (${from_plugin[0]}) — not linking again"
fi

case ":$PATH:" in
*":$bindir:"*) ;;
*) echo "warning: $bindir is not on PATH — add it to your shell profile" >&2 ;;
esac

command -v jq >/dev/null || echo "warning: jq is not installed (agent-send needs it)" >&2
