# Contributing

Contributions are welcome — bug fixes, new features, and improvements to the codebase.

## Getting started

```bash
brew install xcodegen
xcodegen generate
open LapinBrowser.xcodeproj
```

See [CLAUDE.md](CLAUDE.md) for build and test commands.

## Submitting changes

1. Fork the repository and create a branch from `main`.
2. Make your changes. Add or update tests in `LapinBrowserTests/` as appropriate.
3. Ensure all tests pass:
   ```bash
   xcodebuild test -project LapinBrowser.xcodeproj -scheme LapinBrowser -destination 'platform=macOS'
   ```
4. Open a pull request with a clear description of what changed and why.

## Guidelines

- Keep pull requests focused — one logical change per PR.
- The app runs without sandboxing by design (needed to read Chrome's Local State and spawn processes). Don't add sandboxing.
- `AppSettings` is `@MainActor` — keep all settings access on the main actor.
- New URL matching behaviour belongs in `URLRouter.matchedProfileID` and should be covered by a test in `URLRouterTests`.

## Reporting issues

Open an issue on GitHub. Include your macOS version, Chrome version, and the contents of `~/Library/Application Support/pt.lapin.browser/settings.json` (redact any sensitive URLs if needed).
