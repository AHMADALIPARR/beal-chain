#!/bin/bash
# Generate ASP facts from build/obligations.xml (produced by make transform).
# Emits obligation(ID). and depends(FROM, TO). facts, one per line.
# IDs are lowercased and hyphens become underscores, because ASP atoms
# must be lowercase and may not contain hyphens.
# Usage: bash asp/facts.sh [obligations.xml] [facts.lp]
set -euo pipefail
OBLIGATIONS="${1:-build/obligations.xml}"
OUT="${2:-build/facts.lp}"
: > "$OUT"
grep -o '<obligation id="[^"]*"' "$OBLIGATIONS" \
  | sed 's/<obligation id="//; s/"$//' \
  | tr 'A-Z-' 'a-z_' \
  | while read -r id; do echo "obligation($id)." >> "$OUT"; done
grep -o '<dependency from="[^"]*" to="[^"]*"' "$OBLIGATIONS" \
  | sed 's/<dependency from="//; s/" to="/,/; s/"$//' \
  | tr 'A-Z-' 'a-z_' \
  | while read -r pair; do echo "depends($pair)." >> "$OUT"; done
# The theorem's own status, read from the canonical spec (not hardcoded):
# a conjecture recorded as open-conjecture may never be declared proved.
SPEC="${SPEC:-spec/beal.xml}"
if [ -f "$SPEC" ]; then
  tid=$(grep -o 'id="[^"]*"' "$SPEC" | head -1 | sed 's/id="//; s/"$//' | tr 'A-Z-' 'a-z_')
  st=$(grep -o 'status="[^"]*"' "$SPEC" | head -1 | sed 's/status="//; s/"$//')
  [ -n "$tid" ] && [ -n "$st" ] && echo "source_status($tid, \"$st\")." >> "$OUT"
fi
