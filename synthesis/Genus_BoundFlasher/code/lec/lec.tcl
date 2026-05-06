#==============================================================================
# Conformal LEC Script for RISC CPU
# Format matches LAB3B_CONFORMAL.pdf
# Usage: lec -64 -dofile scripts/lec.tcl
#==============================================================================

# Set log file
set_log_file lec.log -replace

# Read standard cell library (revised side)
# UPDATE: Use the same library from your synthesis_env
read_library /data/cc03group4/vlsi/Assignment/synthesis/Genus_BoundFlasher/LIB/slow.lib -lib -revised

# Read RTL (golden reference)
read_design /data/cc03group4/vlsi/Assignment/synthesis/Genus_BoundFlasher/RTL/risc_cpu.v \
    -verilog -golden

# Read synthesis netlist (revised)
read_design /data/cc03group4/vlsi/Assignment/synthesis/Genus_BoundFlasher/code/output/synthesis_net.v -verilog -revised

# Mapping process
set_mapping_method -name only

# Enter LEC mode
set_system_mode lec

# Compare
map_key_points
add_compared_points -all
compare
