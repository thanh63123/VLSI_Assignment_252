//==============================================================================
// Testbench: tb_controller
// Description: Verifies controller FSM state transitions and output signals.
//==============================================================================

`timescale 1ns/1ps

module tb_controller;

    reg        clk;
    reg        rst;
    reg  [2:0] opcode;
    reg        is_zero;
    wire       sel, rd, ld_ir, halt, inc_pc, ld_ac, ld_pc, wr, data_e;

    integer pass_count = 0;
    integer fail_count = 0;

    controller dut (
        .clk     (clk),
        .rst     (rst),
        .opcode  (opcode),
        .is_zero (is_zero),
        .sel     (sel),
        .rd      (rd),
        .ld_ir   (ld_ir),
        .halt    (halt),
        .inc_pc  (inc_pc),
        .ld_ac   (ld_ac),
        .ld_pc   (ld_pc),
        .wr      (wr),
        .data_e  (data_e)
    );

    initial clk = 0;
    always #5 clk = ~clk;

    task check_outputs;
        input exp_sel, exp_rd, exp_ld_ir, exp_halt, exp_inc_pc;
        input exp_ld_ac, exp_ld_pc, exp_wr, exp_data_e;
        input [255:0] test_name;
        begin
            if (sel !== exp_sel || rd !== exp_rd || ld_ir !== exp_ld_ir ||
                halt !== exp_halt || inc_pc !== exp_inc_pc || ld_ac !== exp_ld_ac ||
                ld_pc !== exp_ld_pc || wr !== exp_wr || data_e !== exp_data_e) begin
                $display("FAIL: %0s", test_name);
                $display("  Expected: sel=%b rd=%b ld_ir=%b halt=%b inc_pc=%b ld_ac=%b ld_pc=%b wr=%b data_e=%b",
                         exp_sel, exp_rd, exp_ld_ir, exp_halt, exp_inc_pc, exp_ld_ac, exp_ld_pc, exp_wr, exp_data_e);
                $display("  Got:      sel=%b rd=%b ld_ir=%b halt=%b inc_pc=%b ld_ac=%b ld_pc=%b wr=%b data_e=%b",
                         sel, rd, ld_ir, halt, inc_pc, ld_ac, ld_pc, wr, data_e);
                fail_count = fail_count + 1;
            end else begin
                $display("PASS: %0s", test_name);
                pass_count = pass_count + 1;
            end
        end
    endtask

    initial begin
        rst     = 1;
        opcode  = 3'b010; // ADD
        is_zero = 0;

        @(posedge clk); #1;
        // After reset, state = INST_ADDR
        check_outputs(1,0,0,0,0,0,0,0,0, "INST_ADDR after reset (ADD)");

        rst = 0;
        @(posedge clk); #1;
        check_outputs(1,1,0,0,0,0,0,0,0, "INST_FETCH (ADD)");

        @(posedge clk); #1;
        check_outputs(1,1,1,0,0,0,0,0,0, "INST_LOAD (ADD)");

        @(posedge clk); #1;
        check_outputs(1,1,1,0,0,0,0,0,0, "IDLE (ADD)");

        @(posedge clk); #1;
        check_outputs(0,0,0,0,1,0,0,0,0, "OP_ADDR (ADD)");

        @(posedge clk); #1;
        // ADD is ALUOP, so rd=1
        check_outputs(0,1,0,0,0,0,0,0,0, "OP_FETCH (ADD)");

        @(posedge clk); #1;
        check_outputs(0,1,0,0,0,0,0,0,0, "ALU_OP (ADD)");

        @(posedge clk); #1;
        // STORE: ld_ac=1 (ALUOP), rd=1 (ALUOP)
        check_outputs(0,1,0,0,0,1,0,0,0, "STORE (ADD)");

        // Test HLT instruction
        @(posedge clk); #1; // back to INST_ADDR
        opcode = 3'b000; // HLT
        // go through fetch phases
        @(posedge clk); #1; // INST_FETCH
        @(posedge clk); #1; // INST_LOAD
        @(posedge clk); #1; // IDLE
        @(posedge clk); #1; // OP_ADDR
        check_outputs(0,0,0,1,1,0,0,0,0, "OP_ADDR (HLT) - halt=1");

        // Test JMP instruction
        rst = 1;
        @(posedge clk); #1;
        rst = 0;
        opcode = 3'b111; // JMP
        // INST_ADDR -> INST_FETCH -> INST_LOAD -> IDLE -> OP_ADDR -> OP_FETCH -> ALU_OP -> STORE
        @(posedge clk); #1; // INST_FETCH
        @(posedge clk); #1; // INST_LOAD
        @(posedge clk); #1; // IDLE
        @(posedge clk); #1; // OP_ADDR
        @(posedge clk); #1; // OP_FETCH
        @(posedge clk); #1; // ALU_OP
        check_outputs(0,0,0,0,0,0,1,0,0, "ALU_OP (JMP) - ld_pc=1");
        @(posedge clk); #1; // STORE
        check_outputs(0,0,0,0,0,0,1,0,0, "STORE (JMP) - ld_pc=1");

        // Test STO instruction
        rst = 1;
        @(posedge clk); #1;
        rst = 0;
        opcode = 3'b110; // STO
        @(posedge clk); #1; // INST_FETCH
        @(posedge clk); #1; // INST_LOAD
        @(posedge clk); #1; // IDLE
        @(posedge clk); #1; // OP_ADDR
        @(posedge clk); #1; // OP_FETCH
        @(posedge clk); #1; // ALU_OP
        check_outputs(0,0,0,0,0,0,0,0,1, "ALU_OP (STO) - data_e=1");
        @(posedge clk); #1; // STORE
        check_outputs(0,0,0,0,0,0,0,1,1, "STORE (STO) - wr=1,data_e=1");

        // Test SKZ with is_zero=1
        rst = 1;
        @(posedge clk); #1;
        rst = 0;
        opcode  = 3'b001; // SKZ
        is_zero = 1;
        @(posedge clk); #1; // INST_FETCH
        @(posedge clk); #1; // INST_LOAD
        @(posedge clk); #1; // IDLE
        @(posedge clk); #1; // OP_ADDR
        @(posedge clk); #1; // OP_FETCH
        @(posedge clk); #1; // ALU_OP
        check_outputs(0,0,0,0,1,0,0,0,0, "ALU_OP (SKZ,zero=1) - inc_pc=1");

        // Test SKZ with is_zero=0
        rst = 1;
        @(posedge clk); #1;
        rst = 0;
        opcode  = 3'b001;
        is_zero = 0;
        @(posedge clk); #1; // INST_FETCH
        @(posedge clk); #1; // INST_LOAD
        @(posedge clk); #1; // IDLE
        @(posedge clk); #1; // OP_ADDR
        @(posedge clk); #1; // OP_FETCH
        @(posedge clk); #1; // ALU_OP
        check_outputs(0,0,0,0,0,0,0,0,0, "ALU_OP (SKZ,zero=0) - inc_pc=0");

        $display("\n========================================");
        $display("Controller TB: %0d PASSED, %0d FAILED", pass_count, fail_count);
        $display("========================================\n");
        $finish;
    end

    initial begin
        $dumpfile("tb_controller.vcd");
        $dumpvars(0, tb_controller);
    end

endmodule
