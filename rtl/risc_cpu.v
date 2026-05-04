//==============================================================================
// Module: risc_cpu
// Description: Top-level RISC CPU integrating all sub-modules.
//              - Simple 8-bit RISC processor with 3-bit opcode, 5-bit operand.
//              - 8 instruction types, 32 memory addresses.
//              - Halts when HLT instruction is executed.
//==============================================================================

module risc_cpu (
    input  wire clk,
    input  wire rst,
    output wire halt
);

    //--------------------------------------------------------------------------
    // Internal wires
    //--------------------------------------------------------------------------

    // Program Counter
    wire [4:0] pc_out;

    // Address Mux
    wire [4:0] addr;

    // Controller signals
    wire sel, rd, ld_ir, inc_pc, ld_ac, ld_pc, wr, data_e;

    // Instruction Register
    wire [7:0] ir_out;
    wire [2:0] opcode;
    wire [4:0] ir_addr;

    // Accumulator Register
    wire [7:0] acc_out;

    // ALU
    wire [7:0] alu_out;
    wire       is_zero;

    // Memory data bus (bidirectional)
    wire [7:0] data_bus;

    //--------------------------------------------------------------------------
    // Instruction decoding
    //--------------------------------------------------------------------------
    assign opcode  = ir_out[7:5];
    assign ir_addr = ir_out[4:0];

    //--------------------------------------------------------------------------
    // Data bus: ACC drives bus during STO (data_e asserted)
    //--------------------------------------------------------------------------
    assign data_bus = data_e ? acc_out : 8'bz;

    //--------------------------------------------------------------------------
    // Module instantiations
    //--------------------------------------------------------------------------

    // Program Counter
    program_counter u_pc (
        .clk     (clk),
        .rst     (rst),
        .ld_pc   (ld_pc),
        .inc_pc  (inc_pc),
        .data_in (ir_addr),
        .pc_out  (pc_out)
    );

    // Address Mux
    address_mux #(.WIDTH(5)) u_amux (
        .sel      (sel),
        .pc_addr  (pc_out),
        .ir_addr  (ir_addr),
        .addr_out (addr)
    );

    // Memory
    memory u_mem (
        .clk  (clk),
        .rd   (rd),
        .wr   (wr),
        .addr (addr),
        .data (data_bus)
    );

    // Instruction Register
    register u_ir (
        .clk      (clk),
        .rst      (rst),
        .load     (ld_ir),
        .data_in  (data_bus),
        .data_out (ir_out)
    );

    // Accumulator Register
    register u_acc (
        .clk      (clk),
        .rst      (rst),
        .load     (ld_ac),
        .data_in  (alu_out),
        .data_out (acc_out)
    );

    // ALU
    alu u_alu (
        .inA     (acc_out),
        .inB     (data_bus),
        .opcode  (opcode),
        .alu_out (alu_out),
        .is_zero (is_zero)
    );

    // Controller
    controller u_ctrl (
        .clk    (clk),
        .rst    (rst),
        .opcode (opcode),
        .is_zero(is_zero),
        .sel    (sel),
        .rd     (rd),
        .ld_ir  (ld_ir),
        .halt   (halt),
        .inc_pc (inc_pc),
        .ld_ac  (ld_ac),
        .ld_pc  (ld_pc),
        .wr     (wr),
        .data_e (data_e)
    );

endmodule
