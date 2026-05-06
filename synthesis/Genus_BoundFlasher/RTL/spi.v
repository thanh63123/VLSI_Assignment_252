
module spi (
    spi_clk,
    m_spi_clk,
    spi_fs,
    spi_data,
    clk,
    reset,
    read,
    dflag,
    dout,
    test_mode
    ) ;
 
/*
 *
 *  @(#) spi.v 16.2@(#)
 *  5/31/96  15:23:51
 *
 */

/*
 *
 * Serial Port Interface (SPI)
 *
 * Author:  Mark A. Indovina
 *          Cadence Design Systems, Inc.
 *          CSD-IC Technology Laboratory
 *
 */

input
    spi_clk,            // serial port interface clock
    m_spi_clk,          // muxed serial port interface clock
    spi_fs,             // serial port frame sync pulse
    spi_data,           // serial port data input
    clk,                // system clock
    reset,              // system reset
    read ;              // read parallel data holding register

output
    dflag ;             // parallel data holding register full flag

output [7:0]
    dout ;              // parallel data holding register

input
    test_mode;

`define SPI_IDLE        3'b001
`define SPI_BYTE_START  3'b000
`define SPI_BYTE        3'b010
`define SPI_TRANS_BYTE  3'b011
`define SPI_TRANSFER    3'b111

reg
    dflag;

reg [2:0]
    next_state,
    present_state;

reg [3:0]
    bit_cnt ;

reg [7:0]
    spi_sr,
    dout ;

wire not_full = (bit_cnt != 8) ;
wire full = ~not_full ;

//
// bit counter
//
wire bit_cnt_reset = reset | spi_fs ;
//wire bit_cnt_reset = (reset | spi_fs) & !test_mode;

always @(posedge m_spi_clk or posedge bit_cnt_reset)
    if (bit_cnt_reset)
        bit_cnt <= 0 ;
    else if (not_full)
        bit_cnt <= bit_cnt + 1 ;

//
// shift register
//
always @(posedge m_spi_clk)
    if (not_full)
        spi_sr <= {spi_sr[6:0], spi_data} ;

//
// next state logic
//
always @( bit_cnt or spi_clk or spi_fs or not_full or full or present_state )
    begin : next_state_generation
        case(present_state)
            `SPI_IDLE   : begin
                if (spi_fs && !spi_clk)
                    next_state <= `SPI_BYTE_START ;
                else
                    next_state <= `SPI_IDLE ;
                end
            `SPI_BYTE_START : begin
                if (spi_fs && !spi_clk)
                    next_state <= `SPI_BYTE ;
                else
                    next_state <= `SPI_IDLE ;
                end
            `SPI_BYTE   : begin
                if (not_full && !spi_clk)
                    next_state <= `SPI_BYTE ;
                else
                    next_state <= `SPI_TRANS_BYTE ;
                end
            `SPI_TRANS_BYTE : begin
                if (full && !spi_clk)
                    next_state <= `SPI_TRANSFER ;
                else
                    next_state <= `SPI_TRANS_BYTE ;
                end
            `SPI_TRANSFER   : begin
                next_state <= `SPI_IDLE ;
                end
            default : begin
                next_state <= `SPI_IDLE ;
                end
        endcase
    end

//
// "present state" state register
//
always @(posedge clk or posedge reset)
	if (reset)
		begin
        present_state <= `SPI_IDLE;
		end
	else
    	begin : spi_exp_machine
    	present_state <= next_state;
    	end

//
// transfer shifted data input to output holding register
//
always @(posedge clk)
    if (present_state == `SPI_TRANSFER)
        dout <= spi_sr ;

wire dflag_reset = (reset | read) & !test_mode ;

//
// data out flag
//
always @(posedge clk or posedge dflag_reset)
    if (dflag_reset)
        dflag <= 0 ;
    else if (present_state == `SPI_TRANSFER)
        dflag <= 1 ;

endmodule // spi
