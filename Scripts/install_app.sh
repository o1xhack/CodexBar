#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
INSTALL_PATH="${CODEXBAR_INSTALL_PATH:-/Applications/CodexBar.app}"
SIGNING_MODE="${CODEXBAR_SIGNING:-adhoc}"

cd "${ROOT_DIR}"
env \
  CODEXBAR_SIGNING="${SIGNING_MODE}" \
  CODEXBAR_INSTALL_PATH="${INSTALL_PATH}" \
  "${ROOT_DIR}/Scripts/package_app.sh" "$@"
