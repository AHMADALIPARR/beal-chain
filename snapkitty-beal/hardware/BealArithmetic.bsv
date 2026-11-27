// Copyright (C) 2026 AHMADALIPARR
// SPDX-License-Identifier: AGPL-3.0-only
package BealArithmetic;

// Bounded arithmetic test kernel only. This is NOT a proof of Beal's conjecture.
interface BealArithmeticIfc;
  method Action setOperands(Bit#(16) a, Bit#(16) b, Bit#(16) c);
  method Bit#(1) sumEquals;
endinterface

function Bit#(32) square(Bit#(16) x);
  return zeroExtend(x) * zeroExtend(x);
endfunction

module mkBealArithmetic(BealArithmeticIfc);
  Reg#(Bit#(16)) a <- mkReg(0);
  Reg#(Bit#(16)) b <- mkReg(0);
  Reg#(Bit#(16)) c <- mkReg(0);
  method Action setOperands(Bit#(16) aa, Bit#(16) bb, Bit#(16) cc);
    a <= aa; b <= bb; c <= cc;
  endmethod
  method Bit#(1) sumEquals;
    Bit#(33) lhs = zeroExtend(square(a)) + zeroExtend(square(b));
    Bit#(33) rhs = zeroExtend(square(c));
    return (lhs == rhs) ? 1 : 0;
  endmethod
endmodule

endpackage
