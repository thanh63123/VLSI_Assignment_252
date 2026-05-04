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
