# Safari Browser Integration

**Date:** 2026-05-11
**Branch:** `feature/per-rule-browser` (base for this work)

## Summary

Add Safari as a supported browser in Lapin, alongside Google Chrome and Brave. Each URL routing rule can specify a browser (per-rule browser selection, already implemented on `feature/per-rule-browser`). Safari has no profile system — all URLs routed to Safari open without a `--profile-directory` argument.

## Scope

- Safari support is **basic**: no profile selection, one synthetic "Default" profile.
- Per-rule browser selection (rule's `browserID` field) is the delivery vehicle — already implemented on `feature/per-rule-browser`. This work adds Safari on top of that.
- Safari profiles (macOS Sonoma 14+) are **out of scope**.
- When Safari is the target browser for a rule, the profile ID stored in the rule is ignored at launch time.

## Architecture

### `Browser.swift`

Add `supportsProfiles: Bool` to the `Browser` struct with a default of `true` (backward-compatible — Chrome and Brave unaffected). Add a `Browser.safari` static instance with `supportsProfiles: false`. Add `.safari` to `Browser.all`.

```
Browser.safari = Browser(
    id: "com.apple.Safari",
    name: "Safari",
    localStatePath: "",
    fallbackAppPath: "/Applications/Safari.app",
    binaryName: "Safari",
    supportsProfiles: false
)
```

### `BrowserProfileDetector.swift`

When `browser.supportsProfiles == false`, skip the `Local State` JSON read and return a single synthetic profile:

```
BrowserProfile(
    id: "default",
    directoryName: "default",
    displayName: "Default",
    email: "",
    gaiaName: "",
    browserID: browser.id
)
```

This ensures `URLRouter` can always find a profile for Safari without fallback logic changes, and the rule editor has a valid profile ID to store.

### `BrowserLauncher.swift` (ChromeLauncher)

When `browser.supportsProfiles == false`, open the URL without passing `--profile-directory`. The running/not-running split still applies:

- **Browser running:** `Process` with `arguments = [url.absoluteString]` (no profile arg)
- **Browser not running:** `NSWorkspace.OpenConfiguration` with no arguments (no profile arg), `Process` as fallback

The `BrowserProfile` parameter is still accepted to keep call sites uniform but is ignored.

### `RuleEditView` (UI)

When the browser selected for a rule has `supportsProfiles == false`, hide the profile `Picker` entirely. The browser-change handler in `RuleEditView` must explicitly set `rule.profileID = "default"` when a `supportsProfiles == false` browser is selected, so the rule is always in a valid state. The user never sees or interacts with the profile field for these browsers.

## Data flow

```
User clicks link
  → URLRouter.route(url)
  → matchedRule(for: url, rules:) → URLRule(browserID: "com.apple.Safari", profileID: "default")
  → browser = Browser.safari
  → profile = availableProfiles.first { $0.id == "default" && $0.browserID == "com.apple.Safari" }
  → BrowserLauncher.open(url, in: profile, browser: .safari)
  → browser.supportsProfiles == false → open without --profile-directory
```

## Error handling

- If Safari is not installed, `NSWorkspace.urlForApplication(withBundleIdentifier: "com.apple.Safari")` returns nil → `AppDelegate` filters it out of `availableBrowsers` → Safari does not appear as an option. No special handling needed.
- If `BrowserLauncher` fails to launch Safari (Process throws), the existing `logger.error` path handles it — same as Chrome/Brave.

## Testing

- `URLRouterTests`: existing tests are unaffected. Add a test verifying that a rule with `browserID: "com.apple.Safari"` routes correctly (returns the rule, correct browser resolved).
- `BrowserProfileDetector`: unit test verifying Safari returns exactly one synthetic "Default" profile.
- Manual: select Safari as the browser for a rule, click a link matching that rule, confirm it opens in Safari without a crash.

## Migration

No settings migration needed. `supportsProfiles` is a code-only field (not persisted). Existing settings files (Chrome/Brave rules) are unaffected. Safari rules use `profileID: "default"` which is set at rule-creation time.

## Branch strategy

Work is done on `feature/per-rule-browser`. When complete, the branch is merged to `main` as a single deliverable: per-rule browser selection + Safari support.
