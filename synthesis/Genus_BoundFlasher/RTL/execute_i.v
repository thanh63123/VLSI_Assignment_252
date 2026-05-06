
module execute_i    (
    clk,
    reset,
    phi_1,
    phi_2,
    phi_3,
    phi_4,
    phi_5,
    phi_6,
    decode_skip_one,
    gez,
    gz,
    nz,
    z,
    lz,
    lez,
    ov,
    arnz,
    bioz,
    alu_result,
    mpy_result,
    mdr,
    pdr,
    ir,
    decode,
    ar,
    skip_one,
    fetch_branch,
    branch_stall,
    pc_acc,
    dmov_inc,
    dp,
    arp,
    ar0,
    ar1,
    pc,
    acc,
    p,
    top,
    alu_cmd,
    sel_op_a,
    sel_op_b,
    read_prog,
    go_prog,
    read_data,
    go_data,
    read_port,
    go_port,
    ovm
    );

/*
 *
 *  @(#) execute_i.v 15.4@(#)
 *  4/30/96  16:12:40
 *
 */

/*
 * Tiny DSP Instruction Execution unit
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
input               clk,                // System clock
                    reset,              // System reset
                    phi_1,              // cycle phase 1
                    phi_2,              // cycle phase 2
                    phi_3,              // cycle phase 3
                    phi_4,              // cycle phase 4
                    phi_5,              // cycle phase 5
                    phi_6,              // cycle phase 6
                    decode_skip_one,    // decode_i skip one flag
                    gez,                // accum >= 0
                    gz,                 // accum > 0
                    nz,                 // accum != 0
                    z,                  // accum == 0
                    lz,                 // accum < 0
                    lez,                // accum <= 0
                    arnz,               // ar != 0
                    bioz;               // bio == 0
input   [`MSB:0]    ir,                 // Instruction Holding Register
                    decode,             // Decode Holding Register
                    ar;                 // resolved auxilary register
input   [`ACC:0]    alu_result;         // ALU operation result
input   [`HMSB:0]   mpy_result;         // multiply operation result
input   [`MSB:0]    mdr,                // operand input
                    pdr;                // port data input
output              skip_one,           // skip one cycle flag
                    fetch_branch,       // update pc with branch address
                    branch_stall,       // stall pipeline do to branch cycle
                    pc_acc,             // update pc with accum
                    dmov_inc,           // dmov cycle increment data address
                    dp,                 // data page pointer
                    arp;                // Auxiliary Register Pointer
output  [`MSB:0]    pc;                 // Program counter
output  [`MSB:0]    ar0,                // Auxiliary Register 0
                    ar1;                // Auxiliary Register 1
output  [`ACC:0]    acc;                // Accumulator Register
output  [`HMSB:0]   p;                  // Multiply product Register
output  [`MSB:0]    top;                // Multiply temporary operand
output  [`ALUCMD:0] alu_cmd;            // Accumulator Command opcode
output  [`OPACMD:0] sel_op_a;           // Accumulator Command opcode
output  [`OPBCMD:0] sel_op_b;           // Accumulator Command opcode
output              read_prog,          // read from program bus
                    go_prog,            // program bus mach. go flag
                    read_data,          // read from data bus
                    go_data,            // data bus mach. go flag
                    read_port,          // read from port bus
                    go_port,            // port bus mach. go flag
                    ov,                 // overflow flag
                    ovm;                // overflow mode
reg     [`MSB:0]    pc;                 // Program counter
reg     [`ACC:0]    acc;                // Accumulator Register
reg     [`HMSB:0]   p;                  // Multiply product Register
reg     [`MSB:0]    top;                // Multiply temporary operand
reg     [`ALUCMD:0] alu_cmd;            // Accumulator Command opcode
reg     [`OPACMD:0] sel_op_a;           // Accumulator Command opcode
reg     [`OPBCMD:0] sel_op_b;           // Accumulator Command opcode
reg                 dp,                 // data page pointer
                    two_cycle,          // compound inst. cycle two
                    three_cycle,        // compound inst. cycle three
                    skip_one,           // compound inst. cycle one
                    branch_stall,       // branch instruction pipe stall
                    branch_stall_delay, // branch_stall, delayed
                    pc_acc,             // update pc with accum
                    fetch_branch,       // update pc with branch address
                    read_prog,          // read from program bus
                    go_prog,            // program bus mach. go flag
                    read_data,          // read from data bus
                    go_data,            // data bus mach. go flag
                    read_port,          // read from port bus
                    go_port,            // port bus mach. go flag
                    ovm,                // overflow flag
                    ov_flag,            // overflow flag
                    dmov_inc;           // dmov cycle increment data address

reg     [`MSB:0]    ar0,            // Auxiliary Register 0
                    ar1;            // Auxiliary Register 1
reg                 arp,            // Auxiliary register pointer
                    update_it,      // update auxilary register flag
                    update_stall,   // update auxilary register flag, delayed
                    null_op;        // should be optimized out...

wire    [`MSB:0]    ir,                 // Instruction Register
                    decode,             // 
                    ar;                 // Selected Auxiliary Register
wire    [`ACC:0]    alu_result;
wire    [`HMSB:0]   mpy_result;
wire    [`MSB:0]    alu_out,            // Output from ALU function
                    mdr,                // Memory Data Register
                    pdr;                // Memory Data Register
wire    [`ADDR:0]   res_adr;            // Resolved data address
wire    [`ADDR:0]   res_port_adr;       // Resolved port address
wire    [`HMSB:0]   se_shift_mdr;       // sign extended, shifted data
wire    [`HMSB:0]   shift_acc;          // shifted accumulator
wire    [`HMSB:0]   ze_mdr;             // zero paded mdr
wire                bus_request,        // Data bus, bus request
                    bus_grant,          // Data bus, bus grant
                    done,
                    p_done,
                    port_done,
                    decode_skip_one,
                    gez,                // ACC >= 0
                    gz,                 // ACC > 0
                    nz,                 // ACC != 0
                    z,                  // ACC == 0
                    lz,                 // ACC < 0
                    lez,                // ACC <= 0
                    ov,                 // ACC Overflow
                    arnz,               // AR != 0
                    bioz;               // BIO == 0

parameter Z = 16'bz;

assign #1 ov = ov_flag ;

//
// execute instruction
//
always @(posedge clk or posedge reset)
begin : execute_machine
    if (reset)
		begin
        pc <= 16'hffff;
        dp <= 0;
        fetch_branch <= 0;
        two_cycle <= 0;
        three_cycle <= 0;
        skip_one <= 0;
        branch_stall <= 0;
        branch_stall_delay <= 0;
        pc_acc <= 0;
        read_prog <= 0;
        go_prog <= 0;
        read_data <= 0;
        go_data <= 0;
        read_port <= 0;
        go_port <= 0;
        ovm <= 0;
        ov_flag <= 0;
        dmov_inc <= 0;
	sel_op_a <= 0;
        sel_op_b <= 0;
        alu_cmd <= 0;
	acc <= 0;
        top <= 0;
	p <= 0;
		end
    else
        begin
        if (phi_3)
            begin
            read_prog <= 0;
            go_prog <= 0;
            read_data <= 0;
            go_data <= 0;
            read_port <= 0;
            go_port <= 0;
            end
        if (phi_1 && skip_one)
            begin
            skip_one <= 0 ;
            end
        if (phi_1 && branch_stall)
            begin
            fetch_branch <= 0 ;
            branch_stall <= 0 ;
            branch_stall_delay <= 1 ;
            end
        else if (phi_6 && branch_stall_delay)
            begin
            branch_stall_delay <= 0 ;
            end
        else if (!branch_stall && !branch_stall_delay)
            begin
            case (ir[`S_OP_LINE]) // synopsys full_case parallel_case
            `OP_LINE_0: begin
                case (ir[`S_HI_NIB]) // synopsys full_case parallel_case
                `HI_NIB_0: begin
                    // asm:ADD
                    if (phi_3)
                        begin
                        sel_op_a <= `OP_A_ACC ;
                        sel_op_b <= `OP_B_SE ;
                        alu_cmd <= `ALU_ADD ;
                        end
                    if (phi_6)
                        begin
                        acc <= alu_result ;
                        if (alu_result[`S_ACC_OV])
                            ov_flag <= 1 ;
                        end
                    end
                `HI_NIB_1: begin
                    // asm:SUB
                    if (phi_3)
                        begin
                        sel_op_a <= `OP_A_ACC ;
                        sel_op_b <= `OP_B_SE ;
                        alu_cmd <= `ALU_SUB ;
                        end
                    if (phi_6)
                        begin
                        acc <= alu_result ;
                        if (alu_result[`S_ACC_OV])
                            ov_flag <= 1 ;
                        end
                    end
                default: begin
                    null_op <= 0;
                    end
                endcase
                end
            `OP_LINE_1: begin
                case (ir[`S_HI_NIB]) // synopsys full_case parallel_case
                `HI_NIB_2: begin
                    // asm:LAC
                    if (phi_3)
                        begin
                        sel_op_a <= `OP_A_MDR ;
                        sel_op_b <= `OP_B_SE ;
                        alu_cmd <= `ALU_OPB ;
                        end
                    if (phi_6)
                        begin
                        acc <= alu_result ;
                        end
                    end
                `HI_NIB_3: begin
                    case (ir[`S_OP]) // synopsys full_case parallel_case
                    // asm:LAR
                    // asm:SAR
                    `LAR0,
                    `LAR1,
                    `SAR0,
                    `SAR1: begin
                        null_op <= 0;
                        end
                    default: begin
                        null_op <= 0;
                        end
                    endcase
                    end
                default: begin
                    null_op <= 0;
                    end
                endcase
                end
            `OP_LINE_2: begin
                case (ir[`S_HI_NIB]) // synopsys full_case parallel_case
                `HI_NIB_4: begin
                    case (ir[`S_OP]) // synopsys full_case parallel_case
                    // asm:DMOV
                    `DMOV: begin
                        if (phi_1 && ! two_cycle & ! three_cycle)
                            begin
                            skip_one <= 1 ;
                            end
                        if (phi_6 && ! two_cycle & ! three_cycle)
                            begin
                            two_cycle <= 1 ;
                            dmov_inc <= 1 ;
                            read_data <= 0 ;
                            go_data <= 1 ;
                            read_prog <= 1 ;
                            go_prog <= 1 ;
                            end
                        if (phi_5 && two_cycle & ! three_cycle)
                            begin
                            two_cycle <= 0 ;
                            three_cycle <= 1 ;
                            dmov_inc <= 0 ;
                            end
                        if (phi_6 && ! two_cycle & three_cycle)
                            begin
                            three_cycle <= 0 ;
                            end
                        end
                    // asm:LT
                    `LT: begin
                        if (phi_6)
                            begin
                            top <= mdr;
                            end
                        end
                    // asm:LTA
                    `LTA: begin
                        if (phi_3)
                            begin
                            sel_op_a <= `OP_A_ACC ;
                            sel_op_b <= `OP_B_P ;
                            alu_cmd <= `ALU_ADD ;
                            end
                        if (phi_6)
                            begin
                            top <= mdr;
                            acc <= alu_result ;
                            if (alu_result[`S_ACC_OV])
                                ov_flag <= 1 ;
                            end
                        end
                    // asm:LTD
                    `LTD: begin
                        if (phi_1 && ! two_cycle & ! three_cycle)
                            begin
                            skip_one <= 1 ;
                            end
                        if (phi_3 && ! two_cycle & ! three_cycle)
                            begin
                            sel_op_a <= `OP_A_ACC ;
                            sel_op_b <= `OP_B_P ;
                            alu_cmd <= `ALU_ADD ;
                            end
                        if (phi_6 && ! two_cycle & ! three_cycle)
                            begin
                            top <= mdr;
                            acc <= alu_result ;
                            if (alu_result[`S_ACC_OV])
                                ov_flag <= 1 ;
                            two_cycle <= 1 ;
                            dmov_inc <= 1 ;
                            read_data <= 0 ;
                            go_data <= 1 ;
                            read_prog <= 1 ;
                            go_prog <= 1 ;
                            end
                        if (phi_5 && two_cycle & ! three_cycle)
                            begin
                            two_cycle <= 0 ;
                            three_cycle <= 1 ;
                            dmov_inc <= 0 ;
                            end
                        if (phi_6 && ! two_cycle & three_cycle)
                            begin
                            three_cycle <= 0 ;
                            end
                        end
                    // asm:LTS
                    `LTS: begin
                        if (phi_3)
                            begin
                            sel_op_a <= `OP_A_ACC ;
                            sel_op_b <= `OP_B_P ;
                            alu_cmd <= `ALU_SUB ;
                            end
                        if (phi_6)
                            begin
                            top <= mdr;
                            acc <= alu_result ;
                            if (alu_result[`S_ACC_OV])
                                ov_flag <= 1 ;
                            end
                        end
                    // asm:LTP
                    `LTP: begin
                        if (phi_3)
                            begin
                            sel_op_a <= `OP_A_IR ;
                            sel_op_b <= `OP_B_P ;
                            alu_cmd <= `ALU_OPB ;
                            end
                        if (phi_6)
                            begin
                            top <= mdr;
                            acc <= alu_result ;
                            end
                        end
                    default: begin
                        null_op <= 0;
                        end
                    endcase
                    end
                `HI_NIB_5: begin
                    null_op <= 0;
                    end
                default: begin
                    null_op <= 0;
                    end
                endcase
                end
            `OP_LINE_3: begin
                case (ir[`S_HI_NIB]) // synopsys full_case parallel_case
                `HI_NIB_6: begin
                    case (ir[`S_OP]) // synopsys full_case parallel_case
                    // asm:ADDH
                    `ADDH: begin
                        if (phi_3)
                            begin
                            sel_op_a <= `OP_A_ACC ;
                            sel_op_b <= `OP_B_MDRH ;
                            alu_cmd <= `ALU_ADD ;
                            end
                        if (phi_6)
                            begin
                            acc <= alu_result ;
                            if (alu_result[`S_ACC_OV])
                                ov_flag <= 1 ;
                            end
                        end
                    // asm:ADDS
                    `ADDS: begin
                        if (phi_3)
                            begin
                            sel_op_a <= `OP_A_ACC ;
                            sel_op_b <= `OP_B_MDRL ;
                            alu_cmd <= `ALU_ADD ;
                            if (alu_result[`S_ACC_OV])
                                ov_flag <= 1 ;
                            end
                        if (phi_6)
                            begin
                            acc <= alu_result ;
                            end
                        end
                    // asm:MPY
                    `MPY: begin
                        if (phi_3)
                            begin
                            sel_op_a <= `OP_A_TOP ;
                            sel_op_b <= `OP_B_MDR ;
                            end
                        if (phi_6)
                            begin
                            p <= mpy_result ;
                            end
                        end
                    // asm:SUBH
                    `SUBH: begin
                        if (phi_3)
                            begin
                            sel_op_a <= `OP_A_ACC ;
                            sel_op_b <= `OP_B_MDRH ;
                            alu_cmd <= `ALU_SUB ;
                            end
                        if (phi_6)
                            begin
                            acc <= alu_result ;
                            if (alu_result[`S_ACC_OV])
                                ov_flag <= 1 ;
                            end
                        end
                    // asm:SUBS
                    `SUBS: begin
                        if (phi_3)
                            begin
                            sel_op_a <= `OP_A_ACC ;
                            sel_op_b <= `OP_B_MDRL ;
                            alu_cmd <= `ALU_SUB ;
                            end
                        if (phi_6)
                            begin
                            acc <= alu_result ;
                            if (alu_result[`S_ACC_OV])
                                ov_flag <= 1 ;
                            end
                        end
                    // asm:ZALH
                    `ZALH: begin
                        if (phi_3)
                            begin
                            sel_op_a <= `OP_A_IR ;
                            sel_op_b <= `OP_B_MDRH ;
                            alu_cmd <= `ALU_OPB ;
                            end
                        if (phi_6)
                            begin
                            acc <= alu_result ;
                            end
                        end
                    // asm:ZALS
                    `ZALS: begin
                        if (phi_3)
                            begin
                            sel_op_a <= `OP_A_IR ;
                            sel_op_b <= `OP_B_MDRL ;
                            alu_cmd <= `ALU_OPB ;
                            end
                        if (phi_6)
                            begin
                            acc <= alu_result ;
                            end
                        end
                    // asm:LDP
                    `LDP: begin
                        if (phi_6)
                            begin
                            dp <= mdr[0] ;
                            end
                        end
                    // asm:LDPK
                    `LDPK: begin
                        if (phi_6)
                            begin
                            dp <= ir[0] ;
                            end
                        end
                    // asm:MAR
                    // asm:LARP
                    `MAR: begin
                        null_op <= 0;
                        end
                    default: begin
                        null_op <= 0;
                        end
                    endcase
                    end
                `HI_NIB_7: begin
                    case (ir[`S_OP]) // synopsys full_case parallel_case
                    // asm:AND
                    `AND: begin
                        if (phi_3)
                            begin
                            sel_op_a <= `OP_A_ACC ;
                            sel_op_b <= `OP_B_ZE ;
                            alu_cmd <= `ALU_AND ;
                            end
                        if (phi_6)
                            begin
                            acc <= alu_result ;
                            end
                        end
                    // asm:OR
                    `OR: begin
                        if (phi_3)
                            begin
                            sel_op_a <= `OP_A_ACC ;
                            sel_op_b <= `OP_B_ZE ;
                            alu_cmd <= `ALU_OR ;
                            end
                        if (phi_6)
                            begin
                            acc <= alu_result ;
                            end
                        end
                    // asm:XOR
                    `XOR: begin
                        if (phi_3)
                            begin
                            sel_op_a <= `OP_A_ACC ;
                            sel_op_b <= `OP_B_ZE ;
                            alu_cmd <= `ALU_XOR ;
                            end
                        if (phi_6)
                            begin
                            acc <= alu_result ;
                            end
                        end
                    // asm:LACK
                    // asm:ZAC
                    `LACK: begin    // also ZAC...
                        if (phi_3)
                            begin
                            sel_op_a <= `OP_A_IR ;
                            sel_op_b <= `OP_B_MDRL ;
                            alu_cmd <= `ALU_OPA ;
                            end
                        if (phi_6)
                            begin
                            acc <= alu_result ;
                            end
                        end
                    // asm:LARK
                    `LARK0: begin
                        null_op <= 0;
                        end
                    `LARK1: begin
                        null_op <= 0;
                        end
                    `FULLOP: begin
                        case(ir) // synopsys full_case parallel_case
                        // asm:ABS
                        `ABS: begin
                            if (phi_3)
                                begin
                                sel_op_a <= `OP_A_ACC ;
                                sel_op_b <= `OP_B_P ;
                                alu_cmd <= `ALU_ABS ;
                                end
                            if (phi_6)
                                begin
                                acc <= alu_result ;
                                end
                            end
                        // asm:PAC
                        `PAC: begin
                            if (phi_3)
                                begin
                                sel_op_a <= `OP_A_IR ;
                                sel_op_b <= `OP_B_P ;
                                alu_cmd <= `ALU_OPB ;
                                end
                            if (phi_6)
                                begin
                                acc <= alu_result ;
                                end
                            end
                        // asm:APAC
                        `APAC: begin
                            if (phi_3)
                                begin
                                sel_op_a <= `OP_A_ACC ;
                                sel_op_b <= `OP_B_P ;
                                alu_cmd <= `ALU_ADD ;
                                end
                            if (phi_6)
                                begin
                                acc <= alu_result ;
                                if (alu_result[`S_ACC_OV])
                                    ov_flag <= 1 ;
                                end
                            end
                        // asm:SPAC
                        `SPAC: begin
                            if (phi_3)
                                begin
                                sel_op_a <= `OP_A_ACC ;
                                sel_op_b <= `OP_B_P ;
                                alu_cmd <= `ALU_SUB ;
                                end
                            if (phi_6)
                                begin
                                acc <= alu_result ;
                                if (alu_result[`S_ACC_OV])
                                    ov_flag <= 1 ;
                                end
                            end
                        // asm:ROVM
                        `ROVM: begin
                            ovm <= 0 ;
                            end
                        // asm:SOVM
                        `SOVM: begin
                            ovm <= 1 ;
                            end
                        endcase
                        end
                    default: begin
                        null_op <= 0;
                        end
                    endcase
                    end
                default: begin
                    null_op <= 0;
                    end
                endcase
                end
            `OP_LINE_4: begin
                // asm:MPYK
                if (phi_3)
                    begin
                    sel_op_a <= `OP_A_IR ;
                    sel_op_b <= `OP_B_EIR ;
                    end
                if (phi_6)
                    begin
                    p <= mpy_result ;
                    end
                end
            `OP_LINE_5: begin
                case (ir[`S_HI_NIB]) // synopsys full_case parallel_case
                `HI_NIB_A: begin
                    // asm:IN
                    if (phi_1 && ! two_cycle && ! three_cycle)
                        begin
                        skip_one <= 1 ;
                        end
                    if (phi_6 && ! two_cycle && ! three_cycle)
                        begin
                        two_cycle <= 1 ;
                        skip_one <= 1 ;
                        read_data <= 0 ;
                        go_data <= 1 ;
                        end
                    if (phi_1 && two_cycle && ! three_cycle)
                        begin
                        skip_one <= 1 ;
                        end
                    if (phi_6 && two_cycle && ! three_cycle)
                        begin
                        two_cycle <= 0 ;
                        three_cycle <= 1 ;
                        read_prog <= 1 ;
                        go_prog <= 1 ;
                        end
                    if (phi_1 && ! two_cycle && three_cycle)
                        begin
                        skip_one <= 1 ;
                        end
                    if (phi_4 && three_cycle)
                        begin
                        skip_one <= 0 ;
                        end
                    if (phi_6 && three_cycle)
                        begin
                        three_cycle <= 0 ;
                        end
                    end
                `HI_NIB_B: begin
                    // asm:OUT
                    if (phi_1 && ! two_cycle && ! three_cycle)
                        begin
                        skip_one <= 1 ;
                        end
                    if (phi_6 && ! two_cycle && ! three_cycle)
                        begin
                        two_cycle <= 1 ;
                        skip_one <= 1 ;
                        read_port <= 0 ;
                        go_port <= 1 ;
                        end
                    if (phi_1 && two_cycle && ! three_cycle)
                        begin
                        skip_one <= 1 ;
                        end
                    if (phi_6 && two_cycle && ! three_cycle)
                        begin
                        two_cycle <= 0 ;
                        three_cycle <= 1 ;
                        read_prog <= 1 ;
                        go_prog <= 1 ;
                        end
                    if (phi_1 && ! two_cycle && three_cycle)
                        begin
                        skip_one <= 1 ;
                        end
                    if (phi_4 && three_cycle)
                        begin
                        skip_one <= 0 ;
                        end
                    if (phi_6 && three_cycle)
                        begin
                        three_cycle <= 0 ;
                        end
                    end
                default: begin
                    null_op <= 0;
                    end
                endcase
                end
            `OP_LINE_6: begin
                case (ir[`S_HI_NIB]) // synopsys full_case parallel_case
                `HI_NIB_C: begin
                    case (ir[`S_OP]) // synopsys full_case parallel_case
                    // asm:MAC
                    `MAC:
                        begin
                        if (phi_3 && ! two_cycle & ! three_cycle)
                            begin
                            skip_one <= 1 ;
                            sel_op_a <= `OP_A_TOP ;
                            sel_op_b <= `OP_B_MDR ;
                            end
                        if (phi_6 && ! two_cycle & ! three_cycle)
                            begin
                            p <= mpy_result ;
                            end
                        if (phi_6 && ! two_cycle & ! three_cycle)
                            begin
                            two_cycle <= 1 ;
                            end
                        if (phi_3 && two_cycle & ! three_cycle)
                            begin
                            sel_op_a <= `OP_A_ACC ;
                            sel_op_b <= `OP_B_P ;
                            alu_cmd <= `ALU_ADD ;
                            two_cycle <= 0 ;
                            three_cycle <= 1 ;
                            end
                        if (phi_6 && ! two_cycle & three_cycle)
                            begin
                            acc <= alu_result ;
                            if (alu_result[`S_ACC_OV])
                                ov_flag <= 1 ;
                            three_cycle <= 0 ;
                            end
                        end
                    default: begin
                        null_op <= 0;
                        end
                    endcase
                    end
                `HI_NIB_D: begin
                    null_op <= 0;
                    end
                default: begin
                    null_op <= 0;
                    end
                endcase
                end
            `OP_LINE_7: begin
                case (ir[`S_HI_NIB]) // synopsys full_case parallel_case
                `HI_NIB_E: begin
                    case (ir[`S_OP]) // synopsys full_case parallel_case
                    // asm:TBLR
                    `TBLR: begin
                        if (phi_1 && ! two_cycle && ! three_cycle)
                            begin
                            skip_one <= 1 ;
                            pc_acc <= 1 ;
                            end
                        if (phi_6 && ! two_cycle && ! three_cycle)
                            begin
                            two_cycle <= 1 ;
                            skip_one <= 1 ;
                            read_data <= 0 ;
                            go_data <= 1 ;
                            end
                        if (phi_1 && two_cycle && ! three_cycle)
                            begin
                            skip_one <= 1 ;
                            end
                        if (phi_6 && two_cycle && ! three_cycle)
                            begin
                            two_cycle <= 0 ;
                            three_cycle <= 1 ;
                            pc_acc <= 0 ;
                            read_prog <= 1 ;
                            go_prog <= 1 ;
                            end
                        if (phi_1 && ! two_cycle && three_cycle)
                            begin
                            skip_one <= 1 ;
                            end
                        if (phi_4 && three_cycle)
                            begin
                            skip_one <= 0 ;
                            end
                        if (phi_6 && three_cycle)
                            begin
                            three_cycle <= 0 ;
                            end
                        end
                    // asm:TBLW
                    `TBLW: begin
                        if (phi_1 && ! two_cycle && ! three_cycle)
                            begin
                            skip_one <= 1 ;
                            pc_acc <= 1 ;
                            end
                        if (phi_6 && ! two_cycle && ! three_cycle)
                            begin
                            two_cycle <= 1 ;
                            skip_one <= 1 ;
                            read_prog <= 0 ;
                            go_prog <= 1 ;
                            end
                        if (phi_1 && two_cycle && ! three_cycle)
                            begin
                            skip_one <= 1 ;
                            end
                        if (phi_6 && two_cycle && ! three_cycle)
                            begin
                            two_cycle <= 0 ;
                            three_cycle <= 1 ;
                            pc_acc <= 0 ;
                            read_prog <= 1 ;
                            go_prog <= 1 ;
                            end
                        if (phi_1 && ! two_cycle && three_cycle)
                            begin
                            skip_one <= 1 ;
                            end
                        if (phi_4 && three_cycle)
                            begin
                            skip_one <= 0 ;
                            end
                        if (phi_6 && three_cycle)
                            begin
                            three_cycle <= 0 ;
                            end
                        end
                    default: begin
                        null_op <= 0;
                        end
                    endcase
                    end
                `HI_NIB_F: begin
                    case (ir[`S_OP]) // synopsys full_case parallel_case
                    // asm:B
                    `B: begin
                        if (phi_1)
                            begin
                            fetch_branch <= 1 ;
                            pc <= decode ;
                            branch_stall <= 1 ;
                            end
                        end
                    // asm:BIOZ
                    `BIOZ: begin
                        if (phi_1)
                            begin
                            fetch_branch <= bioz ;
                            if (bioz)
                                pc <= decode ;
                            branch_stall <= 1 ;
                            end
                        end
                    // asm:BZ
                    `BZ: begin
                        if (phi_1)
                            begin
                            fetch_branch <= z ;
                            if (z)
                                pc <= decode ;
                            branch_stall <= 1 ;
                            end
                        end
                    // asm:BNZ
                    `BNZ: begin
                        if (phi_1)
                            begin
                            fetch_branch <= nz ;
                            if (nz)
                                pc <= decode ;
                            branch_stall <= 1 ;
                            end
                        end
                    // asm:BGEZ
                    `BGEZ: begin
                        if (phi_1)
                            begin
                            fetch_branch <= gez ;
                            if (gez)
                                pc <= decode ;
                            branch_stall <= 1 ;
                            end
                        end
                    // asm:BGZ
                    `BGZ: begin
                        if (phi_1)
                            begin
                            fetch_branch <= gz ;
                            if (gz)
                                pc <= decode ;
                            branch_stall <= 1 ;
                            end
                        end
                    // asm:BLEZ
                    `BLEZ: begin
                        if (phi_1)
                            begin
                            fetch_branch <= lez ;
                            if (lez)
                                pc <= decode ;
                            branch_stall <= 1 ;
                            end
                        end
                    // asm:BLZ
                    `BLZ: begin
                        if (phi_1)
                            begin
                            fetch_branch <= lz ;
                            if (lz)
                                pc <= decode ;
                            branch_stall <= 1 ;
                            end
                        end
                    // asm:BV
                    `BV: begin
                        if (phi_1)
                            begin
                            fetch_branch <= ov_flag ;
                            if (ov_flag)
                                begin
                                pc <= decode ;
                                ov_flag <= 0 ;
                                end
                            branch_stall <= 1 ;
                            end
                        end
                    // asm:BANZ
                    `BANZ: begin
                        if (phi_1)
                            begin
                            fetch_branch <= arnz ;
                            if (arnz)
                                pc <= decode ;
                            branch_stall <= 1 ;
                            end
                        end
                    default: begin
                        fetch_branch <= 0 ;
                        branch_stall <= 0 ;
                        end
                    endcase
                    end
                default: begin
                    null_op <= 0;
                    end
                endcase
                end
            default: begin
                null_op <= 0;
                end
            endcase
            end
        if (phi_6 && ! skip_one && ! two_cycle)
            begin
            pc <= pc + 1 ;
            end
    end
end

//
// update auxilary register
//
always @(posedge clk or posedge reset)
begin : update_ar_machine
    if (reset)
		begin
        arp <= 0;
        update_it <= 0;
        update_stall <= 0;
	ar0 <= 0;
	ar1 <= 0;
		end
    else
        begin
        if (phi_1)
            begin
            if (branch_stall)
                begin
                update_stall <= 1 ;
                end
            else
                begin
                update_stall <= 0 ;
                end
            end
        else if (phi_5 && !update_stall)
            begin
            case (ir[`S_OP_LINE]) // synopsys full_case parallel_case
            `OP_LINE_0: begin
                case (ir[`S_HI_NIB]) // synopsys full_case parallel_case
                `HI_NIB_0: begin
                    // asm:ADD
                    update_it <= 1 ;
                    end
                `HI_NIB_1: begin
                    // asm:SUB
                    update_it <= 1 ;
                    end
                default: begin
                    null_op <= 0 ;
                    end
                endcase
                end
            `OP_LINE_1: begin
                case (ir[`S_HI_NIB])  // synopsys full_case parallel_case
                `HI_NIB_2: begin
                    // asm:LAC
                    update_it <= 1 ;
                    end
                `HI_NIB_3: begin
                    case (ir[`S_OP])  // synopsys full_case parallel_case
                    // asm:LAR
                    `LAR0: begin
                        update_it <= 1 ;
                        ar0 <= mdr ;
                        end
                    `LAR1: begin
                        update_it <= 1 ;
                        ar1 <= mdr ;
                        end
                    // asm:SAR
                    `SAR0,
                    `SAR1: begin
                        update_it <= 1 ;
                        end
                    default: begin
                        update_it <= 1 ;
                        end
                    endcase
                    end
                default: begin
                    null_op <= 0 ;
                    end
                endcase
                end
            `OP_LINE_2: begin
                case (ir[`S_HI_NIB])  // synopsys full_case parallel_case
                `HI_NIB_4: begin
                    case (ir[`S_OP])  // synopsys full_case parallel_case
                    // asm:DMOV
                    // asm:LTD
                    `DMOV,
                    `LTD: begin
                        if (two_cycle)
                            begin
                            update_it <= 1 ;
                            end
                        end
                    default: begin
                        // asm:LT
                        // asm:LTA
                        // asm:LTP
                        // asm:LTS
                        update_it <= 1 ;
                        end
                    endcase
                    end
                `HI_NIB_5: begin
                    // asm:SACH
                    // asm:SACL
                    update_it <= 1 ;
                    end
                default: begin
                    null_op <= 0 ;
                    end
                endcase
                end
            `OP_LINE_3: begin
                case (ir[`S_HI_NIB])  // synopsys full_case parallel_case
                `HI_NIB_6: begin
                    case (ir[`S_OP])  // synopsys full_case parallel_case
                    // asm:ADDH
                    // asm:ADDS
                    // asm:LDP
                    // asm:LARP
                    // asm:MAR
                    // asm:MPY
                    // asm:SUBH
                    // asm:SUBS
                    // asm:ZALH
                    // asm:ZALS
                    `ADDH,
                    `ADDS,
                    `LDP,
                    `MAR,
                    `MPY,
                    `SUBH,
                    `SUBS,
                    `ZALH,
                    `ZALS: begin
                        update_it <= 1 ;
                        end
                    default: begin
                        null_op <= 0 ;
                        end
                    endcase
                    end
                `HI_NIB_7: begin
                    case (ir[`S_OP])  // synopsys full_case parallel_case
                    // asm:LARK
                    `LARK0: begin
                        ar0 <= { {`TP{1'b0}}, ir[`S_IDATA] } ;
                        end
                    `LARK1: begin
                        ar1 <= { {`TP{1'b0}}, ir[`S_IDATA] } ;
                        end
                    // asm:AND
                    // asm:OR
                    // asm:XOR
                    `AND,
                    `OR,
                    `XOR: begin
                        update_it <= 1 ;
                        end
                    default: begin
                        null_op <= 0 ;
                        end
                    endcase
                    end
                default: begin
                    null_op <= 0 ;
                    end
                endcase
                end
            `OP_LINE_4: begin
                // asm:MPYK
                null_op <= 0 ;
                end
            `OP_LINE_5: begin
                case (ir[`S_HI_NIB])  // synopsys full_case parallel_case
                `HI_NIB_A: begin
                    // asm:IN
                    if (three_cycle)
                        begin
                        update_it <= 1 ;
                        end
                    end
                `HI_NIB_B: begin
                    // asm:OUT
                    if (three_cycle)
                        begin
                        update_it <= 1 ;
                        end
                    end
                default: begin
                    null_op <= 0 ;
                    end
                endcase
                end
            `OP_LINE_6: begin
                case (ir[`S_HI_NIB])  // synopsys full_case parallel_case
                `HI_NIB_C: begin
                    case (ir[`S_OP])  // synopsys full_case parallel_case
                    // asm:MAC
                    `MAC: begin
                        if (two_cycle)
                            begin
                            update_it <= 1 ;
                            end
                        end
                    default: begin
                        null_op <= 0 ;
                        end
                    endcase
                    end
                `HI_NIB_D: begin
                    null_op <= 0 ;
                    end
                default: begin
                    null_op <= 0 ;
                    end
                endcase
                end
            `OP_LINE_7: begin
                case (ir[`S_HI_NIB])  // synopsys full_case parallel_case
                `HI_NIB_E: begin
                    case (ir[`S_OP])  // synopsys full_case parallel_case
                    // asm:TBLR
                    `TBLR: begin
                        if (three_cycle)
                            begin
                            update_it <= 1 ;
                            end
                        end
                    // asm:TBLW
                    `TBLW: begin
                        if (three_cycle)
                            begin
                            update_it <= 1 ;
                            end
                        end
                    default: begin
                        null_op <= 0 ;
                        end
                    endcase
                    end
                `HI_NIB_F: begin
                    case (ir[`S_OP])  // synopsys full_case parallel_case
                    // asm:B
                    // asm:BIOZ
                    // asm:BZ
                    // asm:BNZ
                    // asm:BGEZ
                    // asm:BGZ
                    // asm:BLEZ
                    // asm:BLZ
                    // asm:BV
                    `B,
                    `BIOZ,
                    `BZ,
                    `BNZ,
                    `BGEZ,
                    `BGZ,
                    `BLEZ,
                    `BLZ,
                    `BV: begin
                        null_op <= 0 ;
                        end
                    // asm:BANZ
                    `BANZ: begin
                        update_it <= 1 ;
                        end
                    default: begin
                        end
                    endcase
                    end
                default: begin
                    null_op <= 0 ;
                    end
                endcase
                end
            default: begin
                null_op <= 0 ;
                end
            endcase
            end
        else if (phi_6 && !update_stall)
            begin
            if (update_it && ir[7])
                begin
                case({ir[5],ir[4],arp})  // synopsys full_case parallel_case
                `AR0_INC: begin
                    ar0 <= ar + 1 ;
                    end
                `AR0_DEC: begin
                    ar0 <= ar - 1 ;
                    end
                `AR1_INC: begin
                    ar1 <= ar + 1 ;
                    end
                `AR1_DEC: begin
                    ar1 <= ar - 1 ;
                    end
                default: begin
                    null_op <= 0 ;
                    end
                endcase
                if (!ir[3])
                    begin
                    arp <= ir[0] ;
                    end
                end
            update_it <= 0 ;
            end
        end
end

endmodule // execute_i
