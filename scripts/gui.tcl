#==============================================================================
# Genus GUI Script - Load synthesized netlist and view schematic
# Based on LAB2_SYNTHESIS.pdf Step 7-8
# Usage: genus -f gui.tcl -gui
#==============================================================================

set DESIGN risc_cpu

###############################################################
## Library setup
###############################################################
# UPDATE THESE PATHS to match your lab server
read_libs "../LIB/slow.lib"

# If using LEF files:
# read_physical -lef "../LEF/gsclib045_tech.lef ../LEF/gsclib045_macro.lef"

####################################################################
## Load Design
####################################################################
read_hdl "./outputs/${DESIGN}_m.v"
elaborate $DESIGN
