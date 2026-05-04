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
