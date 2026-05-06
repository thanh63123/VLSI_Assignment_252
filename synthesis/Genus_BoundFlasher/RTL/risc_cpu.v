`timescale 1ns/1ps

//==============================================================================
// --- START OF address_mux.v ---
//==============================================================================
//==============================================================================
// Module: address_mux
// Description: Parameterized 2-to-1 multiplexer for address selection.
//              - sel=1: selects program counter address (fetch phase)
//              - sel=0: selects instruction operand address (execute phase)
//              - Default width is 5 bits.
//==============================================================================

module address_mux #(
    parameter WIDTH = 5
) (
    input  wire             sel,      // Select signal
    input  wire [WIDTH-1:0] pc_addr,  // Program counter address
    input  wire [WIDTH-1:0] ir_addr,  // Instruction register operand address
    output wire [WIDTH-1:0] addr_out  // Selected address output
);

    assign addr_out = sel ? pc_addr : ir_addr;

endmodule

// --- END OF address_mux.v ---

//==============================================================================
// --- START OF alu.v ---
//==============================================================================
//==============================================================================
// Module: alu
// Description: 8-bit Arithmetic Logic Unit with 3-bit opcode.
//              - Performs 8 operations based on opcode.
//              - is_zero is an ASYNCHRONOUS (combinational) flag indicating
//                whether inA (accumulator) equals zero.
//
// Opcode Table:
//   000 (HLT) -> inA
//   001 (SKZ) -> inA
//   010 (ADD) -> inA + inB
//   011 (AND) -> inA & inB
//   100 (XOR) -> inA ^ inB
//   101 (LDA) -> inB
//   110 (STO) -> inA
//   111 (JMP) -> inA
//==============================================================================

module alu (
    input  wire [7:0] inA,      // Accumulator value
    input  wire [7:0] inB,      // Memory data value
    input  wire [2:0] opcode,   // Operation selector
    output reg  [7:0] alu_out,  // ALU result
    output wire       is_zero   // Asynchronous zero flag for inA
);

    // Asynchronous zero detection on accumulator
    assign is_zero = (inA == 8'b0);

    // Combinational ALU operation
    always @(*) begin
        case (opcode)
            3'b000: alu_out = inA;          // HLT - pass through accumulator
            3'b001: alu_out = inA;          // SKZ - pass through accumulator
            3'b010: alu_out = inA + inB;    // ADD
            3'b011: alu_out = inA & inB;    // AND
            3'b100: alu_out = inA ^ inB;    // XOR
            3'b101: alu_out = inB;          // LDA - load from memory
            3'b110: alu_out = inA;          // STO - pass through accumulator
            3'b111: alu_out = inA;          // JMP - pass through accumulator
            default: alu_out = 8'b0;
        endcase
    end

endmodule

// --- END OF alu.v ---

//==============================================================================
// --- START OF alu_extended.v ---
//==============================================================================
//==============================================================================
// Module: alu_extended
// Description: Enhanced 8-bit ALU with 4-bit opcode supporting 16 operations.
//              - Backward compatible with the original 3-bit opcode ALU
//                (opcodes 0-7 are identical).
//              - Adds 8 advanced operations: SUB, NOT, SHL, SHR, ROL, ROR,
//                CMP, MUL (4-bit x 4-bit).
//              - Additional status flags: carry_out, overflow.
//              - is_zero is asynchronous (combinational) on inA.
//
// Opcode Table:
//   0000 (HLT) -> inA                    | 1000 (SUB) -> inA - inB
//   0001 (SKZ) -> inA                    | 1001 (NOT) -> ~inA
//   0010 (ADD) -> inA + inB              | 1010 (SHL) -> inA << 1
//   0011 (AND) -> inA & inB              | 1011 (SHR) -> inA >> 1
//   0100 (XOR) -> inA ^ inB             | 1100 (ROL) -> rotate left inA
//   0101 (LDA) -> inB                    | 1101 (ROR) -> rotate right inA
//   0110 (STO) -> inA                    | 1110 (CMP) -> inA - inB (flags only)
//   0111 (JMP) -> inA                    | 1111 (MUL) -> inA[3:0] * inB[3:0]
//==============================================================================

module alu_extended (
    input  wire [7:0] inA,        // Accumulator value
    input  wire [7:0] inB,        // Memory data value
    input  wire [3:0] opcode,     // 4-bit operation selector
    output reg  [7:0] alu_out,    // ALU result
    output wire       is_zero,    // Asynchronous zero flag for inA
    output reg        carry_out,  // Carry/borrow flag
    output reg        overflow    // Signed overflow flag
);

    // Asynchronous zero detection on accumulator
    assign is_zero = (inA == 8'b0);

    // Internal 9-bit result for carry detection
    reg [8:0] result9;

    // Combinational ALU operation
    always @(*) begin
        // Default outputs
        carry_out = 1'b0;
        overflow  = 1'b0;
        result9   = 9'b0;

        case (opcode)
            // === Original RISC CPU operations (backward compatible) ===
            4'b0000: alu_out = inA;              // HLT - pass through
            4'b0001: alu_out = inA;              // SKZ - pass through
            4'b0010: begin                        // ADD
                result9   = {1'b0, inA} + {1'b0, inB};
                alu_out   = result9[7:0];
                carry_out = result9[8];
                overflow  = (inA[7] == inB[7]) && (alu_out[7] != inA[7]);
            end
            4'b0011: alu_out = inA & inB;        // AND
            4'b0100: alu_out = inA ^ inB;        // XOR
            4'b0101: alu_out = inB;              // LDA - load from memory
            4'b0110: alu_out = inA;              // STO - pass through
            4'b0111: alu_out = inA;              // JMP - pass through

            // === Extended operations ===
            4'b1000: begin                        // SUB
                result9   = {1'b0, inA} - {1'b0, inB};
                alu_out   = result9[7:0];
                carry_out = result9[8];  // borrow flag
                overflow  = (inA[7] != inB[7]) && (alu_out[7] != inA[7]);
            end
            4'b1001: alu_out = ~inA;             // NOT (bitwise complement)
            4'b1010: begin                        // SHL (shift left by 1)
                carry_out = inA[7];
                alu_out   = {inA[6:0], 1'b0};
            end
            4'b1011: begin                        // SHR (logical shift right by 1)
                carry_out = inA[0];
                alu_out   = {1'b0, inA[7:1]};
            end
            4'b1100: begin                        // ROL (rotate left by 1)
                alu_out = {inA[6:0], inA[7]};
            end
            4'b1101: begin                        // ROR (rotate right by 1)
                alu_out = {inA[0], inA[7:1]};
            end
            4'b1110: begin                        // CMP (compare: flags only)
                result9   = {1'b0, inA} - {1'b0, inB};
                alu_out   = result9[7:0];
                carry_out = result9[8];  // borrow: inA < inB
                overflow  = (inA[7] != inB[7]) && (alu_out[7] != inA[7]);
            end
            4'b1111: begin                        // MUL (4-bit x 4-bit = 8-bit)
                alu_out = inA[3:0] * inB[3:0];
            end
            default: alu_out = 8'b0;
        endcase
    end

endmodule

// --- END OF alu_extended.v ---

//==============================================================================
// --- START OF controller.v ---
//==============================================================================
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

// --- END OF controller.v ---

//==============================================================================
// --- START OF divider.v ---
//==============================================================================
//==============================================================================
// Module: divider
// Description: Sequential 8-bit unsigned divider using restoring division
//              algorithm.
//              - Computes quotient and remainder: dividend / divisor.
//              - Start/done handshake protocol.
//              - Takes 8 clock cycles to complete after start.
//              - Detects division by zero (div_by_zero flag).
//              - Synchronous reset (active high).
//
// Operation:
//   1. Assert start=1 with valid dividend and divisor for 1 cycle.
//   2. Module asserts busy=1 while computing.
//   3. After 8 cycles, done=1 is asserted for 1 cycle with valid outputs.
//   4. If divisor=0, div_by_zero=1 and quotient/remainder are invalid.
//==============================================================================

module divider (
    input  wire       clk,
    input  wire       rst,
    input  wire       start,       // Start computation
    input  wire [7:0] dividend,    // Numerator
    input  wire [7:0] divisor,     // Denominator
    output reg  [7:0] quotient,    // Result: dividend / divisor
    output reg  [7:0] remainder,   // Result: dividend % divisor
    output reg        done,        // Computation complete (1 cycle pulse)
    output reg        busy,        // Currently computing
    output reg        div_by_zero  // Division by zero error
);

    // Internal registers
    reg [7:0]  d_reg;     // Divisor register
    reg [15:0] r_reg;     // Combined remainder:quotient shift register
    reg [3:0]  count;     // Bit counter (0 to 7)

    // Combinational trial subtraction (separated for clean synthesis)
    wire [8:0] trial;
    assign trial = {1'b0, r_reg[14:7]} - {1'b0, d_reg};

    always @(posedge clk) begin
        if (rst) begin
            quotient    <= 8'b0;
            remainder   <= 8'b0;
            done        <= 1'b0;
            busy        <= 1'b0;
            div_by_zero <= 1'b0;
            d_reg       <= 8'b0;
            r_reg       <= 16'b0;
            count       <= 4'b0;
        end else if (start && !busy) begin
            // Check for division by zero
            if (divisor == 8'b0) begin
                div_by_zero <= 1'b1;
                quotient    <= 8'hFF;  // Indicate error
                remainder   <= dividend;
                done        <= 1'b1;
                busy        <= 1'b0;
            end else begin
                // Initialize
                d_reg       <= divisor;
                r_reg       <= {8'b0, dividend};
                count       <= 4'd0;
                busy        <= 1'b1;
                done        <= 1'b0;
                div_by_zero <= 1'b0;
            end
        end else if (busy) begin
            if (count < 4'd8) begin
                // Restoring division step:
                // Trial subtract divisor from upper half of shifted r_reg
                if (trial[8] == 1'b0) begin
                    // Trial >= 0: subtraction successful, set quotient bit = 1
                    r_reg <= {trial[7:0], r_reg[6:0], 1'b1};
                end else begin
                    // Trial < 0: restore, set quotient bit = 0
                    r_reg <= {r_reg[14:0], 1'b0};
                end
                count <= count + 4'd1;
            end else begin
                // Computation complete
                quotient  <= r_reg[7:0];    // Lower 8 bits = quotient
                remainder <= r_reg[15:8];   // Upper 8 bits = remainder
                done      <= 1'b1;
                busy      <= 1'b0;
            end
        end else begin
            done        <= 1'b0;
            div_by_zero <= 1'b0;
        end
    end

endmodule

// --- END OF divider.v ---

//==============================================================================
// --- START OF hazard_unit.v ---
//==============================================================================
//==============================================================================
// Module: hazard_unit
// Description: Hazard detection unit for a pipelined RISC CPU.
//              - Detects RAW (Read After Write) data hazards between
//                the Execute and Decode pipeline stages.
//              - Generates stall and forward control signals.
//              - Designed to be integrated if the CPU is upgraded to
//                a pipelined architecture.
//
// Hazard types handled:
//   RAW hazard: Execute stage writes to a memory address that the
//               Decode stage needs to read from.
//   Forwarding: If the result is available from ALU, forward instead
//               of stalling.
//   Stalling:   If the result requires a memory read (STO), stall
//               the pipeline.
//
// Control flow hazards:
//   JMP hazard:  A jump in Execute means the fetched instruction in
//                Decode is invalid and must be flushed.
//   SKZ hazard:  Conditional skip may invalidate the next instruction.
//==============================================================================

module hazard_unit (
    // Execute stage signals
    input  wire [2:0] ex_opcode,     // Opcode currently in execute stage
    input  wire [4:0] ex_dest_addr,  // Destination address in execute
    input  wire       ex_writes_mem, // Execute stage writes to memory (STO)
    input  wire       ex_writes_acc, // Execute stage writes to accumulator

    // Decode stage signals
    input  wire [2:0] id_opcode,     // Opcode currently in decode stage
    input  wire [4:0] id_src_addr,   // Source address in decode stage
    input  wire       id_reads_mem,  // Decode stage reads from memory

    // ALU status
    input  wire       is_zero,       // ALU zero flag (for SKZ detection)

    // Hazard control outputs
    output wire       stall,         // Stall the pipeline (insert bubble)
    output wire       forward,       // Forward data from execute to decode
    output wire       flush          // Flush the pipeline (branch taken)
);

    //--------------------------------------------------------------------------
    // RAW (Read After Write) hazard detection
    //--------------------------------------------------------------------------
    // A RAW hazard occurs when:
    //   - Execute stage writes to memory (STO instruction)
    //   - Decode stage reads from the same address
    wire raw_hazard;
    assign raw_hazard = ex_writes_mem && id_reads_mem &&
                        (ex_dest_addr == id_src_addr);

    //--------------------------------------------------------------------------
    // Data forwarding detection
    //--------------------------------------------------------------------------
    // Forwarding is possible when:
    //   - Execute stage produces a result in the accumulator (ADD, AND, XOR, LDA)
    //   - Decode stage needs the accumulator value
    //   - The addresses match
    wire forward_possible;
    assign forward_possible = ex_writes_acc && id_reads_mem &&
                              (ex_dest_addr == id_src_addr);

    //--------------------------------------------------------------------------
    // Control flow hazard detection (branch/jump)
    //--------------------------------------------------------------------------
    // JMP: unconditional jump always causes a flush
    wire jmp_hazard;
    assign jmp_hazard = (ex_opcode == 3'b111);  // JMP

    // SKZ: conditional skip causes a flush only when accumulator is zero
    wire skz_hazard;
    assign skz_hazard = (ex_opcode == 3'b001) && is_zero;  // SKZ & zero

    //--------------------------------------------------------------------------
    // Output generation
    //--------------------------------------------------------------------------
    // Stall: RAW hazard that cannot be forwarded (STO followed by read)
    assign stall = raw_hazard && !forward_possible;

    // Forward: RAW hazard that CAN be forwarded (ALU result available)
    assign forward = forward_possible && !raw_hazard;

    // Flush: Branch/jump taken, invalidate fetched instruction
    assign flush = jmp_hazard || skz_hazard;

endmodule

// --- END OF hazard_unit.v ---

//==============================================================================
// --- START OF memory.v ---
//==============================================================================
//==============================================================================
// Module: memory
// Description: 32x8-bit memory with single bidirectional data port.
//              - 5-bit address, 8-bit data.
//              - Read and write are mutually exclusive.
//              - Write: synchronous (on rising edge of clk when wr is asserted).
//              - Read: combinational (when rd is asserted, data is driven out).
//              - Bidirectional data port uses tri-state buffer for read output.
//              - Supports $readmemb for initial program loading.
//==============================================================================

module memory (
    input  wire       clk,
    input  wire       rd,        // Read enable
    input  wire       wr,        // Write enable
    input  wire [4:0] addr,      // 5-bit address
    inout  wire [7:0] data       // Bidirectional 8-bit data port
);

    // Internal memory array: 32 locations x 8 bits
    reg [7:0] mem [0:31];

    // Tri-state buffer: drive data bus during read, high-Z otherwise
    assign data = (rd && !wr) ? mem[addr] : 8'bz;

    // Synchronous write
    always @(posedge clk) begin
        if (wr && !rd) begin
            mem[addr] <= data;
        end
    end

endmodule

// --- END OF memory.v ---

//==============================================================================
// --- START OF multiplier.v ---
//==============================================================================
//==============================================================================
// Module: multiplier
// Description: Sequential 8-bit x 8-bit unsigned multiplier using
//              shift-and-add algorithm.
//              - Produces 16-bit product.
//              - Start/done handshake protocol.
//              - Takes 8 clock cycles to complete after start.
//              - Synchronous reset (active high).
//
// Operation:
//   1. Assert start=1 with valid multiplicand and multiplier_in for 1 cycle.
//   2. Module asserts busy=1 while computing.
//   3. After 8 clock cycles, done=1 is asserted for 1 cycle with valid product.
//==============================================================================

module multiplier (
    input  wire        clk,
    input  wire        rst,
    input  wire        start,          // Start computation
    input  wire [7:0]  multiplicand,   // 8-bit input A
    input  wire [7:0]  multiplier_in,  // 8-bit input B
    output reg  [15:0] product,        // 16-bit result
    output reg         done,           // Computation complete (1 cycle pulse)
    output reg         busy            // Currently computing
);

    // Internal registers
    reg [15:0] a_reg;    // Shifted multiplicand (grows to 16-bit)
    reg [7:0]  b_reg;    // Multiplier being shifted right
    reg [15:0] acc;      // Accumulator for partial products
    reg [3:0]  count;    // Bit counter (0 to 7)

    always @(posedge clk) begin
        if (rst) begin
            product <= 16'b0;
            done    <= 1'b0;
            busy    <= 1'b0;
            a_reg   <= 16'b0;
            b_reg   <= 8'b0;
            acc     <= 16'b0;
            count   <= 4'b0;
        end else if (start && !busy) begin
            // Latch inputs, start computation
            a_reg   <= {8'b0, multiplicand};
            b_reg   <= multiplier_in;
            acc     <= 16'b0;
            count   <= 4'd0;
            busy    <= 1'b1;
            done    <= 1'b0;
        end else if (busy) begin
            if (count < 4'd8) begin
                // Shift-and-add: if LSB of multiplier is 1, add shifted multiplicand
                if (b_reg[0])
                    acc <= acc + a_reg;
                a_reg <= a_reg << 1;   // Shift multiplicand left
                b_reg <= b_reg >> 1;   // Shift multiplier right
                count <= count + 4'd1;
            end else begin
                // Computation complete
                product <= acc;
                done    <= 1'b1;
                busy    <= 1'b0;
            end
        end else begin
            done <= 1'b0;  // Clear done after 1 cycle
        end
    end

endmodule

// --- END OF multiplier.v ---

//==============================================================================
// --- START OF program_counter.v ---
//==============================================================================
//==============================================================================
// Module: program_counter
// Description: 5-bit synchronous program counter with load capability.
//              - Resets to 0 on active-high synchronous reset.
//              - Loads external value when ld_pc is asserted.
//              - Increments by 1 when inc_pc is asserted.
//              - Operates on rising edge of clk.
//==============================================================================

module program_counter (
    input  wire       clk,
    input  wire       rst,
    input  wire       ld_pc,    // Load program counter from data_in
    input  wire       inc_pc,   // Increment program counter
    input  wire [4:0] data_in,  // Data to load into PC
    output reg  [4:0] pc_out    // Current program counter value
);

    always @(posedge clk) begin
        if (rst) begin
            pc_out <= 5'b0;
        end else if (ld_pc) begin
            pc_out <= data_in;
        end else if (inc_pc) begin
            pc_out <= pc_out + 5'b1;
        end
    end

endmodule

// --- END OF program_counter.v ---

//==============================================================================
// --- START OF register.v ---
//==============================================================================
//==============================================================================
// Module: register
// Description: Generic 8-bit register with synchronous reset and load enable.
//              - Used for both Instruction Register (IR) and Accumulator (ACC).
//              - Active-high synchronous reset clears output to 0.
//              - When load is asserted, data_in is captured on rising clk edge.
//              - When load is de-asserted, output holds its value.
//==============================================================================

module register (
    input  wire       clk,
    input  wire       rst,
    input  wire       load,      // Load enable
    input  wire [7:0] data_in,   // Data input
    output reg  [7:0] data_out   // Data output
);

    always @(posedge clk) begin
        if (rst) begin
            data_out <= 8'b0;
        end else if (load) begin
            data_out <= data_in;
        end
    end

endmodule

// --- END OF register.v ---

//==============================================================================
// --- START OF risc_cpu.v ---
//==============================================================================
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

// --- END OF risc_cpu.v ---

