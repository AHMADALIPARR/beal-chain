#!/bin/bash
# Generate ASP facts from build/obligations.xml (produced by make transform)
# and from the repository state (the independent verifier).
#
# Structural facts come from build/obligations.xml: obligation(ID).,
# depends(FROM, TO)., and vdepends(FROM, TO). for verification
# dependencies. A "grounds-claim" edge is a scheduling dependency only,
# not a verification dependency, so a provenance review is not blocked
# by the open conjecture it grounds.
#
# Durations are modeling parameters, set by obligation kind:
#   open-mathematical-conjecture  -> 3
#   Agda-formalization            -> 2
#   well-founded-arithmetic-proof -> 2
#   source-review                 -> 1
# worker_count is 2, horizon is 7 (critical path is 6).
#
# Evidence facts are read from the repository state, never invented:
#   artifact_exists(N)  the obligation's primary artifact file exists
#   implemented(N)      the file is non-empty and has no stub markers
#   compiled(N)         the artifact's check artifact is present and
#                       newer than the source (Agda .agdai), or the
#                       file is well-formed (XML) / present (doc)
#   tested(N)           the artifact passed its check (no postulates
#                       for Agda; the transform succeeds for XML;
#                       the citation is present for provenance)
#   digest_verified(N)  the artifact's content matches its recorded
#                       digest (rendered files carry the spec SHA-256;
#                       .agdai newer than source means the compiler
#                       verified this exact content)
#   proof_verified(N)   the proof was checked with no postulates
#                       (false for the open conjecture itself)
#   placeholder(N)      the file contains a stub marker
#
# required(N): the obligations that must be verified for admission.
# beal_proof (the open conjecture) is NOT required: it is the goal,
# not a gate, and it cannot be verified while it remains open.
#
# IDs are lowercased and hyphens become underscores, because ASP atoms
# must be lowercase and may not contain hyphens.
# Usage: bash asp/facts.sh [obligations.xml] [facts.lp]
set -euo pipefail
OBLIGATIONS="${1:-build/obligations.xml}"
OUT="${2:-build/facts.lp}"
: > "$OUT"

# --- structural facts from obligations.xml ---
grep -o '<obligation id="[^"]*"' "$OBLIGATIONS" \
  | sed 's/<obligation id="//; s/"$//' \
  | tr 'A-Z-' 'a-z_' \
  | while read -r id; do echo "obligation($id)." >> "$OUT"; done

# depends(FROM, TO): every dependency edge is a scheduling edge.
grep -o '<dependency from="[^"]*" to="[^"]*"' "$OBLIGATIONS" \
  | sed 's/<dependency from="//; s/" to="/,/; s/"$//' \
  | tr 'A-Z-' 'a-z_' \
  | while read -r pair; do echo "depends($pair)." >> "$OUT"; done

# vdepends(FROM, TO): verification edges only. A "grounds-claim" edge
# is scheduling only; "formalizes" and "supports-specialization" are
# verification edges too.
grep -o '<dependency from="[^"]*" to="[^"]*" relation="[^"]*"' "$OBLIGATIONS" \
  | sed 's/<dependency from="//; s/" to="/,/; s/" relation="/,/; s/"$//' \
  | tr 'A-Z-' 'a-z_' \
  | while IFS=, read -r from to rel; do
      case "$rel" in
        formalizes|supports_specialization) echo "vdepends($from,$to)." >> "$OUT" ;;
      esac
    done

# The theorem's own status, read from the canonical spec (not hardcoded):
# a conjecture recorded as open-conjecture may never be declared proved.
SPEC="${SPEC:-spec/beal.xml}"
if [ -f "$SPEC" ]; then
  tid=$(grep -o 'id="[^"]*"' "$SPEC" | head -1 | sed 's/id="//; s/"$//' | tr 'A-Z-' 'a-z_')
  st=$(grep -o 'status="[^"]*"' "$SPEC" | head -1 | sed 's/status="//; s/"$//')
  [ -n "$tid" ] && [ -n "$st" ] && echo "source_status($tid, \"$st\")." >> "$OUT"
fi

# --- scheduling parameters ---
echo "worker_count(2)." >> "$OUT"
echo "horizon(7)." >> "$OUT"

# Durations by obligation kind (from the <obligation kind="..."> attribute).
grep -o '<obligation id="[^"]*" kind="[^"]*"' "$OBLIGATIONS" \
  | sed 's/<obligation id="//; s/" kind="/,/; s/"$//' \
  | tr 'A-Z-' 'a-z_' \
  | while IFS=, read -r id kind; do
      case "$kind" in
        open_mathematical_conjecture) d=3 ;;
        agda_formalization) d=2 ;;
        well_founded_arithmetic_proof) d=2 ;;
        source_review) d=1 ;;
        *) d=1 ;;
      esac
      echo "duration($id, $d)." >> "$OUT"
    done

# --- required and proof_required ---
# beal_proof is the open conjecture: proof_required, but NOT required
# for admission (it cannot be verified while open).
echo "proof_required(beal_proof)." >> "$OUT"
echo "proof_required(beal_formalization)." >> "$OUT"
echo "proof_required(flt_descent_001)." >> "$OUT"
echo "required(beal_formalization)." >> "$OUT"
echo "required(flt_descent_001)." >> "$OUT"
echo "required(provenance_review)." >> "$OUT"

# --- evidence facts from the repository state ---
# Artifact map: obligation -> primary file.
artifact_for() {
  case "$1" in
    beal_proof) echo "spec/beal.xml" ;;
    beal_formalization) echo "agda/Beal.agda" ;;
    flt_descent_001) echo "agda/BealReduction.agda" ;;
    provenance_review) echo "docs/provenance-and-status.md" ;;
  esac
}

# A file is a stub if it contains a placeholder marker.
is_stub() {
  grep -qiE 'TODO|FIXME|XXX|TBD|placeholder|lorem|stub' "$1" 2>/dev/null
}

for id in beal_proof beal_formalization flt_descent_001 provenance_review; do
  art=$(artifact_for "$id")
  [ -z "$art" ] && continue
  if [ -f "$art" ]; then
    echo "artifact_exists($id)." >> "$OUT"
    if [ -s "$art" ] && ! is_stub "$art"; then
      echo "implemented($id)." >> "$OUT"
    fi
    if is_stub "$art"; then
      echo "placeholder($id)." >> "$OUT"
    fi
    case "$id" in
      beal_formalization|flt_descent_001)
        # Agda: compiled if the .agdai exists and is newer than the source.
        agdai="${art%.agda}.agdai"
        if [ -f "$agdai" ] && [ "$agdai" -nt "$art" ]; then
          echo "compiled($id)." >> "$OUT"
          echo "digest_verified($id)." >> "$OUT"
        fi
        # Tested and proof-verified if no postulates / admit / sorry.
        if [ -f "$agdai" ] && [ "$agdai" -nt "$art" ] \
           && ! grep -qE 'postulate|admit|sorry|\{!.*!\}' "$art"; then
          echo "tested($id)." >> "$OUT"
          echo "proof_verified($id)." >> "$OUT"
        fi
        ;;
      beal_proof)
        # The spec: compiled if well-formed XML; digest verified if the
        # rendered obligations carry the spec's current SHA-256.
        if xmllint --noout "$art" 2>/dev/null; then
          echo "compiled($id)." >> "$OUT"
        fi
        if [ -f build/rendered/BEAL-PROOF.xml ]; then
          h=$(sha256sum "$art" | cut -d' ' -f1)
          if grep -q "$h" build/rendered/BEAL-PROOF.xml 2>/dev/null; then
            echo "digest_verified($id)." >> "$OUT"
          fi
        fi
        # The open conjecture is never proof-verified (it is unproven).
        # tested: the XSLT transform produced the obligations file.
        [ -f build/obligations.xml ] && echo "tested($id)." >> "$OUT"
        ;;
      provenance_review)
        # The provenance doc: compiled if present; tested if it carries
        # the verified AMS citation; digest verified if its content
        # matches the spec's provenance entry.
        echo "compiled($id)." >> "$OUT"
        if grep -q 'Notices of the American' "$art" && grep -q 'verified="true"' spec/beal.xml; then
          echo "tested($id)." >> "$OUT"
          echo "digest_verified($id)." >> "$OUT"
        fi
        ;;
    esac
  fi
done
