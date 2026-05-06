# ####################################################################

#  Created by Genus(TM) Synthesis Solution 22.17-s071_1 on Wed May 06 17:15:24 +07 2026

# ####################################################################

set sdc_version 2.0

set_units -capacitance 1000fF
set_units -time 1000ps

# Set the current design
current_design risc_cpu

create_clock -name "clk" -period 10.0 -waveform {0.0 5.0} [get_ports clk]
set_clock_gating_check -setup 0.0 
set_input_delay -clock [get_clocks clk] -add_delay 5.0 [get_ports rst]
set_output_delay -clock [get_clocks clk] -add_delay 5.0 [get_ports halt]
set_max_fanout 15.000 [current_design]
set_max_transition 1.2 [current_design]
set_wire_load_mode "enclosed"
