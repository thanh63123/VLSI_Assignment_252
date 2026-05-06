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
read_libs "./synthesis/Genus_BoundFlasher/LIB/slow.lib"

# If using LEF files:
# read_physical -lef "./synthesis/Genus_BoundFlasher/LEF/gsclib045_tech.lef ./synthesis/Genus_BoundFlasher/LEF/gsclib045_macro.lef"

####################################################################
## Load Design
####################################################################
read_hdl "./output/synthesis_net.v"
elaborate $DESIGN
