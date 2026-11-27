<!-- Copyright (C) 2026 AHMADALIPARR -->
<!-- SPDX-License-Identifier: AGPL-3.0-only -->
# SnapKitty Beal theorem-to-hardware co-development

This repository is an executable architecture with an explicit mathematical trust boundary. It does **not** prove Beal's Conjecture. Beal is open; Fermat's Last Theorem is established. The repository records Beal as an open conjecture and FLT as a conditional specialization requiring a formally completed descent lemma.

## Trust model

1. `spec/beal.xml` is the canonical source of truth.
2. `templates/` contains the Mustache presentation template. It is the source of truth for the rendered node format: every obligation is rendered through `templates/obligation.mustache` into `build/rendered/<id>.xml`. The rendered node records the SHA-256 of the canonical source.
3. `xslt/` performs deterministic XML-to-obligation transformation.
4. `dag/` holds the DAG tooling and nodes: the Mustache renderer (`dag/render.c`, strict C11), the render driver (`dag/render_all.sh`), and the aspect DAG node `dag/red2.preserve.xml` (an inverted, sink-oriented node with explicit hole constraints and aspect bindings).
5. `asp/` resolves dependency/eligibility constraints.
6. `ontology/` holds the Sovereign Verification & Provenance Ontology (v2.0.0-owl2), including the aspect DAG node class and the `Red2PreserveNode` individual.
7. Agda is the mathematical proof checker. The Agda modules state the conjecture over real arithmetic (power by recursion, Euclidean gcd, a constructive greater-than-one predicate) and prove the computational witnesses by `refl`. A proof receipt is emitted only after the configured verifier returns success.
8. Bluespec, ATS2 and C11 currently implement a bounded exponent-2 arithmetic reference path, not a Beal proof engine.

## Layout

- `spec/beal.xml`: canonical theorem and public provenance records
- `agda/`: theorem statement over real arithmetic, and the conditional-reduction boundary (Beal + descent implies FLT, genuinely using Beal)
- `asp/`: clingo rules
- `ontology/`: OWL/RDF ontology (v2.0.0-owl2)
- `dag/`: Mustache renderer, render driver, and the `red2.preserve` aspect DAG node
- `hardware/`: Bluespec bounded square checker and C11 reference
- `ats/`: ATS2 foreign-function contract
- `templates/`: Mustache obligation template (source of truth for the rendered node format)
- `build/`: generated obligations (`build/obligations.xml`) and rendered nodes (`build/rendered/*.xml`)

## Build prerequisites

- Agda 2.x
- xsltproc for XSLT execution
- xmllint for XML well-formedness checks
- A C11 compiler (gcc) for the Mustache renderer and the C11 reference
- Optional: clingo for ASP execution
- Bluespec Compiler (bsc), ATS2 and a C11 compiler for hardware/software experiments

## Build and test

```sh
make transform
make render
make agda-check
make c-check
```

`make transform` produces `build/obligations.xml` from the canonical spec. `make render` builds the Mustache renderer and renders every obligation through `templates/obligation.mustache` into `build/rendered/<id>.xml`, each stamped with the SHA-256 of `spec/beal.xml` and verified well-formed. The Agda modules state the Beal proposition over real arithmetic: no assumed operations, no fake proof. The conditional reduction in `BealReduction.agda` genuinely applies Beal to a reduced coprime solution to derive the contradiction.

## Hardware

The Bluespec module and C11 reference check the bounded equation `a²+b²=c²`. They are a hardware/software interface demonstration. The exponent-2 path is intentionally not presented as evidence for Beal, whose exponents must all exceed 2. The ATS2 file declares the interface contract; wire the foreign function to the C11 implementation in the target ATS2 build environment.

## Proof receipts

Receipts are JSON records containing theorem ID, hole ID, canonical source SHA-256, candidate SHA-256, verifier identity, acceptance bit and diagnostics. Production receipts should additionally include the exact Agda version, source revision, dependency lock hash, command line, and a signed build-attestation identity. A `true` receipt from a mock verifier is test data only.

## Provenance caution

The Wiles and Taylor-Wiles publication records identify primary literature relevant to FLT. The Beal source entry is a provenance placeholder, not a verified bibliographic citation. Complete source review and stable bibliographic metadata before marking `PROVENANCE-REVIEW` accepted.
