
module tdsp_core    (
    clk,
    reset,
    as,
    read,
    write,
    write_h,
    address,
    t_data_in,
    t_data_out,
    p_as,
    p_read,
    p_write,
    p_write_h,
    p_address,
    rom_data_in,
    rom_data_out,
    bus_grant,
    bus_request,
    port_address,
    port_pad_data_in,
    port_pad_data_out,
    port_as,
    port_read,
    port_write,
    port_write_h,
    t_sdi,
    t_sdo,
    bio,
    int
    );

/*
 *
 *  @(#) tdsp_core.v 15.3@(#)
 *  4/3/96  10:30:58
 *
 */

/*
 * Tiny DSP
 *  -- the Web friendly DSP
 *
 * Tiny DSP,
 *  mimics some of the instruction set functionality of the
 *  TMS320 DSP family
 *
 * Author:  Mark A. Indovina
 *          Cadence Design Systems, Inc.
 *          CSD-IC Technology Laboratory
 *
 */

// fetch defines
`include "tdsp.h"

// types...
input               clk,            // System clock
                    reset;          // System reset
output              as,             // address strobe
                    read,           // Read Enable
                    write,          // Write Enable
                    write_h;        // Write Enable Hold
output  [`ADDR:0]   address;        // Data memory address bus
input   [`MSB:0]    t_data_in;      // Data bus input
output  [`MSB:0]    t_data_out;     // Data bus output
output              p_as,           // Program address strobe
                    p_read,         // Program memory Read Enable
                    p_write,        // Program memory Write Enable
                    p_write_h;      // Program memory Write Enable Hold
output  [`P_ADDR:0] p_address;      // Program memory address bus
input   [`MSB:0]    rom_data_in;    // Program data bus input
output  [`MSB:0]    rom_data_out;   // Program data bus output
input               bus_grant;      // Data bus, bus grant
output              bus_request;    // Data bus, bus request
output  [`PORT:0]   port_address;   // Port Data bus, bus request
input   [`MSB:0]    port_pad_data_in;       // Port Data bus input
output  [`MSB:0]    port_pad_data_out;      // Port Data bus output
output              port_as,        // Port address strobe
                    port_read,      // Port read strobe
                    port_write,     // Port write strobe
                    port_write_h;   // Port write strobe hold
input               bio,            // Branch I/O input
                    int;            // interrupt input
input   [2:0]       t_sdi;
output  [2:0]       t_sdo;
wire    [`HMSB:0]   opa,            // alu, multiply operand a
                    opb;            // alu, multiply operand b

wire    [`ADDR:0]   addrs_in;       // Data bus mach. address input
wire    [`P_ADDR:0] p_addrs_in;     // Program bus mach address input
wire    [`PORT:0]   port_addrs_in;  // Port bus mach address input
wire    [`ACC:0]    alu_result;     // Accumulator Result output
wire    [`HMSB:0]   mpy_result;     // Multiplier Result output
wire    [`ADDR:0]   address;        // Data memory address Bus
wire    [`MSB:0]    t_data_in,      // Data bus input
                    t_data_out,     // Data bus output
                    data_out;       // Data data holding register
wire    [`P_ADDR:0] p_address;      // Program memory address Bus
wire    [`MSB:0]    rom_data_in,    // Program data bus input
                    rom_data_out,   // Program data bus output
                    p_data_in,      // Program data bus mach data input
                    p_data_out;     // Program data holding register
wire    [`PORT:0]   port_address;   // Port memory address Bus
wire    [`MSB:0]    port_pad_data_in,       // Port Data bus input
                    port_pad_data_out,      // Port Data bus output
                    port_data_in,   // Port data bus mach data input
                    port_data_out;  // Port data holding register
wire    [`MSB:0]    alu_out,        // Output from ALU function
                    mdr,            // Memory Data Register
                    pdr,            // Port Data Register
                    ar;             // Selected Auxiliary Register
wire    [`ADDR:0]   res_adr;        // Resolved data address
wire    [`ADDR:0]   res_port_adr;   // Resolved port address
wire    [`HMSB:0]   se_shift_mdr;   // sign extended, shifted data
wire    [`HMSB:0]   ze_mdr;         // zero paded mdr
wire    [`MSB:0]    ir,             // Current Execute Instruction register
                    decode,         // Current Decode Instruction register
                    pc,             // Program counter
                    ar0,            // Auxiliary Register 0
                    ar1;            // Auxiliary Register 1
wire    [`ACC:0]    acc;            // Accumulator Register
wire    [`HMSB:0]   p;              // Multiply product Register
wire    [`MSB:0]    top;            // Multiply temporary operand
wire    [`ALUCMD:0] alu_cmd;        // Accumulator Command opcode
wire    [`OPACMD:0] sel_op_a;       // Accumulator Command opcode
wire    [`OPBCMD:0] sel_op_b;       // Accumulator Command opcode
wire    [`MSB:0]    data_in;
wire                phi_1,
                    phi_2,
                    phi_3,
                    phi_4,
                    phi_5,
                    phi_6;
wire                bus_request,    // Data bus, bus request
                    bus_grant,      // Data bus, bus grant
                    done,           // data bus mach. cycle done
                    p_done,         // program bus mach. cycle done
                    port_done,      // port bus mach. cycle done
                    as,             // data address strobe
                    p_as,           // program address strobe
                    port_as,        // port address strobe
                    fetch_branch,   // update pc with branch address flag
                    branch_stall,   // branch instruction stall pipeline flag
                    pc_acc,         // use accum for pc flag
                    dmov_inc,       // dmov cycle increment data address
                    dp,             // data page pointer
                    decode_skip_one,    // decode_i skip one cycle
                    dec_read_prog,      // program bus read cycle
                    dec_go_prog,        // enable program bus cycle flag
                    dec_read_data,      // data bus read cycle
                    dec_go_data,        // enable data bus cycle flag
                    dec_read_port,      // port bus read cycle
                    dec_go_port,        // enable port bus cycle flag
                    enc_read_prog,      // program bus read cycle
                    enc_go_prog,        // enable program bus cycle flag
                    enc_read_data,      // data bus read cycle
                    enc_go_data,        // enable data bus cycle flag
                    enc_read_port,      // port bus read cycle
                    enc_go_port,        // enable port bus cycle flag
                    read_prog,      // program bus read cycle
                    go_prog,        // enable program bus cycle flag
                    read_data,      // data bus read cycle
                    go_data,        // enable data bus cycle flag
                    read_port,      // port bus read cycle
                    go_port,        // enable port bus cycle flag
                    arp,            // Auxilary register pointer
                    gez,            // ACC >= 0
                    gz,             // ACC > 0
                    nz,             // ACC != 0
                    z,              // ACC == 0
                    lz,             // ACC < 0
                    lez,            // ACC <= 0
                    ov,             // ACC Overflow
                    arnz,           // AR != 0
                    bioz,           // BIO == 0
                    ovm,            // overflow mode
                    inst_tbl,       // current instruction TBLR/W flag
                    inst_in,        // current instruction IN flag
                    inst_sar0,      // current instruction SAR AR0 flag
                    inst_sar1;      // current instruction SAR AR1 flag


tdsp_core_glue TDSP_CORE_GLUE_INST(
    .addrs_in(addrs_in),
    .data_in(data_in),
    .p_addrs_in(p_addrs_in),
    .p_data_in(p_data_in),
    .port_addrs_in(port_addrs_in),
    .port_data_in(port_data_in),
    .ar(ar),
    .res_adr(res_adr),
    .res_port_adr(res_port_adr),
    .se_shift_mdr(se_shift_mdr),
    .ze_mdr(ze_mdr),
    .alu_out(alu_out),
    .go_prog(go_prog),
    .read_prog(read_prog),
    .go_data(go_data),
    .read_data(read_data),
    .go_port(go_port),
    .read_port(read_port),
    .pc_acc(pc_acc),
    .arp(arp),
    .ar1(ar1),
    .ar0(ar0),
    .dp(dp),
    .ir(ir),
    .pdr(pdr),
    .mdr(mdr),
    .opa(opa),
    .opb(opb),
    .acc(acc),
    .pc(pc),
    .data_out(data_out),
    .p_data_out(p_data_out),
    .port_data_out(port_data_out),
    .top(top),
    .p(p),
    .alu_cmd(alu_cmd),
    .sel_op_a(sel_op_a),
    .sel_op_b(sel_op_b),
    .dec_go_prog(dec_go_prog),
    .enc_go_prog(enc_go_prog),
    .dec_read_prog(dec_read_prog),
    .enc_read_prog(enc_read_prog),
    .dec_go_data(dec_go_data),
    .enc_go_data(enc_go_data),
    .dec_read_data(dec_read_data),
    .enc_read_data(enc_read_data),
    .dec_go_port(dec_go_port),
    .enc_go_port(enc_go_port),
    .dec_read_port(dec_read_port),
    .enc_read_port(enc_read_port),
    .dmov_inc(dmov_inc)
);

//
// Main TDSP State Machine
//
tdsp_core_mach TDSP_CORE_MACH_INST(
    .samp_bio(samp_bio),
    .samp_int(samp_int),
    .phi_1(phi_1),
    .phi_2(phi_2),
    .phi_3(phi_3),
    .phi_4(phi_4),
    .phi_5(phi_5),
    .phi_6(phi_6),
    .reset(reset),
    .clk(clk),
    .bus_request(bus_request),
    .bus_grant(bus_grant),
    .bio(bio),
    .int(int)
);


//
// decode instruction
//
decode_i    DECODE_INST (
    .clk(clk),
    .reset(reset),
    .phi_1(phi_1),
    .phi_2(phi_2),
    .phi_3(phi_3),
    .phi_4(phi_4),
    .phi_5(phi_5),
    .phi_6(phi_6),
    .decode(decode),
    .p_data_out(p_data_out),
    .ir(ir),
    .skip_one(skip_one),
    .read_prog(dec_read_prog),
    .go_prog(dec_go_prog),
    .read_data(dec_read_data),
    .go_data(dec_go_data),
    .read_port(dec_read_port),
    .go_port(dec_go_port),
    .decode_skip_one(decode_skip_one)
    );

//
// execute instruction
//
execute_i   EXECUTE_INST    (
    .clk(clk),
    .reset(reset),
    .phi_1(phi_1),
    .phi_2(phi_2),
    .phi_3(phi_3),
    .phi_4(phi_4),
    .phi_5(phi_5),
    .phi_6(phi_6),
    .decode_skip_one(decode_skip_one),
    .gez(gez),
    .gz(gz),
    .nz(nz),
    .z(z),
    .lz(lz),
    .lez(lez),
    .ov(ov),
    .arnz(arnz),
    .bioz(bioz),
    .alu_result(alu_result),
    .mpy_result(mpy_result),
    .mdr(mdr),
    .pdr(pdr),
    .ir(ir),
    .decode(decode),
    .ar(ar),
    .skip_one(skip_one),
    .fetch_branch(fetch_branch),
    .branch_stall(branch_stall),
    .pc_acc(pc_acc),
    .dmov_inc(dmov_inc),
    .dp(dp),
    .arp(arp),
    .ar0(ar0),
    .ar1(ar1),
    .pc(pc),
    .acc(acc),
    .p(p),
    .top(top),
    .alu_cmd(alu_cmd),
    .sel_op_a(sel_op_a),
    .sel_op_b(sel_op_b),
    .read_prog(enc_read_prog),
    .go_prog(enc_go_prog),
    .read_data(enc_read_data),
    .go_data(enc_go_data),
    .read_port(enc_read_port),
    .go_port(enc_go_port),
    .ovm(ovm)
    );

prog_bus_mach   PROG_BUS_MACH_INST (
    .clk(clk),
    .reset(reset),
    .read(p_read),
    .write(p_write),
    .write_h(p_write_h),
    .address(p_address),
    .pad_data_in(rom_data_in),
    .pad_data_out(rom_data_out),
    .data_in(p_data_in),
    .data_out(p_data_out),
    .addrs_in(p_addrs_in),
    .read_cycle(read_prog),
    .sync(phi_6),
    .go(go_prog),
    .as(p_as),
    .done(p_done)
    );

data_bus_mach   DATA_BUS_MACH_INST (
    .clk(clk),
    .reset(reset),
    .read(read),
    .write(write),
    .write_h(write_h),
    .address(address),
    .pad_data_in(t_data_in),
    .pad_data_out(t_data_out),
    .data_in(data_in),
    .data_out(data_out),
    .addrs_in(addrs_in),
    .read_cycle(read_data),
    .sync(phi_6),
    .go(go_data),
    .as(as),
    .done(done),
    .bus_request(bus_request),
    .bus_grant(bus_grant)
    );

port_bus_mach   PORT_BUS_MACH_INST (
    .clk(clk),
    .reset(reset),
    .read(port_read),
    .write(port_write),
    .write_h(port_write_h),
    .address(port_address),
    .pad_data_in(port_pad_data_in),
    .pad_data_out(port_pad_data_out),
    .data_in(port_data_in),
    .data_out(port_data_out),
    .addrs_in(port_addrs_in),
    .read_cycle(read_port),
    .sync(phi_6),
    .go(go_port),
    .as(port_as),
    .done(port_done)
    );

alu_32  ALU_32_INST (
    .ovm(ovm),
    .op_a(opa),
    .op_b(opb),
    .result(alu_result),
    .cmd(alu_cmd)
    );

accum_stat  ACCUM_STAT_INST (
    .accum(acc),
    .ar(ar),
    .bio(samp_bio),
    .gez(gez),
    .gz(gz),
    .nz(nz),
    .z(z),
    .lz(lz),
    .lez(lez),
    .ov(ov),
    .arnz(arnz),
    .bioz(bioz)
    );

mult_32 MPY_32_INST (
    .ovm(ovm),
    .op_a(opa[`ACCL]),
    .op_b(opb[`ACCL]),
    .result(mpy_result)
    );

endmodule // tdsp_core
