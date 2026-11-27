<!-- Copyright (C) 2026 AHMADALIPARR -->
<!-- SPDX-License-Identifier: AGPL-3.0-only -->
# SnapKitty Beal theorem-to-hardware co-development

This repository is an executable architecture skeleton with an explicit mathematical trust boundary. It does **not** prove Beal's Conjecture. Beal is open; Fermat's Last Theorem is established. The repository records Beal as an open conjecture and FLT as a conditional specialization requiring a formally completed descent lemma.

## Trust model

1. `spec/beal.xml` is the canonical source of truth.
2. `templates/` contains Mustache presentation templates only.
3. `xslt/` performs deterministic XML-to-obligation transformation.
4. `asp/` resolves dependency/eligibility constraints.
5. `ontology/` describes semantic entities and provenance relations.
6. Agda is the mathematical proof checker. A proof receipt is emitted only after the configured verifier returns success.
7. Bluespec, ATS2 and C11 currently implement a bounded exponent-2 arithmetic reference path, not a Beal proof engine.

## Layout

- `spec/beal.xml`: canonical theorem and public provenance records
- `agda/`: theorem statement and explicit conditional-reduction boundary
- `asp/`: clingo rules
- `ontology/`: OWL/RDF ontology
- `hardware/`: Bluespec bounded square checker and C11 reference
- `ats/`: ATS2 foreign-function contract
- `templates/`: Mustache obligation template
- `tests/`: trust-boundary tests

## Build prerequisites

- Agda 2.x
- xsltproc for XSLT execution
- Optional: clingo for ASP execution
- Bluespec Compiler (bsc), ATS2 and a C11 compiler for hardware/software experiments

## Build and test

```sh
make transform
make agda-check
make c-check
```

The Agda modules deliberately leave the Beal proposition uninhabited: the type is stated, but no fake proof is supplied.

## Hardware

The Bluespec module and C11 reference check the bounded equation `a²+b²=c²`. They are a hardware/software interface demonstration. The exponent-2 path is intentionally not presented as evidence for Beal, whose exponents must all exceed 2. The ATS2 file declares the interface contract; wire the foreign function to the C11 implementation in the target ATS2 build environment.

## Proof receipts

Receipts are JSON records containing theorem ID, hole ID, canonical source SHA-256, candidate SHA-256, verifier identity, acceptance bit and diagnostics. Production receipts should additionally include the exact Agda version, source revision, dependency lock hash, command line, and a signed build-attestation identity. A `true` receipt from a mock verifier is test data only.

## Provenance caution

The Wiles and Taylor-Wiles publication records identify primary literature relevant to FLT. The Beal source entry is a provenance placeholder, not a verified bibliographic citation. Complete source review and stable bibliographic metadata before marking `PROVENANCE-REVIEW` accepted.
