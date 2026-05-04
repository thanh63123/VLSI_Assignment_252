#==============================================================================
# Genus Synthesis Script for RISC CPU
# Based on LAB2_SYNTHESIS.pdf (Genus_CUI_RAK template)
#
# Usage: genus -f run.tcl | tee -i sync.log
#
# NOTE: This script assumes you have copied the Genus_CUI_RAK template
#       and placed RTL files in ../RTL/ directory.
#       If running from project root, adjust paths accordingly.
#==============================================================================

##############################################################################
## Preset global variables and attributes
##############################################################################
set DESIGN risc_cpu
set _OUTPUTS_PATH ./outputs
set _REPORTS_PATH ./reports
set _LOG_PATH     ./logs

file mkdir $_OUTPUTS_PATH
file mkdir $_REPORTS_PATH
file mkdir $_LOG_PATH

###############################################################
## Library setup
###############################################################
# UPDATE THESE PATHS to match your lab server
set_db init_lib_search_path "../LIB"
set_db init_hdl_search_path "../RTL"

read_libs "slow.lib"

# If using LEF files for physical-aware synthesis:
# read_physical -lef "../LEF/gsclib045_tech.lef ../LEF/gsclib045_macro.lef"

####################################################################
## Load Design
####################################################################
read_hdl " \
    program_counter.v \
    address_mux.v \
    alu.v \
    controller.v \
    register.v \
    memory.v \
    risc_cpu.v \
"

elaborate $DESIGN
check_design -unresolved

####################################################################
## Constraints Setup
####################################################################
read_sdc ../constraints/risc_cpu_gate.sdc

####################################################################
## Synthesize
####################################################################
syn_generic
syn_map
syn_opt

#######################################################################################################
## Optimize Netlist
#######################################################################################################

## Write Reports
report_timing -max_paths 10 > ${_REPORTS_PATH}/final_time.rpt
report_area                 > ${_REPORTS_PATH}/final_area.rpt
report_qor                  > ${_REPORTS_PATH}/final_qor.rpt
report_power                > ${_REPORTS_PATH}/final_power.rpt
report_gates                > ${_REPORTS_PATH}/final_gates.rpt

## Write Netlist
write_hdl > ${_OUTPUTS_PATH}/${DESIGN}_m.v

## Write SDC for Innovus/Tempus
write_sdc > ${_OUTPUTS_PATH}/${DESIGN}.sdc

#################################
### write_do_lec
#################################
puts ""
puts "============================================"
puts "  Genus Synthesis COMPLETE"
puts "  Netlist: ${_OUTPUTS_PATH}/${DESIGN}_m.v"
puts "  Reports: ${_REPORTS_PATH}/"
puts "============================================"
puts ""

quit
