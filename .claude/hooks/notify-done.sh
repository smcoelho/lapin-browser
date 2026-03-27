#!/bin/bash
# Notification hook — shows a macOS desktop alert when Claude finishes a task.

INPUT=$(cat)
MESSAGE=$(echo "$INPUT" | jq -r '.message // "Task complete"')

osascript -e "display notification \"$MESSAGE\" with title \"Lapin Browser\" sound name \"Glass\""

exit 0
