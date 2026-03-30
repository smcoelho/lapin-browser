#!/usr/bin/env bash
# scripts/bump-version.sh — Bump version and push a release tag.
#
# Usage: ./scripts/bump-version.sh <version>
# Example: ./scripts/bump-version.sh 1.1
#
# This triggers the GitHub Actions release workflow, which handles
# the build, signing, GitHub release creation, and Homebrew tap update.

set -euo pipefail

if [[ $# -lt 1 ]]; then
  echo "Usage: $0 <version>" >&2
  echo "  Example: $0 1.1" >&2
  exit 1
fi

VERSION="$1"
PLIST="LapinBrowser/Info.plist"

CURRENT_BUILD=$(/usr/libexec/PlistBuddy -c "Print :CFBundleVersion" "${PLIST}")
NEW_BUILD=$(( CURRENT_BUILD + 1 ))

/usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString ${VERSION}" "${PLIST}"
/usr/libexec/PlistBuddy -c "Set :CFBundleVersion ${NEW_BUILD}" "${PLIST}"

echo "==> Version: ${VERSION} (build ${NEW_BUILD})"

git add "${PLIST}"
git commit -m "chore: bump version to ${VERSION} (build ${NEW_BUILD})"
git tag "v${VERSION}"
git push origin main
git push origin "v${VERSION}"

echo "==> Tagged v${VERSION} — GitHub Actions will build and publish the release."
