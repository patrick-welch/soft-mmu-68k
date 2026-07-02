# Core RTL Tutorials

These tutorials explain the current SM68861 core RTL implementation in a more guided, reader-friendly form than the source files alone. They are intended for contributors, reviewers, and learners who want to understand how the current modules fit together before changing RTL, tests, or documentation.

These files describe implemented repository behavior. They are not a complete Motorola PMMU specification, and they should not be read as compatibility claims beyond the behavior implemented and tested in this repository.

Each tutorial uses `Source:` annotations before Verilog snippets. Those links point back to the RTL lines being discussed so readers can compare the explanation with the implementation directly.

Source line links are review aids. If RTL line numbers move, update the tutorial as part of the same documentation maintenance pass.

## Recommended Reading Order

1. [mmu_regs_explanation.md](mmu_regs_explanation.md)
2. [mmu_decode_explanation.md](mmu_decode_explanation.md)
3. [perm_check_explanation.md](perm_check_explanation.md)
4. [descriptor_pack_explanation.md](descriptor_pack_explanation.md)
5. [tlb_compare_explanation.md](tlb_compare_explanation.md)
6. [tlb_dm_explanation.md](tlb_dm_explanation.md)
7. [pt_walker_explanation.md](pt_walker_explanation.md)
8. [flush_ctrl_explanation.md](flush_ctrl_explanation.md)
9. [mmu_top_explanation.md](mmu_top_explanation.md)