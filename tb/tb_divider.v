//==============================================================================
// Testbench: tb_divider
// Description: Verifies the sequential restoring division algorithm.
//==============================================================================

`timescale 1ns/1ps

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
        $dumpfile("tb_divider.vcd");
        $dumpvars(0, tb_divider);
    end

endmodule
