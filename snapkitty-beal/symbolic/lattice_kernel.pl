% Copyright (C) 2026 AHMADALIPARR
% SPDX-License-Identifier: AGPL-3.0-only
%% lattice_kernel.pl -- Relational Lattice Kernel (ISO Prolog)
%%
%% Same relations as mu_kanren.scm as portable ISO predicates.
%% Optional CLP(FD) adder via use_module(library(clpfd)).
%% Compatible with SWI-Prolog, GNU Prolog, SICStus.
%%
%% Run: swipl -s lattice_kernel.pl -g demo -t halt
%%      demo is a self-test: it prints PASS for each check and halts
%%      with a non-zero exit code on the first mismatch.

:- use_module(library(lists)).

:- dynamic edb/3, edb/4, fsm_transition/5, clpfd_available/0.

%% ============================================================
%% 1. LIST RELATIONS
%% ============================================================

conso(A, D, [A|D]).
nullo([]).
caro([A|_], A).
cdro([_|D], D).
pairo([_|_]).

listo([]).
listo([_|D]) :- listo(D).

appendo([], S, S).
appendo([A|D], S, [A|R]) :- appendo(D, S, R).

membero(X, [X|_]).
membero(X, [_|T]) :- membero(X, T).

rembero(_, [], []).
rembero(X, [X|D], D) :- !.
rembero(X, [A|D], [A|R]) :- X \= A, rembero(X, D, R).

reverseo(L, O) :- rev_acco(L, [], O).
rev_acco([], Acc, Acc).
rev_acco([A|D], Acc, O) :- rev_acco(D, [A|Acc], O).

lengtho([], z).
lengtho([_|D], s(N)) :- lengtho(D, N).

distincto([]).
distincto([A|D]) :- \+ member(A, D), distincto(D).

permuteo([], []).
permuteo([A|D], O) :-
    permuteo(D, R),
    inserto(A, R, O).

inserto(X, L, [X|L]).
inserto(X, [A|D], [A|R]) :- inserto(X, D, R).

zipo([], [], []).
zipo([A|DA], [B|DB], [[A,B]|R]) :- zipo(DA, DB, R).

takeo(0, _, []) :- !.
takeo(s(N), [A|D], [A|R]) :- takeo(N, D, R).

dropo(0, L, L) :- !.
dropo(s(N), [_|D], O) :- dropo(N, D, O).

filtero(_, [], []).
filtero(P, [A|D], Out) :-
    ( call(P, A) ->
        filtero(P, D, R), Out = [A|R]
    ; filtero(P, D, Out)
    ).

%% ============================================================
%% 2. PEANO ARITHMETIC
%% ============================================================

zeroo(z).
succo(N, s(N)).
nato(z).
nato(s(N)) :- nato(N).

addo(z, Y, Y).
addo(s(X), Y, s(Z)) :- addo(X, Y, Z).

mulo(z, _, z).
mulo(s(X), Y, Z) :-
    mulo(X, Y, Z1),
    addo(Y, Z1, Z).

leq_nato(z, _).
leq_nato(s(X), s(Y)) :- leq_nato(X, Y).

%% ============================================================
%% 3. BIT ARITHMETIC -- FULL ADDER
%% ============================================================

bito(0).
bito(1).

half_addo(0, 0, 0, 0).
half_addo(0, 1, 1, 0).
half_addo(1, 0, 1, 0).
half_addo(1, 1, 0, 1).

full_addo(A, B, Cin, S, Cout) :-
    bito(A), bito(B), bito(Cin),
    half_addo(A, B, W, C1),
    half_addo(W, Cin, S, C2),
    % Parentheses are required: without them `;` binds looser than
    % `->`, so the condition would not group the disjunction.
    ( (C1 =:= 1 ; C2 =:= 1) -> Cout = 1 ; Cout = 0 ).

%% CLP(FD) adder (loaded conditionally)
:- ( catch(use_module(library(clpfd)), _, true) ->
       assert(clpfd_available)
   ; true
   ).

full_addo_clp(A, B, Cin, S, Cout) :-
    clpfd_available, !,
    [A, B, Cin, S, Cout] ins 0..1,
    S #= (A + B + Cin) mod 2,
    Cout #= (A + B + Cin) // 2.
full_addo_clp(A, B, Cin, S, Cout) :-
    full_addo(A, B, Cin, S, Cout).

%% n-bit ripple-carry adder
addero([], [], [], Cin, Cin).
addero([A|As], [B|Bs], [S|Ss], Cin, Cout) :-
    full_addo(A, B, Cin, S, Cmid),
    addero(As, Bs, Ss, Cmid, Cout).

%% ============================================================
%% 4. RELATIONAL INTERPRETER (evalo)
%% ============================================================

lookupo(X, [[X,V]|_], V) :- !.
lookupo(X, [[Y,_]|Rest], V) :-
    X \= Y,
    lookupo(X, Rest, V).

eval_expro(quote(Q), _, Q).
eval_expro(X, Env, V) :-
    atom(X), \+ X = quote, \+ X = lambda, \+ X = cons,
    \+ X = car, \+ X = cdr, \+ X = if, \+ X = 'null?',
    lookupo(X, Env, V).
eval_expro(lambda(P, B), Env, closure(P, B, Env)).
eval_expro(app(Rator, Rand), Env, V) :-
    eval_expro(Rator, Env, Clo),
    eval_expro(Rand, Env, Arg),
    applyo(Clo, Arg, V).
eval_expro(cons(A, D), Env, [VA|VD]) :-
    eval_expro(A, Env, VA),
    eval_expro(D, Env, VD).
eval_expro(car(E), Env, V) :-
    eval_expro(E, Env, [V|_]).
eval_expro(cdr(E), Env, V) :-
    eval_expro(E, Env, [_|V]).
eval_expro(if(C, T, El), Env, V) :-
    eval_expro(C, Env, CV),
    ( CV \= false -> eval_expro(T, Env, V)
    ; eval_expro(El, Env, V)
    ).

applyo(closure(P, B, Env), Arg, V) :-
    eval_expro(B, [[P,Arg]|Env], V).

evalo(Exp, Val) :- eval_expro(Exp, [], Val).

%% ============================================================
%% 5. SMT SOLVER (complete DPLL)
%% ============================================================
%% Formula language: propositional connectives and/or/not over atoms.
%% Atoms are var(Name) for boolean variables and
%% bv_slt(var(A), var(B)) for strict ordering constraints A < B.
%% is_sat(Phi) succeeds iff Phi is satisfiable. The solver is a
%% DPLL procedure over the propositional structure; for each
%% satisfying assignment it checks the bv_slt ordering graph for a
%% cycle (a cycle means the ordering constraints are contradictory).
%% It is complete for this fragment: it succeeds exactly when the
%% formula is satisfiable. Ported from smt-sat? in mu_kanren.scm.

%% is_sat(+Phi) -- true iff Phi is satisfiable.
is_sat(Phi) :- dpll(Phi, []).

%% dpll(+Phi, +Assign) -- true iff Phi is satisfiable under Assign.
%% Assign is a list of Atom-Value pairs (Value is true or false).
dpll(Phi, Assign) :-
    simplify(Phi, Assign, S),
    ( S == true ->
        % All propositional constraints satisfied; the bv_slt
        % ordering graph must be acyclic.
        \+ bv_cycle(Assign)
    ; S == false ->
        fail
    ; atoms(S, [A|_]),
      ( dpll(S, [A-true|Assign])
      ; dpll(S, [A-false|Assign])
      )
    ).

%% simplify(+Phi, +Assign, -Simplified)
%% Substitute assigned atoms, then reduce. Returns true, false,
%% or a residual formula.
simplify(true, _, true) :- !.
simplify(false, _, false) :- !.
simplify(and(A, B), Assign, S) :- !,
    simplify(A, Assign, SA),
    simplify(B, Assign, SB),
    and_combine(SA, SB, S).
simplify(or(A, B), Assign, S) :- !,
    simplify(A, Assign, SA),
    simplify(B, Assign, SB),
    or_combine(SA, SB, S).
simplify(not(A), Assign, S) :- !,
    simplify(A, Assign, SA),
    not_combine(SA, S).
simplify(Atom, Assign, S) :-
    ( member(Atom-Val, Assign) -> S = Val ; S = Atom ).

and_combine(false, _, false) :- !.
and_combine(_, false, false) :- !.
and_combine(true, B, B) :- !.
and_combine(A, true, A) :- !.
and_combine(A, B, and(A, B)).

or_combine(true, _, true) :- !.
or_combine(_, true, true) :- !.
or_combine(false, B, B) :- !.
or_combine(A, false, A) :- !.
or_combine(A, B, or(A, B)).

not_combine(true, false) :- !.
not_combine(false, true) :- !.
not_combine(A, not(A)).

%% atoms(+Phi, -Atoms) -- the atoms (non-connective subterms) of Phi.
atoms(true, []) :- !.
atoms(false, []) :- !.
atoms(and(A, B), As) :- !,
    atoms(A, A1), atoms(B, B1), append(A1, B1, As).
atoms(or(A, B), As) :- !,
    atoms(A, A1), atoms(B, B1), append(A1, B1, As).
atoms(not(A), As) :- !, atoms(A, As).
atoms(Atom, [Atom]).

%% bv_cycle(+Assign) -- true iff the true-assigned bv_slt atoms
%% form a cyclic ordering graph. A bv_slt(var(A), var(B)) assigned
%% true contributes the edge A -> B; a cycle means A < A by
%% transitivity, which is unsatisfiable.
bv_cycle(Assign) :-
    findall(A-B,
            member(bv_slt(var(A), var(B))-true, Assign),
            Edges),
    member(A-B, Edges),
    bv_reach(B, A, Edges, [B]).

%% bv_reach(+From, +To, +Edges, +Seen) -- true iff To is reachable
%% from From following Edges, without revisiting Seen nodes.
bv_reach(X, X, _, _) :- !.
bv_reach(X, Y, Edges, Seen) :-
    member(X-Z, Edges),
    \+ member(Z, Seen),
    bv_reach(Z, Y, Edges, [Z|Seen]).

%% is_sat_result(+Phi, -Result) -- Result is sat or unsat.
is_sat_result(Phi, sat) :- is_sat(Phi), !.
is_sat_result(_, unsat).

%% ============================================================
%% 6. EDB FACT STORE
%% ============================================================

assert_edb(Rel, A, B) :- assertz(edb(Rel, A, B)).
assert_edb(Rel, A, B, C) :- assertz(edb(Rel, A, B, C)).

factso(Rel, A, B) :- edb(Rel, A, B).
factso(Rel, A, B, C) :- edb(Rel, A, B, C).

%% ============================================================
%% 7. PARAMETERIZED PATH / REACHABILITY
%% ============================================================

%% patho(+Rel, +X, ?Y, -Path, -Phi)
%% Path is path(Node) for a direct edge, path(Z, P) for a longer
%% path. Phi is the conjunction of the edge guards. The visited
%% set guards against looping on cyclic graphs, and the accumulated
%% conjunction is checked for satisfiability at each step.
patho(Rel, X, Y, Path, Phi) :- patho_(Rel, X, Y, [X], Path, Phi).

patho_(Rel, X, Y, Visited, path(Y), Phi) :-
    \+ member(Y, Visited),
    factso(Rel, X, Y, Phi),
    is_sat(Phi).
patho_(Rel, X, Y, Visited, path(Z, P), and(E, Phi2)) :-
    factso(Rel, X, Z, E),
    \+ member(Z, Visited),
    is_sat(E),
    patho_(Rel, Z, Y, [Z|Visited], P, Phi2),
    is_sat(and(E, Phi2)).

reacho(_, S, S).
reacho(Rel, S, T) :-
    edb(Rel, S, M),
    reacho(Rel, M, T).

%% ============================================================
%% 8. FSM RELATIONS
%% ============================================================

register_fsm(Id) :-
    assertz(fsm_transition(Id, s0, 0, s0, 0)),
    assertz(fsm_transition(Id, s0, 1, s1, 0)),
    assertz(fsm_transition(Id, s1, 0, s0, 1)),
    assertz(fsm_transition(Id, s1, 1, s1, 1)).

fsmo(Id, St, Inp, Nst, Out) :-
    fsm_transition(Id, St, Inp, Nst, Out).

%% fsm_traceo(+Id, +S0, +Inputs, -Outputs)
fsm_traceo(_, _, [], []).
fsm_traceo(Id, S, [I|Rest], [O|RestO]) :-
    fsmo(Id, S, I, S1, O),
    fsm_traceo(Id, S1, Rest, RestO).

%% ============================================================
%% 9. REFINEMENT LATTICE
%% ============================================================

refineo(conc(C), C, refined).
refineo(top, _, refined).
refineo(interval(Lo, Hi), N, refined) :-
    leq_nato(Lo, N),
    leq_nato(N, Hi).

refineo_nat(conc(C), C).
refineo_nat(top, _).
refineo_nat(interval(Lo, Hi), N) :-
    integer(Lo), integer(Hi), integer(N),
    Lo =< N, N =< Hi.

%% ============================================================
%% 10. HIGHER-ORDER LIST OPERATIONS
%% ============================================================

mapo(_, [], []).
mapo(Goal, [A|D], [B|R]) :-
    call(Goal, A, B),
    mapo(Goal, D, R).

foldo(_, [], Acc, Acc).
foldo(Goal, [A|D], Acc, Out) :-
    call(Goal, A, Acc, NAcc),
    foldo(Goal, D, NAcc, Out).

%% Helper predicates used by the self-test.
is_pos(X) :- X > 0.
double(X, Y) :- Y is X * 2.
add_acc(X, Acc, NAcc) :- NAcc is Acc + X.

%% ============================================================
%% 11. SEED DATA
%% ============================================================

seed_db :-
    retractall(edb(_, _, _)),
    retractall(edb(_, _, _, _)),
    retractall(fsm_transition(_, _, _, _, _)),
    assert_edb(edge, 0, 1, bv_slt(var(x), var(y))),
    assert_edb(edge, 1, 2, bv_slt(var(y), var(z))),
    assert_edb(edge, 2, 3, and(var(p), not(var(q)))),
    assert_edb(edge, 0, 2),
    assert_edb(edge, 1, 3),
    register_fsm(fsm0).

%% ============================================================
%% 12. SELF-TEST
%% ============================================================
%% check(+Name, +Got, +Want): print PASS on match; on mismatch
%% print FAIL and halt with exit code 1.
check(Name, Got, Want) :-
    ( Got == Want ->
        format('PASS ~w~n', [Name])
    ; format('FAIL ~w: got ~w, want ~w~n', [Name, Got, Want]),
      halt(1)
    ).

demo :-
    seed_db,
    format('=== lattice_kernel.pl ===~n'),

    % List relations.
    findall(Q, appendo([1,2],[3],Q), R1),
    check('appendo', R1, [[1,2,3]]),
    findall(Q, (membero(2, [1,2,3]), Q = found), R1b),
    check('membero', R1b, [found]),
    findall(R, rembero(2, [1,2,3], R), R1c),
    check('rembero', R1c, [[1,3]]),
    findall(R, rembero(2, [2,2,3], R), R1d),
    check('rembero-first-only', R1d, [[2,3]]),
    findall(R, reverseo([1,2,3], R), R1e),
    check('reverseo', R1e, [[3,2,1]]),
    findall(R, (distincto([1,2,3]), R = ok), R1f),
    check('distincto', R1f, [ok]),
    findall(R, filtero(is_pos, [1,-2,3], R), R1g),
    check('filtero', R1g, [[1,3]]),
    findall(R, mapo(double, [1,2,3], R), R1h),
    check('mapo', R1h, [[2,4,6]]),
    findall(R, foldo(add_acc, [1,2,3], 0, R), R1i),
    check('foldo', R1i, [6]),

    % Peano arithmetic.
    findall(Q, addo(s(z), s(s(z)), Q), R2),
    check('addo', R2, [s(s(s(z)))]),
    findall(Q, mulo(s(s(z)), s(s(s(z))), Q), R2b),
    check('mulo', R2b, [s(s(s(s(s(s(z))))))]),

    % Full adder, logic mode.
    findall(S-C, full_addo(1,1,0,S,C), R3),
    check('full_addo', R3, [0-1]),
    findall(S-C, full_addo(1,1,1,S,C), R3b),
    check('full_addo-carry', R3b, [1-1]),
    % n-bit ripple-carry adder: 01 + 01 + 0 = 10, carry 0.
    findall(S-C, addero([1,0],[1,0],S,0,C), R3c),
    check('addero', R3c, [[0,1]-0]),

    % Full adder, CLP(FD) mode.
    findall(S-C, full_addo_clp(1,1,0,S,C), R3d),
    check('full_addo_clp', R3d, [0-1]),

    % Relational interpreter: identity applied to hello.
    findall(V, evalo(app(lambda(x,x), quote(hello)), V), R4),
    check('evalo-identity', R4, [hello]),

    % SMT solver: satisfiable cases.
    is_sat_result(and(var(p), not(var(q))), S1),
    check('is_sat-sat', S1, sat),
    is_sat_result(and(bv_slt(var(x), var(y)), bv_slt(var(y), var(z))), S2),
    check('is_sat-bv-chain', S2, sat),
    is_sat_result(or(bv_slt(var(x), var(y)), bv_slt(var(y), var(x))), S3),
    check('is_sat-bv-or', S3, sat),
    is_sat_result(or(and(var(p), not(var(p))), var(q)), S4),
    check('is_sat-or-branch', S4, sat),
    % SMT solver: unsatisfiable cases.
    is_sat_result(and(var(p), not(var(p))), U1),
    check('is_sat-unsat-contradiction', U1, unsat),
    is_sat_result(and(bv_slt(var(x), var(y)), bv_slt(var(y), var(x))), U2),
    check('is_sat-unsat-bv-cycle', U2, unsat),
    is_sat_result(bv_slt(var(x), var(x)), U3),
    check('is_sat-unsat-bv-refl', U3, unsat),
    is_sat_result(or(and(var(p), not(var(p))), and(var(q), not(var(q)))), U4),
    check('is_sat-unsat-or', U4, unsat),
    is_sat_result(false, U5),
    check('is_sat-unsat-false', U5, unsat),

    % Reachability from the seed data (3-arity edges 0->2, 1->3).
    findall(T, reacho(edge, 0, T), R5),
    sort(R5, R5s),
    check('reacho-0', R5s, [0,2]),
    findall(T, reacho(edge, 1, T), R5d),
    sort(R5d, R5ds),
    check('reacho-1', R5ds, [1,3]),

    % Guarded path derivation with accumulated formulas.
    findall(P-Phi, patho(edge, 0, 3, P, Phi), R5b),
    sort(R5b, R5bs),
    check('patho-0-3', R5bs,
          [path(1, path(2, path(3)))-and(bv_slt(var(x), var(y)), and(bv_slt(var(y), var(z)), and(var(p), not(var(q)))))]),
    % A cyclic guard must not loop: add a back edge 3->1 and confirm
    % patho still terminates and finds the acyclic path.
    assert_edb(edge, 3, 1, bv_slt(var(z), var(x))),
    findall(P, patho(edge, 0, 3, P, _), R5c),
    sort(R5c, R5cs),
    check('patho-cyclic-terminates', R5cs, [path(1, path(2, path(3)))]),
    retract(edb(edge, 3, 1, bv_slt(var(z), var(x)))),

    % FSM trace.
    findall(O, fsm_traceo(fsm0, s0, [0,1,0], O), R6),
    check('fsm_traceo', R6, [[0,0,1]]),

    % Refinement lattice.
    findall(R, refineo(interval(s(z), s(s(s(z)))), s(s(z)), R), R7),
    check('refineo-interval', R7, [refined]),
    findall(R, (refineo_nat(interval(1, 7), 3), R = ok), R7b),
    check('refineo_nat', R7b, [ok]),

    format('~n=== lattice_kernel.pl: all checks passed ===~n').
