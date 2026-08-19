# i-have-adhd

An always-on output contract for [Claude Code](https://claude.com/claude-code), written for ADHD brains.

I have ADHD and usually run 5–10 Claude Code sessions in parallel. Each reply gets a few seconds of my attention — I don't have a couple of minutes to read every response across 5–10 sessions in an 8+ hour workday. A 40-line technical explanation doesn't get read — it gets skipped, and the session stalls. This skill makes every reply digestible in one glance, and makes the agent finish approved work instead of pausing to ask permission.

It's been my daily driver across a dozen production projects (iOS, Go, Python, Next.js).

## What it changes

Every reply, every session, without asking:

- **Plain-English TLDR first, hard cap ~10 lines.** Technical detail only after, and only what's needed to act. Long output (logs, diffs, reports) goes to a file, not the reply.
- **First line = the next action.** No preamble, no closing pleasantries. Multi-step work is numbered; state is restated every turn ("Step 3 of 5 done: X. Doing 4 now: Y").
- **Momentum (Rule 0).** An approved plan is the go signal. The agent runs every phase to completion and never stops mid-task to ask "say go" — a next-action handed to you is only something *only you* can do (a decision, a login, a device test).
- **It opens files for you.** Never "open `src/auth.ts` and look at line 42" — it runs `code src/auth.ts` and says "opened it for you."
- **Concrete estimates, visible wins, capped lists, matter-of-fact errors.**

Full rules with rationale: [`skill/SKILL.md`](skill/SKILL.md). Each rule maps to a specific fact about ADHD cognition (small working memory, starting friction, flat time perception, scarce dopamine).

## Why a skill alone isn't enough

A skill only shapes output when it's invoked, and terseness decays over long sessions as the instruction falls out of recency. So this is enforced in three layers:

1. **The skill** (`~/.claude/skills/i-have-adhd/SKILL.md`) — source of truth, also invocable as `/i-have-adhd`.
2. **A SessionStart hook** — injects the full skill at session start, resume, clear, and compact.
3. **A UserPromptSubmit hook** — injects a ~400-token compact reminder after *every* prompt. This is the load-bearing layer: highest recency in context, survives compaction, so the contract doesn't fade at hour three.

Both hooks are one script: [`hooks/adhd.sh`](hooks/adhd.sh). No dependencies beyond bash.

## Install

One command, ~30 seconds:

```bash
git clone https://github.com/m1insights/i-have-adhd.git && cd i-have-adhd && ./install.sh
```

The installer copies the skill and hook into `~/.claude/`, wires both hooks into `~/.claude/settings.json` without touching anything else in it, and backs the file up first (`settings.json.bak.i-have-adhd`). Safe to re-run. Needs bash + python3.

Uninstall: delete `~/.claude/skills/i-have-adhd/`, `~/.claude/hooks/adhd.sh`, and the two `adhd.sh` hook entries in `settings.json` (or restore the backup).

<details>
<summary>Manual install (if you'd rather not run a script)</summary>

```bash
mkdir -p ~/.claude/skills/i-have-adhd ~/.claude/hooks
cp skill/SKILL.md ~/.claude/skills/i-have-adhd/SKILL.md
cp hooks/adhd.sh  ~/.claude/hooks/adhd.sh
chmod +x ~/.claude/hooks/adhd.sh
```

Then wire the hooks into `~/.claude/settings.json`:

```json
{
  "hooks": {
    "SessionStart": [
      {
        "matcher": "startup|resume|clear|compact",
        "hooks": [
          { "type": "command", "command": "\"$HOME/.claude/hooks/adhd.sh\" session-start", "timeout": 10 }
        ]
      }
    ],
    "UserPromptSubmit": [
      {
        "hooks": [
          { "type": "command", "command": "\"$HOME/.claude/hooks/adhd.sh\" prompt", "timeout": 10 }
        ]
      }
    ]
  }
}
```

</details>

New sessions pick it up immediately. Verify: ask Claude anything — the reply should lead with a plain-English answer and fit on one screen.

Optional: if you use custom slash commands that orchestrate long tasks, append [`examples/task-command-footer.md`](examples/task-command-footer.md) to them so subagent-driven runs report in the same register — and never pause between approved phases.

## Two lessons from running this for months

**Your example text trains the model.** An early version of Rule 5 showed the "good" state restatement as: *"Step 3 of 5 done: schema updated. Next: backfill the new column. Run the script?"* That trailing question taught Claude to stop between phases of already-approved plans and wait for a "go" — even in auto-accept mode, even mid-orchestration. Every example in a skill is a behavioral template, not an illustration. The fix was rewriting the examples as autonomous continuations and adding Rule 0.

**Brevity and autonomy pull in opposite directions.** "End with one next action for the reader" quietly becomes "hand the next phase back to the reader." The contract now separates them explicitly: brevity governs how the agent *reports*, never how much it *works*. Short replies, full effort.

## Files

| Path | What it is |
|---|---|
| `skill/SKILL.md` | The skill — full contract with rationale and examples |
| `hooks/adhd.sh` | Both hooks in one script (`session-start` / `prompt` modes) |
| `install.sh` | One-command installer — copies files, wires hooks, backs up settings |
| `examples/task-command-footer.md` | Drop-in footer for custom orchestrator slash commands |

## License

MIT. If this helps your brain too, that's the point.
