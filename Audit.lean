-- Copyright (C) 2026 AHMADALIPARR
-- SPDX-License-Identifier: AGPL-3.0-only
import BealChain

open Lean

/-- Check that `declName` depends only on the three standard axioms
    (`propext`, `Classical.choice`, `Quot.sound`). Anything else
    (`sorryAx`, `Lean.ofReduceBool`, `Lean.trustCompiler`, ...) is an error. -/
def checkAllowedAxioms (declName : Name) : MetaM Bool := do
  let axioms ← Lean.collectAxioms declName
  let allowed : Std.HashSet Name :=
    Std.HashSet.ofList [``propext, ``Classical.choice, ``Quot.sound]
  let illegal := axioms.filter (!allowed.contains ·)
  if !illegal.isEmpty then
    throwError "Disallowed axioms in {declName}: {illegal.toList}"
  IO.println s!"OK {declName}: {axioms.toList}"
  return true

#print axioms BealChain.exists_odd_prime_or_four_of_gt_two
#print axioms BealChain.pairwise_coprime_pow_of_pairwise_coprime
#print axioms BealChain.prime_ge_five_of_not_small
#print axioms BealChain.step1_exponent_reduction
#print axioms BealChain.step2_signature_partition
#print axioms BealChain.radical_pos
#print axioms BealChain.step3_frey_curve_pp4
#print axioms BealChain.step3_frey_curve_pp3
#print axioms BealChain.sturm_bound_level_32
#print axioms BealChain.sturm_bound_level_27
#print axioms BealChain.sturm_bound_level_64
#print axioms BealChain.known_signature_no_primitive_solutions
#print axioms BealChain.conditional_beal_distinct_primes

#eval checkAllowedAxioms ``BealChain.exists_odd_prime_or_four_of_gt_two
#eval checkAllowedAxioms ``BealChain.pairwise_coprime_pow_of_pairwise_coprime
#eval checkAllowedAxioms ``BealChain.prime_ge_five_of_not_small
#eval checkAllowedAxioms ``BealChain.step1_exponent_reduction
#eval checkAllowedAxioms ``BealChain.step2_signature_partition
#eval checkAllowedAxioms ``BealChain.radical_pos
#eval checkAllowedAxioms ``BealChain.step3_frey_curve_pp4
#eval checkAllowedAxioms ``BealChain.step3_frey_curve_pp3
#eval checkAllowedAxioms ``BealChain.sturm_bound_level_32
#eval checkAllowedAxioms ``BealChain.sturm_bound_level_27
#eval checkAllowedAxioms ``BealChain.sturm_bound_level_64
#eval checkAllowedAxioms ``BealChain.known_signature_no_primitive_solutions
#eval checkAllowedAxioms ``BealChain.conditional_beal_distinct_primes

def main : IO Unit := pure ()
