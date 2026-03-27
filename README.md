# Lapin Browser

A macOS menu bar app that acts as your system default browser, routing URLs to the right browser profile based on rules you define.

Click a link anywhere on your Mac → Lapin matches the URL against your rules → your browser opens in the correct profile.

**Supported browsers:** Google Chrome, Brave

## Requirements

- macOS 13.0+
- Google Chrome or Brave
- [xcodegen](https://github.com/yonaskolb/XcodeGen)

## Build

```bash
brew install xcodegen
xcodegen generate
open LapinBrowser.xcodeproj
```

Build and run from Xcode, or via the command line:

```bash
xcodebuild build -project LapinBrowser.xcodeproj -scheme LapinBrowser -destination 'platform=macOS'
```

## Usage

1. Run the app — a rabbit icon appears in the menu bar.
2. Open **Settings → General**, select your **Browser**, click **Set as Default Browser**, and confirm in the macOS dialog.
3. Open **Settings → Rules**, click **+** to add a rule. Each rule has:
   - **Pattern** — a glob matched against the URL host (e.g. `*.apple.com`) or the full URL when the pattern contains a `/` (e.g. `https://linear.app/*`). Case-insensitive.
   - **Profile** — the browser profile to open.
   - **Label** — optional note for yourself.
   - **Enabled** toggle.
4. Rules are evaluated top-to-bottom; the first match wins. Unmatched URLs open in the default profile set in General.

## How it works

When macOS routes a URL to Lapin, `AppDelegate.application(_:open:)` passes it to `URLRouter`, which walks the enabled rules in order and uses POSIX `fnmatch` to test each pattern. The matched profile (or the configured default) is passed to `BrowserLauncher`, which spawns the active browser with `--profile-directory`.

Settings are persisted to `~/Library/Application Support/pt.lapin.browser/settings.json`. Available profiles are detected on each launch by reading the active browser's `Local State` JSON.

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md). Licensed under the [MIT License](LICENSE).
