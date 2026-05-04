//==============================================================================
// Testbench: tb_alu
// Description: Verifies all 8 ALU operations and the is_zero flag.
//==============================================================================

`timescale 1ns/1ps

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
        $dumpfile("tb_alu.vcd");
        $dumpvars(0, tb_alu);
    end

endmodule
