`ifdef PLL_MODEL
`else
module pllclk(refclk, vcop, vcom, clk1x, clk2x, reset, ibias);
    input  refclk;
    output vcop;
    output vcom;
    output clk1x;
    output clk2x;
    input reset;
    input ibias;
endmodule
`endif
