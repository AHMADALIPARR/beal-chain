(* Copyright (C) 2026 AHMADALIPARR *)
(* SPDX-License-Identifier: AGPL-3.0-only *)
(* ATS2 bounded arithmetic contract, pure ATS (no C FFI).
   This executable checks one bounded equation; it is not a proof of Beal.
   Uses the non-linear Option type so the results can be matched without
   linear-resource bookkeeping. *)
#include "share/atspre_staload.hats"

(* Max ullint. ullint_max is not a defined identifier in this ATS
   install, so the literal 2^64-1 is used. *)
val max_ullint : ullint = 18446744073709551615ULL

fun pow_u64 (base: ullint, exp: uint): Option(ullint) = let
  fun loop (acc: ullint, i: uint): Option(ullint) =
    if i >= exp then Some(acc)
    else if base != 0ULL && acc > max_ullint / base then None()
    else loop(acc * base, i + 1U)
in
  loop(1ULL, 0U)
end

implement main0 () = let
  val a = 3ULL
  val b = 4ULL
  val c = 5ULL
  val x = 2U
  val y = 2U
  val z = 2U
  val ax = pow_u64(a, x)
  val by = pow_u64(b, y)
  val cz = pow_u64(c, z)
in
  case+ (ax, by, cz) of
  | (Some(m), Some(n), Some(k)) =>
      println!("bounded ATS check: ", m + n, " == ", k,
               " : ", m + n = k)
  | (Some(_), Some(_), None()) => println!("overflow")
  | (Some(_), None(), Some(_)) => println!("overflow")
  | (Some(_), None(), None()) => println!("overflow")
  | (None(), Some(_), Some(_)) => println!("overflow")
  | (None(), Some(_), None()) => println!("overflow")
  | (None(), None(), Some(_)) => println!("overflow")
  | (None(), None(), None()) => println!("overflow")
end
