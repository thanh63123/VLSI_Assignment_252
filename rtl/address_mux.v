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
