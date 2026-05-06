
module port_bus_mach    (
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
    done
    );

/*
 *
 *  @(#) port_bus_mach.v 16.1@(#)
 *  2/13/98   *
 */

/*
 * Tiny DSP Port Bus interface
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
`include "port_bus_mach.h"

// types...
input               clk,            // System clock
                    reset;          // System reset
output              read,           // Read Enable
                    write,          // Write Enable
                    write_h;        // Write Enable Hold
output  [`PORT:0]   address;        // Address bus
input   [`MSB:0]    data_in;        // Input Data
output  [`MSB:0]    data_out;       // Output Data
input   [`MSB:0]    pad_data_in;    // tdsp pad Input Data
output  [`MSB:0]    pad_data_out;   // tdsp pad Output Data
input   [`PORT:0]   addrs_in;       // Address
input               read_cycle,     // read/ write mode
                    sync,           // machine sync
                    go;             // cycle_start
output              as,             // address strobe
                    done;           // machine done
wire                clk,            // System clock
                    reset;          // System reset
reg                 read, t_read,   // Read Enable
                    write, t_write, // Write Enable
                    write_h,t_write_h;// Write Enable Hold
wire    [`PORT:0]   address;        // Address bus
wire    [`MSB:0]    data_in;        // Input Data
reg     [`MSB:0]    data_out;       // Output Data
wire    [`MSB:0]    pad_data_in;    // tdsp pad Input Data
wire    [`MSB:0]    pad_data_out;   // tdsp pad Output Data
wire    [`PORT:0]   addrs_in;       // Address
wire                sync;           // machine sync
reg                 as, t_as,        // address strobe
                    done,t_done;    // machine done


reg[2:0] present_state, next_state;


 assign #1 pad_data_out = data_in ;
 assign #1 address = addrs_in ;

//
// reset machine
//
always @( posedge reset or posedge clk)
begin : port_bus_machine_reset
    if (reset)
       begin
         read 		<= 0 ;
         write 		<= 0 ;
         write_h 	<= 0 ;
         data_out 	<= 0 ;
         as 		<= 0 ;
         done 		<= 0 ;
		 present_state <= `PORT_BUS_IDLE ;
       end
    else
       begin
        read 		<= t_read ;
        write		<= t_write ;
        write_h 	<= t_write_h;
        as 			<= t_as;
        done 		<= t_done;
		present_state<= next_state ;
        if (present_state == `PORT_DATA_OUT)
        begin
          data_out 	<= pad_data_in;
        end
       end
end

//
// explicit state machine
//
always @(present_state or go or read_cycle or pad_data_in)
begin : port_bus_machine

		t_read 		= 0 ;
        t_write 	= 0 ;
        t_write_h 	= 0 ;
        t_as 		= 0 ;
	
	case (present_state)
		`PORT_BUS_IDLE : begin
        	t_done = 0 ;
         if (go) 
			 begin
            	t_as = 1 ;
            	if (read_cycle)
					next_state 	<= `PORT_READ_CYCLE ;
				else 
					next_state 	<= `PORT_WRITE_CYCLE ;
			  end
		  else
		    		next_state 	<= `PORT_BUS_IDLE ;
		end

		  `PORT_READ_CYCLE : begin
                    t_as 		= 1 ;
             		t_read 		= 1 ;
					t_done 		= 0 ;
					next_state 	<= `PORT_DATA_OUT ;
				end
          `PORT_DATA_OUT : begin
            		t_as 		= 1 ;
					t_done 		= 0 ;
					next_state 	<= `PORT_BUS_CLEAR ;
			    end
		   `PORT_BUS_CLEAR : begin
				 	t_as 		= 0 ;
            		t_done 		= 1 ;
					next_state 	<= `PORT_BUS_IDLE ;
				end
       	   `PORT_WRITE_CYCLE : begin
					t_done 		= 0 ;
            		t_as 		= 1 ;
                    t_write 	= 1 ;
                    t_write_h 	= 1 ;
					next_state  <= `PORT_WRITE_ASSERT ;
				end
			`PORT_WRITE_ASSERT : begin
					t_done 		= 0 ;
            		t_as 		= 1 ;
                    t_write 	= 1 ;
                    t_write_h 	= 1 ;
					next_state 	<= `PORT_WRITE_DEASSERT;
				end
			`PORT_WRITE_DEASSERT : begin
 					t_done	 	= 0 ;
            		t_as 		= 1 ;
                    t_write_h 	= 1 ;
                    next_state	<= `PORT_WRITE_CLEAR ;
				end 
			`PORT_WRITE_CLEAR : begin 
					t_as 		= 0 ;
            		t_done 		= 1 ;
					next_state 	<= `PORT_BUS_IDLE ;
				end
            default : begin
					next_state <= `PORT_BUS_IDLE ;
			end
	endcase                       								               			                      	end

endmodule // port_bus_mach
