#!/usr/bin/env bash
set -euo pipefail
ROOT=$(cd "$(dirname "$0")/.." && pwd)
python3 - "$ROOT/Scripts/upload_ios_testflight.sh" <<'PY'
import re, sys
from pathlib import Path
text = Path(sys.argv[1]).read_text()
commands = re.findall(r'^xcodebuild\b.*?(?=\n\s*\|)', text, re.M | re.S)
assert len(commands) == 2, 'Archive and export commands must both be checked'
for command in commands:
    assert '-packageAuthorizationProvider netrc' in command, 'Release package resolution must not use Keychain'
    assert '-authenticationKeyPath' not in command and '-authenticationKeyID' not in command, 'Keep Xcode session cloud signing'
assert re.search(r'<key>manageAppVersionAndBuildNumber</key>\s*<false/>', text), 'Preserve the reviewed build number'
print('iOS upload contract passed: netrc resolution, Xcode session signing, exact build version')
PY
