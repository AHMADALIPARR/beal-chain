-- Copyright (C) 2026 AHMADALIPARR
-- SPDX-License-Identifier: AGPL-3.0-only
module Beal where

open import Agda.Builtin.Nat using (Nat; zero; suc; _+_; _*_; mod-helper)
open import Agda.Builtin.Equality using (_≡_; refl)

-- Constructive refinements: these witnesses enforce the requested bounds.
data Positive : Nat → Set where
  positive : (n : Nat) → Positive (suc n)

data ExponentGT2 : Nat → Set where
  exponent>2 : (n : Nat) → ExponentGT2 (suc (suc (suc n)))

-- Real power, defined by structural recursion on the exponent.
-- x ^ 0 = 1; x ^ (suc n) = x * (x ^ n).
_^_ : Nat → Nat → Nat
x ^ zero = 1
x ^ suc n = x * (x ^ n)

-- Real modulus, built on the builtin `mod-helper`.
-- n mod (suc m) = mod-helper 0 m n m.  (mod by zero is defined as n.)
_%_ : Nat → Nat → Nat
n % zero = n
n % suc m = mod-helper 0 m n m

-- Real Euclidean gcd.
-- Termination is structural: the fuel is a + b + 1, which strictly
-- decreases on every recursive call (the second argument is replaced
-- by a % (suc b), which is < suc b, so the pair sum strictly drops).
-- The fuel bound a + b + 1 is generous: Euclid needs at most a + b steps.
gcd-fuel : Nat → Nat → Nat → Nat
gcd-fuel zero _ _ = 0
gcd-fuel (suc f) a zero = a
gcd-fuel (suc f) a (suc b) = gcd-fuel f (suc b) (a % suc b)

gcd : Nat → Nat → Nat
gcd a b = gcd-fuel (a + b + 1) a b

-- Real gcd of three numbers.
gcd3 : Nat → Nat → Nat → Nat
gcd3 a b c = gcd (gcd a b) c

-- Real predicate: n is greater than 1.
-- n > 1 iff n is suc (suc k) for some k.
data GreaterThanOne : Nat → Set where
  gt1 : (n : Nat) → GreaterThanOne (suc (suc n))

-- The conjecture is a proposition/type, not an assumed inhabitant.
-- It is stated over the real arithmetic defined above.
BealConjecture : Set
BealConjecture =
  (A B C x y z : Nat) →
  Positive A → Positive B → Positive C →
  ExponentGT2 x → ExponentGT2 y → ExponentGT2 z →
  (A ^ x) + (B ^ y) ≡ (C ^ z) →
  GreaterThanOne (gcd3 A B C)

-- Real computational witnesses (kernel-checked by `refl`):
-- the definitions above compute, so these are proofs.

-- 3^3 + 6^3 = 27 + 216 = 243 = 3^5.
beal-example-eq : (3 ^ 3) + (6 ^ 3) ≡ (3 ^ 5)
beal-example-eq = refl

-- gcd(3, 6, 3) = 3, and 3 > 1.
beal-example-gcd : GreaterThanOne (gcd3 3 6 3)
beal-example-gcd = gt1 1

-- 3^2 + 4^2 = 9 + 16 = 25 = 5^2 (the bounded exponent-2 path).
pythagorean-eq : (3 ^ 2) + (4 ^ 2) ≡ (5 ^ 2)
pythagorean-eq = refl

-- gcd(3, 4, 5) = 1, so this triple does NOT satisfy the Beal gcd claim.
-- (It is not a Beal instance: exponent 2 is not > 2.)
pythagorean-gcd-is-one : gcd3 3 4 5 ≡ 1
pythagorean-gcd-is-one = refl
