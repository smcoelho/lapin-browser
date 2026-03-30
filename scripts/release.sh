#!/usr/bin/env bash
# scripts/release.sh — Manual fallback: build, sign, archive, and publish a release.
#
# NOTE: The primary release path is GitHub Actions (triggered by version tags).
# Use bump-version.sh instead: ./scripts/bump-version.sh <version>
#
# This script is only needed if you must release without CI access.
#
# Usage: ./scripts/release.sh <version>
# Example: ./scripts/release.sh 1.1
#
# Prerequisites:
#   - gh CLI authenticated (gh auth status)
#   - xcodegen installed (brew install xcodegen)
#   - Tap repo cloned at ../homebrew-tap  OR  set TAP_REPO_PATH env var
#     git clone git@github.com:smcoelho/homebrew-tap.git ../homebrew-tap

set -euo pipefail

# ---------------------------------------------------------------------------
# Configuration
# ---------------------------------------------------------------------------
SCHEME="LapinBrowser"
PROJECT="LapinBrowser.xcodeproj"
BUNDLE_NAME="LapinBrowser"
PLIST="LapinBrowser/Info.plist"
BUILD_DIR="$(pwd)/build"
ARCHIVE_PATH="${BUILD_DIR}/${BUNDLE_NAME}.xcarchive"
APP_PATH="${ARCHIVE_PATH}/Products/Applications/${BUNDLE_NAME}.app"
GITHUB_REPO="smcoelho/lapin-browser"
TAP_REPO_PATH="${TAP_REPO_PATH:-../homebrew-tap}"
CASK_FILE="${TAP_REPO_PATH}/Casks/lapin-browser.rb"

# ---------------------------------------------------------------------------
# Argument validation
# ---------------------------------------------------------------------------
if [[ $# -lt 1 ]]; then
  echo "Usage: $0 <version>" >&2
  echo "  Example: $0 1.1" >&2
  exit 1
fi

VERSION="$1"
ZIP_NAME="${BUNDLE_NAME}-${VERSION}.zip"
ZIP_PATH="${BUILD_DIR}/${ZIP_NAME}"

echo "==> Releasing Lapin Browser v${VERSION}"

# ---------------------------------------------------------------------------
# Check prerequisites
# ---------------------------------------------------------------------------
if ! command -v xcodegen &> /dev/null; then
  echo "ERROR: xcodegen not found. Install with: brew install xcodegen" >&2
  exit 1
fi

if ! command -v gh &> /dev/null; then
  echo "ERROR: gh CLI not found. Install with: brew install gh" >&2
  exit 1
fi

if ! gh auth status &> /dev/null; then
  echo "ERROR: gh CLI not authenticated. Run: gh auth login" >&2
  exit 1
fi

if [[ ! -f "${CASK_FILE}" ]]; then
  echo "ERROR: Tap cask not found at ${CASK_FILE}" >&2
  echo "       Clone the tap repo first:" >&2
  echo "         git clone git@github.com:smcoelho/homebrew-tap.git ../homebrew-tap" >&2
  echo "       Or set TAP_REPO_PATH to point to your local clone." >&2
  exit 1
fi

# ---------------------------------------------------------------------------
# 1. Bump version in Info.plist
# ---------------------------------------------------------------------------
echo "==> Bumping version in ${PLIST}"

CURRENT_BUILD=$(/usr/libexec/PlistBuddy -c "Print :CFBundleVersion" "${PLIST}")
NEW_BUILD=$(( CURRENT_BUILD + 1 ))

/usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString ${VERSION}" "${PLIST}"
/usr/libexec/PlistBuddy -c "Set :CFBundleVersion ${NEW_BUILD}" "${PLIST}"

echo "    CFBundleShortVersionString = ${VERSION}"
echo "    CFBundleVersion            = ${NEW_BUILD}"

# ---------------------------------------------------------------------------
# 2. Regenerate Xcode project
# ---------------------------------------------------------------------------
echo "==> Running xcodegen generate"
xcodegen generate --quiet

# ---------------------------------------------------------------------------
# 3. Archive
# ---------------------------------------------------------------------------
echo "==> Archiving with xcodebuild (this may take a minute)"
mkdir -p "${BUILD_DIR}"
rm -rf "${ARCHIVE_PATH}"

xcodebuild archive \
  -project "${PROJECT}" \
  -scheme "${SCHEME}" \
  -configuration Release \
  -archivePath "${ARCHIVE_PATH}" \
  CODE_SIGN_IDENTITY="-" \
  CODE_SIGN_STYLE=Manual \
  CODE_SIGNING_REQUIRED=NO \
  AD_HOC_CODE_SIGNING_ALLOWED=YES \
  2>&1 | grep -E "^(Build|error:|warning: )" || true

if [[ ! -d "${APP_PATH}" ]]; then
  echo "ERROR: App not found at ${APP_PATH}" >&2
  echo "       Run xcodebuild archive manually to see the full build log." >&2
  exit 1
fi

# ---------------------------------------------------------------------------
# 4. Ad-hoc sign (force, in case xcodebuild skipped it with NO signing required)
# ---------------------------------------------------------------------------
echo "==> Signing ad-hoc"
codesign --force --deep --sign "-" "${APP_PATH}"

# ---------------------------------------------------------------------------
# 5. Create zip using ditto (preserves macOS metadata and resource forks)
# ---------------------------------------------------------------------------
echo "==> Creating ${ZIP_NAME}"
rm -f "${ZIP_PATH}"
ditto -c -k --keepParent "${APP_PATH}" "${ZIP_PATH}"

# ---------------------------------------------------------------------------
# 6. Compute SHA256
# ---------------------------------------------------------------------------
SHA256=$(shasum -a 256 "${ZIP_PATH}" | awk '{print $1}')
echo "    SHA256 = ${SHA256}"

# ---------------------------------------------------------------------------
# 7. Commit version bump, tag, and push
# ---------------------------------------------------------------------------
echo "==> Committing version bump"
git add "${PLIST}"
git commit -m "chore: bump version to ${VERSION} (build ${NEW_BUILD})"
git tag "v${VERSION}"
git push origin main
git push origin "v${VERSION}"

# ---------------------------------------------------------------------------
# 8. Create GitHub release and upload zip
# ---------------------------------------------------------------------------
echo "==> Creating GitHub release v${VERSION}"
gh release create "v${VERSION}" \
  --repo "${GITHUB_REPO}" \
  --title "v${VERSION}" \
  --notes "Lapin Browser v${VERSION}" \
  "${ZIP_PATH}#${ZIP_NAME}"

# ---------------------------------------------------------------------------
# 9. Update tap cask formula
# ---------------------------------------------------------------------------
echo "==> Updating tap formula"
sed -i '' "s/^  version \".*\"/  version \"${VERSION}\"/" "${CASK_FILE}"
sed -i '' "s/^  sha256 \".*\"/  sha256 \"${SHA256}\"/" "${CASK_FILE}"

pushd "${TAP_REPO_PATH}" > /dev/null
git add "Casks/lapin-browser.rb"
git commit -m "lapin-browser: update to v${VERSION}"
git push origin main
popd > /dev/null

echo ""
echo "==> Done. Lapin Browser v${VERSION} is live."
echo ""
echo "    Install:"
echo "      brew tap smcoelho/tap"
echo "      brew install --cask lapin-browser"
echo ""
echo "    Upgrade:"
echo "      brew upgrade --cask lapin-browser"
