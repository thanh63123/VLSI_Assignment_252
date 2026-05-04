# Set the current design
current_design risc_cpu

# Clock: start with 10ns (100 MHz), adjust to find Fmax
create_clock -name "clk" -add -period 10.0 -waveform {0.0 5.0} [get_ports clk]

# Input/Output delays = 50% of clock period
set_input_delay  -clock [get_clocks clk] -add_delay 5.0 [get_ports rst]
set_output_delay -clock [get_clocks clk] -add_delay 5.0 [get_ports halt]

# Max fanout and transition
set_max_fanout 15.000 [current_design]
set_max_transition 1.2 [current_design]
