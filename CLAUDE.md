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

Lapin Browser is a macOS menu bar app (no Dock icon via `LSUIElement`) that registers as the system default browser and routes every incoming URL to a specific browser and profile based on user-defined glob rules. Supported browsers: Google Chrome, Brave, Safari.

**URL flow:** macOS clicks a link → OS calls `AppDelegate.application(_:open:)` → `URLRouter.shared.route(url)` → `BrowserLauncher.open(url, in: profile, browser:)`

**File naming:** some files still carry pre-multi-browser names: `BrowserProfile` lives in `Models/ChromeProfile.swift`, `BrowserProfileDetector` in `Services/ChromeProfileDetector.swift`, and `BrowserLauncher` in `Services/ChromeLauncher.swift`.

### Key design decisions

**Glob matching** (`URLRouter.matchedRule`): patterns without `/` are matched against `url.host` only; patterns containing `/` are matched against `url.absoluteString` (including scheme, e.g. `https://blip.pt/*`), with a trailing `/` appended when the URL has no path. Uses POSIX `fnmatch` with `FNM_CASEFOLD`. If there's no direct match, a leading `www.`/`ftp.` on the host is stripped and `http://` is retried as `https://`. First matching enabled rule wins.

**Browser/profile resolution** (`URLRouter.route`): browser = rule's `browserID` → global `activeBrowserID` → Chrome. Profile = rule's `profileID` → `defaultProfileID`. When a rule pins a browser, the profile lookup is scoped to that browser and falls back to its first profile if the ID isn't found.

**Browser launch strategy** (`BrowserLauncher`): for browsers with `supportsProfiles`, when the browser is already running a `Process` is spawned directly with `--profile-directory` and the URL; when it is not running, `NSWorkspace.OpenConfiguration` is used for cold launch (with `Process` as fallback). Profileless browsers (Safari) always go through `NSWorkspace` with no arguments so the URL opens as a tab, not a new window.

**`Browser` model** (`Models/Browser.swift`): value type capturing `id` (bundle ID), `name`, `localStatePath` (relative to home dir; empty for Safari), `fallbackAppPath`, `binaryName`, and `supportsProfiles`. `Browser.all` lists all supported browsers; `AppDelegate` filters to installed ones on launch. For profileless browsers `BrowserProfileDetector` returns a single synthetic "Default" profile, and the UI hides profile pickers.

**`AppSettings`** is a `@MainActor` singleton (`ObservableObject`) that persists to `~/Library/Application Support/pt.lapin.browser/settings.json`. `availableProfiles` (across all installed browsers, each tagged with `browserID`) and `availableBrowsers` are runtime-only, populated on launch by `AppDelegate`.

**Profile re-matching**: `save()` stores each rule's profile email / display name / GAIA name alongside `profileID`. On launch, `resolveProfileIDs()` uses these to re-point rules whose `profileID` no longer exists (e.g. after a browser reshuffles profile directories).

**No sandbox** — required to read browser Local State files and spawn processes. Entitlements explicitly set `com.apple.security.app-sandbox = false`.

### Settings persistence

Persisted: `rules: [URLRule]` (each with optional `browserID` and profile identity fields), `defaultProfileID`, `activeBrowserID`, `launchAtLogin`. `activeBrowserID` defaults to `"com.google.Chrome"` when absent (backward-compatible with older settings files); if the saved browser is no longer installed, `AppDelegate` switches to the first installed one. A rule with `browserID == nil` uses the global browser.

## Release

To publish a new version, run locally:

```bash
./scripts/bump-version.sh 1.1
```

This bumps `Info.plist`, commits, tags `v1.1`, and pushes. GitHub Actions (`.github/workflows/release.yml`) picks up the tag and handles the build, signing, GitHub release creation, and Homebrew tap update automatically.

**One-time setup required**: Add a `TAP_TOKEN` secret to this repo (GitHub PAT with `Contents: Read and write` on `smcoelho/homebrew-tap`) so the workflow can push to the tap.

`scripts/release.sh` remains as a manual fallback if CI is unavailable.

## Deployment target & constraints

- macOS 13.0 minimum
- Bundle ID: `pt.lapin.browser`
- Swift 6.0
- Ad-hoc signing (`CODE_SIGN_IDENTITY = "-"`, `CODE_SIGN_STYLE = Manual`) — no provisioning profile needed for local development
