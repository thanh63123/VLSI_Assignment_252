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
