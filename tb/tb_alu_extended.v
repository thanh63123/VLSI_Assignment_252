//==============================================================================
// Testbench: tb_alu_extended
// Description: Verifies all 16 operations of the extended ALU including
//              carry, overflow, and is_zero flags.
//==============================================================================

`timescale 1ns/1ps

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
        $dumpfile("tb_alu_extended.vcd");
        $dumpvars(0, tb_alu_extended);
    end

endmodule
