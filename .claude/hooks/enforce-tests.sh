#!/bin/bash
# Stop hook — runs the test suite before Claude declares "done".
# Exit 2 = block and send message to Claude for self-correction.
# Exit 0 = allow.

INPUT=$(cat)

# Prevent infinite loop: if Claude is already retrying due to this hook, let it stop.
STOP_HOOK_ACTIVE=$(echo "$INPUT" | jq -r '.stop_hook_active // false')
if [ "$STOP_HOOK_ACTIVE" = "true" ]; then
    exit 0
fi

# Skip if the project hasn't been generated yet.
if [ ! -f "$CLAUDE_PROJECT_DIR/LapinBrowser.xcodeproj/project.pbxproj" ]; then
    exit 0
fi

xcodebuild test \
    -project "$CLAUDE_PROJECT_DIR/LapinBrowser.xcodeproj" \
    -scheme LapinBrowser \
    -destination 'platform=macOS' \
    -quiet 2>&1

if [ $? -ne 0 ]; then
    echo "Tests failed — fix the failures before finishing." >&2
    exit 2
fi

exit 0
