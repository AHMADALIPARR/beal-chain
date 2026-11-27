-- Copyright (C) 2026 AHMADALIPARR
-- SPDX-License-Identifier: AGPL-3.0-only
module Beal where

open import Agda.Builtin.Nat using (Nat; suc)
open import Agda.Builtin.Equality using (_≡_)

-- Constructive refinements: these witnesses enforce the requested bounds.
data Positive : Nat → Set where
  positive : (n : Nat) → Positive (suc n)

data ExponentGT2 : Nat → Set where
  exponent>2 : (n : Nat) → ExponentGT2 (suc (suc (suc n)))

-- Arithmetic interface. A production development must replace these
-- declarations with proved definitions or imports from a pinned library.
postulate
  _^_ : Nat → Nat → Nat
  _+_ : Nat → Nat → Nat
  gcd3 : Nat → Nat → Nat → Nat
  GreaterThanOne : Nat → Set

-- The conjecture is a proposition/type, not an assumed inhabitant.
BealConjecture : Set
BealConjecture =
  (A B C x y z : Nat) →
  Positive A → Positive B → Positive C →
  ExponentGT2 x → ExponentGT2 y → ExponentGT2 z →
  (A ^ x) + (B ^ y) ≡ (C ^ z) →
  GreaterThanOne (gcd3 A B C)
