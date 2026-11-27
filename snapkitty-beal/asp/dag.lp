% Copyright (C) 2026 AHMADALIPARR
% SPDX-License-Identifier: AGPL-3.0-only
% dag.lp: complete DAG program for the beal-chain skeleton obligations.
%
% Follows the guide's architecture: ASP for structural validity and
% dependency constraints, integer scheduling for time and resources,
% and evidence admission from an independent verifier. The program
% types used are only those in the guide: normal logic programming,
% choice rules, integrity constraints, cardinality and aggregate ASP,
% recursive ASP (transitive closure), default and strong negation,
% generate-and-test, and optimization ASP (weak constraints).
%
% Input facts (asp/facts.sh, generated from build/obligations.xml and
% the repository state):
%   obligation(ID).            a proof obligation (a DAG node)
%   depends(FROM, TO).         FROM is scheduled after TO (a DAG edge)
%   vdepends(FROM, TO).        FROM's verification requires TO verified
%   source_status(TID, S).     the theorem's own status from spec/beal.xml
%   duration(ID, D).           effort for ID in time units (modeling
%                              parameter, set by obligation kind)
%   worker_count(N).           number of workers
%   horizon(H).                latest allowed finish time
%   required(ID).              ID is mandatory for admission
%   proof_required(ID).        ID is a proof obligation
%   implemented(ID).           ID has a non-stub implementation
%   artifact_exists(ID).       ID's primary artifact file exists
%   compiled(ID).              ID's artifact compiled / elaborated
%   tested(ID).                ID's artifact passed its check
%   digest_verified(ID).       ID's artifact matches its recorded digest
%   proof_verified(ID).        ID's proof was checked with no postulates
%   placeholder(ID).           ID is an unauthorized stub
%   declared_proved(T).        the orchestration layer declared T proved
%
% The evidence predicates (implemented, artifact_exists, compiled,
% tested, digest_verified, proof_verified) are supplied by the
% independent verifier (asp/facts.sh reading the repository state),
% never by the program itself. The solver only validates them.
%
% Dependency direction: depends(X, Y) means X is scheduled after Y
% (Y is a prerequisite of X). vdepends is the stricter verification
% dependency: X's verification requires Y verified. A "grounds-claim"
% edge is a scheduling dependency only, not a verification dependency,
% so a provenance review is not blocked by the open conjecture it
% grounds.

% ======================================
% DOMAIN
% ======================================
node(N) :- obligation(N).
worker_id(1..W) :- worker_count(W).
time(0..H-1) :- horizon(H).

% ======================================
% C01 IDENTITY
% Every node has a unique identity. The fact generator lowercases IDs
% and converts hyphens to underscores, so each obligation maps to
% exactly one atom. A duplicate obligation fact would be the same
% atom, not a second node.

% ======================================
% C03 REFERENTIAL INTEGRITY
% Every referenced node exists.
% ======================================
:- depends(X, Y), not node(X).
:- depends(X, Y), not node(Y).
:- vdepends(X, Y), not node(X).
:- vdepends(X, Y), not node(Y).
:- depends(X, X).
:- vdepends(X, X).

% ======================================
% C02 ACYCLICITY (recursive ASP + native #edge)
% Transitive closure of the dependency graph, then reject any cycle.
% The native #edge directive lets clingo reject answer sets that
% induce a cyclic graph.
% ======================================
edge(X, Y) :- depends(X, Y).
reach(X, Y) :- edge(X, Y).
reach(X, Z) :- reach(X, Y), edge(Y, Z).
:- reach(X, X).
#edge (X, Y) : edge(X, Y).

% ======================================
% C04 DEPENDENCY CLOSURE
% All prerequisites are included: every node a node depends on
% (transitively) is itself a node in the graph.
% ======================================
:- reach(X, Y), not node(Y).

% ======================================
% SCHEDULING (choice rules + integer constraints)
% Exactly one start time and one worker per node.
% ======================================
1 { start(N, T) : time(T) } 1 :- node(N).
1 { worker(N, W) : worker_id(W) } 1 :- node(N).

finish(N, F) :- start(N, S), duration(N, D), F = S + D.

% C10 RESOURCE BOUNDEDNESS: finish within the horizon.
:- finish(N, F), horizon(H), F > H.

% C05 TEMPORAL PRECEDENCE: a dependent node starts only after its
% prerequisite finishes.
:- depends(X, Y), finish(Y, F), start(X, S), S < F.

% C10 RESOURCE BOUNDEDNESS: at most one node per worker at a time.
active(N, T) :- start(N, S), finish(N, F), time(T), S <= T, T < F.
:- worker(X, W), worker(Y, W), active(X, T), active(Y, T), X != Y.

% ======================================
% C06-C08 TYPE / INTERFACE / TOTALITY
% Every node has a duration, a worker, and a start time (totality of
% the schedule). A node without a duration is a modeling error.
% ======================================
:- node(N), not duration(N, _).
:- node(N), not start(N, _).
:- node(N), not worker(N, _).

% ======================================
% EVIDENCE ADMISSION (generate-and-test + default negation)
% A node is verified only when every piece of independent evidence
% is present. The evidence comes from the verifier, not from this
% program.
% ======================================
% C12 ARTIFACT EXISTENCE
:- required(N), not artifact_exists(N).
% C13 IMPLEMENTATION COMPLETENESS
:- required(N), not implemented(N).
% C14 PLACEHOLDER EXCLUSION
:- required(N), placeholder(N).
% C15 COMPILATION INTEGRITY
:- required(N), not compiled(N).
% C16 TEST INTEGRITY
:- required(N), not tested(N).
% C19 HASH INTEGRITY
:- required(N), not digest_verified(N).
% C17 PROOF INTEGRITY: a proof obligation that is required for
% admission must have its proof verified. (The open conjecture itself
% is proof_required but not required, so it is exempt: it remains open.)
:- proof_required(N), required(N), not proof_verified(N).

% C18 EVIDENCE INTEGRITY: verified requires all evidence.
% A non-proof node needs the five artifact evidences. A proof node
% additionally needs its proof verified.
verified(N) :-
    required(N),
    not proof_required(N),
    implemented(N),
    artifact_exists(N),
    compiled(N),
    tested(N),
    digest_verified(N).
verified(N) :-
    proof_required(N),
    proof_verified(N),
    implemented(N),
    artifact_exists(N),
    compiled(N),
    tested(N),
    digest_verified(N).

% C25 FAILURE PROPAGATION: a failed verification prerequisite blocks
% its dependents (through vdepends only).
blocked(X) :- vdepends(X, Y), not verified(Y).
blocked(X) :- vdepends(X, Y), blocked(Y).
:- required(N), blocked(N).

% C09 TERMINATION: a proof obligation is discharged only when its
% proof is verified (enforced by the verified rule above and C17).

% C21 STATE INTEGRITY: only legal lifecycle transitions.
% A node is open until its evidence is complete; it is closed only
% when verified. It cannot be closed while blocked.
open(N) :- node(N), not verified(N).
closed(N) :- verified(N).
:- closed(N), blocked(N).

% C20 VERSION INTEGRITY: the theorem's recorded status governs
% admission. A conjecture recorded as open may never be declared
% proved by the orchestration layer.
:- source_status(T, "open-conjecture"), declared_proved(T).

% C22 SCOPE PRESERVATION: the canonical spec is the source of truth.
% Its status is read from the file, never hardcoded in this program.

% C23 REQUIREMENT COVERAGE: every requirement maps to a node.
:- required(N), not node(N).

% C24 FINAL ADMISSION: admit only when no required node is outstanding.
outstanding :- required(N), not verified(N).
admit :- not outstanding.

% ======================================
% AGGREGATE ASP: global graph properties
% ======================================
node_count(C) :- C = #count { N : node(N) }.
edge_count(C) :- C = #count { X, Y : edge(X, Y) }.
verified_count(C) :- C = #count { N : verified(N) }.
blocked_count(C) :- C = #count { N : blocked(N) }.
open_count(C) :- C = #count { N : open(N) }.

% ======================================
% OPTIMIZATION ASP: minimize the makespan
% ======================================
makespan(M) :- M = #max { F, N : finish(N, F) }.
#minimize { M : makespan(M) }.

% ======================================
% OUTPUT
% ======================================
#show node_count/1.
#show edge_count/1.
#show start/2.
#show finish/2.
#show worker/2.
#show makespan/1.
#show verified/1.
#show blocked/1.
#show open/1.
#show closed/1.
#show admit/0.
#show outstanding/0.
