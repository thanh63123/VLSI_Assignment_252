
module accum_stat   (
    accum,
    ar,
    bio,
    gez,
    gz,
    nz,
    z,
    lz,
    lez,
    ov,
    arnz,
    bioz
    );

/*
 *
 *  @(#) accum_stat.v 15.1@(#)
 *  4/1/96  09:09:47
 *
 */

/*
 * Tiny DSP Accumulator Status
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
input   [`ACC:0]    accum;          // Accumulator
input   [`MSB:0]    ar;             // Selected Auxilary Register
input               bio;            // BIO
output              gez,            // ACC GT, Equal Zero
                    gz,             // ACC GT Zero
                    nz,             // ACC Not Zero
                    z,              // ACC Zero
                    lz,             // ACC LT Zero
                    lez;            // ACC LT, Equal Zero
input               ov;             // ACC Overflow
output              arnz,           // AR no Zero
                    bioz;           // BIO Zero
wire    [`ACC:0]    accum;          // Accumulator
wire    [`MSB:0]    ar;             // Selected Auxilary Register
wire    [`S_ACC]    acc_v;          // accumulator value
wire                bio;            // BIO
wire                gez,            // ACC GT, Equal Zero
                    gz,             // ACC GT Zero
                    nz,             // ACC Not Zero
                    z,              // ACC Zero
                    lz,             // ACC LT Zero
                    lez,            // ACC LT, Equal Zero
                    ov,             // ACC Overflow
                    arnz,           // AR Not Zero
                    bioz,           // BIO Zero
                    sign;           // Accumulator sign bit

assign #1 sign = accum[`S_ACC_SIGN] ;
assign #1 acc_v = accum[`S_ACC] ;

assign #1 gez = gz | z ;                        // (accum >= 0)
assign #1 gz = ~sign & (|acc_v) ;               // (accum > 0)
assign #1 nz = ~z ;                             // (accum != 0)
assign #1 z = ~sign & (acc_v == 0) ;            // (accum == 0)
assign #1 lz = sign ;                           // (accum < 0)
assign #1 lez = lz | z ;                        // (accum < 0)

assign #1 arnz = (ar != 0) ;

assign #1 bioz = (bio == 0) ;

endmodule // accum_stat
