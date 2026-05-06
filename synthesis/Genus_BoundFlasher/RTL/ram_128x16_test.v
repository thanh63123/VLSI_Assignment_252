
module ram_128x16_test (
    a,
    din,
    dout,
    oe,
    wr,
    test_mode
    ) ;


/*
 *
 *  @(#) ram_128x16.v 15.4@(#)
 *  4/24/96  21:03:42
 *
 */

/*
 * Behavioral module for a RAM
 *   stolen from somewhere...
 *   15apr93mai
 */

    parameter
    addrsize = 7,           // number of address bits
    datasize = 16,          // number of data bits
    words = 128,            // total number of words in ram
    addrs = addrsize - 1,
    data = datasize - 1,
    wordLen = words - 1;

    input [addrs:0] a;      // address bus inputs
    input [data:0] din;     // input data bus
    output [data:0] dout;   // output data bus
    input wr;               // write strobe
    input oe;               // output enable strobe
    input test_mode;
    
    wire [data:0] ramout ;   // testable dout pins

assign #2 dout = test_mode ? din : ramout ;

CDK_S256x16 RAM_128x16_INST(
        .ADDRESS({1'b0,a}),
        .DATA_IN(din),
        .DATA_OUT(ramout),
        .CLOCK(wr),
	.WR_ENABLE(1'b0),
	.ENABLE(1'b0)
);

endmodule // ram_128x16_test
