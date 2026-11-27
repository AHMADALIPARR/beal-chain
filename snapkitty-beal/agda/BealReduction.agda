-- Copyright (C) 2026 AHMADALIPARR
-- SPDX-License-Identifier: AGPL-3.0-only
module BealReduction where

open import Agda.Builtin.Nat using (Nat; zero; suc; _+_; _*_)
open import Agda.Builtin.Equality using (_≡_; refl)
open import Agda.Builtin.Sigma using (Σ; _,_)
open import Beal

-- Product type (not exported by Agda.Builtin.Sigma in 2.6.3).
infixr 2 _×_
_×_ : Set → Set → Set
A × B = Σ A (λ _ → B)

-- Empty type (no constructors).
data ⊥ : Set where

-- Formal boundary for the conditional reduction.
-- The descent step is an explicit input hypothesis, not a hidden assertion:
-- any equal-exponent solution reduces to a *coprime* equal-exponent solution
-- (divide out the common divisor). Beal then contradicts coprimality.
record FermatDescent : Set where
  field
    reduce-to-coprime :
      (n a b c : Nat) →
      ExponentGT2 n → Positive a → Positive b → Positive c →
      (a ^ n) + (b ^ n) ≡ (c ^ n) →
      Σ Nat (λ a' → Σ Nat (λ b' → Σ Nat (λ c' →
        Positive a' × Positive b' × Positive c' ×
        ((a' ^ n) + (b' ^ n) ≡ (c' ^ n)) ×
        (gcd3 a' b' c' ≡ 1))))

-- A number that is both > 1 and ≡ 1 is impossible.
-- GreaterThanOne n means n ≡ suc (suc k); 1 is suc zero, not suc (suc k).
gt1-neq-1 : (n : Nat) → GreaterThanOne n → n ≡ 1 → ⊥
gt1-neq-1 .(suc (suc k)) (gt1 k) ()

-- Conditional FLT: Beal + descent implies no equal-exponent solution.
-- Given a purported solution (a,b,c,n):
--   1. reduce it to a coprime solution (a',b',c',n) via the descent hypothesis,
--   2. apply Beal to the coprime solution: gcd(a',b',c') > 1,
--   3. but the reduced solution is coprime: gcd(a',b',c') ≡ 1. Contradiction.
-- This genuinely uses `beal`: the contradiction comes from applying Beal
-- to the reduced (coprime) solution.
conditional-FLT : BealConjecture → FermatDescent →
  ((n a b c : Nat) →
   ExponentGT2 n → Positive a → Positive b → Positive c →
   (a ^ n) + (b ^ n) ≡ (c ^ n) → ⊥)
conditional-FLT beal descent n a b c hex pa pb pc heq =
  let (a' , b' , c' , pa' , pb' , pc' , heq' , hcop) =
        FermatDescent.reduce-to-coprime descent n a b c hex pa pb pc heq
      gt1-proof = beal a' b' c' n n n pa' pb' pc' hex hex hex heq'
  in gt1-neq-1 (gcd3 a' b' c') gt1-proof hcop
