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
