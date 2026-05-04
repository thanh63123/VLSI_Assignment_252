# 8-bit RISC CPU VLSI Design

## Overview
This project implements a simple 8-bit RISC CPU in Verilog, designed specifically for a VLSI coursework assignment. It is fully verified and prepared for a professional ASIC design flow using Cadence EDA tools (Xcelium, Genus, Innovus, Conformal).

## Features
- **Architecture**: 8-bit data bus, 5-bit address bus (32 memory locations).
- **Instruction Set**: 8 core instructions (`HLT`, `SKZ`, `ADD`, `AND`, `XOR`, `LDA`, `STO`, `JMP`).
- **Control Unit**: 8-state Moore FSM controller.
- **Advanced Modules**: Includes an extended 16-operation ALU, an 8x8 shift-and-add multiplier, a restoring divider, and a hazard detection unit for pipeline extensions.
- **Verification**: 13 comprehensive test suites (130 test cases) achieving 100% pass rate.

## Directory Structure
- `rtl/` - Verilog source files (modules).
- `tb/` - Testbenches for unit and system testing.
- `test/` - Memory files (`.mem`) containing sample assembly programs (e.g., Fibonacci).
- `sim/` - Windows simulation scripts (`run_all.bat`).
- `scripts/` - Cadence Linux scripts for Simulation, Synthesis, PnR, and LEC.

## How to Demo & Run

### 1. Functional Simulation (Windows - Icarus Verilog)
If you are on Windows and have Icarus Verilog installed, you can run the entire test suite (130 test cases) with a single click:
```cmd
cd sim
run_all.bat
```

### 2. Functional Simulation (Linux - Cadence Xcelium)
To run the RTL simulation on the Cadence lab server:
```bash
chmod +x scripts/go_*
./scripts/go_sim
```

### 3. VLSI Design Flow (Cadence Tools)
This project includes automated scripts for the standard Cell-based IC design flow:

1. **Logic Synthesis (Genus)**
   ```bash
   ./scripts/go_syn
   ```
   *Synthesizes RTL into a gate-level netlist (`output/synthesis_net.v`) using standard cell libraries.*

2. **Logic Equivalence Check (Conformal)**
   ```bash
   ./scripts/go_lec
   ```
   *Verifies that the synthesized netlist is logically equivalent to the original RTL.*

3. **Place and Route (Innovus)**
   ```bash
   ./scripts/go_pnr
   ```
   *Generates the physical layout (`output/innovus.gds`) from the netlist.*

> **Note**: Before running Cadence tools, ensure you have correctly set the standard cell library paths in `scripts/synthesis.tcl` and `scripts/pnr.tcl`.
