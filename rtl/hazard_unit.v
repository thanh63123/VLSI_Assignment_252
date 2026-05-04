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
