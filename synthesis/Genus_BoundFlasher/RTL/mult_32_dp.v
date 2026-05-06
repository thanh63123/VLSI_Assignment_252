
module mult_32  (
    ovm,
    op_a,
    op_b,
    result
    );

/*
 *
 *  @(#) mult_32.v 15.1@(#)
 *  4/1/96  09:09:55
 *
 */

/*
 * Tiny DSP Multiplier
 * 
 * Tiny DSP,
 *  mimics some of the instruction set functionality of the
 *  TMS320 DSP family
 *
 * Author:  Mark A. Indovina
 *          Cadence Design Systems, Inc.
 *          CSD-IC Technology Laboratory
 *
 */

// fetch defines
`include "tdsp.h"

// types...
input               ovm;            // Overflow mode
input   [`MSB:0]    op_a,           // Input Operand A
                    op_b;           // input Operand B
output  [`HMSB:0]   result;         // Result Output Data

wire                ovm,            // Overflow mode
                    sign_a,
                    sign_b;
wire    [`MSB:0]    op_a,           // Input Operand A
                    op_b,           // input Operand B
                    ab_a,           // (unsigned) input Operand B
                    ab_b,           // (unsigned) input Operand B
                    tc_a,           // (2's comp) input Operand B
                    tc_b;           // (2's comp) input Operand B
wire    [`HMSB:0]   ab_result,      // (unsigned) Result Output Data
                    result;         // Result Output Data

parameter PSAT = 32'h7fffffff;
parameter NSAT = 32'h80000000;

assign #1 sign_a = op_a[15] ;
assign #1 sign_b = op_b[15] ;
assign #1 tc_a = ((~op_a) + 1) ;
assign #1 tc_b = ((~op_b) + 1) ;
assign #1 ab_a = sign_a ?
            (ovm ? ((op_a == NSAT) ? PSAT : tc_a) : tc_a) : op_a ;
assign #1 ab_b = sign_b ?
            (ovm ? ((op_b == NSAT) ? PSAT : tc_b) : tc_b) : op_b ;
//assign #1 ab_result = ab_a * ab_b ;
m16x16 M16X16_INST (.a(ab_a), .b(ab_b), .y(ab_result)) ;
assign #1 result = (sign_a ^ sign_b) ? ((~ab_result) + 1) : ab_result ;

endmodule // mult_32
