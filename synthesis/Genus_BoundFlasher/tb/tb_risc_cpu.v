`timescale 1ns/1ps

//==============================================================================
// --- START OF tb_address_mux.v ---
//==============================================================================
//==============================================================================
// Testbench: tb_address_mux
// Description: Verifies address mux selection between PC and IR addresses.
//==============================================================================


module tb_address_mux;

    reg        sel;
    reg  [4:0] pc_addr;
    reg  [4:0] ir_addr;
    wire [4:0] addr_out;

    integer pass_count = 0;
    integer fail_count = 0;

    // Instantiate DUT
    address_mux #(.WIDTH(5)) dut (
        .sel      (sel),
        .pc_addr  (pc_addr),
        .ir_addr  (ir_addr),
        .addr_out (addr_out)
    );

    task check;
        input [4:0] expected;
        input [255:0] test_name;
        begin
            #1;
            if (addr_out !== expected) begin
                $display("FAIL: %0s - Expected %0d, Got %0d", test_name, expected, addr_out);
                fail_count = fail_count + 1;
            end else begin
                $display("PASS: %0s - addr_out = %0d", test_name, addr_out);
                pass_count = pass_count + 1;
            end
        end
    endtask

    initial begin
        // Test 1: sel=1 selects PC address
        pc_addr = 5'd10;
        ir_addr = 5'd20;
        sel     = 1;
        check(5'd10, "sel=1 selects PC address");

        // Test 2: sel=0 selects IR address
        sel = 0;
        check(5'd20, "sel=0 selects IR address");

        // Test 3: Change PC address with sel=1
        sel     = 1;
        pc_addr = 5'd31;
        check(5'd31, "sel=1 with new PC address");

        // Test 4: Change IR address with sel=0
        sel     = 0;
        ir_addr = 5'd0;
        check(5'd0, "sel=0 with IR address 0");

        // Test 5: Both addresses same value
        pc_addr = 5'd15;
        ir_addr = 5'd15;
        sel     = 1;
        check(5'd15, "Both inputs same, sel=1");
        sel     = 0;
        check(5'd15, "Both inputs same, sel=0");

        // Summary
        $display("\n========================================");
        $display("Address Mux TB: %0d PASSED, %0d FAILED", pass_count, fail_count);
        $display("========================================\n");
        $finish;
    end

    initial begin
//         $recordfile("output/waves_tb_address_mux");
//         $recordvars("depth=0", tb_address_mux);
    end

endmodule

// --- END OF tb_address_mux.v ---

//==============================================================================
// --- START OF tb_alu.v ---
//==============================================================================
//==============================================================================
// Testbench: tb_alu
// Description: Verifies all 8 ALU operations and the is_zero flag.
//==============================================================================


module tb_alu;

    reg  [7:0] inA;
    reg  [7:0] inB;
    reg  [2:0] opcode;
    wire [7:0] alu_out;
    wire       is_zero;

    integer pass_count = 0;
    integer fail_count = 0;

    // Instantiate DUT
    alu dut (
        .inA     (inA),
        .inB     (inB),
        .opcode  (opcode),
        .alu_out (alu_out),
        .is_zero (is_zero)
    );

    task check_alu;
        input [7:0] expected_out;
        input       expected_zero;
        input [255:0] test_name;
        begin
            #1;
            if (alu_out !== expected_out || is_zero !== expected_zero) begin
                $display("FAIL: %0s - Expected out=%b zero=%b, Got out=%b zero=%b",
                         test_name, expected_out, expected_zero, alu_out, is_zero);
                fail_count = fail_count + 1;
            end else begin
                $display("PASS: %0s - out=%b, zero=%b", test_name, alu_out, is_zero);
                pass_count = pass_count + 1;
            end
        end
    endtask

    initial begin
        // === HLT (000) ===
        inA = 8'hAA; inB = 8'h55; opcode = 3'b000;
        check_alu(8'hAA, 1'b0, "HLT: pass through inA");

        inA = 8'h00; inB = 8'h55; opcode = 3'b000;
        check_alu(8'h00, 1'b1, "HLT: inA=0, is_zero=1");

        // === SKZ (001) ===
        inA = 8'hFF; inB = 8'h00; opcode = 3'b001;
        check_alu(8'hFF, 1'b0, "SKZ: pass through inA");

        inA = 8'h00; inB = 8'hFF; opcode = 3'b001;
        check_alu(8'h00, 1'b1, "SKZ: inA=0, is_zero=1");

        // === ADD (010) ===
        inA = 8'h0A; inB = 8'h05; opcode = 3'b010;
        check_alu(8'h0F, 1'b0, "ADD: 10+5=15");

        inA = 8'hFF; inB = 8'h01; opcode = 3'b010;
        check_alu(8'h00, 1'b0, "ADD: 255+1=0 (overflow)");

        inA = 8'h80; inB = 8'h80; opcode = 3'b010;
        check_alu(8'h00, 1'b0, "ADD: 128+128=0 (overflow)");

        // === AND (011) ===
        inA = 8'hFF; inB = 8'h0F; opcode = 3'b011;
        check_alu(8'h0F, 1'b0, "AND: FF & 0F = 0F");

        inA = 8'hAA; inB = 8'h55; opcode = 3'b011;
        check_alu(8'h00, 1'b0, "AND: AA & 55 = 00");

        inA = 8'h00; inB = 8'hFF; opcode = 3'b011;
        check_alu(8'h00, 1'b1, "AND: 00 & FF = 00, is_zero=1");

        // === XOR (100) ===
        inA = 8'hAA; inB = 8'h55; opcode = 3'b100;
        check_alu(8'hFF, 1'b0, "XOR: AA ^ 55 = FF");

        inA = 8'hFF; inB = 8'hFF; opcode = 3'b100;
        check_alu(8'h00, 1'b0, "XOR: FF ^ FF = 00");

        inA = 8'h00; inB = 8'h00; opcode = 3'b100;
        check_alu(8'h00, 1'b1, "XOR: 00 ^ 00 = 00, is_zero=1");

        // === LDA (101) ===
        inA = 8'hAA; inB = 8'h55; opcode = 3'b101;
        check_alu(8'h55, 1'b0, "LDA: pass through inB");

        inA = 8'h00; inB = 8'hBB; opcode = 3'b101;
        check_alu(8'hBB, 1'b1, "LDA: inA=0 pass through inB, is_zero=1");

        // === STO (110) ===
        inA = 8'hCC; inB = 8'h00; opcode = 3'b110;
        check_alu(8'hCC, 1'b0, "STO: pass through inA");

        // === JMP (111) ===
        inA = 8'hDD; inB = 8'h00; opcode = 3'b111;
        check_alu(8'hDD, 1'b0, "JMP: pass through inA");

        // Summary
        $display("\n========================================");
        $display("ALU TB: %0d PASSED, %0d FAILED", pass_count, fail_count);
        $display("========================================\n");
        $finish;
    end

    initial begin
//         $recordfile("output/waves_tb_alu");
//         $recordvars("depth=0", tb_alu);
    end

endmodule

// --- END OF tb_alu.v ---

//==============================================================================
// --- START OF tb_alu_extended.v ---
//==============================================================================
//==============================================================================
// Testbench: tb_alu_extended
// Description: Verifies all 16 operations of the extended ALU including
//              carry, overflow, and is_zero flags.
//==============================================================================


module tb_alu_extended;

    reg  [7:0] inA;
    reg  [7:0] inB;
    reg  [3:0] opcode;
    wire [7:0] alu_out;
    wire       is_zero;
    wire       carry_out;
    wire       overflow;

    integer pass_count = 0;
    integer fail_count = 0;

    // Instantiate DUT
    alu_extended dut (
        .inA       (inA),
        .inB       (inB),
        .opcode    (opcode),
        .alu_out   (alu_out),
        .is_zero   (is_zero),
        .carry_out (carry_out),
        .overflow  (overflow)
    );

    task check;
        input [7:0]   exp_out;
        input         exp_zero;
        input         exp_carry;
        input         exp_ovf;
        input [255:0] test_name;
        begin
            #1;
            if (alu_out !== exp_out || is_zero !== exp_zero ||
                carry_out !== exp_carry || overflow !== exp_ovf) begin
                $display("FAIL: %0s", test_name);
                $display("  Expected: out=%h zero=%b carry=%b ovf=%b",
                         exp_out, exp_zero, exp_carry, exp_ovf);
                $display("  Got:      out=%h zero=%b carry=%b ovf=%b",
                         alu_out, is_zero, carry_out, overflow);
                fail_count = fail_count + 1;
            end else begin
                $display("PASS: %0s - out=%h c=%b v=%b z=%b",
                         test_name, alu_out, carry_out, overflow, is_zero);
                pass_count = pass_count + 1;
            end
        end
    endtask

    initial begin
        $display("\n========================================");
        $display("Extended ALU Testbench");
        $display("========================================\n");

        // === Original operations (backward compatibility) ===
        // HLT (0000)
        inA = 8'hAA; inB = 8'h55; opcode = 4'b0000;
        check(8'hAA, 1'b0, 1'b0, 1'b0, "HLT: pass through inA");

        // SKZ (0001)
        inA = 8'h00; inB = 8'hFF; opcode = 4'b0001;
        check(8'h00, 1'b1, 1'b0, 1'b0, "SKZ: inA=0, is_zero=1");

        // ADD (0010) - no carry
        inA = 8'h0A; inB = 8'h05; opcode = 4'b0010;
        check(8'h0F, 1'b0, 1'b0, 1'b0, "ADD: 10+5=15, no carry");

        // ADD (0010) - with carry
        inA = 8'hFF; inB = 8'h01; opcode = 4'b0010;
        check(8'h00, 1'b0, 1'b1, 1'b0, "ADD: FF+01=00, carry=1");

        // ADD (0010) - with overflow
        inA = 8'h7F; inB = 8'h01; opcode = 4'b0010;
        check(8'h80, 1'b0, 1'b0, 1'b1, "ADD: 127+1=128, overflow=1");

        // AND (0011)
        inA = 8'hFF; inB = 8'h0F; opcode = 4'b0011;
        check(8'h0F, 1'b0, 1'b0, 1'b0, "AND: FF & 0F = 0F");

        // XOR (0100)
        inA = 8'hAA; inB = 8'h55; opcode = 4'b0100;
        check(8'hFF, 1'b0, 1'b0, 1'b0, "XOR: AA ^ 55 = FF");

        // LDA (0101)
        inA = 8'hAA; inB = 8'h55; opcode = 4'b0101;
        check(8'h55, 1'b0, 1'b0, 1'b0, "LDA: pass through inB");

        // STO (0110)
        inA = 8'hCC; inB = 8'h00; opcode = 4'b0110;
        check(8'hCC, 1'b0, 1'b0, 1'b0, "STO: pass through inA");

        // JMP (0111)
        inA = 8'hDD; inB = 8'h00; opcode = 4'b0111;
        check(8'hDD, 1'b0, 1'b0, 1'b0, "JMP: pass through inA");

        // === Extended operations ===
        // SUB (1000) - no borrow
        inA = 8'h0A; inB = 8'h05; opcode = 4'b1000;
        check(8'h05, 1'b0, 1'b0, 1'b0, "SUB: 10-5=5, no borrow");

        // SUB (1000) - with borrow
        inA = 8'h05; inB = 8'h0A; opcode = 4'b1000;
        check(8'hFB, 1'b0, 1'b1, 1'b0, "SUB: 5-10=FB, borrow=1");

        // SUB (1000) - with overflow
        inA = 8'h80; inB = 8'h01; opcode = 4'b1000;
        check(8'h7F, 1'b0, 1'b0, 1'b1, "SUB: -128-1=127, overflow=1");

        // SUB (1000) - equal values
        inA = 8'hAA; inB = 8'hAA; opcode = 4'b1000;
        check(8'h00, 1'b0, 1'b0, 1'b0, "SUB: AA-AA=0");

        // NOT (1001)
        inA = 8'hAA; inB = 8'h00; opcode = 4'b1001;
        check(8'h55, 1'b0, 1'b0, 1'b0, "NOT: ~AA = 55");

        inA = 8'h00; inB = 8'h00; opcode = 4'b1001;
        check(8'hFF, 1'b1, 1'b0, 1'b0, "NOT: ~00 = FF, is_zero=1");

        // SHL (1010) - shift left
        inA = 8'h55; inB = 8'h00; opcode = 4'b1010;
        check(8'hAA, 1'b0, 1'b0, 1'b0, "SHL: 55<<1 = AA, carry=0");

        inA = 8'h80; inB = 8'h00; opcode = 4'b1010;
        check(8'h00, 1'b0, 1'b1, 1'b0, "SHL: 80<<1 = 00, carry=1");

        inA = 8'hC5; inB = 8'h00; opcode = 4'b1010;
        check(8'h8A, 1'b0, 1'b1, 1'b0, "SHL: C5<<1 = 8A, carry=1");

        // SHR (1011) - shift right
        inA = 8'hAA; inB = 8'h00; opcode = 4'b1011;
        check(8'h55, 1'b0, 1'b0, 1'b0, "SHR: AA>>1 = 55, carry=0");

        inA = 8'h01; inB = 8'h00; opcode = 4'b1011;
        check(8'h00, 1'b0, 1'b1, 1'b0, "SHR: 01>>1 = 00, carry=1");

        inA = 8'hFF; inB = 8'h00; opcode = 4'b1011;
        check(8'h7F, 1'b0, 1'b1, 1'b0, "SHR: FF>>1 = 7F, carry=1");

        // ROL (1100) - rotate left
        inA = 8'h81; inB = 8'h00; opcode = 4'b1100;
        check(8'h03, 1'b0, 1'b0, 1'b0, "ROL: 81 -> 03");

        inA = 8'hA5; inB = 8'h00; opcode = 4'b1100;
        check(8'h4B, 1'b0, 1'b0, 1'b0, "ROL: A5 -> 4B");

        // ROR (1101) - rotate right
        inA = 8'h81; inB = 8'h00; opcode = 4'b1101;
        check(8'hC0, 1'b0, 1'b0, 1'b0, "ROR: 81 -> C0");

        inA = 8'hA5; inB = 8'h00; opcode = 4'b1101;
        check(8'hD2, 1'b0, 1'b0, 1'b0, "ROR: A5 -> D2");

        // CMP (1110) - compare
        inA = 8'h0A; inB = 8'h05; opcode = 4'b1110;
        check(8'h05, 1'b0, 1'b0, 1'b0, "CMP: 10>5, borrow=0");

        inA = 8'h05; inB = 8'h0A; opcode = 4'b1110;
        check(8'hFB, 1'b0, 1'b1, 1'b0, "CMP: 5<10, borrow=1");

        inA = 8'h0A; inB = 8'h0A; opcode = 4'b1110;
        check(8'h00, 1'b0, 1'b0, 1'b0, "CMP: 10==10, result=0");

        // MUL (1111) - 4-bit multiply
        inA = 8'h03; inB = 8'h04; opcode = 4'b1111;
        check(8'h0C, 1'b0, 1'b0, 1'b0, "MUL: 3*4=12");

        inA = 8'h0F; inB = 8'h0F; opcode = 4'b1111;
        check(8'hE1, 1'b0, 1'b0, 1'b0, "MUL: 15*15=225");

        inA = 8'h00; inB = 8'h0F; opcode = 4'b1111;
        check(8'h00, 1'b1, 1'b0, 1'b0, "MUL: 0*15=0, is_zero=1");

        inA = 8'hF7; inB = 8'hF5; opcode = 4'b1111;
        check(8'h23, 1'b0, 1'b0, 1'b0, "MUL: 7*5=35 (upper bits ignored)");

        // Summary
        $display("\n========================================");
        $display("Extended ALU TB: %0d PASSED, %0d FAILED", pass_count, fail_count);
        $display("========================================\n");
        $finish;
    end

    initial begin
//         $recordfile("output/waves_tb_alu_extended");
//         $recordvars("depth=0", tb_alu_extended);
    end

endmodule

// --- END OF tb_alu_extended.v ---

//==============================================================================
// --- START OF tb_controller.v ---
//==============================================================================
//==============================================================================
// Testbench: tb_controller
// Description: Verifies controller FSM state transitions and output signals.
//==============================================================================


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
//         $recordfile("output/waves_tb_controller");
//         $recordvars("depth=0", tb_controller);
    end

endmodule

// --- END OF tb_controller.v ---

//==============================================================================
// --- START OF tb_divider.v ---
//==============================================================================
//==============================================================================
// Testbench: tb_divider
// Description: Verifies the sequential restoring division algorithm.
//==============================================================================


module tb_divider;

    reg        clk, rst, start;
    reg  [7:0] dividend, divisor;
    wire [7:0] quotient, remainder;
    wire       done, busy, div_by_zero;

    integer pass_count = 0;
    integer fail_count = 0;

    divider dut (
        .clk(clk), .rst(rst), .start(start),
        .dividend(dividend), .divisor(divisor),
        .quotient(quotient), .remainder(remainder),
        .done(done), .busy(busy), .div_by_zero(div_by_zero)
    );

    initial clk = 0;
    always #5 clk = ~clk;

    task divide_and_check;
        input [7:0] a, b, exp_q, exp_r;
        input exp_dbz;
        input [255:0] test_name;
        begin
            dividend = a; divisor = b;
            start = 1;
            @(posedge clk); #1;
            start = 0;
            begin : wait_done
                integer timeout;
                timeout = 0;
                while (done !== 1'b1 && timeout < 20) begin
                    @(posedge clk); #1;
                    timeout = timeout + 1;
                end
                if (timeout >= 20) begin
                    $display("FAIL: %0s - TIMEOUT", test_name);
                    fail_count = fail_count + 1;
                end else if (exp_dbz) begin
                    if (div_by_zero !== 1'b1) begin
                        $display("FAIL: %0s - Expected div_by_zero=1", test_name);
                        fail_count = fail_count + 1;
                    end else begin
                        $display("PASS: %0s - div_by_zero detected", test_name);
                        pass_count = pass_count + 1;
                    end
                end else if (quotient !== exp_q || remainder !== exp_r) begin
                    $display("FAIL: %0s - Expected Q=%0d R=%0d, Got Q=%0d R=%0d",
                             test_name, exp_q, exp_r, quotient, remainder);
                    fail_count = fail_count + 1;
                end else begin
                    $display("PASS: %0s - %0d/%0d = Q%0d R%0d",
                             test_name, a, b, quotient, remainder);
                    pass_count = pass_count + 1;
                end
            end
            @(posedge clk); #1;
        end
    endtask

    initial begin
        $display("\n========================================");
        $display("Divider Testbench");
        $display("========================================\n");
        rst = 1; start = 0; dividend = 0; divisor = 0;
        repeat(3) @(posedge clk); rst = 0;
        @(posedge clk); #1;

        divide_and_check(8'd12,  8'd3,   8'd4,   8'd0,  1'b0, "12/3=Q4 R0");
        divide_and_check(8'd10,  8'd3,   8'd3,   8'd1,  1'b0, "10/3=Q3 R1");
        divide_and_check(8'd100, 8'd10,  8'd10,  8'd0,  1'b0, "100/10=Q10 R0");
        divide_and_check(8'd255, 8'd1,   8'd255, 8'd0,  1'b0, "255/1=Q255 R0");
        divide_and_check(8'd1,   8'd1,   8'd1,   8'd0,  1'b0, "1/1=Q1 R0");
        divide_and_check(8'd0,   8'd5,   8'd0,   8'd0,  1'b0, "0/5=Q0 R0");
        divide_and_check(8'd7,   8'd10,  8'd0,   8'd7,  1'b0, "7/10=Q0 R7");
        divide_and_check(8'd255, 8'd255, 8'd1,   8'd0,  1'b0, "255/255=Q1 R0");
        divide_and_check(8'd255, 8'd128, 8'd1,   8'd127,1'b0, "255/128=Q1 R127");
        divide_and_check(8'd200, 8'd13,  8'd15,  8'd5,  1'b0, "200/13=Q15 R5");
        divide_and_check(8'd144, 8'd12,  8'd12,  8'd0,  1'b0, "144/12=Q12 R0");
        divide_and_check(8'd100, 8'd0,   8'd0,   8'd0,  1'b1, "100/0=div_by_zero");
        divide_and_check(8'd0,   8'd0,   8'd0,   8'd0,  1'b1, "0/0=div_by_zero");

        $display("\n========================================");
        $display("Divider TB: %0d PASSED, %0d FAILED", pass_count, fail_count);
        $display("========================================\n");
        $finish;
    end

    initial begin
//         $recordfile("output/waves_tb_divider");
//         $recordvars("depth=0", tb_divider);
    end

endmodule

// --- END OF tb_divider.v ---

//==============================================================================
// --- START OF tb_hazard_unit.v ---
//==============================================================================
//==============================================================================
// Testbench: tb_hazard_unit
// Description: Verifies hazard detection including RAW hazards, forwarding,
//              stalling, and control flow flushing.
//==============================================================================


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
//         $recordfile("output/waves_tb_hazard_unit");
//         $recordvars("depth=0", tb_hazard_unit);
    end

endmodule

// --- END OF tb_hazard_unit.v ---

//==============================================================================
// --- START OF tb_memory.v ---
//==============================================================================
//==============================================================================
// Testbench: tb_memory
// Description: Verifies memory read, write, and bidirectional port behavior.
//==============================================================================


module tb_memory;

    reg        clk;
    reg        rd;
    reg        wr;
    reg  [4:0] addr;
    wire [7:0] data;

    reg  [7:0] data_driver;
    reg        drive_data;

    assign data = drive_data ? data_driver : 8'bz;

    integer pass_count = 0;
    integer fail_count = 0;

    memory dut (
        .clk  (clk),
        .rd   (rd),
        .wr   (wr),
        .addr (addr),
        .data (data)
    );

    initial clk = 0;
    always #5 clk = ~clk;

    task check_read;
        input [7:0] expected;
        input [255:0] test_name;
        begin
            #1;
            if (data !== expected) begin
                $display("FAIL: %0s - Expected %0h, Got %0h", test_name, expected, data);
                fail_count = fail_count + 1;
            end else begin
                $display("PASS: %0s - data = %0h", test_name, data);
                pass_count = pass_count + 1;
            end
        end
    endtask

    initial begin
        rd = 0; wr = 0; addr = 5'b0; data_driver = 8'b0; drive_data = 0;

        // Write AA to addr 0
        drive_data = 1; data_driver = 8'hAA; addr = 5'd0; wr = 1;
        @(posedge clk); #1;
        wr = 0; drive_data = 0;

        // Read back addr 0
        rd = 1; addr = 5'd0;
        check_read(8'hAA, "Read AA from addr 0");
        rd = 0;

        // Write 55 to addr 5
        drive_data = 1; data_driver = 8'h55; addr = 5'd5; wr = 1;
        @(posedge clk); #1;
        wr = 0; drive_data = 0;

        // Read back addr 5
        rd = 1; addr = 5'd5;
        check_read(8'h55, "Read 55 from addr 5");

        // Addr 0 still has AA
        addr = 5'd0;
        check_read(8'hAA, "Addr 0 still AA");
        rd = 0;

        // Write FF to addr 31
        drive_data = 1; data_driver = 8'hFF; addr = 5'd31; wr = 1;
        @(posedge clk); #1;
        wr = 0; drive_data = 0;

        rd = 1; addr = 5'd31;
        check_read(8'hFF, "Read FF from addr 31");
        rd = 0;

        $display("\n========================================");
        $display("Memory TB: %0d PASSED, %0d FAILED", pass_count, fail_count);
        $display("========================================\n");
        $finish;
    end

    initial begin
//         $recordfile("output/waves_tb_memory");
//         $recordvars("depth=0", tb_memory);
    end

endmodule

// --- END OF tb_memory.v ---

//==============================================================================
// --- START OF tb_multiplier.v ---
//==============================================================================
//==============================================================================
// Testbench: tb_multiplier
// Description: Verifies the sequential shift-and-add 8x8 multiplier.
//              Tests various multiplication cases including edge cases.
//==============================================================================


module tb_multiplier;

    reg         clk;
    reg         rst;
    reg         start;
    reg  [7:0]  multiplicand;
    reg  [7:0]  multiplier_in;
    wire [15:0] product;
    wire        done;
    wire        busy;

    integer pass_count = 0;
    integer fail_count = 0;

    // Instantiate DUT
    multiplier dut (
        .clk           (clk),
        .rst           (rst),
        .start         (start),
        .multiplicand  (multiplicand),
        .multiplier_in (multiplier_in),
        .product       (product),
        .done          (done),
        .busy          (busy)
    );

    // Clock generation: 10ns period
    initial clk = 0;
    always #5 clk = ~clk;

    task multiply_and_check;
        input [7:0]   a;
        input [7:0]   b;
        input [15:0]  expected;
        input [255:0] test_name;
        begin
            // Apply inputs and start
            multiplicand  = a;
            multiplier_in = b;
            start = 1;
            @(posedge clk); #1;
            start = 0;

            // Wait for done
            begin : wait_done
                integer timeout;
                timeout = 0;
                while (done !== 1'b1 && timeout < 20) begin
                    @(posedge clk); #1;
                    timeout = timeout + 1;
                end

                if (timeout >= 20) begin
                    $display("FAIL: %0s - TIMEOUT", test_name);
                    fail_count = fail_count + 1;
                end else if (product !== expected) begin
                    $display("FAIL: %0s - Expected %0d (0x%h), Got %0d (0x%h)",
                             test_name, expected, expected, product, product);
                    fail_count = fail_count + 1;
                end else begin
                    $display("PASS: %0s - %0d * %0d = %0d (0x%h)",
                             test_name, a, b, product, product);
                    pass_count = pass_count + 1;
                end
            end

            // Wait 1 cycle for done to clear
            @(posedge clk); #1;
        end
    endtask

    initial begin
        $display("\n========================================");
        $display("Multiplier Testbench");
        $display("========================================\n");

        // Reset
        rst   = 1;
        start = 0;
        multiplicand  = 0;
        multiplier_in = 0;
        repeat(3) @(posedge clk);
        rst = 0;
        @(posedge clk); #1;

        // Test cases
        multiply_and_check(8'd3,   8'd4,   16'd12,    "3 * 4 = 12");
        multiply_and_check(8'd10,  8'd10,  16'd100,   "10 * 10 = 100");
        multiply_and_check(8'd255, 8'd255, 16'd65025, "255 * 255 = 65025");
        multiply_and_check(8'd0,   8'd100, 16'd0,     "0 * 100 = 0");
        multiply_and_check(8'd100, 8'd0,   16'd0,     "100 * 0 = 0");
        multiply_and_check(8'd1,   8'd1,   16'd1,     "1 * 1 = 1");
        multiply_and_check(8'd1,   8'd255, 16'd255,   "1 * 255 = 255");
        multiply_and_check(8'd128, 8'd2,   16'd256,   "128 * 2 = 256");
        multiply_and_check(8'd7,   8'd13,  16'd91,    "7 * 13 = 91");
        multiply_and_check(8'd200, 8'd150, 16'd30000, "200 * 150 = 30000");
        multiply_and_check(8'd16,  8'd16,  16'd256,   "16 * 16 = 256");
        multiply_and_check(8'd255, 8'd1,   16'd255,   "255 * 1 = 255");

        // Summary
        $display("\n========================================");
        $display("Multiplier TB: %0d PASSED, %0d FAILED", pass_count, fail_count);
        $display("========================================\n");
        $finish;
    end

    initial begin
//         $recordfile("output/waves_tb_multiplier");
//         $recordvars("depth=0", tb_multiplier);
    end

endmodule

// --- END OF tb_multiplier.v ---

//==============================================================================
// --- START OF tb_program_counter.v ---
//==============================================================================
//==============================================================================
// Testbench: tb_program_counter
// Description: Verifies program counter reset, increment, and load operations.
//==============================================================================


module tb_program_counter;

    reg        clk;
    reg        rst;
    reg        ld_pc;
    reg        inc_pc;
    reg  [4:0] data_in;
    wire [4:0] pc_out;

    integer pass_count = 0;
    integer fail_count = 0;

    // Instantiate DUT
    program_counter dut (
        .clk     (clk),
        .rst     (rst),
        .ld_pc   (ld_pc),
        .inc_pc  (inc_pc),
        .data_in (data_in),
        .pc_out  (pc_out)
    );

    // Clock generation: 10ns period
    initial clk = 0;
    always #5 clk = ~clk;

    // Task for checking results
    task check;
        input [4:0] expected;
        input [255:0] test_name;
        begin
            if (pc_out !== expected) begin
                $display("FAIL: %0s - Expected %0d, Got %0d", test_name, expected, pc_out);
                fail_count = fail_count + 1;
            end else begin
                $display("PASS: %0s - pc_out = %0d", test_name, pc_out);
                pass_count = pass_count + 1;
            end
        end
    endtask

    initial begin
        // Initialize
        rst     = 1;
        ld_pc   = 0;
        inc_pc  = 0;
        data_in = 5'b0;

        // Test 1: Reset
        @(posedge clk); #1;
        check(5'd0, "Reset clears PC to 0");

        // Release reset
        rst = 0;

        // Test 2: Increment
        inc_pc = 1;
        @(posedge clk); #1;
        check(5'd1, "Increment PC to 1");

        @(posedge clk); #1;
        check(5'd2, "Increment PC to 2");

        @(posedge clk); #1;
        check(5'd3, "Increment PC to 3");

        // Test 3: Load
        inc_pc  = 0;
        ld_pc   = 1;
        data_in = 5'd20;
        @(posedge clk); #1;
        check(5'd20, "Load PC with 20");

        // Test 4: Load has priority over increment
        inc_pc  = 1;
        ld_pc   = 1;
        data_in = 5'd10;
        @(posedge clk); #1;
        check(5'd10, "Load priority over increment");

        // Test 5: Hold value (no load, no increment)
        inc_pc = 0;
        ld_pc  = 0;
        @(posedge clk); #1;
        check(5'd10, "Hold value when idle");

        // Test 6: Reset during operation
        inc_pc = 1;
        @(posedge clk); #1;  // PC = 11
        rst = 1;
        @(posedge clk); #1;
        check(5'd0, "Reset during operation");

        // Test 7: Wrap around (overflow)
        rst    = 0;
        inc_pc = 0;
        ld_pc  = 1;
        data_in = 5'd31;
        @(posedge clk); #1;
        check(5'd31, "Load PC with max value 31");
        ld_pc  = 0;
        inc_pc = 1;
        @(posedge clk); #1;
        check(5'd0, "Wrap around from 31 to 0");

        // Summary
        $display("\n========================================");
        $display("Program Counter TB: %0d PASSED, %0d FAILED", pass_count, fail_count);
        $display("========================================\n");
        $finish;
    end

    // Waveform dump
    initial begin
//         $recordfile("output/waves_tb_program_counter");
//         $recordvars("depth=0", tb_program_counter);
    end

endmodule

// --- END OF tb_program_counter.v ---

//==============================================================================
// --- START OF tb_register.v ---
//==============================================================================
//==============================================================================
// Testbench: tb_register
// Description: Verifies register load, hold, and reset behavior.
//==============================================================================


module tb_register;

    reg        clk;
    reg        rst;
    reg        load;
    reg  [7:0] data_in;
    wire [7:0] data_out;

    integer pass_count = 0;
    integer fail_count = 0;

    // Instantiate DUT
    register dut (
        .clk      (clk),
        .rst      (rst),
        .load     (load),
        .data_in  (data_in),
        .data_out (data_out)
    );

    // Clock generation
    initial clk = 0;
    always #5 clk = ~clk;

    task check;
        input [7:0] expected;
        input [255:0] test_name;
        begin
            if (data_out !== expected) begin
                $display("FAIL: %0s - Expected %0h, Got %0h", test_name, expected, data_out);
                fail_count = fail_count + 1;
            end else begin
                $display("PASS: %0s - data_out = %0h", test_name, data_out);
                pass_count = pass_count + 1;
            end
        end
    endtask

    initial begin
        // Initialize
        rst     = 1;
        load    = 0;
        data_in = 8'h00;

        // Test 1: Reset
        @(posedge clk); #1;
        check(8'h00, "Reset clears register");

        // Release reset
        rst = 0;

        // Test 2: Load data
        load    = 1;
        data_in = 8'hAA;
        @(posedge clk); #1;
        check(8'hAA, "Load AA into register");

        // Test 3: Load different data
        data_in = 8'h55;
        @(posedge clk); #1;
        check(8'h55, "Load 55 into register");

        // Test 4: Hold value when load is de-asserted
        load    = 0;
        data_in = 8'hFF;
        @(posedge clk); #1;
        check(8'h55, "Hold value when load=0");

        @(posedge clk); #1;
        check(8'h55, "Still holding value");

        // Test 5: Reset overrides loaded value
        load    = 1;
        data_in = 8'hBB;
        @(posedge clk); #1;
        check(8'hBB, "Load BB");
        rst = 1;
        @(posedge clk); #1;
        check(8'h00, "Reset overrides loaded value");

        // Summary
        $display("\n========================================");
        $display("Register TB: %0d PASSED, %0d FAILED", pass_count, fail_count);
        $display("========================================\n");
        $finish;
    end

    initial begin
//         $recordfile("output/waves_tb_register");
//         $recordvars("depth=0", tb_register);
    end

endmodule

// --- END OF tb_register.v ---

//==============================================================================
// --- START OF tb_risc_cpu.v ---
//==============================================================================
//==============================================================================
// Testbench: tb_risc_cpu
// Description: System-level testbench for the RISC CPU.
//              - Loads test programs from .mem files into memory.
//              - Runs until halt or timeout.
//              - Checks the PC value at halt to determine PASS/FAIL.
//              - Dumps VCD waveform for analysis.
//==============================================================================


module tb_risc_cpu;

    reg  clk;
    reg  rst;
    wire halt;

    // Instantiate CPU
    risc_cpu dut (
        .clk  (clk),
        .rst  (rst),
        .halt (halt)
    );

    // Clock generation: 10ns period (100 MHz)
    initial clk = 0;
    always #5 clk = ~clk;

    // Program selection parameter
    // Override from command line: +define+PROG=1
    `ifndef PROG
        `define PROG 1
    `endif

    // Expected halt PC for each test program
    reg [4:0] expected_halt_pc;
    reg [255:0] prog_name;

    initial begin
        case (`PROG)
            1: begin
                expected_halt_pc = 5'h18;
                prog_name = "PROG1 (JMP/LDA/SKZ/STO/XOR)";
            end
            2: begin
                expected_halt_pc = 5'h11;
                prog_name = "PROG2 (AND/ADD)";
            end
            3: begin
                expected_halt_pc = 5'h0D;
                prog_name = "PROG3 (Fibonacci)";
            end
            default: begin
                expected_halt_pc = 5'h18;
                prog_name = "PROG1 (default)";
            end
        endcase
    end

    // Load program into memory
    initial begin
        case (`PROG)
            1: $readmemb("test/prog1.mem", dut.u_mem.mem);
            2: $readmemb("test/prog2.mem", dut.u_mem.mem);
            3: $readmemb("test/prog3.mem", dut.u_mem.mem);
            default: $readmemb("test/prog1.mem", dut.u_mem.mem);
        endcase
    end

    // Monitor key signals
    integer cycle_count;

    initial begin
        cycle_count = 0;
    end

    always @(posedge clk) begin
        cycle_count = cycle_count + 1;
    end

    // Display state machine progress
    reg [2:0] prev_state;
    initial prev_state = 3'b0;

    always @(posedge clk) begin
        if (!rst && dut.u_ctrl.state == 3'd0 && prev_state == 3'd7) begin
            // New instruction cycle starting
            $display("[Cycle %0d] PC=%0d, IR=%b (opcode=%b, addr=%0d), ACC=%0h",
                     cycle_count, dut.u_pc.pc_out, dut.u_ir.data_out,
                     dut.u_ir.data_out[7:5], dut.u_ir.data_out[4:0],
                     dut.u_acc.data_out);
        end
        prev_state = dut.u_ctrl.state;
    end

    // Main test sequence
    initial begin
        $display("\n========================================");
        $display("RISC CPU System Test: %0s", prog_name);
        $display("========================================\n");

        // Apply reset
        rst = 1;
        repeat(3) @(posedge clk);
        rst = 0;

        $display("Reset released, CPU running...\n");

        // Wait for halt or timeout (Verilog-2001 compatible)
        begin : wait_loop
            integer timeout;
            timeout = 0;
            while (halt !== 1'b1 && timeout < 10000) begin
                @(posedge clk);
                timeout = timeout + 1;
            end

            if (timeout >= 10000) begin
                $display("\n*** FAIL: %0s - TIMEOUT after 10000 cycles ***", prog_name);
            end else begin
                // Wait one more cycle to ensure PC is stable
                @(posedge clk);
                $display("\n--- CPU Halted ---");
                $display("Halt PC = %0d (0x%0h)", dut.u_pc.pc_out, dut.u_pc.pc_out);
                $display("Total cycles = %0d", cycle_count);
                $display("ACC = 0x%0h", dut.u_acc.data_out);

                // Check result
                if (dut.u_pc.pc_out == expected_halt_pc) begin
                    $display("\n*** PASS: %0s - Halted at expected PC ***", prog_name);
                end else begin
                    $display("\n*** FAIL: %0s - Expected halt at PC=%0d, got PC=%0d ***",
                             prog_name, expected_halt_pc, dut.u_pc.pc_out);
                end
            end
        end

        // Dump memory contents for debugging
        $display("\n--- Memory Dump (data region 0x1A-0x1F) ---");
        $display("  [0x1A] = 0x%0h", dut.u_mem.mem[5'h1A]);
        $display("  [0x1B] = 0x%0h", dut.u_mem.mem[5'h1B]);
        $display("  [0x1C] = 0x%0h", dut.u_mem.mem[5'h1C]);
        $display("  [0x1D] = 0x%0h", dut.u_mem.mem[5'h1D]);
        $display("  [0x1E] = 0x%0h", dut.u_mem.mem[5'h1E]);
        $display("  [0x1F] = 0x%0h", dut.u_mem.mem[5'h1F]);

        $display("\n========================================\n");
        $finish;
    end

    // Waveform dump for Cadence SimVision (LAB1 format)
    initial begin
        $recordfile("output/waves");
        $recordvars("depth=0", tb_risc_cpu);
    end

endmodule

// --- END OF tb_risc_cpu.v ---

