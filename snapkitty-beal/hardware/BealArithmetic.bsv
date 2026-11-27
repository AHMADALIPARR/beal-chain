// Copyright (C) 2026 AHMADALIPARR
// SPDX-License-Identifier: AGPL-3.0-only
package BealArithmetic;

// Bounded arithmetic test kernel only. This is NOT a proof of Beal's conjecture.
// The instance check mirrors hardware/beal_ref.c: bases are 16-bit, exponents
// are 6-bit (0..63), powers and the sum are checked against the 64-bit bound,
// and the status codes match the C BEAL_* values.

// Status codes (match the C BEAL_* values in hardware/beal_ref.h).
typedef Bit#(2) BealStatus;
BealStatus bealEqual    = 2'b00;
BealStatus bealNotEqual = 2'b01;
BealStatus bealOverflow = 2'b10;
BealStatus bealInvalid  = 2'b11;

typedef struct {
  Bit#(64) value;
  Bool overflow;
} PowResult deriving (Bits, Eq);

// Checked power by binary exponentiation. Each multiply is done in 128 bits
// and the high 64 bits are tested, so an overflow is reported instead of
// wrapping. exp is 6 bits, so the loop is bounded to 6 iterations.
function PowResult pow64(Bit#(16) base, Bit#(6) exp);
  Bit#(64) result = 1;
  Bit#(64) b = zeroExtend(base);
  Bool ovf = False;
  for (Integer i = 0; i < 6; i = i + 1) begin
    if (exp[i] == 1) begin
      Bit#(128) p = zeroExtend(result) * zeroExtend(b);
      if (p[127:64] != 0) ovf = True;
      else result = p[63:0];
    end
    // Square b for the next bit, unless this is the last bit.
    if (i < 5) begin
      Bit#(128) p2 = zeroExtend(b) * zeroExtend(b);
      if (p2[127:64] != 0) ovf = True;
      else b = p2[63:0];
    end
  end
  return PowResult { value: result, overflow: ovf };
endfunction

// General bounded Beal-instance check: A^x + B^y == C^z.
// Bases must be >= 1; exponents must be >= 3 (the Beal range).
function BealStatus bealInstance(Bit#(16) a, Bit#(16) b, Bit#(16) c,
                                 Bit#(6) x, Bit#(6) y, Bit#(6) z);
  BealStatus s;
  if (a == 0 || b == 0 || c == 0) s = bealInvalid;
  else if (x < 3 || y < 3 || z < 3) s = bealInvalid;
  else begin
    PowResult p1 = pow64(a, x);
    PowResult p2 = pow64(b, y);
    PowResult p3 = pow64(c, z);
    if (p1.overflow || p2.overflow || p3.overflow) s = bealOverflow;
    else begin
      Bit#(65) sum = zeroExtend(p1.value) + zeroExtend(p2.value);
      if (sum[64] == 1) s = bealOverflow;
      else if (sum[63:0] == p3.value) s = bealEqual;
      else s = bealNotEqual;
    end
  end
  return s;
endfunction

interface BealArithmeticIfc;
  method Action setOperands(Bit#(16) a, Bit#(16) b, Bit#(16) c);
  method Bit#(1) sumEquals;
  method Action setInstance(Bit#(16) a, Bit#(16) b, Bit#(16) c,
                            Bit#(6) x, Bit#(6) y, Bit#(6) z);
  method BealStatus instanceStatus;
endinterface

function Bit#(32) square(Bit#(16) x);
  return zeroExtend(x) * zeroExtend(x);
endfunction

module mkBealArithmetic(BealArithmeticIfc);
  // The square kernel and the instance checker keep separate registers,
  // so setOperands and setInstance never write the same register.
  Reg#(Bit#(16)) a <- mkReg(0);
  Reg#(Bit#(16)) b <- mkReg(0);
  Reg#(Bit#(16)) c <- mkReg(0);
  Reg#(Bit#(16)) ia <- mkReg(0);
  Reg#(Bit#(16)) ib <- mkReg(0);
  Reg#(Bit#(16)) ic <- mkReg(0);
  Reg#(Bit#(6)) ix <- mkReg(0);
  Reg#(Bit#(6)) iy <- mkReg(0);
  Reg#(Bit#(6)) iz <- mkReg(0);
  method Action setOperands(Bit#(16) aa, Bit#(16) bb, Bit#(16) cc);
    a <= aa; b <= bb; c <= cc;
  endmethod
  method Bit#(1) sumEquals;
    Bit#(33) lhs = zeroExtend(square(a)) + zeroExtend(square(b));
    Bit#(33) rhs = zeroExtend(square(c));
    return (lhs == rhs) ? 1 : 0;
  endmethod
  method Action setInstance(Bit#(16) aa, Bit#(16) bb, Bit#(16) cc,
                            Bit#(6) xx, Bit#(6) yy, Bit#(6) zz);
    ia <= aa; ib <= bb; ic <= cc;
    ix <= xx; iy <= yy; iz <= zz;
  endmethod
  method BealStatus instanceStatus;
    return bealInstance(ia, ib, ic, ix, iy, iz);
  endmethod
endmodule

endpackage
