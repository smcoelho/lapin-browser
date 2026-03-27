# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Setup

`project.yml` is the source of truth for the Xcode project. The `.xcodeproj` is gitignored and must be regenerated before building:

```bash
brew install xcodegen   # first time only
xcodegen generate
```

## Build & Test

```bash
# Build (after xcodegen generate)
xcodebuild build -project LapinBrowser.xcodeproj -scheme LapinBrowser -destination 'platform=macOS'

# Run all tests
xcodebuild test -project LapinBrowser.xcodeproj -scheme LapinBrowser -destination 'platform=macOS'

# Run a single test class
xcodebuild test -project LapinBrowser.xcodeproj -scheme LapinBrowser -destination 'platform=macOS' -only-testing:LapinBrowserTests/URLRouterTests

# Run a single test method
xcodebuild test -project LapinBrowser.xcodeproj -scheme LapinBrowser -destination 'platform=macOS' -only-testing:LapinBrowserTests/URLRouterTests/testHostPatternMatches
```

## Architecture

Lapin Browser is a macOS menu bar app (no Dock icon via `LSUIElement`) that registers as the system default browser and routes every incoming URL to a specific browser profile based on user-defined glob rules. Supported browsers: Google Chrome, Brave.

**URL flow:** macOS clicks a link → OS calls `AppDelegate.application(_:open:)` → `URLRouter.shared.route(url)` → `BrowserLauncher.open(url, in: profile, browser:)`

### Key design decisions

**Glob matching** (`URLRouter.matchedProfileID`): patterns without `/` are matched against `url.host` only; patterns containing `/` are matched against `url.absoluteString` (including scheme, e.g. `https://blip.pt/*`). Uses POSIX `fnmatch` with `FNM_CASEFOLD`. First matching enabled rule wins.

**Browser launch strategy**: When the active browser is already running, a `Process` is spawned directly with `--profile-directory` and the URL as arguments. When it is not running, `NSWorkspace.OpenConfiguration` is used for cold launch (with `Process` as fallback if it fails).

**`Browser` model** (`Models/Browser.swift`): value type capturing `id` (bundle ID), `name`, `localStatePath` (relative to home dir), `fallbackAppPath`, and `binaryName`. `Browser.all` lists all supported browsers; `AppDelegate` filters to installed ones on launch.

**`AppSettings`** is a `@MainActor` singleton (`ObservableObject`) that persists `rules`, `defaultProfileID`, and `activeBrowserID` to `~/Library/Application Support/pt.lapin.browser/settings.json`. `availableProfiles` and `availableBrowsers` are runtime-only — populated on launch by `BrowserProfileDetector` reading the active browser's `Local State` JSON.

**No sandbox** — required to read browser Local State files and spawn processes. Entitlements explicitly set `com.apple.security.app-sandbox = false`.

### Settings persistence

`rules: [URLRule]`, `defaultProfileID: String`, and `activeBrowserID: String` are persisted. `availableProfiles: [BrowserProfile]` and `availableBrowsers: [Browser]` are always re-detected on launch. `activeBrowserID` defaults to `"com.google.Chrome"` when absent (backward-compatible with existing settings files).

## Deployment target & constraints

- macOS 13.0 minimum
- Bundle ID: `pt.lapin.browser`
- Swift 6.0
- Ad-hoc signing (`CODE_SIGN_IDENTITY = "-"`, `CODE_SIGN_STYLE = Manual`) — no provisioning profile needed for local development
