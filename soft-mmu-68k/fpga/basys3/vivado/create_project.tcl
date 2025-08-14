# Vivado project creation (no board_part; set part directly)
set root_dir [file normalize [file dirname [info script]]/../../..]
create_project soft_mmu_68k \/soft_mmu_68k.xpr -part xc7a35tcpg236-1 -force
