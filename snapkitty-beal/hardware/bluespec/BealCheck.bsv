// Copyright (C) 2026 AHMADALIPARR
// SPDX-License-Identifier: AGPL-3.0-only
// BealCheck: bounded Beal-instance checker datapath.
// Checks A^x + B^y = C^z over 32-bit bases with a 64-bit intermediate,
// flagging overflow when the true result exceeds 32 bits. This is a
// bounded finite-instance check only; it does not prove Beal.
// Fixed: pow32 uses binary exponentiation (5 iterations) instead of a
// 31-iteration linear loop, so Bluespec generates Verilog without
// exhausting memory.
package BealCheck;

interface BealCheckIfc;
  method Action start(Bit#(32) a, Bit#(32) b, Bit#(32) c,
                      Bit#(5) x, Bit#(5) y, Bit#(5) z);
  method Bool done;
  method Bool overflow;
  method Bool equationHolds;
endinterface

function Tuple2#(Bit#(64), Bool) pow32(Bit#(32) base, Bit#(5) exp);
  Bit#(64) result = 1;
  Bit#(64) b = zeroExtend(base);
  Bool ov = False;
  Bit#(5) e = exp;
  // Binary exponentiation over the 5 exponent bits.
  for (Integer i = 0; i < 5; i = i + 1) begin
    if (e[0] == 1) begin
      Bit#(64) next = result * b;
      if ((next >> 32) != 0) ov = True;
      result = next;
    end
    // Square b for the next bit. The square is computed in 128 bits;
    // if it overflows 64 bits and a later exponent bit will consume b,
    // the result would be wrong, so flag overflow.
    Bit#(128) b2wide = zeroExtend(b) * zeroExtend(b);
    Bool bOv = (b2wide >> 64) != 0;
    b = truncate(b2wide);
    if (bOv && (e >> 1) != 0) ov = True;
    e = e >> 1;
  end
  return tuple2(result, ov);
endfunction

module mkBealCheck(BealCheckIfc);
  Reg#(Bool) rDone <- mkReg(False);
  Reg#(Bool) rOverflow <- mkReg(False);
  Reg#(Bool) rHolds <- mkReg(False);

  method Action start(Bit#(32) a, Bit#(32) b, Bit#(32) c,
                      Bit#(5) x, Bit#(5) y, Bit#(5) z);
    match {.pa, .oa} = pow32(a, x);
    match {.pb, .ob} = pow32(b, y);
    match {.pc, .oc} = pow32(c, z);
    Bit#(64) sum = pa + pb;
    Bool addOverflow = (sum >> 32) != 0;
    rOverflow <= oa || ob || oc || addOverflow ||
                 (pa > 64'hffffffff) || (pb > 64'hffffffff) ||
                 (pc > 64'hffffffff);
    rHolds <= !oa && !ob && !oc && !addOverflow && (sum == pc);
    rDone <= True;
  endmethod

  method Bool done = rDone;
  method Bool overflow = rOverflow;
  method Bool equationHolds = rHolds;
endmodule

endpackage
