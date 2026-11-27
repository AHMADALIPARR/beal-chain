// Copyright (C) 2026 AHMADALIPARR
// SPDX-License-Identifier: AGPL-3.0-only
#include <stdint.h>
#include <stdbool.h>

/* Reference semantics for the bounded exponent-2 hardware test. */
bool beal_square_check(uint16_t a, uint16_t b, uint16_t c) {
    uint64_t lhs = (uint64_t)a * a + (uint64_t)b * b;
    uint64_t rhs = (uint64_t)c * c;
    return lhs == rhs;
}
