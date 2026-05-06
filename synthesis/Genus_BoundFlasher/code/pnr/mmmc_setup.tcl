create_library_set -name default_lib -timing { /data/cc03group4/vlsi/Assignment/synthesis/Genus_BoundFlasher/LIB/slow.lib }
create_rc_corner -name default_rc -T 25
create_delay_corner -name default_delay -library_set default_lib -rc_corner default_rc
create_constraint_mode -name default_sdc -sdc_files { /data/cc03group4/vlsi/Assignment/synthesis/Genus_BoundFlasher/code/output/synthesis.sdc }
create_analysis_view -name default_view -delay_corner default_delay -constraint_mode default_sdc
set_analysis_view -setup {default_view} -hold {default_view}
