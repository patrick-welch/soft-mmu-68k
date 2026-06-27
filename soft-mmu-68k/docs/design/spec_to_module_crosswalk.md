# Spec → Module → Test Crosswalk (draft)

This crosswalk maps major Motorola PMMU concepts to the current repo modules and verification collateral. It is intentionally conservative: entries describe the implemented first-pass project subset unless explicitly marked otherwise.

| Area | Module(s) | Testbench / collateral | Notes / sources |
|---|---|---|---|
| CRP/SRP/TC/TT0/TT1/MMUSR registers | `rtl/core/mmu_regs.v` | `tb/unit/mmu_regs_tb.sv` | Register image, reset behavior, read/write path, masks, first-pass `MMUSR` policy |
| Root/pointer/page descriptor pack/unpack | `rtl/core/descriptor_pack.v` | `tb/unit/descriptor_pack_tb.sv` | Motorola-aligned long-format subset; live datapath migration still deferred |
| FC decode | `rtl/core/mmu_decode.v` | `tb/unit/perm_check_tb.sv` | User/supervisor, program/data, CPU/special-space classification for current RTL |
| R/W/X and U/S permission checking | `rtl/core/perm_check.v` | `tb/unit/perm_check_tb.sv`; `tb/common/golden_vectors/perm_check_golden_vectors.csv`; `scripts/matlab/models/mmu_perm_check_reference.m`; `scripts/matlab/generators/generate_perm_check_vectors.m` | Exhaustive MATLAB-generated vectors cover mode, request encoding, user perms, supervisor perms, and TT bypass |
| ATC/TLB lookup/fill/invalidate, direct-mapped subset | `rtl/core/tlb_dm.v`, `rtl/core/tlb_compare.v` | `tb/unit/tlb_dm_tb.sv` | First-pass direct-mapped translation cache behavior |
| Page-table walker FSM | `rtl/core/pt_walker.v` | `tb/unit/pt_walker_tb.sv` | Minimal single-level walker and first-pass fault classes |
| PFLUSH/PTEST/PLOAD control and status shim | `rtl/core/flush_ctrl.v` | `tb/integ/instr_shim_tb.sv` | Control-layer shim only; not yet complete Motorola instruction behavior |
| Top-level integration | `rtl/core/mmu_top.v` | `tb/integ/mmu_core_tb.sv` | Register/control, TLB lookup, walker refill, TT subset, and permission check integration |
| Basys 3 smoke demo | `fpga/basys3/tops/top_mmu_demo.v`; `fpga/basys3/vivado/*.tcl`; generated XDC flow | Vivado build/programming flow; smoke observations | Hardware smoke harness only, not a full 68k SoC |

## Documentation notes

- Replace draft source labels with exact manual sections as the verified source index is completed.
- Do not use this crosswalk to imply full Motorola architectural compatibility.
- Public docs and Wiki pages must not contain assistant-only citation artifacts such as `:contentReference[` or `oaicite:`.
