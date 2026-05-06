
module conv_subreg (
    rcc_clk,
    enable,
    din,
    dout
    ) ;
 
/*
 *
 *  @(#) conv_subreg.v 15.2@(#)
 *  2/25/98  10:16:30
 *
 */

/*
 *
 * Results Character Conversion (RCC)
 *  processes a computed frequency spectrum to
 *  determine if a valid DTMF digit can be found
 *
 * Author:  Meera Balakrishnan
 *          Cadence Design Systems, Inc.
 *          CSD-IC Technology Laboratory
 *  
 * Modifications:
 * 
 * 7/9/98 : Fixed state machine transitions (CHARACTER->IDLE), GDG
 * 9/20/04 : Carl Schwink (schwink@cadence.com) -- submodule created to
 *           illustrate clock gating decloning
 */

input
    rcc_clk ;             // data input write strobe

input
    enable ;               // holding register address bus

input [7:0]
    din ;                   // data input bus

output [7:0]
    dout ;                  // data output bus

reg [7:0]
    dout ;

`include "results_conv.h"

always @(negedge rcc_clk)
    dout = enable ? din : dout;

endmodule // conv_subreg
