# Copyright (C) 2026 AHMADALIPARR
# SPDX-License-Identifier: AGPL-3.0-only
#!/usr/bin/env bash
# render_all.sh — render every obligation in build/obligations.xml through
# templates/obligation.mustache (the source of truth for the node format).
#
# For each <obligation>, writes build/rendered/<id>.xml with:
#   hole_id        = obligation id
#   theorem_id     = the theorem id from the obligation-set
#   source_sha256  = SHA-256 of spec/beal.xml (the canonical source)
#   kind           = obligation kind
#   dependencies   = comma-separated ids this obligation depends on
#                    (the "to" of each <dependency from="<id>" .../>)
#
# Usage: run from the snapkitty-beal directory (or pass the repo root as $1).
# Requires: build/obligations.xml (run `make transform` first),
#           the compiled renderer at dag/render (run `make render` or build it).
# Exits non-zero if any obligation fails to render or is not well-formed XML.
set -euo pipefail

ROOT="${1:-.}"
TEMPLATE="$ROOT/templates/obligation.mustache"
OBLIGATIONS="$ROOT/build/obligations.xml"
SPEC="$ROOT/spec/beal.xml"
RENDERER="$ROOT/dag/render"
OUTDIR="$ROOT/build/rendered"

[ -f "$TEMPLATE" ] || { echo "render_all: missing template $TEMPLATE" >&2; exit 1; }
[ -f "$OBLIGATIONS" ] || { echo "render_all: missing $OBLIGATIONS (run make transform first)" >&2; exit 1; }
[ -f "$SPEC" ] || { echo "render_all: missing $SPEC" >&2; exit 1; }
[ -x "$RENDERER" ] || { echo "render_all: missing renderer $RENDERER (run make render first)" >&2; exit 1; }

SHA="$(sha256sum "$SPEC" | cut -d' ' -f1)"
THEOREM="$(grep -o 'theorem="[^"]*"' "$OBLIGATIONS" | head -1 | cut -d'"' -f2)"
[ -n "$THEOREM" ] || { echo "render_all: cannot read theorem id" >&2; exit 1; }

mkdir -p "$OUTDIR"
count=0
# Each <obligation .../> line carries id and kind.
while IFS= read -r line; do
  id="$(echo "$line" | grep -o 'id="[^"]*"' | head -1 | cut -d'"' -f2)"
  kind="$(echo "$line" | grep -o 'kind="[^"]*"' | head -1 | cut -d'"' -f2)"
  [ -n "$id" ] && [ -n "$kind" ] || { echo "render_all: cannot parse obligation line: $line" >&2; exit 1; }
  # dependencies: the "to" of every <dependency from="<id>" .../>
  # (grep finds nothing for obligations with no outgoing edges; the
  #  `|| true` keeps set -e from aborting on that empty result.)
  deps="$( (grep -o "from=\"$id\" to=\"[^\"]*\"" "$OBLIGATIONS" || true) | cut -d'"' -f4 | paste -sd, -)"
  data="$(mktemp)"
  {
    echo "hole_id=$id"
    echo "theorem_id=$THEOREM"
    echo "source_sha256=$SHA"
    echo "kind=$kind"
    echo "dependencies=$deps"
  } > "$data"
  "$RENDERER" "$TEMPLATE" "$data" > "$OUTDIR/$id.xml"
  rm -f "$data"
  # the rendered node must be well-formed XML
  xmllint --noout "$OUTDIR/$id.xml" \
    || { echo "render_all: $OUTDIR/$id.xml is not well-formed XML" >&2; exit 1; }
  echo "rendered $id (kind=$kind, deps=${deps:-none}) -> $OUTDIR/$id.xml"
  count=$((count + 1))
done < <(grep '<obligation ' "$OBLIGATIONS")

echo "render_all: $count obligation(s) rendered into $OUTDIR"
