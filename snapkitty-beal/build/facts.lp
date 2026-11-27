obligation(beal_proof).
obligation(beal_formalization).
obligation(flt_descent_001).
obligation(provenance_review).
depends(beal_proof,beal_formalization).
depends(beal_proof,flt_descent_001).
depends(provenance_review,beal_proof).
vdepends(beal_proof,beal_formalization).
vdepends(beal_proof,flt_descent_001).
source_status(beal_hol_001, "open-conjecture").
worker_count(2).
horizon(7).
duration(beal_proof, 3).
duration(beal_formalization, 2).
duration(flt_descent_001, 2).
duration(provenance_review, 1).
proof_required(beal_proof).
proof_required(beal_formalization).
proof_required(flt_descent_001).
required(beal_formalization).
required(flt_descent_001).
required(provenance_review).
artifact_exists(beal_proof).
implemented(beal_proof).
compiled(beal_proof).
digest_verified(beal_proof).
tested(beal_proof).
artifact_exists(beal_formalization).
implemented(beal_formalization).
compiled(beal_formalization).
digest_verified(beal_formalization).
tested(beal_formalization).
proof_verified(beal_formalization).
artifact_exists(flt_descent_001).
implemented(flt_descent_001).
compiled(flt_descent_001).
digest_verified(flt_descent_001).
tested(flt_descent_001).
proof_verified(flt_descent_001).
artifact_exists(provenance_review).
implemented(provenance_review).
compiled(provenance_review).
tested(provenance_review).
digest_verified(provenance_review).
