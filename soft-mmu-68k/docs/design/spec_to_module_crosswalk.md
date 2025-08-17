# Spec → Module → Test Crosswalk (draft)

| Area (from manuals)                              | Module(s)                    | Unit TB(s)                 | Notes / Sources |
|--------------------------------------------------|------------------------------|----------------------------|-----------------|
| CRP/SRP/TC/TT0/TT1/MMUSR registers               | rtl/core/mmu_regs.v          | tb/unit/mmu_regs_tb.sv     | RA V1: regs list |
| Root/ptr/page descriptors pack/unpack            | rtl/core/descriptor_pack.v   | tb/unit/descriptor_pack_tb | RA V1: desc fmt  |
| FC decode; U/S + R/W/X permissions               | rtl/core/mmu_decode.v,       | tb/unit/perm_check_tb.sv   | RA V1: perms     |
|                                                  | rtl/core/perm_check.v        |                            |                 |
| ATC/TLB lookup/fill/invalidate (direct-mapped)   | rtl/core/tlb_dm.v,           | tb/unit/tlb_dm_tb.sv       | RA V1: ATC/TLB   |
|                                                  | rtl/core/tlb_compare.v       |                            |                 |
| Page-table walker FSM (CRP/SRP trees, TC)        | rtl/core/pt_walker.v         | tb/unit/pt_walker_tb.sv    | RA V1: tables    |
| PFLUSH / PTEST / PLOAD control & MMUSR updates   | rtl/core/flush_ctrl.v        | tb/integ/instr_shim_tb.sv  | RA V1: instrs    |
| Top-level integration & buses                    | rtl/core/mmu_top.v           | tb/integ/mmu_core_tb.sv    | project skeleton |
