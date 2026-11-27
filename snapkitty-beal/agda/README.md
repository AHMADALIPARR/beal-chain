<!-- Copyright (C) 2026 AHMADALIPARR -->
<!-- SPDX-License-Identifier: AGPL-3.0-only -->
# Agda target

`Beal.agda` states the Beal proposition over real arithmetic (power by
recursion, Euclidean gcd, a constructive greater-than-one predicate) and
proves the computational witnesses by `refl`. `BealReduction.agda` applies
Beal to a descent-reduced coprime solution to derive the contradiction;
the descent itself is an explicit unproved hypothesis field.

`SnapKitty/Prelude.agda` is a compact local arithmetic vocabulary for the
higher-order schema: `GT2`, `+N`, `*N`, `pow`, `_≤_`, `_∣_`, and `Prime`.
Agda 2.6.3 has no `Agda.Builtin.Sum`, so the sum type `_⊎_` is defined
here instead of imported.

`SnapKitty/Beal.agda` states the higher-order Beal schema: it quantifies
over admissible predicates on exponent triples and requires the Beal
conclusion for every admissible predicate. The ordinary Beal conjecture
is the instance for the predicate accepting every triple with all
exponents greater than two. Both `HigherOrderBeal` and `OrdinaryBeal`
are types only. No proof term is given: Beal is open, and no generated
artifact may claim a proof.
