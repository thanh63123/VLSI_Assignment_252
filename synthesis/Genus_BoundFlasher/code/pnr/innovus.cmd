#######################################################
#                                                     
#  Innovus Command Logging File                     
#  Created on Wed May  6 17:35:03 2026                
#                                                     
#######################################################

#@(#)CDS: Innovus v22.17-s086_1 (64bit) 09/24/2024 10:51 (Linux 3.10.0-693.el7.x86_64)
#@(#)CDS: NanoRoute 22.17-s086_1 NR240905-1647/22_17-UB (database version 18.20.629) {superthreading v2.20}
#@(#)CDS: AAE 22.17-s013 (64bit) 09/24/2024 (Linux 3.10.0-693.el7.x86_64)
#@(#)CDS: CTE 22.17-s017_1 () Sep 12 2024 04:53:54 ( )
#@(#)CDS: SYNTECH 22.17-s006_1 () Aug 12 2024 03:52:27 ( )
#@(#)CDS: CPE v22.17-s051
#@(#)CDS: IQuantus/TQuantus 21.2.2-s369 (64bit) Tue May 7 14:30:42 PDT 2024 (Linux 3.10.0-693.el7.x86_64)

set_global _enable_mmmc_by_default_flow      $CTE::mmmc_default
suppressMessage ENCEXT-2799
getVersion
set init_verilog /data/cc03group4/vlsi/Assignment/synthesis/Genus_BoundFlasher/code/output/synthesis_net.v
set init_top_cell risc_cpu
set init_lef_file {/data/cc03group4/vlsi/Assignment/synthesis/Genus_BoundFlasher/LEF/gsclib045_tech.lef /data/cc03group4/vlsi/Assignment/synthesis/Genus_BoundFlasher/LEF/gsclib045_macro.lef}
set init_pwr_net VDD
set init_gnd_net VSS
set init_mmmc_file mmmc_setup.tcl
init_design
init_design
win
set enc_check_rename_command_name 1
zoomBox -90.83500 -18.46850 143.05750 102.34550
zoomBox -90.83500 17.77600 143.05750 138.59000
zoomBox -90.83700 17.77600 143.05750 138.59100
zoomBox -170.28450 -20.01850 210.57450 176.70900
fit
