// Coding the DMA Explicitly 

module dma (
    clk,
    reset,
    dflag,
    bgrant,
    read_spi,
    breq,
    a,
    as,
    write,
    top_buf_flag
    ) ;

input
    clk,                    // system clock
    reset,                  // system reset
    dflag,                  // spi data out flag
    bgrant ;                // data sample bus grant

output
    read_spi,               // read from spi controller
    breq,                   // data sample bus requeset
    as,                     // address strobe
    write,                  // write cycle flag
    top_buf_flag ;          // using top buffer flag

output [7:0]
    a ;                     // address bus

reg 
    read_spi, t_read_spi,            
    breq,  t_breq,                 
    as, t_as,                    
    write, t_write,                
    top_buf_flag, t_top_buf_flag ; 
        
reg [7:0] a, t_a ;
reg [3:0] present_state, next_state ;


//including the state encoding file

`include "dma.h"



always @ (posedge reset or posedge clk) 
// asynchronous reset operation 
 if (reset) 
    begin 
	 present_state <= `DMA_IDLE;
   	 read_spi      <= 0;
	 breq 	       <= 0;
	 as 	       <= 0;
	 write	       <= 0;
	 top_buf_flag  <= 0;
	 a 			   <= 0;
   end
// "present state" state register	
  else 
   begin
    present_state <= next_state ;
	read_spi 	  <= t_read_spi ;
	breq     	  <= t_breq ;
	as		 	  <= t_as ;
	write		  <= t_write ;
	top_buf_flag  <= t_top_buf_flag ;
	a			  <= t_a ;
   end

  
always @ (present_state or dflag or bgrant or a)
begin : dma_machine
 	 t_read_spi 	<= 0;
	 t_breq 		<= 0;
	 t_as 			<= 0;
	 t_write		<= 0;
	 t_top_buf_flag <= 0;
     t_a            <= a;

 case (present_state)
	`DMA_IDLE : 
            begin
              if (dflag)
                 next_state <= `DMA_DFLAG;
              else
                 next_state <= `DMA_IDLE;
            end
	`DMA_DFLAG : 
            begin
              t_breq     <= 1 ;
              if (bgrant)
                 next_state <= `DMA_BGRANT;
              else 
                 next_state <= `DMA_DFLAG ;
            end
	`DMA_BGRANT : 
            begin 
               t_breq     <= 1 ;
               t_read_spi <= 1;
               t_as	   <= 1;
               next_state <= `DMA_WRITE1;
            end
	`DMA_WRITE1: 
            begin 
               t_breq     <= 1 ;
               t_write    <= 1;
               t_read_spi <= 1;
               t_as	   <= 1;
               next_state <= `DMA_WRITE2;
			end
	`DMA_WRITE2: 
            begin
               t_breq     <= 1 ;
               t_write	  <= 0;
               t_read_spi <= 1;
               t_as	   <= 1;
               next_state <= `DMA_WRITE_CLEAR ;
			end
	`DMA_WRITE_CLEAR : begin
                t_breq     <= 0;
                t_read_spi <= 0;
                t_as	   <= 0;
                next_state <= `DMA_ADD_INCR ;
			end
	`DMA_ADD_INCR : 
            begin
                t_a        <= a + 1 ;
                next_state <= `DMA_TOP_BUF_FLAG ;
			end
	`DMA_TOP_BUF_FLAG : 
            begin
	  	if (a[7]) begin
				t_top_buf_flag <= 1;
				next_state <= `DMA_IDLE ;
			end
		else
			begin
				t_top_buf_flag <= 0;
				next_state <= `DMA_IDLE ;
			end
		end
	default : 
            begin
                next_state <= `DMA_IDLE ;
			end
	endcase

end
endmodule

