module tdsp_core_mach(
    samp_bio,
    samp_int,
    phi_1,
    phi_2,
    phi_3,
    phi_4,
    phi_5,
    phi_6,
    reset,
    clk,
    bus_request,
    bus_grant,
    bio,
    int
);

output 
    samp_bio,
    samp_int,
    phi_1,
    phi_2,
    phi_3,
    phi_4,
    phi_5,
    phi_6;

input
    reset,
    clk,
    bus_request,
    bus_grant,
    bio,
    int;

reg [2:0] tdsp_state;
reg phi_1,
    phi_2,
    phi_3,
    phi_4,
    phi_5,
    phi_6,
    samp_bio,
    samp_int;

`include "tdsp.h"

//
// synchronize bio and int inputs
//
always @(posedge clk)
    begin
    samp_bio <= bio ;
    samp_int <= int ;
    end

// machine "main" fsm
always @(posedge clk or posedge reset)
    begin : machine
    if (reset)
		begin
           phi_1 <= 0;
           phi_2 <= 0;
           phi_3 <= 0;
           phi_4 <= 0;
           phi_5 <= 0;
           phi_6 <= 0;
		   tdsp_state <= `TDSP_PHI_1;
		end
    else
	begin
		case (tdsp_state)
			`TDSP_PHI_1 : begin
     	     // machine cycle phase 1
   	            phi_1 <= 1 ;
   	            phi_2 <= 0 ;
   	            phi_3 <= 0 ;
   	            phi_4 <= 0 ;
   	            phi_5 <= 0 ;
	            phi_6 <= 0 ;
		        tdsp_state <= `TDSP_PHI_2;
		     end
			`TDSP_PHI_2 : begin
             // machine cycle phase 2
                phi_1 <= 0 ;
                phi_2 <= 1 ;
                phi_3 <= 0 ;
                phi_4 <= 0 ;
                phi_5 <= 0 ;
                phi_6 <= 0 ;
		        tdsp_state <= `TDSP_PHI_3;
             end
			`TDSP_PHI_3 : begin
                // machine cycle phase 3
                if ((!bus_request) || (bus_request && bus_grant))
                   begin
                   // no wait
                   phi_1 <= 0 ;
                   phi_2 <= 0 ;
                   phi_3 <= 1 ;
                   phi_4 <= 0 ;
                   phi_5 <= 0 ;
                   phi_6 <= 0 ;
		           tdsp_state <= `TDSP_PHI_4;
                   end
               else if (bus_request && !bus_grant)
                   begin
                   // wait state generator
                      phi_1 <= 0 ;
                      phi_2 <= 0 ;
                      phi_3 <= 0 ;
                      phi_4 <= 0 ;
                      phi_5 <= 0 ;
                      phi_6 <= 0 ;
		              tdsp_state <= `TDSP_WAIT;
				   end
			   end
			`TDSP_WAIT : begin
                if (bus_request && bus_grant)
				   begin
		              tdsp_state <= `TDSP_RECOVERY;
				   end
				else
				   begin
		              tdsp_state <= `TDSP_WAIT;
				   end
			   end
			`TDSP_RECOVERY : begin
                    // cycle recovery
                    phi_1 <= 0 ;
                    phi_2 <= 0 ;
                    phi_3 <= 1 ;
                    phi_4 <= 0 ;
                    phi_5 <= 0 ;
                    phi_6 <= 0 ;
		            tdsp_state <= `TDSP_PHI_4;
                end
			`TDSP_PHI_4 : begin
            // machine cycle phase 4
               phi_1 <= 0 ;
               phi_2 <= 0 ;
               phi_3 <= 0 ;
               phi_4 <= 1 ;
               phi_5 <= 0 ;
               phi_6 <= 0 ;
		       tdsp_state <= `TDSP_PHI_5;
			end
			`TDSP_PHI_5 : begin
            // machine cycle phase 5
               phi_1 <= 0 ;
               phi_2 <= 0 ;
               phi_3 <= 0 ;
               phi_4 <= 0 ;
               phi_5 <= 1 ;
               phi_6 <= 0 ;
		       tdsp_state <= `TDSP_PHI_6;
			end
			`TDSP_PHI_6 : begin
            // machine cycle phase 6
               phi_1 <= 0 ;
               phi_2 <= 0 ;
               phi_3 <= 0 ;
               phi_4 <= 0 ;
               phi_5 <= 0 ;
               phi_6 <= 1 ;
		       tdsp_state <= `TDSP_PHI_1;
			end
			default : begin
               phi_1 <= 0 ;
               phi_2 <= 0 ;
               phi_3 <= 0 ;
               phi_4 <= 0 ;
               phi_5 <= 0 ;
               phi_6 <= 0 ;
		       tdsp_state <= `TDSP_PHI_1;
			end
		endcase
    end // else
end // always



endmodule
