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
