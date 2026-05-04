//==============================================================================
// Testbench: tb_risc_cpu
// Description: System-level testbench for the RISC CPU.
//              - Loads test programs from .mem files into memory.
//              - Runs until halt or timeout.
//              - Checks the PC value at halt to determine PASS/FAIL.
//              - Dumps VCD waveform for analysis.
//==============================================================================

`timescale 1ns/1ps

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

    // Waveform dump
    initial begin
        $dumpfile("tb_risc_cpu.vcd");
        $dumpvars(0, tb_risc_cpu);
    end

endmodule
