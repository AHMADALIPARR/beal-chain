<!-- Copyright (C) 2026 AHMADALIPARR -->
<!-- SPDX-License-Identifier: AGPL-3.0-only -->
# Provenance and mathematical status

## Beal

The Beal conjecture says that for positive integers A, B, C, x, y, z with
x, y, z > 2, if A^x + B^y = C^z, then A, B, C have a common prime factor.
It remains open. The project records it as `open-conjecture`.

Primary publication: Andrew Beal, "A Generalization of Fermat's Last
Theorem: The Beal Conjecture and Prize Problem", Notices of the American
Mathematical Society, volume 44, issue 7, 1997. The conjecture was
formulated in 1993; the $1,000,000 prize for a proof or counterexample is
held in trust by the American Mathematical Society.

## Fermat

Fermat's Last Theorem is established. Wiles' 1995 Annals paper proves
modularity for semistable elliptic curves and obtains FLT as a corollary
using prior work of Frey, Serre, and Ribet. That result is provenance
context only. It does not prove Beal.

Beal implies FLT: a hypothetical FLT counterexample can be divided by the
common gcd of its three bases to obtain a primitive counterexample; Beal
would then force a common prime divisor, contradicting primitivity. The
reverse implication is not asserted. The descent lemma that makes this
reduction formal (FLT-DESCENT-001) is an open obligation in this repo,
not a proved result.

## Higher-order packaging

`HigherOrderBeal` (in `agda/SnapKitty/Beal.agda`) quantifies over exponent
predicates C and requires the Beal conclusion for every admissible C whose
accepted triples all have exponents greater than two. This is a
higher-order schema around the Beal statement, not a claim that a new
number-theoretic theorem has been proved. Both the higher-order schema
and the ordinary Beal statement are types only; no proof term is given.
