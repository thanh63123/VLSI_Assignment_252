//==============================================================================
// Testbench: tb_multiplier
// Description: Verifies the sequential shift-and-add 8x8 multiplier.
//              Tests various multiplication cases including edge cases.
//==============================================================================

`timescale 1ns/1ps

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
        $dumpfile("tb_multiplier.vcd");
        $dumpvars(0, tb_multiplier);
    end

endmodule
