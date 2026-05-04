//==============================================================================
// Module: controller
// Description: CPU Controller with 8-state FSM.
//              - Manages all control signals for the RISC CPU.
//              - Synchronous reset (active high), operates on rising edge of clk.
//              - 8 states cycle continuously: INST_ADDR -> INST_FETCH ->
//                INST_LOAD -> IDLE -> OP_ADDR -> OP_FETCH -> ALU_OP -> STORE
//              - Output logic is combinational based on state, opcode, and is_zero.
//==============================================================================

module controller (
    input  wire       clk,
    input  wire       rst,
    input  wire [2:0] opcode,   // Current instruction opcode
    input  wire       is_zero,  // ALU zero flag (accumulator == 0)
    output reg        sel,      // Address mux select
    output reg        rd,       // Memory read enable
    output reg        ld_ir,    // Load instruction register
    output reg        halt,     // Halt signal
    output reg        inc_pc,   // Increment program counter
    output reg        ld_ac,    // Load accumulator
    output reg        ld_pc,    // Load program counter (for JMP)
    output reg        wr,       // Memory write enable
    output reg        data_e    // Data enable (tri-state control for STO)
);

    // State encoding
    localparam [2:0] INST_ADDR  = 3'd0,
                     INST_FETCH = 3'd1,
                     INST_LOAD  = 3'd2,
                     IDLE       = 3'd3,
                     OP_ADDR    = 3'd4,
                     OP_FETCH   = 3'd5,
                     ALU_OP     = 3'd6,
                     STORE      = 3'd7;

    reg [2:0] state;

    // ALUOP: opcode requires memory read (ADD, AND, XOR, LDA)
    wire aluop;
    assign aluop = (opcode == 3'b010) ||  // ADD
                   (opcode == 3'b011) ||  // AND
                   (opcode == 3'b100) ||  // XOR
                   (opcode == 3'b101);    // LDA

    //--------------------------------------------------------------------------
    // State register: sequential state transitions
    //--------------------------------------------------------------------------
    always @(posedge clk) begin
        if (rst) begin
            state <= INST_ADDR;
        end else begin
            case (state)
                INST_ADDR:  state <= INST_FETCH;
                INST_FETCH: state <= INST_LOAD;
                INST_LOAD:  state <= IDLE;
                IDLE:       state <= OP_ADDR;
                OP_ADDR:    state <= OP_FETCH;
                OP_FETCH:   state <= ALU_OP;
                ALU_OP:     state <= STORE;
                STORE:      state <= INST_ADDR;
                default:    state <= INST_ADDR;
            endcase
        end
    end

    //--------------------------------------------------------------------------
    // Output logic: combinational based on current state and opcode/is_zero
    //--------------------------------------------------------------------------
    always @(*) begin
        // Default all outputs to 0
        sel    = 1'b0;
        rd     = 1'b0;
        ld_ir  = 1'b0;
        halt   = 1'b0;
        inc_pc = 1'b0;
        ld_ac  = 1'b0;
        ld_pc  = 1'b0;
        wr     = 1'b0;
        data_e = 1'b0;

        case (state)
            INST_ADDR: begin
                sel = 1'b1;
            end

            INST_FETCH: begin
                sel = 1'b1;
                rd  = 1'b1;
            end

            INST_LOAD: begin
                sel   = 1'b1;
                rd    = 1'b1;
                ld_ir = 1'b1;
            end

            IDLE: begin
                sel   = 1'b1;
                rd    = 1'b1;
                ld_ir = 1'b1;
            end

            OP_ADDR: begin
                halt   = (opcode == 3'b000);  // HLT
                inc_pc = 1'b1;
            end

            OP_FETCH: begin
                rd = aluop;
            end

            ALU_OP: begin
                rd     = aluop;
                inc_pc = (opcode == 3'b001) && is_zero;  // SKZ & zero
                ld_pc  = (opcode == 3'b111);             // JMP
                data_e = (opcode == 3'b110);             // STO
            end

            STORE: begin
                rd     = aluop;
                ld_ac  = aluop;
                ld_pc  = (opcode == 3'b111);             // JMP
                wr     = (opcode == 3'b110);             // STO
                data_e = (opcode == 3'b110);             // STO
            end

            default: begin
                // All outputs stay at default (0)
            end
        endcase
    end

endmodule
