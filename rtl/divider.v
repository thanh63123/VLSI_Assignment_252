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
