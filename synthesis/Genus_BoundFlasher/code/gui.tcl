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
read_libs "/data/cc03group4/vlsi/Assignment/synthesis/Genus_BoundFlasher/LIB/slow.lib"

# If using LEF files:
# read_physical -lef "/data/cc03group4/vlsi/Assignment/synthesis/Genus_BoundFlasher/LEF/gsclib045_tech.lef /data/cc03group4/vlsi/Assignment/synthesis/Genus_BoundFlasher/LEF/gsclib045_macro.lef"

####################################################################
## Load Design
####################################################################
read_hdl "/data/cc03group4/vlsi/Assignment/synthesis/Genus_BoundFlasher/code/output/synthesis_net.v"
elaborate $DESIGN
