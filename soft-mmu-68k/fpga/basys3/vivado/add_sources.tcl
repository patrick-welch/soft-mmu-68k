set script_dir [file normalize [file dirname [info script]]]
set repo_root [file normalize [file join $script_dir .. .. ..]]

set rtl_files [list \
  [file join $repo_root rtl core mmu_decode.v] \
  [file join $repo_root rtl core mmu_regs.v] \
  [file join $repo_root rtl core perm_check.v] \
  [file join $repo_root rtl core tlb_compare.v] \
  [file join $repo_root rtl core tlb_dm.v] \
  [file join $repo_root rtl core pt_walker.v] \
  [file join $repo_root rtl core flush_ctrl.v] \
  [file join $repo_root rtl core mmu_top.v] \
  [file join $repo_root fpga basys3 tops top_mmu_demo.v] \
]

add_files -norecurse $rtl_files

set master_xdc [file join $repo_root fpga basys3 xdc Basys-3-Master.xdc]
set generated_dir [file normalize [file join $script_dir build generated]]
set generated_xdc [file join $generated_dir basys3_mmu_demo.xdc]

file mkdir $generated_dir

set keep_regexes [list \
  {get_ports clk\]} \
  {get_ports btnC\]} \
  {get_ports \{sw\[[0-9]+\]\}\]} \
  {get_ports \{led\[[0-9]+\]\}\]} \
  {^create_clock -add -name sys_clk_pin} \
  {^set_property CONFIG_VOLTAGE} \
  {^set_property CFGBVS} \
  {^set_property BITSTREAM\.GENERAL\.COMPRESS} \
  {^set_property BITSTREAM\.CONFIG\.CONFIGRATE} \
  {^set_property CONFIG_MODE} \
]

set in_fh [open $master_xdc r]
set master_lines [split [read $in_fh] "\n"]
close $in_fh

set out_fh [open $generated_xdc w]
puts $out_fh "## Auto-generated from Basys-3-Master.xdc for top_mmu_demo"
puts $out_fh {## Kept ports: clk, btnC, sw[15:0], led[15:0]}

foreach raw_line $master_lines {
  set line [string trim $raw_line]
  if {$line eq ""} {
    continue
  }

  set uncommented $line
  if {[string match "#*" $line]} {
    set uncommented [string trimleft $line "#"]
    set uncommented [string trimleft $uncommented]
  }

  set keep_line 0
  foreach pattern $keep_regexes {
    if {[regexp -- $pattern $uncommented]} {
      set keep_line 1
      break
    }
  }

  if {$keep_line} {
    puts $out_fh $uncommented
  }
}

close $out_fh

add_files -fileset constrs_1 -norecurse $generated_xdc
update_compile_order -fileset sources_1

puts "Added RTL sources and generated constraints: $generated_xdc"
