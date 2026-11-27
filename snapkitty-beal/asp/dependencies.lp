% Copyright (C) 2026 AHMADALIPARR
% SPDX-License-Identifier: AGPL-3.0-only
% Input facts: obligation(ID). depends(ID, DEP). receipt(ID, accepted).
open(H) :- obligation(H), not receipt(H, accepted).
blocked(H) :- depends(H, D), not receipt(D, accepted).
eligible(H) :- open(H), not blocked(H).
closed(H) :- receipt(H, accepted).
:- closed(H), blocked(H).
:- receipt(H, accepted), not obligation(H).
#show open/1.
#show blocked/1.
#show eligible/1.
#show closed/1.
