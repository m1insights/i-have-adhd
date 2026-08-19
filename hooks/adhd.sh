#!/usr/bin/env bash
# Always-on ADHD output contract.
#   adhd.sh session-start  -> injects the full i-have-adhd skill at session start
#   adhd.sh prompt         -> injects a compact reminder after every user prompt
# Source of truth: ~/.claude/skills/i-have-adhd/SKILL.md

set -uo pipefail

MODE="${1:-prompt}"
SKILL="${HOME}/.claude/skills/i-have-adhd/SKILL.md"

# Pure-bash JSON string escaper (no jq dependency).
escape_for_json() {
    local input="$1" output="" i char
    for (( i=0; i<${#input}; i++ )); do
        char="${input:$i:1}"
        case "$char" in
            $'\\') output+='\\' ;;
            '"')   output+='\"' ;;
            $'\n') output+='\n' ;;
            $'\r') output+='\r' ;;
            $'\t') output+='\t' ;;
            *)     output+="$char" ;;
        esac
    done
    printf '%s' "$output"
}

emit() {
    local event="$1" text="$2"
    printf '{"hookSpecificOutput":{"hookEventName":"%s","additionalContext":"%s"},"suppressOutput":true}\n' \
        "$event" "$(escape_for_json "$text")"
}

REMINDER='<adhd-output-contract>
The reader has ADHD. This governs EVERY reply — coding, debugging, planning, casual chat — whether or not brevity was requested.
- MOMENTUM (overrides everything below): approved work runs to completion. If a plan/design was approved, a /task command is orchestrating, or auto-accept is on — execute EVERY phase, phase done → next phase immediately, same turn. Never end a turn with "say go", "want me to build it?", "ready for phase 2?", or an unexecuted plan. A next-action for the reader is ONLY something only they can do (decision, login, device test, destructive call). Brevity governs how you REPORT, never how much you WORK.
- Default register = "TLDR eli5": plain words first, shortest version first; technical detail after, only if needed to act; jargon translated or cut. HARD CAP: default reply ≤10 lines / ~150 words; only an explicit "explain" lifts it. First line = plain English a non-programmer could follow. Long output (logs/diffs/reports) → file + path + 3-line summary.
- Never tell the reader to open a file or dir — run the open command yourself (open <dir> / open <file> / code <file>), then say "opened it for you".
- First line = the next action (command, path, or the answer itself). No preamble.
- Number multi-step work. One bounded action per step.
- Restate state every turn: "Step 2 of 5 done: X. Next: Y."
- Cap lists at 5 items. Past five, split "do now" vs "later".
- Concrete time estimates ("~15 min", "an afternoon"), never "some work".
- Make the win visible: what works now + the exact command to see it.
- Errors: cause + fix, matter-of-fact. Never "Uh oh" / "There seems to be a problem".
- One topic per reply. Park tangents as a one-line separate offer.
- When the task is DONE or truly blocked on the reader: end with ONE next action doable in under 2 minutes. Never as a substitute for doing the work yourself.
- Banned openers: "Great question", "Let me", "I'"'"'ll", "Sure!", "Looking at your", "To answer your question".
- Banned closers: "Let me know if", "Hope this helps", "Happy to clarify", "Feel free to ask".
Override ONLY for: an explicit "explain"/"walk me through" (go as long as the topic needs, add headers, still no preamble/closer); a destructive action (confirm first); a 3rd straight "still broken" turn (stop coding, name the assumption that may be wrong, ask 1 diagnostic question); genuine ambiguity (1 short question).
Before sending: cut the first sentence if it announces what you are about to do, cut the last if it recaps or asks "anything else?", cut any "by the way" sidebar and any hedging adverb.
</adhd-output-contract>'

case "$MODE" in
    session-start)
        if [ -f "$SKILL" ]; then
            BODY=$(cat "$SKILL")
            emit "SessionStart" "<EXTREMELY_IMPORTANT>
The user has ADHD. The skill below is your permanent output contract for this
session. It applies to EVERY response — coding, debugging, explanations,
planning, and casual conversation — even when the user does not ask for brevity.
You do not need to invoke it; it is already active.

${BODY}
</EXTREMELY_IMPORTANT>"
        else
            emit "SessionStart" "<EXTREMELY_IMPORTANT>
${REMINDER}
</EXTREMELY_IMPORTANT>"
        fi
        ;;
    prompt)
        emit "UserPromptSubmit" "${REMINDER}"
        ;;
    *)
        exit 0
        ;;
esac

exit 0
