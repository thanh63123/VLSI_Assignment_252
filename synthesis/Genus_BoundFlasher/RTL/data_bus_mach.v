
module data_bus_mach    (
    clk,
    reset,
    read,
    write,
    write_h,
    address,
    data_in,
    data_out,
    pad_data_in,
    pad_data_out,
    addrs_in,
    read_cycle,
    sync,
    go,
    as,
    done,
    bus_request,
    bus_grant
    );

/*
 *
 *  @(#) data_bus_mach.v 16.1@(#)
 *  2/13/98  
 *
 */

/*
 * Tiny DSP Data Bus interface
 * 
 * Tiny DSP,
 *  mimics some of the instruction set functionality of the
 *  TMS320 DSP family
 *
 * Author:  Meera Balakrishnan
 *          Cadence Design Systems, Inc.
 *          CSD-IC Technology Laboratory
 *
 */

// fetch defines
`include "tdsp.h"
`include "data_bus_mach.h"


// types...
input               clk,            // System clock
                    reset;          // System reset
output              read,           // Read Enable
                    write,          // Write Enable
                    write_h;        // Write Enable Hold
output  [`ADDR:0]   address;        // Address bus
input   [`MSB:0]    data_in;        // Input Data
output  [`MSB:0]    data_out;       // Output Data
input   [`MSB:0]    pad_data_in;    // tdsp pad Input Data
output  [`MSB:0]    pad_data_out;   // tdsp pad Output Data
input   [`ADDR:0]   addrs_in;       // Address
input               read_cycle,     // read/ write mode
                    sync,           // machine sync
                    go;             // cycle_start
output              as,             // address strobe
                    done, 			// machine done
                    bus_request;    // bus request
input               bus_grant;      // bus grant          
wire                clk,            // System clock
                    reset;          // System reset
reg                 read,t_read,    // Read Enable
                    write,t_write,  // Write Enable
                    write_h,t_write_h;// Write Enable Hold
wire    [`ADDR:0]   address;        // Address bus
wire    [`MSB:0]    data_in;        // Input Data
reg     [`MSB:0]    data_out;       // Output Data
wire    [`MSB:0]    pad_data_in;    // tdsp pad Input Data
wire    [`MSB:0]    pad_data_out;   // tdsp pad Output Data
wire    [`ADDR:0]   addrs_in;       // Address
wire                sync;           // machine sync
reg                 as, t_as,       // address strobe
                    done,t_done,    // machine done
                    bus_request,t_bus_request;    // bus request
wire                bus_grant;      // bus grant


reg [2:0] next_state, present_state;

assign #1 pad_data_out = data_in ;
assign #1 address = addrs_in ;


always @( posedge reset or posedge clk)
begin : data_bus_machine_reset
    if (reset)
       begin
         read 		<= 0 ;
         write 		<= 0 ;
         write_h 	<= 0 ;
         data_out 	<= 0 ;
         as 		<= 0 ;
         done 		<= 0 ;
		 bus_request <= 0 ;
		 present_state <= `DATA_BUS_IDLE ;
       end
    else
       begin
          read     		<= t_read ;
          write	    	<= t_write ;
          write_h 	    <= t_write_h;
          as 		    <= t_as;
          done 		    <= t_done;
  		  bus_request   <= t_bus_request;
		  present_state <= next_state ;
          if (present_state == `DATA_OUT)
          begin
             data_out 	<= pad_data_in;
          end
       end
end


//
// expilcit state machine
//
always @(present_state or go or read_cycle or pad_data_in or bus_grant)
begin : data_bus_machine
		t_read 		 = 0 ;
        t_write 	 = 0 ;
        t_write_h 	 = 0 ;
        t_as 		 = 0 ;
		t_bus_request= 0 ;

	case (present_state)
		  `DATA_BUS_IDLE : 
		begin
			t_done 	= 0 ;
           if (go) 
			 begin
            	t_as 			= 1 ;
				t_bus_request	= 1 ;
            	if (read_cycle) 
				  begin
					if (bus_grant)
						next_state 	<= `DATA_READ_CYCLE ;
					else
						next_state 	<= `DATA_BUS_IDLE ;
				  end
				else 
				  begin
					 if (bus_grant)
						next_state 	<= `DATA_WRITE_CYCLE ;
					 else
						next_state 	<= `DATA_BUS_IDLE ;
				  end
			  end
		  else
		    		next_state 	<= `DATA_BUS_IDLE ;
		end

		  `DATA_READ_CYCLE : begin
            		t_as 			= 1 ;
					t_bus_request	= 1 ;
             		t_read 			= 1 ;
					t_done 			= 0 ;
					next_state 		<= `DATA_OUT ;
				end
          `DATA_OUT : begin
            		t_as 			= 1 ;
					t_bus_request	= 1 ;
					t_done 			= 0 ;
					next_state 		<= `DATA_BUS_CLEAR ;
			    end
		   `DATA_BUS_CLEAR : begin
            		t_done 			= 1 ;
					t_as			= 0 ;
					t_bus_request	= 0 ;
					next_state 		<= `DATA_BUS_IDLE ;
				end
       	   `DATA_WRITE_CYCLE : begin
					t_done 			= 0 ;
            		t_as 			= 1 ;
					t_bus_request	= 1 ;                    
					t_write 		= 1 ;
                    t_write_h 		= 1 ;
					next_state  	<= `DATA_WRITE_ASSERT ;
				end
			`DATA_WRITE_ASSERT : begin
					t_done 			= 0 ;
            		t_as 			= 1 ;
					t_bus_request	= 1 ;
                    t_write_h 		= 1 ;					
					next_state 		<= `DATA_WRITE_DEASSERT;
				end
			`DATA_WRITE_DEASSERT : begin
					t_done 			= 0 ;
            		t_as 			= 1 ;
					t_bus_request	= 1 ;
                    next_state		<= `DATA_WRITE_CLEAR ;
				end 
			`DATA_WRITE_CLEAR : begin 
					t_done 			= 1 ;
					t_as			= 0 ;
					t_bus_request	= 0 ;
					next_state 		<= `DATA_BUS_IDLE ;
				end
            default : begin
					next_state <= `DATA_BUS_IDLE ;
			end
	endcase                       								               			                      	end
  
endmodule // data_bus_mach
