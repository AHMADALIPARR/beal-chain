# Copyright (C) 2026 AHMADALIPARR
# SPDX-License-Identifier: AGPL-3.0-only
#!/usr/bin/env bash
# verify.sh — build the library, run the axiom audit, and scan for banned tokens.
# Run from the repository root: bash scripts/verify.sh
# Exits non-zero if any step fails.
set -euo pipefail

LAKE="${LAKE:-lake}"

echo "=== lake build ==="
"$LAKE" build

echo "=== lake env lean Audit.lean ==="
"$LAKE" env lean Audit.lean

echo "=== banned-token scan (BealChain/, BealChain.lean, Audit.lean) ==="
if grep -REn '\b(sorry|admit|axiom|believe_me|native_decide)\b' BealChain BealChain.lean Audit.lean; then
  echo "FAIL: banned token found" >&2
  exit 1
fi
echo "OK: no banned tokens"

echo "=== verify: PASS ==="
