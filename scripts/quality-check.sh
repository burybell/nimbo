#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

cd "$PROJECT_ROOT"
node scripts/quality-check.mjs
git diff --check

if [[ "${1:-}" == "--build" ]]; then
  ./build_hap.sh
fi
