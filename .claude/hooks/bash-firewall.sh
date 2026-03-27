#!/bin/bash
# PreToolUse hook — blocks dangerous bash commands before they run.
# Exit 2 = block execution and send stderr to Claude for self-correction.
# Exit 0 = allow.

INPUT=$(cat)
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty')

if [ -z "$COMMAND" ]; then
    exit 0
fi

# Literal string patterns (checked with grep -F)
LITERAL_PATTERNS=(
    "rm -rf /"
    "git push --force"
    "git push -f "
    "DROP TABLE"
    "DROP DATABASE"
    "> /dev/"
    "| bash"
    "| sh"
)

for pattern in "${LITERAL_PATTERNS[@]}"; do
    if echo "$COMMAND" | grep -qF "$pattern"; then
        echo "Blocked: command matches dangerous pattern '$pattern'" >&2
        exit 2
    fi
done

exit 0
