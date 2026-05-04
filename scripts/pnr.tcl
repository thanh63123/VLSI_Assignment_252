#==============================================================================
# Innovus Place & Route Script for RISC CPU
# Usage: innovus -files scripts/pnr.tcl
# NOTE: Update library paths before running!
#==============================================================================

# ---- USER CONFIGURATION (MUST UPDATE) ----
set LIB_PATH "/path/to/stdcell/lib"    ;# <-- UPDATE THIS
set LIB_NAME "your_stdcell.lib"        ;# <-- UPDATE THIS
set LEF_FILE "/path/to/stdcell.lef"    ;# <-- UPDATE THIS
set TOP_MODULE "risc_cpu"

# ---- Read Design ----
puts "Reading design..."
read_verilog output/synthesis_net.v
read_libs $LIB_PATH/$LIB_NAME
read_lef $LEF_FILE
read_sdc output/synthesis.sdc

# ---- Initialize Design ----
init_design

# ---- Floorplan ----
puts "Creating floorplan..."
# Aspect ratio 1.0, utilization 70%, margins 10um all sides
floorPlan -site core -r 1.0 0.7 10 10 10 10

# ---- Power Planning ----
puts "Creating power rings..."
addRing -nets {VDD VSS} -type core_rings \
    -width 2 -spacing 1 \
    -layer {top metal3 bottom metal3 left metal4 right metal4}

# ---- Special Route (Power) ----
sroute -nets {VDD VSS}

# ---- Placement ----
puts "Placing standard cells..."
place_design
# Optimize placement
optDesign -preCTS

# ---- Clock Tree Synthesis ----
puts "Running CTS..."
create_ccopt_clock_tree_spec
ccopt_design

# Optimize after CTS
optDesign -postCTS

# ---- Routing ----
puts "Routing design..."
routeDesign
# Optimize after route
optDesign -postRoute

# ---- Filler Cells ----
puts "Adding filler cells..."
# Update cell names based on your library
addFiller -cell {FILL64 FILL32 FILL16 FILL8 FILL4 FILL2 FILL1} -prefix FILLER

# ---- Verify ----
verifyConnectivity
verifyGeometry

# ---- Export Results ----
puts "Exporting results..."
file mkdir output

write_verilog output/innovus.v
streamOut output/innovus.gds -mapFile streamOut.map

# ---- Reports ----
file mkdir reports
report_timing > reports/pnr_timing.rpt
report_area   > reports/pnr_area.rpt
report_power  > reports/pnr_power.rpt

puts ""
puts "============================================"
puts "  Innovus Place & Route COMPLETE"
puts "  Netlist: output/innovus.v"
puts "  Layout:  output/innovus.gds"
puts "  Reports: reports/"
puts "============================================"
puts ""
