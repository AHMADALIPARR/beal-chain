-- Copyright (C) 2026 AHMADALIPARR
-- SPDX-License-Identifier: AGPL-3.0-only
-- SnapKitty.Beal: higher-order Beal schema. The ordinary Beal conjecture
-- and the higher-order schema are stated as types only. No proof term is
-- given: Beal is open, and no generated artifact may claim a proof. The
-- computational witnesses for the example instance live in Beal.agda.
module SnapKitty.Beal where

open import Agda.Builtin.Nat
open import Agda.Builtin.Equality
open import Agda.Builtin.Sigma
open import SnapKitty.Prelude

Positive : Nat → Set
Positive n = Σ Nat (λ k → n ≡ suc k)

CommonPrimeDivisor : Nat → Nat → Nat → Set
CommonPrimeDivisor a b c =
  Σ Nat (λ p → Prime p × ((p ∣ a) × ((p ∣ b) × (p ∣ c))))

BealEquation : Nat → Nat → Nat → Nat → Nat → Nat → Set
BealEquation a b c x y z =
  (pow a x +N pow b y) ≡ pow c z

ExponentConstraint : Set₁
ExponentConstraint = Nat → Nat → Nat → Set

AllExponentsGT2 : ExponentConstraint
AllExponentsGT2 x y z = (GT2 x) × ((GT2 y) × (GT2 z))

ConstraintAdmissible : ExponentConstraint → Set
ConstraintAdmissible C =
  (x y z : Nat) → C x y z → (GT2 x) × ((GT2 y) × (GT2 z))

BealFor : ExponentConstraint → Set
BealFor C =
  (a b c x y z : Nat) →
  Positive a → Positive b → Positive c →
  C x y z →
  BealEquation a b c x y z →
  CommonPrimeDivisor a b c

-- Higher-order schema: quantify over admissible predicates on exponent triples.
HigherOrderBeal : Set₁
HigherOrderBeal =
  (C : ExponentConstraint) →
  ConstraintAdmissible C →
  BealFor C

OrdinaryBeal : Set
OrdinaryBeal = BealFor AllExponentsGT2

-- The ordinary Beal statement is the central open instance.
-- It is a type, not a proof: no term of type OrdinaryBeal or
-- HigherOrderBeal is given, because the conjecture is unproved.
