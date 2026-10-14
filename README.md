# Lapin Browser

A macOS menu bar app that acts as your system default browser, routing URLs to the right browser and profile based on rules you define.

Click a link anywhere on your Mac → Lapin matches the URL against your rules → the right browser opens in the right profile.

**Supported browsers:** Google Chrome, Brave, Safari (Safari has no profile selection; links open as a new tab)

## Install

```bash
brew install --cask smcoelho/tap/lapin-browser
```

Or download the latest `LapinBrowser-<version>.zip` from [Releases](https://github.com/smcoelho/lapin-browser/releases).

## Requirements

- macOS 13.0+
- At least one supported browser installed
- [xcodegen](https://github.com/yonaskolb/XcodeGen) (only to build from source)

## Build from source

```bash
brew install xcodegen
xcodegen generate
open LapinBrowser.xcodeproj
```

Build and run from Xcode, or via the command line:

```bash
xcodebuild build -project LapinBrowser.xcodeproj -scheme LapinBrowser -destination 'platform=macOS'
xcodebuild test  -project LapinBrowser.xcodeproj -scheme LapinBrowser -destination 'platform=macOS'
```

## Usage

1. Run the app. A rabbit icon appears in the menu bar (there is no Dock icon).
2. Open **Settings → General**:
   - Pick the default **Browser** and, for Chrome or Brave, the **Default Profile**. These handle any URL that no rule matches.
   - Click **Set as Default Browser** and confirm in the macOS dialog.
   - Optionally enable **Launch at Login**.
3. Open **Settings → Rules** and click **+** to add a rule. Each rule has:
   - **Pattern**: a case-insensitive glob (see below).
   - **Label**: an optional note for yourself.
   - **Browser**: a specific browser, or **Default (global)** to use the one set in General.
   - **Profile**: the browser profile to open. Hidden for browsers without profiles, such as Safari.
   - **Enabled** toggle.
4. Rules are checked top to bottom, and the first enabled match wins.

### Pattern syntax

| Pattern | Matches against | Example match |
|---|---|---|
| No `/`, e.g. `*.apple.com` | URL host only | `https://developer.apple.com/news` |
| Contains `/`, e.g. `https://linear.app/*` | Full URL, including scheme | `https://linear.app/team/issue/123` |

Matching is forgiving in two ways:

- A leading `www.` or `ftp.` in the URL host is ignored when the pattern doesn't match directly, so `apple.com` also matches `https://www.apple.com`.
- `http://` URLs are also tried as `https://`, so an `https://…` rule catches plain-HTTP links too.

### Editing settings by hand

Settings live in `~/Library/Application Support/pt.lapin.browser/settings.json`. **Settings → General → Edit settings.json** opens it directly.

## How it works

When macOS routes a URL to Lapin, `AppDelegate.application(_:open:)` passes it to `URLRouter`. The router walks the enabled rules in order, tests each pattern with POSIX `fnmatch`, and resolves the browser (the rule's browser, else the global one) and the profile (the rule's profile, else the default).

`BrowserLauncher` then opens the URL:

- **Chrome and Brave**: launched with `--profile-directory=<profile>`. If the browser is already running, its binary is spawned directly. On a cold start, `NSWorkspace` is used instead, with a direct spawn as the fallback.
- **Safari**: opened through `NSWorkspace` with no extra arguments, so the link lands in a new tab of the existing window.

Profiles are detected on every launch by reading each installed browser's `Local State` file. The app runs unsandboxed because it needs to read those files and launch browser processes.

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md). Licensed under the [MIT License](LICENSE).
