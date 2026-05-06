
module alu_32   (
    ovm,
    op_a,
    op_b,
    result,
    cmd
    );

/*
 *
 *  @(#) alu_32.v 15.1@(#)
 *  4/1/96  09:09:48
 *
 */

/*
 * Tiny DSP Arithemic Logic Unit
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
input               ovm;            // overflow mode
input   [`HMSB:0]   op_a,           // Input Operand A
                    op_b;           // input Operand B
output  [`ACC:0]    result;         // Result Output Data
input   [`ALUCMD:0] cmd;            // ALU command code

wire                ovm;            // overflow mode
wire    [`HMSB:0]   op_a,           // Input Operand A
                    op_b,           // input Operand B
                    tc_a;           // two's complement version of opa
wire    [`ALUCMD:0] cmd;            // ALU command code
wire    [`HMSB:0]   sat_prod;       // saturated alu product
wire    [`ACC:0]    result;         // Result Output Data
wire                ovf;            // overflow

reg     [`HMSB:0]   prod;           // ALU Product 

parameter PSAT = 32'h7fffffff;
parameter NSAT = 32'h80000000;

assign #1 tc_a = ((~op_a) + 1) ;
assign #1 sat_prod = (ovm && ovf) ? (prod[`HMSB]) ? PSAT : NSAT : prod ;
assign #1 result = { ovf, sat_prod } ;

/*
 *
 * Overflow conditions (only adds and subtracts can overflow):
 *  (+a) + (+b) = (-c)
 *  (-a) + (-b) = (+c)
 *  (+a) - (-b) = (-c)
 *  (-a) - (+b) = (+c)
 *
 */

assign #1 ovf = ((cmd == `ALU_ADD) || (cmd == `ALU_SUB)) ?
                ((cmd == `ALU_ADD) ?
               ((!op_a[`HMSB] && !op_b[`HMSB] && prod[`HMSB]) ||
                (op_a[`HMSB] && op_b[`HMSB] && !prod[`HMSB])) :
               ((!op_a[`HMSB] && op_b[`HMSB] && prod[`HMSB]) ||
                (op_a[`HMSB] && !op_b[`HMSB] && !prod[`HMSB]))) :
                0 ;

// calculate Product
always @(cmd or op_a or op_b or ovm or tc_a)
begin : alu_function
    case (cmd)
    `ALU_ADD: begin             // addition
        prod <= op_a + op_b ;
        end
    `ALU_SUB: begin             // subtraction
        prod <= op_a - op_b ;
        end
    `ALU_AND: begin             // logical and
        prod <= op_a & op_b ;
        end
    `ALU_OR: begin              // logical or
        prod <= op_a | op_b ;
        end
    `ALU_XOR: begin             // logical xor
        prod <= op_a ^ op_b ;
        end
    `ALU_ABS: begin             // absolute value of accum
        prod <= op_a[`HMSB] ?
                       (ovm ?
            ((op_a == NSAT) ? PSAT : tc_a)
                                   : tc_a)
                                   : op_a ;
        end
    `ALU_OPA: begin             // pass through opa
        prod <= op_a ;
        end
    `ALU_OPB: begin             // pass through opb
        prod <= op_b ;
        end
    default: begin
        prod <= 32'bx ;
        end
    endcase
end

endmodule // alu_32
