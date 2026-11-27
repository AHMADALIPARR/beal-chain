// Copyright (C) 2026 AHMADALIPARR
// SPDX-License-Identifier: AGPL-3.0-only
#ifndef BEAL_REF_H
#define BEAL_REF_H

#include <stdint.h>
#include <stdbool.h>

/* Status codes for beal_instance_check. */
#define BEAL_EQUAL     0  /* A^x + B^y == C^z, all values in range */
#define BEAL_NOT_EQUAL 1  /* A^x + B^y != C^z, all values in range */
#define BEAL_OVERFLOW  2  /* a power or the sum overflowed uint64_t */
#define BEAL_INVALID   3  /* invalid input: a base is 0, or an exponent < 3 */

/* Reference semantics for the bounded exponent-2 hardware test kernel. */
bool beal_square_check(uint16_t a, uint16_t b, uint16_t c);

/* int-typed wrapper for FFI callers (for example ATS) that pass plain ints.
   Returns false when an argument is outside 0..65535. */
bool beal_square_check_int(int a, int b, int c);

/* Checked power: computes base^exp into *out.
   Returns 0 on success, 1 if the result overflows uint64_t.
   exp == 0 yields 1, by definition. */
int beal_pow_u64(uint64_t base, uint64_t exp, uint64_t *out);

/* General bounded Beal-instance check: A^x + B^y == C^z.
   Bases must be >= 1; exponents must be >= 3 (the Beal range).
   Returns BEAL_EQUAL / BEAL_NOT_EQUAL / BEAL_OVERFLOW / BEAL_INVALID.
   This is a bounded arithmetic check only. It does not prove, or
   disprove, Beal's conjecture, which is open. */
int beal_instance_check(uint64_t a, uint64_t b, uint64_t c,
                        uint64_t x, uint64_t y, uint64_t z);

#endif /* BEAL_REF_H */
