
module tdsp_ds_cs (
    clk,
    test_mode,
    address,
    write,
    read,
    reset,
    as,
    port_as,
    port_address,
    port_write,
    port_read,
    top_buf_flag,
    t_write_ds,
    t_read_ds,
    t_write_d,
    t_read_d,
    t_write_rcc,
    t_address_ds,
    bus_request_in,
    bus_grant_in,
    bus_request_out,
    bus_grant_out
    ) ;
 
/*
 *
 *  @(#) tdsp_ds_cs.v 15.1@(#)
 *  4/1/96  09:10:07
 *
 */

/*
 *
 * TDSP Data Bus Decode logic
 *
 * Author:  Mark A. Indovina
 *          Cadence Design Systems, Inc.
 *          CSD-IC Technology Laboratory
 *
 */

input [7:0]
    address ;

input [2:0]
    port_address ;

input
    clk,
    test_mode,
    write,
    read,
    reset,
    as,
    port_as,
    port_write,
    port_read,
    top_buf_flag,
    bus_request_in,
    bus_grant_in ;

output
    t_write_ds,
    t_read_ds,
    t_write_d,
    t_read_d,
    t_write_rcc,
    bus_request_out,
    bus_grant_out ;

output [7:0]
    t_address_ds ;

reg
    t_sel_7,
    t_bit_7 ;

/*
    memory map:
    (data space)
    0x00 - 0xff -> tdsp program memory (256 bytes)
    0x00 - 0x7f -> data sample memory (128 words)
    0x80 - 0xdf -> data scratch memory (96 words)
    0xe0 - 0xef -> results character conversion (16 words)
    (port space)
    0x00 - 0x07 -> misc. control (8 words)
        0x00    -> select dma to generate address bit 7
        0x01    -> select tdsp to generate address bit 7
        0x02    -> tdsp select lower data sample buffer
        0x03    -> tdsp select upper data sample buffer
 */

/*
 * bus request/ grant "steering" logic
 */

wire
    bus_request_out = (address[7] == 1'b0) & as & bus_request_in ;

wire
    bus_grant_out = ((address[7] == 1'b0) & bus_request_in) ? bus_grant_in : 1'b1 ;

wire
    t_write_ds = (address[7] == 1'b0) & as & write ;

wire
    t_read_ds = (address[7] == 1'b0) & as & read ;

wire
    t_write_d = ((address[7:6] == 2'b10) | (address[7:5] == 3'b110)) & as & write ;

wire
    t_read_d = ((address[7:6] == 2'b10) | (address[7:5] == 3'b110)) & as & read ;

wire
    t_write_rcc = (address[7:4] == 4'b1110) & as & write ;

/*
 * select bit for tdsp or dma control of address bit 7
 */

wire sel_ds_address = (port_address[2:1] == 2'b00) & port_as & write ;
wire m_sel_ds_address = test_mode ? clk : sel_ds_address ;


always @(posedge m_sel_ds_address or posedge reset)
    if (reset)
        t_sel_7 <= 0 ;
    else    
        t_sel_7 <= port_address[0] ;

/*
 * strobe logic for tdsp to control address bit 7
 */

wire strobe_ds_address = (port_address[2:1] == 2'b01) & port_as & write ;
wire m_strobe_ds_address = test_mode ? clk : strobe_ds_address ;

always @(posedge m_strobe_ds_address or posedge reset)
    if (reset)
        t_bit_7 <= 0 ;
    else
        t_bit_7 <= port_address[0] ;

/*
 * address bit 7 multiplexor, need to invert top_buf_flag since it reflects
 *  which block the dma controller is currently writing to
 */

wire
    sel_7 = t_sel_7 ? t_bit_7 : ~top_buf_flag ;

/*
 * final data sample ram address address
 */

wire [7:0]
    t_address_ds = { sel_7, address[6:0]} ;

endmodule // tdsp_ds_cs
