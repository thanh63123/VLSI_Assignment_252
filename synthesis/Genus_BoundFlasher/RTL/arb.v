module arb (
    reset,
    clk,
    dma_breq,
    dma_grant,
    tdsp_breq,
    tdsp_grant
    );

/*
 *
 *  @(#) arb.v 15.1@(#)
 *  4/1/96  09:09:49
 *
 */

/*
 *
 * DMA/ TDSP bus arbiter
 *
 * Author:  Mark A. Indovina
 *          Cadence Design Systems, Inc.
 *          CSD-IC Technology Laboratory
 *
 */

input
    reset,                      // system reset
    clk,                        // system clock
    dma_breq,                   // dma controller bus request
    tdsp_breq ;                 // tdsp bus request

output
    dma_grant,                  // dma controller bus grant
    tdsp_grant ;                // tdsp bus grant

//
// explicit state machine states
//
`define ARB_IDLE        3'b001
`define ARB_GRANT_TDSP  3'b000
`define ARB_GRANT_DMA   3'b010
`define ARB_CLEAR       3'b011
`define ARB_DMA_PRI     3'b111

reg [2:0]
    next_state,
    present_state;

reg
    tdsp_grant,
    dma_grant ;

//
// next state logic
//
always @( dma_breq or tdsp_breq or present_state )
    begin : next_state_generation
        case(present_state)
            `ARB_IDLE   : begin
                if ( tdsp_breq )
                    next_state <= `ARB_GRANT_TDSP ;
                else if ( dma_breq )
                    next_state <= `ARB_GRANT_DMA ;
                else
                    next_state <= `ARB_IDLE ;
                end
            `ARB_GRANT_TDSP : begin
                if ( tdsp_breq )
                    next_state <= `ARB_GRANT_TDSP ;
                else
                    next_state <= `ARB_CLEAR ;
                end
            `ARB_GRANT_DMA  : begin
                if ( dma_breq )
                    next_state <= `ARB_GRANT_DMA ;
                else
                    next_state <= `ARB_CLEAR ;
                end
            `ARB_CLEAR  : begin
                if ( tdsp_breq )
                    next_state <= `ARB_GRANT_TDSP ;
                else if ( dma_breq )
                    next_state <= `ARB_DMA_PRI ;
                else
                    next_state <= `ARB_CLEAR ;
                end
            `ARB_DMA_PRI    : begin
                if ( dma_breq )
                    next_state <= `ARB_GRANT_DMA ;
                else if ( tdsp_breq )
                    next_state <= `ARB_GRANT_TDSP ;
                else
                    next_state <= `ARB_IDLE ;
                end
            default : begin
                next_state <= `ARB_IDLE ;
                end
        endcase
    end

//
// "present state" state register
//
always @(posedge clk or posedge reset)
	if (reset)
		begin
		present_state <= `ARB_IDLE;
		end
	else
    	begin : exp_machine
    	present_state <= next_state;
    	end

//
// tdsp grant register
// grant priority to the tdsp
//
always @(posedge clk or posedge reset)
    if (reset)
        tdsp_grant <= 0 ;
    else
        tdsp_grant <= ((next_state == `ARB_GRANT_TDSP) ||
                       (next_state == `ARB_CLEAR)) ;

//
// dma grant register
//
always @(posedge clk or posedge reset)
    if (reset)
        dma_grant <= 0 ;
    else
        dma_grant <= (next_state == `ARB_GRANT_DMA) ;
    
endmodule // arb
