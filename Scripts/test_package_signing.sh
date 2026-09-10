#!/usr/bin/env bash
set -euo pipefail

ROOT=$(cd "$(dirname "$0")/.." && pwd)
PACKAGE_SCRIPT="$ROOT/Scripts/package_app.sh"
RELEASE_SCRIPT="$ROOT/Scripts/sign-and-notarize.sh"
FUNCTIONS_FILE=$(mktemp "${TMPDIR:-/tmp}/codexbar-package-signing-functions.XXXXXX")
trap 'rm -f "$FUNCTIONS_FILE"' EXIT

python3 - "$PACKAGE_SCRIPT" "$FUNCTIONS_FILE" <<'PY'
import sys
from pathlib import Path

script = Path(sys.argv[1]).read_text()
functions = []
for name in (
    'resolve_package_signing_mode',
    'verify_no_quarantine_attribute',
    'verify_packaged_app_integrity',
):
    start = script.index(f'{name}() {{')
    end = script.index('\n}\n', start) + 3
    functions.append(script[start:end])
Path(sys.argv[2]).write_text('\n\n'.join(functions))
PY

source "$FUNCTIONS_FILE"

unset CODEXBAR_SIGNING
SIGNING_MODE=
resolve_package_signing_mode
[[ "$SIGNING_MODE" == "adhoc" ]]

CODEXBAR_SIGNING=identity
resolve_package_signing_mode
[[ "$SIGNING_MODE" == "identity" ]]

CODEXBAR_SIGNING=invalid
if resolve_package_signing_mode 2>/dev/null; then
  echo "Invalid package signing mode unexpectedly succeeded" >&2
  exit 1
fi

grep -Fq 'CODEXBAR_SIGNING=identity ./Scripts/package_app.sh release' "$RELEASE_SCRIPT"
# Public package/artifact resolution must never fall back to an interactive
# macOS Keychain lookup during headless packaging.
grep -Fq -- '-packageAuthorizationProvider netrc' "$PACKAGE_SCRIPT"

TEMP_DIR=$(mktemp -d "${TMPDIR:-/tmp}/codexbar-package-signing.XXXXXX")
trap 'rm -f "$FUNCTIONS_FILE"; rm -rf "$TEMP_DIR"' EXIT
APP="$TEMP_DIR/CodexBar.app"
mkdir -p "$APP/Contents/Frameworks/Sparkle.framework"

xattr() {
  if [[ "${MOCK_QUARANTINE:-0}" == "1" ]]; then
    printf '0081;fake;Safari;https://example.invalid\n'
    return 0
  fi
  return 1
}

codesign() {
  return "${MOCK_CODESIGN_STATUS:-0}"
}

verify_packaged_app_integrity "$APP"

export MOCK_QUARANTINE=1
if verify_packaged_app_integrity "$APP" 2>/dev/null; then
  echo "Quarantined app unexpectedly passed integrity verification" >&2
  exit 1
fi
unset MOCK_QUARANTINE

export MOCK_CODESIGN_STATUS=1
if verify_packaged_app_integrity "$APP" 2>/dev/null; then
  echo "App with an invalid signature unexpectedly passed integrity verification" >&2
  exit 1
fi
unset MOCK_CODESIGN_STATUS

python3 - "$PACKAGE_SCRIPT" <<'PY'
import itertools
import os
import plistlib
import subprocess
import sys
import tempfile
from pathlib import Path

source = Path(sys.argv[1]).read_text()
start = source.index('BUNDLE_ID="com.o1xhack.codexbar"')
end = source.index('BUILD_TIMESTAMP=', start)
generation = source[start:end]
start = source.index('PROVISION_PROFILE="$ROOT/Provisioning/CodexBar_Dev.provisionprofile"')
end = source.index('\nfi', start) + len('\nfi')
embedding = source[start:end]

for configuration, signing, profile_present, allow_lldb in itertools.product(
    ['release', 'debug'], ['identity', 'adhoc'], [False, True], ['0', '1'],
):
    with tempfile.TemporaryDirectory(prefix='codexbar-entitlement-test-') as directory:
        root = Path(directory)
        app = root / 'CodexBar.app'
        (app / 'Contents').mkdir(parents=True)
        profile = root / 'Provisioning/CodexBar_Dev.provisionprofile'
        if profile_present:
            profile.parent.mkdir(parents=True)
            profile.write_text('synthetic fork profile selection marker\n')
        # An upstream profile must never satisfy the fork's provisioning requirement.
        upstream = root / 'Scripts/profiles/CodexBar-DeveloperID.provisionprofile'
        upstream.parent.mkdir(parents=True)
        upstream.write_text('incompatible upstream profile marker\n')
        env = dict(os.environ, ROOT=str(root), APP=str(app), APP_TEAM_ID='3TUERHN53E',
                   CONF=configuration, LOWER_CONF=configuration, SIGNING_MODE=signing, ALLOW_LLDB=allow_lldb)
        result = subprocess.run(['bash', '-eu', '-c', generation + '\n' + embedding],
                                env=env, capture_output=True, text=True)
        expected_failure = (allow_lldb == '1' and configuration != 'debug') or (
            configuration == 'release' and signing == 'identity' and not profile_present)
        if expected_failure:
            assert result.returncode != 0, (configuration, signing, profile_present, allow_lldb)
            continue
        assert result.returncode == 0, result.stderr
        app_entitlements = plistlib.loads((root / '.build/entitlements/CodexBar.entitlements').read_bytes())
        widget_entitlements = plistlib.loads((root / '.build/entitlements/CodexBarWidget.entitlements').read_bytes())
        cloudkit = signing == 'identity'
        if cloudkit:
            assert app_entitlements['com.apple.developer.team-identifier'] == '3TUERHN53E'
            assert app_entitlements['com.apple.developer.icloud-container-environment'] == 'Production'
            assert app_entitlements['com.apple.developer.icloud-container-identifiers'] == ['iCloud.com.o1xhack.codexbar']
            assert app_entitlements['com.apple.security.application-groups'][0].startswith('group.com.o1xhack.codexbar')
        else:
            assert 'com.apple.developer.icloud-services' not in app_entitlements
        assert widget_entitlements['com.apple.security.app-sandbox'] is True
        embedded = app / 'Contents/embedded.provisionprofile'
        assert embedded.exists() == profile_present
        if embedded.exists():
            assert embedded.read_bytes() == profile.read_bytes()
print('16 entitlement/profile configuration cases passed.')
PY

echo "Package signing tests passed."
