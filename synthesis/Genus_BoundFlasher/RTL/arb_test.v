
`timescale 1ns / 1ns

module test;

/*

	@(#) arb_test.v 1.1@(#)
	5/31/96  17:02:13

*/

wire  dma_grant, tdsp_grant;

reg  clk, dma_breq, reset, tdsp_breq;

arb top(reset, clk, dma_breq, dma_grant, tdsp_breq, tdsp_grant); 

reg [4:0]
	dma_wait,
	tdsp_wait ;

integer
	i,
	j,
	dma_cnt,
	tdsp_cnt ;

wire
	grant = dma_grant | tdsp_grant ;

initial
begin 

   clk = 1'b0;
   dma_breq = 1'b0;
   reset = 1'b0;
   tdsp_breq = 1'b0;
   dma_cnt = 0 ;
   tdsp_cnt = 0 ;

	@(negedge clk)
		reset = 1'b1 ;
	repeat (2)
		@(negedge clk) ;
	@(negedge clk)
		reset = 1'b0 ;

	repeat (256)
		begin
		@(posedge clk)
			dma_wait <= $random ;
			tdsp_wait <= $random ;
		fork
		dma_request ;
		tdsp_request ;
		join
		repeat (4)
			@(posedge clk) ;
		end
	repeat (4)
		@(posedge clk) ;
	if (dma_cnt != tdsp_cnt)
		begin
		$display(" ** Fails simulation!");
		$display(" ** 256 Individual Bus request cycles generated,");
		$display(" ** (#tdsp grants == %d) != (#dma grants == %d)", tdsp_cnt, dma_cnt);
		end
	else
		begin
		$display(" ** Passes simulation!");
		$display(" ** 256 Individual Bus request cycles generated,");
		$display(" ** (#tdsp grants == %d) == (#dma grants == %d)", tdsp_cnt, dma_cnt);
		end
	$stop ;
end 

always #20
	clk = ~clk ;

task dma_request ;
begin
	repeat (dma_wait)
		@(posedge clk) ;
	dma_breq <= 1 ;
	$display("%t DMA Bus Request", $time);
	for (i = 0 ; i < (dma_wait + tdsp_wait + 10) ; i = i + 1)
		@(posedge clk)
			if (dma_grant)
				begin
				dma_cnt = dma_cnt +1 ;
				i = (dma_wait + tdsp_wait + 10) ;
				end
	@(posedge clk)
		dma_breq <= 0 ;
	@(posedge clk);
end
endtask

task tdsp_request ;
begin
	repeat (tdsp_wait)
		@(posedge clk) ;
	tdsp_breq <= 1 ;
	$display("%t TDSP Bus Request", $time);
	for (j = 0 ; j < (dma_wait + tdsp_wait + 10) ; j = j + 1)
		@(posedge clk)
			if (tdsp_grant)
				begin
				tdsp_cnt = tdsp_cnt +1 ;
				j = (dma_wait + tdsp_wait + 10) ;
				end
	@(posedge clk)
		tdsp_breq <= 0 ;
	@(posedge clk);
end
endtask

endmodule 
