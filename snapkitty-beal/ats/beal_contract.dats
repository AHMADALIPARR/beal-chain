(* Copyright (C) 2026 AHMADALIPARR *)
(* SPDX-License-Identifier: AGPL-3.0-only *)
(* ATS2 interface contract for the bounded Beal-instance checker.
   The C reference implements a bounded arithmetic check only.
   It does not encode arbitrary exponents beyond uint64_t, and it
   does not establish Beal's conjecture or FLT. *)
#include "share/atspre_staload.hats"

(* The generated C includes the reference header, so the FFI calls are
   declared and type-checked by the C compiler as well. *)
%{^
#include "beal_ref.h"
%}

(* The exponent-2 hardware test kernel, via the int-typed wrapper. *)
extern fun beal_square_check_int
  (a: int, b: int, c: int): bool = "mac#beal_square_check_int"

(* The general bounded instance check. Status codes are the
   BEAL_* values from hardware/beal_ref.h.
   ulint is used because ATS2 UL literals have type ulint, and on
   LP64 (Linux x86-64) unsigned long is exactly uint64_t. *)
extern fun beal_instance_check
  (a: ulint, b: ulint, c: ulint,
   x: ulint, y: ulint, z: ulint): int = "mac#beal_instance_check"

(* Print one instance result as a single line. *)
fun print_instance
  (a: ulint, b: ulint, c: ulint,
   x: ulint, y: ulint, z: ulint): void = let
  val s = beal_instance_check(a, b, c, x, y, z)
  val () = print(a)
  val () = print("^")
  val () = print(x)
  val () = print(" + ")
  val () = print(b)
  val () = print("^")
  val () = print(y)
  val () = print(" =? ")
  val () = print(c)
  val () = print("^")
  val () = print(z)
  val () = print(" -> ")
  val () = if s = 0 then print("EQUAL")
           else if s = 1 then print("NOT_EQUAL")
           else if s = 2 then print("OVERFLOW")
           else print("INVALID")
  val () = print("\n")
in
end

implement main0 () = let
  (* The exponent-2 hardware kernel on the Pythagorean triple. *)
  val sq = beal_square_check_int(3, 4, 5)
  val () = print("square 3^2+4^2=5^2 -> ")
  val () = print(sq)
  val () = print("\n")
  (* The Beal example: 3^3 + 6^3 = 3^5. *)
  val () = print_instance(3UL, 6UL, 3UL, 3UL, 3UL, 5UL)
  (* A non-solution. *)
  val () = print_instance(2UL, 3UL, 5UL, 3UL, 3UL, 3UL)
  (* An overflow case: 2^64 does not fit in uint64_t. *)
  val () = print_instance(2UL, 2UL, 2UL, 64UL, 64UL, 64UL)
  (* An invalid case: exponent 2 is below the Beal range. *)
  val () = print_instance(2UL, 2UL, 2UL, 2UL, 2UL, 2UL)
in
end
