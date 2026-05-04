//==============================================================================
// Testbench: tb_program_counter
// Description: Verifies program counter reset, increment, and load operations.
//==============================================================================

`timescale 1ns/1ps

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
        $dumpfile("tb_program_counter.vcd");
        $dumpvars(0, tb_program_counter);
    end

endmodule
