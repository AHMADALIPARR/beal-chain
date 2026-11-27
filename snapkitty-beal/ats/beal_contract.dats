(* Copyright (C) 2026 AHMADALIPARR *)
(* SPDX-License-Identifier: AGPL-3.0-only *)
(* ATS2 interface contract for bounded arithmetic accelerator. *)
#include "share/atspre_staload.hats"

(* The hardware block currently checks squares only. It does not encode
   arbitrary exponents or establish Beal/FLT. *)
extern fun beal_square_check
  (a: uint16, b: uint16, c: uint16): bool = "mac#beal_square_check"

implement main0 () = ()
