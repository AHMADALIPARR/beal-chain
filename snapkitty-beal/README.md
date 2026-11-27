<!-- Copyright (C) 2026 AHMADALIPARR -->
<!-- SPDX-License-Identifier: AGPL-3.0-only -->
# SnapKitty Beal theorem-to-hardware co-development

This repository is an executable architecture with an explicit mathematical trust boundary. It does **not** prove Beal's Conjecture. Beal is open; Fermat's Last Theorem is established. The repository records Beal as an open conjecture and FLT as a conditional specialization requiring a formally completed descent lemma.

## Trust model

1. `spec/beal.xml` is the canonical source of truth.
2. `templates/` contains the Mustache presentation template. It is the source of truth for the rendered node format: every obligation is rendered through `templates/obligation.mustache` into `build/rendered/<id>.xml`. The rendered node records the SHA-256 of the canonical source.
3. `xslt/` performs deterministic XML-to-obligation transformation.
4. `dag/` holds the DAG tooling and nodes: the Mustache renderer (`dag/render.c`, strict C11), the render driver (`dag/render_all.sh`), and the aspect DAG node `dag/red2.preserve.xml` (an inverted, sink-oriented node with explicit hole constraints and aspect bindings).
5. `asp/` is a complete DAG program (`asp/dag.lp`), not a stub. It models the obligations as nodes and their dependencies as edges, enforces acyclicity with the native `#edge` directive and transitive closure, schedules the obligations on two workers with a 7-unit horizon and minimizes the makespan, and admits the program only when every required obligation has independently verified evidence. Facts are generated from `build/obligations.xml` and the repository state by `asp/facts.sh` and solved with clingo (`make asp-check`, `--opt-mode=optN`). The optimal schedule has makespan 6. The conjecture itself stays open by design; the three required obligations are verified and the program admits.
6. `ontology/` holds the Sovereign Verification & Provenance Ontology (v2.0.0-owl2), including the aspect DAG node class and the `Red2PreserveNode` individual.
7. Agda is the mathematical proof checker. The Agda modules state the conjecture over real arithmetic (power by recursion, Euclidean gcd, a constructive greater-than-one predicate) and prove the computational witnesses by `refl`. A proof receipt is emitted only after the configured verifier returns success.
8. The C11 reference (`hardware/beal_ref.c`) implements a bounded Beal-instance checker: general exponents with overflow-safe 64-bit arithmetic and explicit status codes (equal, not equal, overflow, invalid). The Bluespec modules (`hardware/BealArithmetic.bsv`, `hardware/bluespec/BealCheck.bsv`) implement the same check in hardware, and the ATS2 contracts (`ats/beal_contract.dats`, `hardware/ats/beal_check_pure.dats`) drive the C reference and run a pure-ATS bounded check. None of these proves Beal, whose exponents must all exceed 2 and whose statement is open.
9. The higher-order schema (`agda/SnapKitty/`) quantifies over admissible predicates on exponent triples and requires the Beal conclusion for every admissible predicate. Both the higher-order schema and the ordinary Beal statement are types only; no proof term is given.

## Layout

- `spec/beal.xml`: canonical theorem and public provenance records
- `agda/`: theorem statement over real arithmetic, and the conditional-reduction boundary (Beal + descent implies FLT, genuinely using Beal); `agda/SnapKitty/` holds the higher-order schema
- `asp/`: clingo rules plus a facts generator driven by the obligations
- `ontology/`: OWL/RDF ontology (v2.0.0-owl2)
- `dag/`: Mustache renderer, render driver, and the `red2.preserve` aspect DAG node
- `hardware/`: Bluespec bounded Beal-instance kernels and C11 references (`beal_ref.c`/`beal_ref.h` for uint64, `c11/beal_check.c`/`c11/beal_check.h` for uint32)
- `ats/`: ATS2 contract driving the C11 reference; `hardware/ats/` holds a pure-ATS bounded check
- `docs/`: provenance and mathematical status
- `templates/`: Mustache obligation template (source of truth for the rendered node format)
- `examples/`: runnable edge-case tests and a worked Beal example
- `build/`: generated obligations (`build/obligations.xml`), manifest (`build/manifest.xml`), ASP facts (`build/facts.lp`), and rendered nodes (`build/rendered/*.xml`)

## Build prerequisites

- Agda 2.x
- xsltproc for XSLT execution
- xmllint for XML well-formedness checks
- A C11 compiler (gcc) for the Mustache renderer and the C11 reference
- clingo for ASP execution
- Bluespec Compiler (bsc) for the hardware kernel
- ATS2 (patscc) for the contract program

## Build and test

```sh
make transform
make manifest
make render
make agda-check
make c-check
make c-test
make ats-check
make ats-pure-check
make bsv-check
make asp-check
```

`make transform` produces `build/obligations.xml` from the canonical spec. `make manifest` produces `build/manifest.xml`, a deterministic manifest of the theorem and its open holes. `make render` builds the Mustache renderer and renders every obligation through `templates/obligation.mustache` into `build/rendered/<id>.xml`, each stamped with the SHA-256 of `spec/beal.xml` and verified well-formed. The Agda modules state the Beal proposition over real arithmetic: no assumed operations, no fake proof. The conditional reduction in `BealReduction.agda` genuinely applies Beal to a reduced coprime solution to derive the contradiction. The higher-order schema in `agda/SnapKitty/` states the Beal conclusion for every admissible exponent predicate; both the schema and the ordinary statement are types only, with no proof term. `make c-test` runs 23 edge-case checks on the bounded instance checker (square kernel, the Beal example 3^3+6^3=3^5, non-solutions, invalid inputs, and the uint64_t overflow boundaries) plus 35 checks on the u32 library. `make ats-check` compiles and runs the ATS2 contract. `make ats-pure-check` compiles and runs the pure-ATS bounded check. `make bsv-check` compiles both Bluespec kernels to Verilog. `make asp-check` runs the complete DAG program in `asp/dag.lp` with clingo (`--opt-mode=optN`): it finds the optimal schedule (makespan 6), verifies the three required obligations, leaves the open conjecture open, and admits.

## Hardware

The Bluespec modules and C11 references check bounded Beal instances `A^x + B^y = C^z` with explicit overflow and validity status. They are a hardware/software interface demonstration. The bounded check is intentionally not presented as evidence for Beal, whose statement is open and whose exponents are unbounded. The ATS2 file drives the C11 reference through a foreign-function interface and prints the results.

Two C11 libraries are provided, both general (no `main`, no hardcoded instance):

- `hardware/beal_ref.c` / `hardware/beal_ref.h`: uint64 instance checker — general exponents via binary exponentiation, overflow-safe (pure ISO C11 division-based checked multiply), status codes `EQUAL` / `NOT_EQUAL` / `OVERFLOW` / `INVALID`, plus the square kernel and an `int`-typed wrapper for ATS FFI.
- `hardware/c11/beal_check.c` / `hardware/c11/beal_check.h`: uint32 instance checker — checked 32-bit multiply/add/power widened to 64 bits, status codes `BEAL32_EQUAL` / `BEAL32_NOT_EQUAL` / `BEAL32_OVERFLOW` / `BEAL32_INVALID`, with fast paths for bases 0 and 1. `make c-test` runs 35 checks against it (checked arithmetic, powers, the Beal example 3^3+6^3=3^5, non-solutions, invalid inputs, and the u32 overflow boundaries).

## Proof receipts

Receipts are JSON records containing theorem ID, hole ID, canonical source SHA-256, candidate SHA-256, verifier identity, acceptance bit and diagnostics. Production receipts should additionally include the exact Agda version, source revision, dependency lock hash, command line, and a signed build-attestation identity. A `true` receipt from a mock verifier is test data only.

## Provenance

The Beal source is the primary publication: Andrew Beal, "A Generalization of Fermat's Last Theorem: The Beal Conjecture and Prize Problem", Notices of the American Mathematical Society, volume 44, issue 7, 1997. The conjecture was formulated in 1993; the $1,000,000 prize for a proof or counterexample is held in trust by the American Mathematical Society. The Wiles and Taylor-Wiles publication records identify primary literature relevant to FLT.
