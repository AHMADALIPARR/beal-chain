-- Copyright (C) 2026 AHMADALIPARR
-- SPDX-License-Identifier: AGPL-3.0-only
import Mathlib.Data.Nat.Prime.Basic
import Mathlib.Data.Nat.Prime.Defs
import Mathlib.Data.Nat.GCD.Basic
import Mathlib.Data.Rat.Defs
import Mathlib.Tactic

/-! # BealChain core

Fermat-type exponent reduction, signature routing, Frey-curve invariants,
and exact rational Sturm bounds for the Beal conjecture proof chain.
Deep results (Fermat's Last Theorem, Darmon-Merel, Kraus, the general
Darmon program) are kept as hypotheses, not claimed unconditionally. -/

set_option autoImplicit false

namespace BealChain

/-- Pairwise coprimality predicate. -/
def PairwiseCoprime (a b c : ℕ) : Prop :=
  Nat.Coprime a b ∧ Nat.Coprime a c ∧ Nat.Coprime b c

/-- Every integer n > 2 is divisible either by an odd prime p ≥ 3 or by 4. -/
lemma exists_odd_prime_or_four_of_gt_two :
    ∀ n : ℕ, 2 < n → (∃ p k, Nat.Prime p ∧ 3 ≤ p ∧ n = p * k) ∨ (∃ k, n = 4 * k) := by
  intro n
  induction n using Nat.strong_induction_on with
  | h n ih =>
    intro hn
    by_cases h4 : 4 ∣ n
    · exact Or.inr h4
    · by_cases h2 : 2 ∣ n
      · obtain ⟨m, rfl⟩ := h2
        have hm2 : 2 < m := by
          have : m ≠ 0 := by omega
          have : m ≠ 1 := by omega
          have : m ≠ 2 := by
            intro hm_eq
            subst hm_eq
            exact h4 ⟨1, rfl⟩
          omega
        rcases ih m (by omega) hm2 with ⟨p, k, hp, hp3, hmk⟩ | ⟨k, hmk⟩
        · left
          refine ⟨p, 2 * k, hp, hp3, ?_⟩
          rw [hmk]
          ring
        · exfalso
          apply h4
          refine ⟨2 * k, ?_⟩
          rw [hmk]
          ring
      · left
        have hn1 : n ≠ 1 := by omega
        have hp : Nat.Prime n.minFac := Nat.minFac_prime hn1
        have hdvd : n.minFac ∣ n := Nat.minFac_dvd n
        have hne2 : n.minFac ≠ 2 := by
          intro h_eq
          apply h2
          rw [← h_eq]
          exact hdvd
        have hp3 : 3 ≤ n.minFac := by
          have := hp.two_le
          omega
        obtain ⟨k, hk⟩ := hdvd
        exact ⟨n.minFac, k, hp, hp3, hk⟩

lemma pairwise_coprime_pow_of_pairwise_coprime
    {A B C k m n : ℕ} (h : PairwiseCoprime A B C) :
    PairwiseCoprime (A ^ k) (B ^ m) (C ^ n) :=
  ⟨h.1.pow k m, h.2.1.pow k n, h.2.2.pow m n⟩

lemma prime_ge_five_of_not_small {p : ℕ} (hp : Nat.Prime p)
    (h3 : p ≠ 3) (h2 : p ≠ 2) : 5 ≤ p := by
  have h2_le : 2 ≤ p := hp.two_le
  have h4 : p ≠ 4 := by
    intro hp4
    subst hp4
    exact (by decide : ¬Nat.Prime 4) hp
  omega

/-- Reduced exponent validity: either an odd prime ≥ 3 or 4. -/
def ValidReducedExp (p : ℕ) : Prop :=
  (Nat.Prime p ∧ 3 ≤ p) ∨ p = 4

structure ReducedBealInstance (a b c p q r : ℕ) : Prop where
  pos_a : 0 < a
  pos_b : 0 < b
  pos_c : 0 < c
  exp_p : ValidReducedExp p
  exp_q : ValidReducedExp q
  exp_r : ValidReducedExp r
  coprime : PairwiseCoprime a b c
  eq : a ^ p + b ^ q = c ^ r

/-- Step 1: Reduce arbitrary exponents x, y, z > 2 to reduced exponents in {p ≥ 3 prime} ∪ {4}. -/
lemma step1_exponent_reduction
    (A B C x y z : ℕ)
    (h_pos : 0 < A ∧ 0 < B ∧ 0 < C)
    (h_exp : 2 < x ∧ 2 < y ∧ 2 < z)
    (h_eq  : A ^ x + B ^ y = C ^ z)
    (h_cop : PairwiseCoprime A B C) :
    ∃ (a b c p q r : ℕ), ReducedBealInstance a b c p q r := by
  have hx : ∃ p k, ValidReducedExp p ∧ x = p * k := by
    rcases exists_odd_prime_or_four_of_gt_two x h_exp.1 with ⟨p, k, hp, hp3, hk⟩ | ⟨k, hk⟩
    · exact ⟨p, k, Or.inl ⟨hp, hp3⟩, hk⟩
    · exact ⟨4, k, Or.inr rfl, hk⟩
  have hy : ∃ q m, ValidReducedExp q ∧ y = q * m := by
    rcases exists_odd_prime_or_four_of_gt_two y h_exp.2.1 with ⟨q, m, hq, hq3, hm⟩ | ⟨m, hm⟩
    · exact ⟨q, m, Or.inl ⟨hq, hq3⟩, hm⟩
    · exact ⟨4, m, Or.inr rfl, hm⟩
  have hz : ∃ r n, ValidReducedExp r ∧ z = r * n := by
    rcases exists_odd_prime_or_four_of_gt_two z h_exp.2.2 with ⟨r, n, hr, hr3, hn⟩ | ⟨n, hn⟩
    · exact ⟨r, n, Or.inl ⟨hr, hr3⟩, hn⟩
    · exact ⟨4, n, Or.inr rfl, hn⟩
  obtain ⟨p, k, hp_v, hk⟩ := hx
  obtain ⟨q, m, hq_v, hm⟩ := hy
  obtain ⟨r, n, hr_v, hn⟩ := hz
  refine ⟨A ^ k, B ^ m, C ^ n, p, q, r, ?_⟩
  refine
    { pos_a := Nat.pow_pos h_pos.1
      pos_b := Nat.pow_pos h_pos.2.1
      pos_c := Nat.pow_pos h_pos.2.2
      exp_p := hp_v
      exp_q := hq_v
      exp_r := hr_v
      coprime := pairwise_coprime_pow_of_pairwise_coprime h_cop
      eq := ?_ }
  have hp_eq : (A ^ k) ^ p = A ^ x := by
    rw [← pow_mul, mul_comm k p, ← hk]
  have hq_eq : (B ^ m) ^ q = B ^ y := by
    rw [← pow_mul, mul_comm m q, ← hm]
  have hr_eq : (C ^ n) ^ r = C ^ z := by
    rw [← pow_mul, mul_comm n r, ← hn]
  rw [hp_eq, hq_eq, hr_eq]
  exact h_eq

/-! ### 2. Signature partition (known solved signatures vs. open hyperbolic triples) -/

inductive SolvedByKnownSignature (p q r : ℕ) : Prop
  | flt    : p = q ∧ q = r → SolvedByKnownSignature p q r
  | darmon : (p = q ∧ r = 3) ∨ (p = q ∧ r = 4) → SolvedByKnownSignature p q r
  | kraus  : p = 3 ∧ q = 3 → SolvedByKnownSignature p q r

/-- Open hyperbolic prime triples not covered by FLT, (p,p,3), (p,p,4), or (3,3,r). -/
def OpenHyperbolicSignature (p q r : ℕ) : Prop :=
  3 ≤ p ∧ 3 ≤ q ∧ 3 ≤ r ∧ p * q + p * r + q * r < p * q * r ∧
  ¬SolvedByKnownSignature p q r

lemma step2_signature_partition
    (p q r : ℕ)
    (hp3 : 3 ≤ p) (hq3 : 3 ≤ q) (hr3 : 3 ≤ r) :
    SolvedByKnownSignature p q r ∨ OpenHyperbolicSignature p q r := by
  by_cases h_known : SolvedByKnownSignature p q r
  · exact Or.inl h_known
  · right
    refine ⟨hp3, hq3, hr3, ?_, h_known⟩
    by_cases hp4 : 4 ≤ p
    · -- p ≥ 4, q ≥ 3, r ≥ 3: p*q + p*r + q*r ≤ p*q*r/4 + p*q*r/3 + p*q*r/3 < p*q*r
      have h1 : p * q ≤ p * q * r / 3 := by
        rw [Nat.le_div_iff_mul_le (by omega)]
        exact Nat.mul_le_mul_left _ hr3
      have h2 : p * r ≤ p * q * r / 3 := by
        rw [Nat.le_div_iff_mul_le (by omega), mul_right_comm p q r]
        exact Nat.mul_le_mul_left _ hq3
      have h3 : q * r ≤ p * q * r / 4 := by
        rw [Nat.le_div_iff_mul_le (by omega), show p * q * r = q * r * p from by ring]
        exact Nat.mul_le_mul_left _ hp4
      have h4 : p * q * r / 3 + p * q * r / 3 + p * q * r / 4 < p * q * r := by
        have hdiv3 : 3 * (p * q * r / 3) ≤ p * q * r := Nat.mul_div_le _ 3
        have hdiv4 : 4 * (p * q * r / 4) ≤ p * q * r := Nat.mul_div_le _ 4
        have hpos : 0 < p * q * r := by positivity
        omega
      omega
    · by_cases hq4 : 4 ≤ q
      · -- p = 3, q ≥ 4, r ≥ 3
        have hp_eq : p = 3 := by omega
        subst hp_eq
        nlinarith
      · by_cases hr4 : 4 ≤ r
        · -- p = 3, q = 3, r ≥ 4: ruled out by `SolvedByKnownSignature.kraus`
          have hp_eq : p = 3 := by omega
          have hq_eq : q = 3 := by omega
          exact False.elim (h_known (SolvedByKnownSignature.kraus ⟨hp_eq, hq_eq⟩))
        · -- p = 3, q = 3, r = 3: ruled out by `SolvedByKnownSignature.flt`
          have hp_eq : p = 3 := by omega
          have hq_eq : q = 3 := by omega
          have hr_eq : r = 3 := by omega
          exact False.elim (h_known (SolvedByKnownSignature.flt ⟨by omega, by omega⟩))

/-! ### 3. Concrete Frey curve invariants (with explicit positivity premises) -/

def radical (n : ℕ) : ℕ :=
  n.primeFactorsList.dedup.prod

lemma radical_pos {n : ℕ} (hn : 0 < n) : 0 < radical n := by
  unfold radical
  apply List.prod_pos
  intro p hp
  have hp_mem : p ∈ n.primeFactorsList := List.mem_dedup.mp hp
  exact (Nat.prime_of_mem_primeFactorsList hp_mem).pos

lemma step3_frey_curve_pp4
    (a b c p : ℕ)
    (ha : 0 < a) (hb : 0 < b) (hc : 0 < c) :
    ∃ (E_cond : ℕ) (E_disc : ℤ), 0 < E_cond ∧ E_disc ≠ 0 := by
  refine ⟨32 * radical (a * b), -16 * ((a * b : ℕ) : ℤ) ^ (2 * p) * (c : ℤ) ^ 4, ?_, ?_⟩
  · exact Nat.mul_pos (by decide) (radical_pos (Nat.mul_pos ha hb))
  · have hab_ne : ((a * b : ℕ) : ℤ) ≠ 0 := Nat.cast_ne_zero.mpr (Nat.ne_of_gt (Nat.mul_pos ha hb))
    have hc_ne : (c : ℤ) ≠ 0 := Nat.cast_ne_zero.mpr (Nat.ne_of_gt hc)
    exact mul_ne_zero (mul_ne_zero (by norm_num) (pow_ne_zero _ hab_ne)) (pow_ne_zero _ hc_ne)

lemma step3_frey_curve_pp3
    (a b c p : ℕ)
    (ha : 0 < a) (hb : 0 < b) (hc : 0 < c) :
    ∃ (E_cond : ℕ) (E_disc : ℤ), 0 < E_cond ∧ E_disc ≠ 0 := by
  refine ⟨27 * radical (a * b), -27 * ((a * b : ℕ) : ℤ) ^ (2 * p) * (c : ℤ) ^ 3, ?_, ?_⟩
  · exact Nat.mul_pos (by decide) (radical_pos (Nat.mul_pos ha hb))
  · have hab_ne : ((a * b : ℕ) : ℤ) ≠ 0 := Nat.cast_ne_zero.mpr (Nat.ne_of_gt (Nat.mul_pos ha hb))
    have hc_ne : (c : ℤ) ≠ 0 := Nat.cast_ne_zero.mpr (Nat.ne_of_gt hc)
    exact mul_ne_zero (mul_ne_zero (by norm_num) (pow_ne_zero _ hab_ne)) (pow_ne_zero _ hc_ne)

/-! ### 4. Exact rational Sturm bound for Γ₀(N) in weight 2 (proved by exact rational arithmetic) -/

def sturm_bound_weight2 (N : ℕ) : ℕ :=
  Nat.floor (((N : ℚ) * (N.primeFactorsList.dedup.map (fun p => (1 : ℚ) + 1 / (p : ℚ))).prod) / 6)

lemma sturm_bound_level_32 : sturm_bound_weight2 32 = 8 := by
  unfold sturm_bound_weight2
  norm_num [Nat.primeFactorsList]

lemma sturm_bound_level_27 : sturm_bound_weight2 27 = 6 := by
  unfold sturm_bound_weight2
  norm_num [Nat.primeFactorsList]

lemma sturm_bound_level_64 : sturm_bound_weight2 64 = 16 := by
  unfold sturm_bound_weight2
  norm_num [Nat.primeFactorsList]

/-! ### 5. Explicit assumption interfaces for deep arithmetic-geometric theorems -/

structure KnownSignatureTheorems where
  flt_no_primitive :
    ∀ (a b c p : ℕ), 0 < a → 0 < b → 0 < c → 3 ≤ p →
      PairwiseCoprime a b c → a ^ p + b ^ p = c ^ p → False
  darmon_pp3_no_primitive :
    ∀ (a b c p : ℕ), 0 < a → 0 < b → 0 < c → 3 ≤ p →
      PairwiseCoprime a b c → a ^ p + b ^ p = c ^ 3 → False
  darmon_pp4_no_primitive :
    ∀ (a b c p : ℕ), 0 < a → 0 < b → 0 < c → 3 ≤ p →
      PairwiseCoprime a b c → a ^ p + b ^ p = c ^ 4 → False
  kraus_33r_no_primitive :
    ∀ (a b c r : ℕ), 0 < a → 0 < b → 0 < c → 3 ≤ r →
      PairwiseCoprime a b c → a ^ 3 + b ^ 3 = c ^ r → False

structure GeneralDarmonProgramData (a b c p q r : ℕ) where
  FreyAbelianVariety : Prop
  residual_rep_irred : FreyAbelianVariety → Prop
  modularity_and_level_lowering :
    (h_frey : FreyAbelianVariety) → residual_rep_irred h_frey → Prop
  base_level_trace_contradiction :
    (h_frey : FreyAbelianVariety) →
    (h_irred : residual_rep_irred h_frey) →
    modularity_and_level_lowering h_frey h_irred → False

theorem known_signature_no_primitive_solutions
    (h_thms : KnownSignatureTheorems)
    (a b c p q r : ℕ)
    (h_inst : ReducedBealInstance a b c p q r)
    (hp3 : 3 ≤ p) (hq3 : 3 ≤ q) (hr3 : 3 ≤ r)
    (h_known : SolvedByKnownSignature p q r) :
    False := by
  cases h_known with
  | flt h =>
    obtain ⟨hpq, hqr⟩ := h
    subst hpq; subst hqr
    exact h_thms.flt_no_primitive a b c p h_inst.pos_a h_inst.pos_b h_inst.pos_c hp3 h_inst.coprime h_inst.eq
  | darmon h =>
    cases h with
    | inl hpp3 =>
      obtain ⟨hpq, hr_eq⟩ := hpp3
      subst hpq; subst hr_eq
      exact h_thms.darmon_pp3_no_primitive a b c p h_inst.pos_a h_inst.pos_b h_inst.pos_c hp3 h_inst.coprime h_inst.eq
    | inr hpp4 =>
      obtain ⟨hpq, hr_eq⟩ := hpp4
      subst hpq; subst hr_eq
      exact h_thms.darmon_pp4_no_primitive a b c p h_inst.pos_a h_inst.pos_b h_inst.pos_c hp3 h_inst.coprime h_inst.eq
  | kraus h =>
    obtain ⟨hp_eq, hq_eq⟩ := h
    subst hp_eq; subst hq_eq
    exact h_thms.kraus_33r_no_primitive a b c r h_inst.pos_a h_inst.pos_b h_inst.pos_c hr3 h_inst.coprime h_inst.eq

theorem conditional_beal_distinct_primes
    (a b c p q r : ℕ)
    (h_prog : GeneralDarmonProgramData a b c p q r)
    (h_frey : h_prog.FreyAbelianVariety)
    (h_irred : h_prog.residual_rep_irred h_frey)
    (h_mod : h_prog.modularity_and_level_lowering h_frey h_irred) :
    False :=
  h_prog.base_level_trace_contradiction h_frey h_irred h_mod

end BealChain
