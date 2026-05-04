//==============================================================================
// Testbench: tb_address_mux
// Description: Verifies address mux selection between PC and IR addresses.
//==============================================================================

`timescale 1ns/1ps

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
        $dumpfile("tb_address_mux.vcd");
        $dumpvars(0, tb_address_mux);
    end

endmodule
