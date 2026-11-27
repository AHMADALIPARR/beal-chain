-- Copyright (C) 2026 AHMADALIPARR
-- SPDX-License-Identifier: AGPL-3.0-only
-- SnapKitty.Prelude: compact local arithmetic vocabulary for the
-- higher-order Beal schema. Agda 2.6.3 has no Agda.Builtin.Sum, so the
-- sum type is defined here instead of imported.
module SnapKitty.Prelude where

open import Agda.Builtin.Nat public
open import Agda.Builtin.Equality public
open import Agda.Builtin.Sigma public
open import Agda.Builtin.Bool public

data ⊥ : Set where

record ⊤ : Set where
  constructor tt

data _⊎_ (A B : Set) : Set where
  inj₁ : A → A ⊎ B
  inj₂ : B → A ⊎ B

¬_ : Set → Set
¬ P = P → ⊥

_×_ : Set → Set → Set
A × B = Σ A (λ _ → B)

-- Greater than two. (The name GT2 avoids a mixfix operator containing
-- a digit, which Agda does not parse as a postfix operator.)
GT2 : Nat → Set
GT2 (suc (suc (suc n))) = ⊤
GT2 zero = ⊥
GT2 (suc zero) = ⊥
GT2 (suc (suc zero)) = ⊥

_+N_ : Nat → Nat → Nat
zero +N n = n
(suc m) +N n = suc (m +N n)

_*N_ : Nat → Nat → Nat
zero *N n = zero
(suc m) *N n = n +N (m *N n)

pow : Nat → Nat → Nat
pow a zero = suc zero
pow a (suc n) = a *N pow a n

_≤_ : Nat → Nat → Set
zero ≤ n = ⊤
suc m ≤ zero = ⊥
suc m ≤ suc n = m ≤ n

_∣_ : Nat → Nat → Set
d ∣ n = Σ Nat (λ k → n ≡ d *N k)

record Prime (p : Nat) : Set where
  constructor primeWitness
  field
    greaterThanOne : Σ Nat (λ k → p ≡ suc (suc k))
    irreducible : (d : Nat) → d ∣ p → (d ≡ suc zero) ⊎ (d ≡ p)
