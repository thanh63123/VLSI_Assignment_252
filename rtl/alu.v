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
