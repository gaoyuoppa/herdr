#!/usr/bin/env bash
# Compatibility entry point. The cross-platform implementation lives in Python.
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$PROJECT_DIR"

if command -v python3 >/dev/null 2>&1; then
  exec python3 scripts/sync-upstream.py "$@"
fi

exec python scripts/sync-upstream.py "$@"
