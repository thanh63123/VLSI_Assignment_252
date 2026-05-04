//==============================================================================
// Testbench: tb_register
// Description: Verifies register load, hold, and reset behavior.
//==============================================================================

`timescale 1ns/1ps

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
        $dumpfile("tb_register.vcd");
        $dumpvars(0, tb_register);
    end

endmodule
