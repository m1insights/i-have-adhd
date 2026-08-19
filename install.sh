#!/usr/bin/env bash
# Installs the i-have-adhd skill + hooks and wires them into Claude Code.
# Safe to re-run. Backs up settings.json before touching it.
# Requires: bash, python3 (for the JSON merge).
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_DIR="${CLAUDE_DIR:-$HOME/.claude}"
SETTINGS="$CLAUDE_DIR/settings.json"

mkdir -p "$CLAUDE_DIR/skills/i-have-adhd" "$CLAUDE_DIR/hooks"
cp "$REPO_DIR/skill/SKILL.md" "$CLAUDE_DIR/skills/i-have-adhd/SKILL.md"
cp "$REPO_DIR/hooks/adhd.sh" "$CLAUDE_DIR/hooks/adhd.sh"
chmod +x "$CLAUDE_DIR/hooks/adhd.sh"

[ -f "$SETTINGS" ] || printf '{}\n' > "$SETTINGS"
cp "$SETTINGS" "$SETTINGS.bak.i-have-adhd"

python3 - "$SETTINGS" <<'PY'
import json, sys

path = sys.argv[1]
with open(path) as f:
    settings = json.load(f)

hooks = settings.setdefault("hooks", {})

def ensure(event, matcher, command):
    entries = hooks.setdefault(event, [])
    for entry in entries:
        for h in entry.get("hooks", []):
            if "adhd.sh" in h.get("command", ""):
                return False
    entry = {"hooks": [{"type": "command", "command": command, "timeout": 10}]}
    if matcher:
        entry["matcher"] = matcher
    entries.append(entry)
    return True

added = [
    ensure("SessionStart", "startup|resume|clear|compact",
           '"$HOME/.claude/hooks/adhd.sh" session-start'),
    ensure("UserPromptSubmit", None,
           '"$HOME/.claude/hooks/adhd.sh" prompt'),
]

with open(path, "w") as f:
    json.dump(settings, f, indent=2)
    f.write("\n")

print("hooks wired" if any(added) else "hooks already wired — nothing to do")
PY

echo "Installed. Settings backup: $SETTINGS.bak.i-have-adhd"
echo "New Claude Code sessions pick it up automatically."
echo "Verify: start a session, ask anything — the reply should fit one screen."
