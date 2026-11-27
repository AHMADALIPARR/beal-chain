// Copyright (C) 2026 AHMADALIPARR
// SPDX-License-Identifier: AGPL-3.0-only
/* Edge-case test driver for the bounded Beal-instance checker.
   Build: cc -std=c11 -Wall -Wextra -Werror -I../hardware \
          beal_instance_test.c ../hardware/beal_ref.c -o beal_instance_test
   Run: ./beal_instance_test
   Exit 0 only if every case passes. */
#include <stdio.h>
#include <stdint.h>
#include <inttypes.h>
#include "beal_ref.h"

static int failures = 0;
static int checks = 0;

static const char *status_name(int s) {
    switch (s) {
        case BEAL_EQUAL: return "EQUAL";
        case BEAL_NOT_EQUAL: return "NOT_EQUAL";
        case BEAL_OVERFLOW: return "OVERFLOW";
        case BEAL_INVALID: return "INVALID";
        default: return "?";
    }
}

static void check_instance(const char *name,
                           uint64_t a, uint64_t b, uint64_t c,
                           uint64_t x, uint64_t y, uint64_t z,
                           int expected) {
    int got = beal_instance_check(a, b, c, x, y, z);
    checks++;
    if (got == expected) {
        printf("PASS %s -> %s\n", name, status_name(got));
    } else {
        printf("FAIL %s -> got %s, expected %s\n",
               name, status_name(got), status_name(expected));
        failures++;
    }
}

static void check_square(const char *name,
                         uint16_t a, uint16_t b, uint16_t c,
                         bool expected) {
    bool got = beal_square_check(a, b, c);
    checks++;
    if (got == expected) {
        printf("PASS %s -> %s\n", name, got ? "true" : "false");
    } else {
        printf("FAIL %s -> got %s, expected %s\n",
               name, got ? "true" : "false", expected ? "true" : "false");
        failures++;
    }
}

static void check_pow(const char *name, uint64_t base, uint64_t exp,
                      int expected_rc, uint64_t expected_val) {
    uint64_t out = 0;
    int rc = beal_pow_u64(base, exp, &out);
    checks++;
    if (rc == expected_rc && (rc != 0 || out == expected_val)) {
        printf("PASS %s -> rc=%d val=%" PRIu64 "\n", name, rc, out);
    } else {
        printf("FAIL %s -> rc=%d val=%" PRIu64
               ", expected rc=%d val=%" PRIu64 "\n",
               name, rc, out, expected_rc, expected_val);
        failures++;
    }
}

int main(void) {
    /* The exponent-2 hardware kernel. */
    check_square("square 3^2+4^2=5^2", 3, 4, 5, true);
    check_square("square 1^2+2^2!=3^2", 1, 2, 3, false);
    check_square("square 0^2+0^2=0^2", 0, 0, 0, true);
    check_square("square max 65535^2+0^2=65535^2", 65535, 0, 65535, true);

    /* The Beal example: 3^3 + 6^3 = 27 + 216 = 243 = 3^5.
       Bases share gcd 3, as Beal requires for a solution. */
    check_instance("beal 3^3+6^3=3^5", 3, 6, 3, 3, 3, 5, BEAL_EQUAL);
    /* Distinct small bases, no solution. */
    check_instance("beal 2^3+3^3!=5^3", 2, 3, 5, 3, 3, 3, BEAL_NOT_EQUAL);
    check_instance("beal 1^3+1^3!=1^3", 1, 1, 1, 3, 3, 3, BEAL_NOT_EQUAL);
    check_instance("beal 1^3+2^3!=3^3", 1, 2, 3, 3, 3, 3, BEAL_NOT_EQUAL);
    /* A larger non-solution with mixed exponents. */
    check_instance("beal 2^3+3^4!=5^5", 2, 3, 5, 3, 4, 5, BEAL_NOT_EQUAL);

    /* Invalid inputs: zero base, exponent below 3. */
    check_instance("invalid base 0", 0, 1, 1, 3, 3, 3, BEAL_INVALID);
    check_instance("invalid exponent 2", 2, 2, 2, 2, 2, 2, BEAL_INVALID);
    check_instance("invalid exponent 1", 2, 2, 2, 1, 3, 3, BEAL_INVALID);
    check_instance("invalid exponent 0", 2, 2, 2, 0, 3, 3, BEAL_INVALID);

    /* Overflow boundaries.
       2^21 = 2097152, and 2097152^3 = 2^63, the largest power of two
       that fits in uint64_t. 2^22 = 4194304, and 4194304^3 = 2^66. */
    check_pow("pow 2^0", 2, 0, 0, 1);
    check_pow("pow 2^63", 2, 63, 0, UINT64_C(9223372036854775808));
    check_pow("pow 2^64 overflows", 2, 64, 1, 0);
    check_pow("pow 2097152^3 = 2^63", 2097152, 3, 0,
              UINT64_C(9223372036854775808));
    check_pow("pow 4194304^3 = 2^66 overflows", 4194304, 3, 1, 0);
    check_instance("overflow 2^64", 2, 2, 2, 64, 64, 64, BEAL_OVERFLOW);
    check_instance("overflow 4194304^3", 4194304, 1, 1, 3, 3, 3,
                   BEAL_OVERFLOW);
    /* 2^63 + 2^63 = 2^64: each power fits, the sum does not. */
    check_instance("overflow sum 2^63+2^63", 2097152, 2097152, 1, 3, 3, 3,
                   BEAL_OVERFLOW);
    /* 2^63 fits and is not equal to 1. */
    check_instance("boundary 2^63+1 != 1", 2097152, 1, 1, 3, 3, 3,
                   BEAL_NOT_EQUAL);
    /* Largest base overflows on any exponent >= 3. */
    check_instance("overflow UINT64_MAX^3", UINT64_MAX, 1, 1, 3, 3, 3,
                   BEAL_OVERFLOW);

    printf("beal_instance_test: %d checks, %d failures\n", checks, failures);
    return (failures == 0) ? 0 : 1;
}
