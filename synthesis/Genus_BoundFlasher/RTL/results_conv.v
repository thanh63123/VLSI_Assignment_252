
module results_conv (
    clk,
    reset,
    rcc_clk,
    address,
    din,
    digit_clk,
    dout,
    dout_flag,
    test_mode
    ) ;
 
/*
 *
 *  @(#) results_conv.v 15.2@(#)
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
 */

input
    clk,                    // system clock
    reset,                  // system reset
    rcc_clk ;             // data input write strobe

input [3:0]
    address ;               // holding register address bus

input [15:0]
    din ;                   // data input bus

output
    digit_clk ;            // data output write strobe

output [7:0]
    dout ;                  // data output bus

output
    dout_flag ;             // data output change flag

input
    test_mode;		    // test mode control

reg
    digit_clk, 
    dout_flag, 
    go,
    gt,
    ok,
    clear_flag,
    seen_quiet;

reg [2:0]
    low,
    high ;

reg [3:0] state;

reg [7:0]
    dout, 
    out_p1,    // two stage pipeline for digit/ quite framing; I should
    out_p2;    //  have used dout as part of the pipeline to save area...

reg [15:0]
    r697,
//  r770,	// CZS
    r852,
    r941,
    r1200,
//  r1336,	// CZS
    r1477,
    r1633,
    low_mag, 
    high_mag ;

wire [15:0]	r770;		// CZS - break up reg to show declone
reg		r770_enable;
wire [15:0]	r1336;		// CZS - break up reg to show declone
reg		r1336_enable;

`include "results_conv.h"

wire flag_reset = (reset | clear_flag) & !test_mode ;

always @(negedge rcc_clk or posedge flag_reset) 
    if (flag_reset)
        go <= 0 ;
    else
        go <= address[3] ;

always @(negedge rcc_clk)
    case (address[3:0])
    `R_697  : r697  <= din ;
//  `R_770  : r770  <= din ;	// CZS
    `R_852  : r852  <= din ;
    `R_941  : r941  <= din ;
    `R_1200 : r1200 <= din ;
//  `R_1336 : r1336 <= din ;	// CZS
    `R_1477 : r1477 <= din ;
    `R_1633 : r1633 <= din ;
    endcase

// CZS -- break up regs to show decloning...
always @(address)
    begin
    r770_enable = (address[3:0] == `R_770);
    r1336_enable = (address[3:0] == `R_1336);
    end

conv_subreg lower770(.rcc_clk(rcc_clk), .enable(r770_enable),
		  .din(din[7:0]), .dout(r770[7:0]));

conv_subreg upper770(.rcc_clk(rcc_clk), .enable(r770_enable),
		  .din(din[15:8]), .dout(r770[15:8]));

conv_subreg lower1336(.rcc_clk(rcc_clk), .enable(r1336_enable),
		  .din(din[7:0]), .dout(r1336[7:0]));

conv_subreg upper1336(.rcc_clk(rcc_clk), .enable(r1336_enable),
		  .din(din[15:8]), .dout(r1336[15:8]));
// end CZS

always @(posedge reset or posedge clk)
    begin : rcc_machine
    if (reset)
        begin
         digit_clk 	<= 0 ;
         dout_flag 	<= 0 ;
         clear_flag 	<= 0 ;
         seen_quiet 	<= 1 ;
         out_p1 	<= 0 ;
         out_p2 	<= 8'hff ;
	 low		<= 0 ;
	 high 		<= 0 ;
	 low_mag	<= 0 ;
	 high_mag	<= 0 ;
         dout 		<= 8'hff ;
	 state  	<= `IDLE ;
        end
    else
        begin 
   	case (state) 
			`IDLE : begin 
			 if (go)
     		   begin
        		low 		<= 3'b100 ;
        		high 		<= 3'b100 ;
        		clear_flag 	<= 1 ;
        		out_p2 		<= out_p1 ;  // digit pipeline
        		gt_comp( r697, r770, r852, r941 ) ;
				state 	<= `F1 ;
			   end
			else
			 begin
		 		low			<= 0 ;
		 		high 		<= 0 ;
         		clear_flag 	<= 0 ;
         		out_p2 		<= 8'hff ;
				state	<= `IDLE ;
			 end
			end
			`F1 : begin
       			clear_flag 	<= 0 ;
        		if (gt)
            	begin
            		low 	<= {1'b0, `V_697} ;
            		low_mag <= r697 ;
				end
			        gt_comp( r770, r697, r852, r941 ) ;
				state 	<= `F2 ;
			  end
			`F2 : begin
               	if (gt)
            	begin
            		low 	<= {1'b0, `V_770} ;
            		low_mag <= r770 ;
            	end
        		gt_comp( r852, r697, r770, r941 ) ;
				state 	<= `F3 ;
			end
      		`F3 : begin
        		if (gt)
            	begin
            		low 	<= {1'b0, `V_852} ;
            		low_mag <= r852 ;
            	end
        		gt_comp( r941, r697, r770, r852 ) ;
 				state 	<= `F4 ;
			end
			`F4 : begin       
        		if (gt)
            	begin
            		low 	<= {1'b0, `V_941} ;
            		low_mag <= r941 ;
            	end
			    gt_comp( r1200, r1336, r1477, r1633 ) ;
				state 	<= `F5 ;
			end
        	`F5 : begin
        		if (gt)
            	begin
            		high 	 <= {1'b0, `V_1200} ;
            		high_mag <= r1200 ;
            	end
				gt_comp( r1336, r1200, r1477, r1633 ) ;
				state 	 <= `F6 ;
			end
			`F6 : begin
               if (gt)
            	begin
            		high 	 <= {1'b0, `V_1336} ;
            		high_mag <= r1336 ;
            	end
				gt_comp( r1477, r1200, r1336, r1633 ) ;
				state 	 <= `F7 ;
			end
			`F7 : begin
        		if (gt)
            	begin
            		high 	<= {1'b0, `V_1477} ;
            		high_mag<= r1477 ;
            	end
        		gt_comp( r1633, r1200, r1336, r1477 ) ;
				state 	<= `F8 ;
			end
        	`F8 : begin
        		if (gt)
            	begin
            		high 	 <= {1'b0, `V_1633} ;
            		high_mag <= r1633 ;
           		 end
        // did we find both frequencies?
				state 	 <= `CHECK ;
				end		
       		`CHECK : begin
        		if (!low[2] && !high[2])
            	begin
            		check_twist( low_mag, high_mag ) ;
					state <= `OK ;
				end
				else 
				 begin
                	out_p1 	   <= `NO_DIGIT ;
					state <= `CHARACTER ;
                 end
			 end
	
      		`OK : begin
            if (ok)
                begin
                case ({low[1:0], high[1:0]})
                    key_1[3:0]     : out_p1 <= val_key_1 ;
                    key_2[3:0]     : out_p1 <= val_key_2 ;
                    key_3[3:0]     : out_p1 <= val_key_3 ;
                    key_a[3:0]     : out_p1 <= val_key_a ;
                    key_4[3:0]     : out_p1 <= val_key_4 ;
                    key_5[3:0]     : out_p1 <= val_key_5 ;
                    key_6[3:0]     : out_p1 <= val_key_6 ;
                    key_b[3:0]     : out_p1 <= val_key_b ;
                    key_7[3:0]     : out_p1 <= val_key_7 ;
                    key_8[3:0]     : out_p1 <= val_key_8 ;
                    key_9[3:0]     : out_p1 <= val_key_9 ;
                    key_c[3:0]     : out_p1 <= val_key_c ;
                    key_star[3:0]  : out_p1 <= val_key_star ;
                    key_0[3:0]     : out_p1 <= val_key_0 ;
                    key_pound[3:0] : out_p1 <= val_key_pound ;
                    key_d[3:0]     : out_p1 <= val_key_d ;
                endcase
				state 	<= `CHARACTER ;
               end
            else
                begin
                	out_p1 	<= `NO_DIGIT ;
					state 	<= `CHARACTER ;
                end
            end
         // should we output a new digit?
        //  need to see two frames worth for timing...
       	`CHARACTER : begin
        	if (out_p1 == out_p2)
            begin
            // quiet tone?
            	if (out_p2 == 0)
                 begin
                	seen_quiet 	<= 1 ;
                    state	<= `IDLE ;
                 end
           		else
                 begin
                	if (seen_quiet)
                      begin
                         seen_quiet 	<= 0 ;
                         state	<= `P1 ;
					  end 
                    else
                      state	<= `P1 ;
				 end
			end
            else
                state   <= `IDLE ;
		end
            // toggle msb for each new char...
		`P1 : begin 
                     dout 		<= { 1'b0, out_p2[6:0] } ;
                     dout_flag 	<= ~dout_flag ;
 				 	 state	<= `P2 ;

			  end 
    	`P2 : begin 
                     digit_clk <= 1 ;
 				     state	<= `P3 ;
			  end
		`P3 : begin
                     digit_clk <= 0 ;
 					 state	<= `IDLE ;

                end
		default : 	state 	<= `IDLE ;
		endcase
	 end                                 
    end // rcc_machine

//
// 16 bit "greater-than" comparision
// we'll build our own pipelined comparitor here
// (we want to force resource sharring...)
//
task gt_comp ;
    input [15:0]
        opa,
        opb,
        opc,
        opd ;

    reg [16:0]
        cmpb,
        cmpc,
        cmpd ;

    begin

         cmpb = opb - opa ;
         cmpc = opc - opa ;
         cmpd = opd - opa ;
   
         gt = cmpb[16] & cmpc[16] & cmpd[16] ;
    end
endtask

//
// check the twist between the frequencies,
// constrain to +/- 12dB for the now...
//
task check_twist ;
    input [15:0]
        mag_low,
        mag_high ;

    reg [16:0]
        cmpf,
        cmpr ;
    begin

    // find if larger magnitude is in low or high frequency group
            	cmpf = mag_low - mag_high ;
           if (cmpf[16])   // high freq is larger
            begin
                cmpf = mag_low - {2'b0, mag_high[15:2]} ;
                cmpr = mag_high - mag_low ;
            end
           else            // low freq is larger
            begin
                cmpf = mag_high - {2'b0, mag_low[15:2]} ;
                cmpr = mag_low - mag_high ;
            end
   
        	ok = (~cmpf[16]) && (~cmpr[16]) ;
    end
endtask

endmodule // results_conv_exp
