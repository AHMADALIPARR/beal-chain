// Copyright (C) 2026 AHMADALIPARR
// SPDX-License-Identifier: AGPL-3.0-only
#include "beal_ref.h"

/* Reference semantics for the bounded exponent-2 hardware test. */
bool beal_square_check(uint16_t a, uint16_t b, uint16_t c) {
    uint64_t lhs = (uint64_t)a * a + (uint64_t)b * b;
    uint64_t rhs = (uint64_t)c * c;
    return lhs == rhs;
}

/* int-typed wrapper for FFI callers (for example ATS) that pass plain ints. */
bool beal_square_check_int(int a, int b, int c) {
    if (a < 0 || a > 65535 || b < 0 || b > 65535 || c < 0 || c > 65535) {
        return false;
    }
    return beal_square_check((uint16_t)a, (uint16_t)b, (uint16_t)c);
}

/* Checked multiply: *out = x * y, or 1 if the product overflows uint64_t.
   Pure ISO C11: when x != 0, x*y overflows exactly when y > UINT64_MAX / x. */
static int checked_mul_u64(uint64_t x, uint64_t y, uint64_t *out) {
    if (x != 0 && y > UINT64_MAX / x) {
        return 1;
    }
    *out = x * y;
    return 0;
}

/* Checked power by binary exponentiation. Each multiply is overflow-checked,
   so a huge exponent terminates in O(log exp) steps instead of looping. */
int beal_pow_u64(uint64_t base, uint64_t exp, uint64_t *out) {
    uint64_t result = 1;
    uint64_t b = base;
    uint64_t e = exp;
    while (e > 0) {
        if ((e & 1u) != 0) {
            if (checked_mul_u64(result, b, &result) != 0) {
                return 1;
            }
        }
        e >>= 1;
        if (e > 0) {
            if (checked_mul_u64(b, b, &b) != 0) {
                return 1;
            }
        }
    }
    *out = result;
    return 0;
}

/* General bounded Beal-instance check: A^x + B^y == C^z. */
int beal_instance_check(uint64_t a, uint64_t b, uint64_t c,
                        uint64_t x, uint64_t y, uint64_t z) {
    if (a == 0 || b == 0 || c == 0) {
        return BEAL_INVALID;
    }
    if (x < 3 || y < 3 || z < 3) {
        return BEAL_INVALID;
    }
    uint64_t p1 = 0;
    uint64_t p2 = 0;
    uint64_t p3 = 0;
    if (beal_pow_u64(a, x, &p1) != 0) {
        return BEAL_OVERFLOW;
    }
    if (beal_pow_u64(b, y, &p2) != 0) {
        return BEAL_OVERFLOW;
    }
    if (beal_pow_u64(c, z, &p3) != 0) {
        return BEAL_OVERFLOW;
    }
    /* Checked addition: sum wraps exactly when it is smaller than an addend. */
    uint64_t sum = p1 + p2;
    if (sum < p1) {
        return BEAL_OVERFLOW;
    }
    return (sum == p3) ? BEAL_EQUAL : BEAL_NOT_EQUAL;
}
