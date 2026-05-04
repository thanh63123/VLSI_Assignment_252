//==============================================================================
// Testbench: tb_hazard_unit
// Description: Verifies hazard detection including RAW hazards, forwarding,
//              stalling, and control flow flushing.
//==============================================================================

`timescale 1ns/1ps

module tb_hazard_unit;

    reg  [2:0] ex_opcode;
    reg  [4:0] ex_dest_addr;
    reg        ex_writes_mem;
    reg        ex_writes_acc;
    reg  [2:0] id_opcode;
    reg  [4:0] id_src_addr;
    reg        id_reads_mem;
    reg        is_zero;
    wire       stall;
    wire       forward;
    wire       flush;

    integer pass_count = 0;
    integer fail_count = 0;

    hazard_unit dut (
        .ex_opcode(ex_opcode), .ex_dest_addr(ex_dest_addr),
        .ex_writes_mem(ex_writes_mem), .ex_writes_acc(ex_writes_acc),
        .id_opcode(id_opcode), .id_src_addr(id_src_addr),
        .id_reads_mem(id_reads_mem), .is_zero(is_zero),
        .stall(stall), .forward(forward), .flush(flush)
    );

    task check;
        input exp_stall, exp_forward, exp_flush;
        input [255:0] test_name;
        begin
            #1;
            if (stall !== exp_stall || forward !== exp_forward || flush !== exp_flush) begin
                $display("FAIL: %0s", test_name);
                $display("  Expected: stall=%b forward=%b flush=%b",
                         exp_stall, exp_forward, exp_flush);
                $display("  Got:      stall=%b forward=%b flush=%b",
                         stall, forward, flush);
                fail_count = fail_count + 1;
            end else begin
                $display("PASS: %0s - stall=%b fwd=%b flush=%b",
                         test_name, stall, forward, flush);
                pass_count = pass_count + 1;
            end
        end
    endtask

    initial begin
        $display("\n========================================");
        $display("Hazard Detection Unit Testbench");
        $display("========================================\n");

        // 1. No hazard: different addresses
        ex_opcode = 3'b110; ex_dest_addr = 5'd10; ex_writes_mem = 1; ex_writes_acc = 0;
        id_opcode = 3'b101; id_src_addr  = 5'd20; id_reads_mem  = 1; is_zero = 0;
        check(1'b0, 1'b0, 1'b0, "No hazard: different addresses");

        // 2. RAW hazard: STO writes, next reads same addr -> stall
        ex_opcode = 3'b110; ex_dest_addr = 5'd15; ex_writes_mem = 1; ex_writes_acc = 0;
        id_opcode = 3'b101; id_src_addr  = 5'd15; id_reads_mem  = 1; is_zero = 0;
        check(1'b1, 1'b0, 1'b0, "RAW stall: STO->LDA same addr");

        // 3. Forward possible: ALU writes acc, next reads same addr
        ex_opcode = 3'b010; ex_dest_addr = 5'd15; ex_writes_mem = 0; ex_writes_acc = 1;
        id_opcode = 3'b101; id_src_addr  = 5'd15; id_reads_mem  = 1; is_zero = 0;
        check(1'b0, 1'b1, 1'b0, "Forward: ADD result available");

        // 4. No hazard: execute doesn't write
        ex_opcode = 3'b001; ex_dest_addr = 5'd15; ex_writes_mem = 0; ex_writes_acc = 0;
        id_opcode = 3'b101; id_src_addr  = 5'd15; id_reads_mem  = 1; is_zero = 0;
        check(1'b0, 1'b0, 1'b0, "No hazard: execute doesn't write");

        // 5. No hazard: decode doesn't read
        ex_opcode = 3'b110; ex_dest_addr = 5'd15; ex_writes_mem = 1; ex_writes_acc = 0;
        id_opcode = 3'b110; id_src_addr  = 5'd15; id_reads_mem  = 0; is_zero = 0;
        check(1'b0, 1'b0, 1'b0, "No hazard: decode doesn't read");

        // 6. JMP flush
        ex_opcode = 3'b111; ex_dest_addr = 5'd5; ex_writes_mem = 0; ex_writes_acc = 0;
        id_opcode = 3'b000; id_src_addr  = 5'd0; id_reads_mem  = 0; is_zero = 0;
        check(1'b0, 1'b0, 1'b1, "Flush: JMP instruction");

        // 7. SKZ flush (zero=1)
        ex_opcode = 3'b001; ex_dest_addr = 5'd0; ex_writes_mem = 0; ex_writes_acc = 0;
        id_opcode = 3'b000; id_src_addr  = 5'd0; id_reads_mem  = 0; is_zero = 1;
        check(1'b0, 1'b0, 1'b1, "Flush: SKZ with zero=1");

        // 8. SKZ no flush (zero=0)
        ex_opcode = 3'b001; ex_dest_addr = 5'd0; ex_writes_mem = 0; ex_writes_acc = 0;
        id_opcode = 3'b000; id_src_addr  = 5'd0; id_reads_mem  = 0; is_zero = 0;
        check(1'b0, 1'b0, 1'b0, "No flush: SKZ with zero=0");

        // 9. HLT: no hazard
        ex_opcode = 3'b000; ex_dest_addr = 5'd0; ex_writes_mem = 0; ex_writes_acc = 0;
        id_opcode = 3'b000; id_src_addr  = 5'd0; id_reads_mem  = 0; is_zero = 0;
        check(1'b0, 1'b0, 1'b0, "No hazard: HLT instruction");

        // 10. Forward with AND opcode
        ex_opcode = 3'b011; ex_dest_addr = 5'd20; ex_writes_mem = 0; ex_writes_acc = 1;
        id_opcode = 3'b010; id_src_addr  = 5'd20; id_reads_mem  = 1; is_zero = 0;
        check(1'b0, 1'b1, 1'b0, "Forward: AND result to ADD");

        $display("\n========================================");
        $display("Hazard Unit TB: %0d PASSED, %0d FAILED", pass_count, fail_count);
        $display("========================================\n");
        $finish;
    end

    initial begin
        $dumpfile("tb_hazard_unit.vcd");
        $dumpvars(0, tb_hazard_unit);
    end

endmodule
