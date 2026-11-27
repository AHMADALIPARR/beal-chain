-- Copyright (C) 2026 AHMADALIPARR
-- SPDX-License-Identifier: AGPL-3.0-only
module BealReduction where

open import Agda.Builtin.Nat using (Nat)
open import Agda.Builtin.Equality using (_≡_)
open import Beal

-- Formal boundary for the conditional reduction. The well-founded descent
-- development is an explicit input, not an unproved assertion hidden in Beal.
record FermatDescent : Set where
  field
    no-equal-exponent-solution :
      (n a b c : Nat) →
      ExponentGT2 n → Positive a → Positive b → Positive c →
      (a ^ n) + (b ^ n) ≡ (c ^ n) → Set

conditional-FLT : BealConjecture → FermatDescent → Set
conditional-FLT beal descent =
  (n a b c : Nat) →
  ExponentGT2 n → Positive a → Positive b → Positive c →
  (a ^ n) + (b ^ n) ≡ (c ^ n) →
  FermatDescent.no-equal-exponent-solution descent n a b c
