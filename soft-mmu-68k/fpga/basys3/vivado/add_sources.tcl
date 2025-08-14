set root_dir [file normalize [file dirname [info script]]/../../..]
# Add RTL
add_files -fileset sources_1 \/rtl/core/mmu_top.v
add_files -fileset sources_1 \/rtl/util/mux_idx.v
add_files -fileset sources_1 \/rtl/util/mux_onehot.v
# Add top demo
add_files -fileset sources_1 \/fpga/basys3/tops/top_mmu_demo.v
# Constraints
add_files -fileset constrs_1 \/fpga/basys3/xdc/Basys-3-Master.xdc
