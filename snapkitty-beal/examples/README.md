<!-- Copyright (C) 2026 AHMADALIPARR -->
<!-- SPDX-License-Identifier: AGPL-3.0-only -->
# Examples

## The Beal instance 3^3 + 6^3 = 3^5

The smallest Beal-type solution with a common prime divisor:

```
3^3 = 27
6^3 = 216
3^3 + 6^3 = 243 = 3^5
gcd(3, 6, 3) = 3 > 1
```

This is the instance the Agda kernel checks by `refl` (`beal-example-eq`,
`beal-example-gcd`), the instance the C checker returns `BEAL_EQUAL` for,
and the instance the ATS contract prints first. It is a solution, not a
proof: Beal's conjecture (that every solution shares a common prime divisor)
remains open.

## Running the edge-case tests

```sh
make c-test
```

Builds `examples/beal_instance_test.c` against `hardware/beal_ref.c` and
runs 23 checks: the exponent-2 square kernel, the Beal example above,
non-solutions, invalid inputs (zero base, exponent below 3), and the
uint64_t overflow boundaries (2^63 fits, 2^64 does not; a sum of two
2^63 powers overflows). Exit 0 only if every check passes.

## Running the ATS contract

```sh
make ats-check
```

Compiles `ats/beal_contract.dats` against `hardware/beal_ref.c` with
`patscc` and runs it. It prints the square-kernel result and four
instance results (equal, not equal, overflow, invalid).
