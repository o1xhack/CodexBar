#!/usr/bin/env bash
set -euo pipefail

ROOT=$(cd "$(dirname "$0")/.." && pwd)
cd "$ROOT"

source "$ROOT/version.env"
source "$ROOT/Scripts/load-release-secrets.sh"
source "$HOME/Projects/agent-scripts/release/sparkle_lib.sh"

APPCAST="$ROOT/appcast.xml"
APP_NAME="CodexBar"
RELEASE_ASSET_BASENAME="${APP_NAME}-${MARKETING_VERSION}-mobile.${MOBILE_VERSION}"
ARTIFACT_PREFIX="CodexBar-"
BUNDLE_ID="com.o1xhack.codexbar"
RELEASE_BRANCH="${CODEXBAR_RELEASE_BRANCH:-mobile-dev}"
FEED_URL="https://raw.githubusercontent.com/o1xhack/CodexBar/${RELEASE_BRANCH}/appcast.xml"
TAG="v${MARKETING_VERSION}-mobile.${MOBILE_VERSION}"
RELEASE_TITLE="${APP_NAME} ${MARKETING_VERSION} Mobile ${MOBILE_VERSION}"

err() { echo "ERROR: $*" >&2; exit 1; }

require_clean_worktree
ensure_changelog_finalized "$MARKETING_VERSION"
ensure_appcast_monotonic "$APPCAST" "$MARKETING_VERSION" "$BUILD_NUMBER"

swiftformat Sources Tests >/dev/null
swiftlint --strict
swift test

# Note: run this script in the foreground; do not background it so it waits to completion.
"$ROOT/Scripts/sign-and-notarize.sh"

KEY_FILE=$(clean_key "$SPARKLE_PRIVATE_KEY_FILE")
trap 'rm -f "$KEY_FILE"' EXIT

probe_sparkle_key "$KEY_FILE"

clear_sparkle_caches "$BUNDLE_ID"

NOTES_FILE=$(mktemp /tmp/codexbar-notes.XXXXXX.md)
extract_notes_from_changelog "$MARKETING_VERSION" "$NOTES_FILE"
trap 'rm -f "$KEY_FILE" "$NOTES_FILE"' EXIT

git tag -s -f -m "${RELEASE_TITLE}" "$TAG"
git push -f origin "$TAG"

gh release create "$TAG" "${RELEASE_ASSET_BASENAME}.zip" "${RELEASE_ASSET_BASENAME}.dSYM.zip" \
  --title "${RELEASE_TITLE}" \
  --notes-file "$NOTES_FILE"

SPARKLE_PRIVATE_KEY_FILE="$KEY_FILE" \
  SPARKLE_RELEASE_VERSION="$MARKETING_VERSION" \
  "$ROOT/Scripts/make_appcast.sh" \
  "${RELEASE_ASSET_BASENAME}.zip" \
  "$FEED_URL"

verify_appcast_entry "$APPCAST" "$MARKETING_VERSION" "$KEY_FILE"

git add "$APPCAST"
git commit -m "docs: update appcast for ${MARKETING_VERSION}"
git push origin "$RELEASE_BRANCH"

if [[ "${RUN_SPARKLE_UPDATE_TEST:-0}" == "1" ]]; then
  PREV_TAG=$(git tag --sort=-v:refname | sed -n '2p')
  [[ -z "$PREV_TAG" ]] && err "RUN_SPARKLE_UPDATE_TEST=1 set but no previous tag found"
  "$ROOT/Scripts/test_live_update.sh" "$PREV_TAG" "v${MARKETING_VERSION}"
fi

check_assets "$TAG" "$ARTIFACT_PREFIX"

git push origin --tags

echo "Release ${MARKETING_VERSION} complete."
