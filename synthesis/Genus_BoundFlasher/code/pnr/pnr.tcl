#==============================================================================
# Innovus Place & Route Script for RISC CPU
# Usage: innovus -files scripts/pnr.tcl
# NOTE: Update library paths before running!
#==============================================================================

# ---- USER CONFIGURATION (MUST UPDATE) ----
set LIB_PATH "/data/cc03group4/vlsi/Assignment/synthesis/Genus_BoundFlasher/LIB"
set LIB_NAME "slow.lib"
set LEF_FILE "/data/cc03group4/vlsi/Assignment/synthesis/Genus_BoundFlasher/LEF/gsclib045_tech.lef /data/cc03group4/vlsi/Assignment/synthesis/Genus_BoundFlasher/LEF/gsclib045_macro.lef"
set TOP_MODULE "risc_cpu"

# ---- Design Initialization & MMMC Setup ----
puts "Setting up design variables..."
set init_verilog "/data/cc03group4/vlsi/Assignment/synthesis/Genus_BoundFlasher/code/output/synthesis_net.v"
set init_top_cell $TOP_MODULE
set init_lef_file $LEF_FILE
set init_pwr_net "VDD"
set init_gnd_net "VSS"

puts "Creating MMMC timing setup..."
set mmmc_file [open "mmmc_setup.tcl" w]
puts $mmmc_file "create_library_set -name default_lib -timing { $LIB_PATH/$LIB_NAME }"
puts $mmmc_file "create_rc_corner -name default_rc -T 25"
puts $mmmc_file "create_delay_corner -name default_delay -library_set default_lib -rc_corner default_rc"
puts $mmmc_file "create_constraint_mode -name default_sdc -sdc_files { /data/cc03group4/vlsi/Assignment/synthesis/Genus_BoundFlasher/code/output/synthesis.sdc }"
puts $mmmc_file "create_analysis_view -name default_view -delay_corner default_delay -constraint_mode default_sdc"
puts $mmmc_file "set_analysis_view -setup {default_view} -hold {default_view}"
close $mmmc_file

set init_mmmc_file "mmmc_setup.tcl"

puts "Initializing design..."
init_design

# ---- Floorplan ----
puts "Creating floorplan..."
# Aspect ratio 1.0, utilization 70%, margins 10um all sides
# FIX APPLIED: Removed "-site core"
floorPlan -r 1.0 0.7 10 10 10 10

# ---- Power Planning ----
puts "Creating power rings..."
addRing -nets {VDD VSS} -type core_rings \
    -width 2 -spacing 1 \
    -layer {top M3 bottom M3 left M4 right M4}

# ---- Global Net Connect ----
puts "Connecting global power nets..."
clearGlobalNets
globalNetConnect VDD -type pgpin -pin VDD -inst *
globalNetConnect VSS -type pgpin -pin VSS -inst *
globalNetConnect VDD -type tiehi -inst *
globalNetConnect VSS -type tielo -inst *

# ---- Special Route (Power) ----
puts "Routing power rails..."
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
setNanoRouteMode -routeStrictlyHonorNonDefaultRule false
setNanoRouteMode -routeWithViaOnlyForStandardCellPin false
routeDesign

# ---- Filler Cells ----
puts "Adding filler cells..."
# Update cell names based on your library
addFiller -cell {FILL64 FILL32 FILL16 FILL8 FILL4 FILL2 FILL1} -prefix FILLER

# ---- Verify ----
verifyConnectivity
verifyGeometry

# ---- Export Results ----
puts "Exporting results..."
file mkdir ./output/

write_verilog ./output/innovus.v
streamOut ./output/innovus.gds -mapFile streamOut.map

# ---- Reports ----
file mkdir reports
report_timing > ./reports/pnr_timing.rpt
report_area   > ./reports/pnr_area.rpt
report_power  > ./reports/pnr_power.rpt

puts ""
puts "============================================"
puts "  Innovus Place & Route COMPLETE"
puts "  Netlist: ./output/innovus.v"
puts "  Layout:  ./output/innovus.gds"
puts "  Reports: ./reports/"
puts "============================================"
puts ""