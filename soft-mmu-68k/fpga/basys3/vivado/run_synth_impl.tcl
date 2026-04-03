set script_dir [file normalize [file dirname [info script]]]
set project_name basys3_mmu_demo
set project_dir [file normalize [file join $script_dir build $project_name]]

source [file join $script_dir create_project.tcl]

launch_runs synth_1 -jobs 4
wait_on_run synth_1

launch_runs impl_1 -to_step write_bitstream -jobs 4
wait_on_run impl_1

open_run impl_1
report_timing_summary -file [file join $project_dir timing_summary.rpt]
report_utilization -file [file join $project_dir utilization.rpt]

puts "Implementation finished. Bitstream and reports are under $project_dir"
