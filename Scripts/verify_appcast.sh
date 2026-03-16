#!/usr/bin/env bash
set -euo pipefail

# Verifies that the appcast entry for the given version has a valid ed25519 signature
# and that the enclosure length matches the downloaded archive.
#
# Usage: SPARKLE_PRIVATE_KEY_FILE=/path/to/key ./Scripts/verify_appcast.sh [version]

ROOT=$(cd "$(dirname "$0")/.." && pwd)
source "$ROOT/Scripts/load-release-secrets.sh"
VERSION=${1:-$(source "$ROOT/version.env" && echo "$MARKETING_VERSION")}
APPCAST="${ROOT}/appcast.xml"

if [[ -z "${SPARKLE_PRIVATE_KEY_FILE:-}" ]]; then
  echo "SPARKLE_PRIVATE_KEY_FILE is required" >&2
  exit 1
fi
if [[ ! -f "$SPARKLE_PRIVATE_KEY_FILE" ]]; then
  echo "Sparkle key file not found: $SPARKLE_PRIVATE_KEY_FILE" >&2
  exit 1
fi
if [[ ! -f "$APPCAST" ]]; then
  echo "appcast.xml not found at $APPCAST" >&2
  exit 1
fi

# Clean the key file: strip comments/blank lines and require exactly one line of base64.
function cleaned_key_path() {
  local tmp key_lines
  key_lines=$(grep -v '^[[:space:]]*#' "$SPARKLE_PRIVATE_KEY_FILE" | sed '/^[[:space:]]*$/d')
  if [[ $(printf "%s\n" "$key_lines" | wc -l) -ne 1 ]]; then
    echo "Sparkle key file must contain exactly one base64 line (no comments/blank lines)." >&2
    exit 1
  fi
  tmp=$(mktemp)
  printf "%s" "$key_lines" > "$tmp"
  echo "$tmp"
}

KEY_FILE=$(cleaned_key_path)
trap 'rm -f "$KEY_FILE" "$TMP_ZIP"' EXIT

TMP_ZIP=$(mktemp /tmp/codexbar-enclosure.XXXX.zip)

python3 - "$APPCAST" "$VERSION" >"$TMP_ZIP.meta" <<'PY'
import sys, xml.etree.ElementTree as ET

appcast = sys.argv[1]
version = sys.argv[2]
tree = ET.parse(appcast)
root = tree.getroot()
ns = {"sparkle": "http://www.andymatuschak.org/xml-namespaces/sparkle"}

entry = None
for item in root.findall("./channel/item"):
    sv = item.findtext("sparkle:shortVersionString", default="", namespaces=ns)
    if sv == version:
        entry = item
        break

if entry is None:
    sys.exit("No appcast entry found for version {}".format(version))

enclosure = entry.find("enclosure")
url = enclosure.get("url")
sig = enclosure.get("{http://www.andymatuschak.org/xml-namespaces/sparkle}edSignature")
length = enclosure.get("length")

if not all([url, sig, length]):
    sys.exit("Missing url/signature/length in appcast for version {}".format(version))

print(url)
print(sig)
print(length)
PY

readarray -t META <"$TMP_ZIP.meta"
URL="${META[0]}"
SIG="${META[1]}"
LEN_EXPECTED="${META[2]}"

echo "Downloading enclosure: $URL"
curl -L -o "$TMP_ZIP" "$URL"

LEN_ACTUAL=$(stat -f%z "$TMP_ZIP")
if [[ "$LEN_ACTUAL" != "$LEN_EXPECTED" ]]; then
  echo "Length mismatch: expected $LEN_EXPECTED, got $LEN_ACTUAL" >&2
  exit 1
fi

echo "Verifying Sparkle signature…"
sign_update --verify "$TMP_ZIP" "$SIG" --ed-key-file "$KEY_FILE"
echo "Appcast entry for $VERSION verified (signature and length match)."
