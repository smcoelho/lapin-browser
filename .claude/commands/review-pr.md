# Review PR

Review an existing GitHub pull request. Usage: `/review-pr <PR number>`

## Steps

1. `gh pr view $ARGUMENTS` — get title, description, author, base branch
2. `gh pr diff $ARGUMENTS` — get the full diff
3. `gh pr checks $ARGUMENTS` — check CI status
4. Read any changed Swift files in full for deeper context beyond the diff
5. Output a structured review (see format below)

## Review checklist

### Correctness
- Logic errors, off-by-one, unhandled nil/optional
- Missing error propagation or swallowed errors
- Edge cases not covered (empty arrays, empty strings, missing profiles)

### Swift 6 concurrency
- `@MainActor` on anything that touches `AppSettings`, SwiftUI views, or `NSApp`
- No data races: check `Sendable` conformance when values cross actor boundaries
- `async/await` used correctly; no blocking calls on the main actor

### Architecture fit
- New browser support follows the `Browser` model pattern in `Models/Browser.swift`
- Services use `BrowserLauncher` / `BrowserProfileDetector` — not hardcoded bundle IDs
- Persisted settings changes go through `AppSettings.save()` and `PersistedSettings`
- No new sandbox entitlements added without clear justification

### No sandbox violations
- No new APIs that require entitlements not in `LapinBrowser.entitlements`
- File access outside app sandbox handled correctly (reading Chrome/Brave Local State is intentional and already allowed)

### Tests
- URL routing logic changes covered by `URLRouterTests`
- New matching patterns tested with both host-only and full-URL forms

## Output format

**Summary** — one paragraph on what the PR does and why

**Issues** (blocking)
- `file.swift:42` — description of bug or problem

**Suggestions** (non-blocking)
- `file.swift:15` — improvement idea

**Verdict**: Approve / Request changes / Needs discussion
