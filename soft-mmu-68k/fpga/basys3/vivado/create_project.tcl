set script_dir [file normalize [file dirname [info script]]]
set repo_root [file normalize [file join $script_dir .. .. ..]]
set project_name basys3_mmu_demo
set project_dir [file normalize [file join $script_dir build $project_name]]

file mkdir $project_dir

create_project -force $project_name $project_dir -part xc7a35tcpg236-1
set_property target_language Verilog [current_project]
set_property default_lib xil_defaultlib [current_project]

source [file join $script_dir add_sources.tcl]

set_property top top_mmu_demo [get_filesets sources_1]
update_compile_order -fileset sources_1

puts "Created project $project_name in $project_dir"
