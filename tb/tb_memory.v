//==============================================================================
// Testbench: tb_memory
// Description: Verifies memory read, write, and bidirectional port behavior.
//==============================================================================

`timescale 1ns/1ps

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
        $dumpfile("tb_memory.vcd");
        $dumpvars(0, tb_memory);
    end

endmodule
