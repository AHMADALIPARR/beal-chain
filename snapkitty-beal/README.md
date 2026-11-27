<!-- Copyright (C) 2026 AHMADALIPARR -->
<!-- SPDX-License-Identifier: AGPL-3.0-only -->
# SnapKitty Beal theorem-to-hardware co-development

This repository is an executable architecture with an explicit mathematical trust boundary. It does **not** prove Beal's Conjecture. Beal is open; Fermat's Last Theorem is established. The repository records Beal as an open conjecture and FLT as a conditional specialization requiring a formally completed descent lemma.

## Trust model

1. `spec/beal.xml` is the canonical source of truth.
2. `templates/` contains the Mustache presentation template. It is the source of truth for the rendered node format: every obligation is rendered through `templates/obligation.mustache` into `build/rendered/<id>.xml`. The rendered node records the SHA-256 of the canonical source.
3. `xslt/` performs deterministic XML-to-obligation transformation.
4. `dag/` holds the DAG tooling and nodes: the Mustache renderer (`dag/render.c`, strict C11), the render driver (`dag/render_all.sh`), and the aspect DAG node `dag/red2.preserve.xml` (an inverted, sink-oriented node with explicit hole constraints and aspect bindings).
5. `asp/` resolves dependency/eligibility constraints. Facts are generated from `build/obligations.xml` by `asp/facts.sh` and solved with clingo (`make asp-check`).
6. `ontology/` holds the Sovereign Verification & Provenance Ontology (v2.0.0-owl2), including the aspect DAG node class and the `Red2PreserveNode` individual.
7. Agda is the mathematical proof checker. The Agda modules state the conjecture over real arithmetic (power by recursion, Euclidean gcd, a constructive greater-than-one predicate) and prove the computational witnesses by `refl`. A proof receipt is emitted only after the configured verifier returns success.
8. The C11 reference (`hardware/beal_ref.c`) implements a bounded Beal-instance checker: general exponents with overflow-safe 64-bit arithmetic and explicit status codes (equal, not equal, overflow, invalid). The Bluespec module (`hardware/BealArithmetic.bsv`) implements the same check in hardware, and the ATS2 contract (`ats/beal_contract.dats`) drives the C reference. None of these proves Beal, whose exponents must all exceed 2 and whose statement is open.

## Layout

- `spec/beal.xml`: canonical theorem and public provenance records
- `agda/`: theorem statement over real arithmetic, and the conditional-reduction boundary (Beal + descent implies FLT, genuinely using Beal)
- `asp/`: clingo rules plus a facts generator driven by the obligations
- `ontology/`: OWL/RDF ontology (v2.0.0-owl2)
- `dag/`: Mustache renderer, render driver, and the `red2.preserve` aspect DAG node
- `hardware/`: Bluespec bounded Beal-instance kernel and C11 reference
- `ats/`: ATS2 contract driving the C11 reference
- `templates/`: Mustache obligation template (source of truth for the rendered node format)
- `examples/`: runnable edge-case tests and a worked Beal example
- `build/`: generated obligations (`build/obligations.xml`), ASP facts (`build/facts.lp`), and rendered nodes (`build/rendered/*.xml`)

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
make render
make agda-check
make c-check
make c-test
make ats-check
make bsv-check
make asp-check
```

`make transform` produces `build/obligations.xml` from the canonical spec. `make render` builds the Mustache renderer and renders every obligation through `templates/obligation.mustache` into `build/rendered/<id>.xml`, each stamped with the SHA-256 of `spec/beal.xml` and verified well-formed. The Agda modules state the Beal proposition over real arithmetic: no assumed operations, no fake proof. The conditional reduction in `BealReduction.agda` genuinely applies Beal to a reduced coprime solution to derive the contradiction. `make c-test` runs 23 edge-case checks on the bounded instance checker (square kernel, the Beal example 3^3+6^3=3^5, non-solutions, invalid inputs, and the uint64_t overflow boundaries). `make ats-check` compiles and runs the ATS2 contract. `make bsv-check` compiles the Bluespec kernel to Verilog. `make asp-check` generates ASP facts from the obligations and solves the dependency rules with clingo.

## Hardware

The Bluespec module and C11 reference check bounded Beal instances `A^x + B^y = C^z` with explicit overflow and validity status. They are a hardware/software interface demonstration. The bounded check is intentionally not presented as evidence for Beal, whose statement is open and whose exponents are unbounded. The ATS2 file drives the C11 reference through a foreign-function interface and prints the results.

## Proof receipts

Receipts are JSON records containing theorem ID, hole ID, canonical source SHA-256, candidate SHA-256, verifier identity, acceptance bit and diagnostics. Production receipts should additionally include the exact Agda version, source revision, dependency lock hash, command line, and a signed build-attestation identity. A `true` receipt from a mock verifier is test data only.

## Provenance

The Beal source is the primary publication: Andrew Beal, "A Generalization of Fermat's Last Theorem: The Beal Conjecture and Prize Problem", Notices of the American Mathematical Society, volume 44, issue 7, 1997. The conjecture was formulated in 1993; the $1,000,000 prize for a proof or counterexample is held in trust by the American Mathematical Society. The Wiles and Taylor-Wiles publication records identify primary literature relevant to FLT.
