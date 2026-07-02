# Core RTL Tutorials

This page links the Wiki to the canonical SM68861 core RTL tutorials kept in the repository under `soft-mmu-68k/docs/tutorial/`.

The tutorials explain current implemented RTL behavior in a guided, reader-friendly form. They are intended for contributors, reviewers, and learners who want to understand the core modules before changing RTL, tests, or documentation.

The tutorial files are not copied into the Wiki. The repository copies remain canonical because they include `Source:` annotations that point back to specific RTL line ranges, and those source-line links need to be maintained with the RTL.

## Scope note

These tutorials describe implemented repository behavior. They are not a complete Motorola PMMU specification and should not be read as compatibility claims beyond the behavior implemented and tested in this repository.

## Tutorial index

Start here:

- [Core RTL Tutorials README](https://github.com/patrick-welch/soft-mmu-68k/blob/main/soft-mmu-68k/docs/tutorial/README.md)

Recommended order:

1. [`mmu_regs.v` Tutorial](https://github.com/patrick-welch/soft-mmu-68k/blob/main/soft-mmu-68k/docs/tutorial/mmu_regs_explanation.md)
2. [`mmu_decode.v` Tutorial](https://github.com/patrick-welch/soft-mmu-68k/blob/main/soft-mmu-68k/docs/tutorial/mmu_decode_explanation.md)
3. [`perm_check.v` Tutorial](https://github.com/patrick-welch/soft-mmu-68k/blob/main/soft-mmu-68k/docs/tutorial/perm_check_explanation.md)
4. [`descriptor_pack.v` Tutorial](https://github.com/patrick-welch/soft-mmu-68k/blob/main/soft-mmu-68k/docs/tutorial/descriptor_pack_explanation.md)
5. [`tlb_compare.v` Tutorial](https://github.com/patrick-welch/soft-mmu-68k/blob/main/soft-mmu-68k/docs/tutorial/tlb_compare_explanation.md)
6. [`tlb_dm.v` Tutorial](https://github.com/patrick-welch/soft-mmu-68k/blob/main/soft-mmu-68k/docs/tutorial/tlb_dm_explanation.md)
7. [`pt_walker.v` Tutorial](https://github.com/patrick-welch/soft-mmu-68k/blob/main/soft-mmu-68k/docs/tutorial/pt_walker_explanation.md)
8. [`flush_ctrl.v` Tutorial](https://github.com/patrick-welch/soft-mmu-68k/blob/main/soft-mmu-68k/docs/tutorial/flush_ctrl_explanation.md)
9. [`mmu_top.v` Tutorial](https://github.com/patrick-welch/soft-mmu-68k/blob/main/soft-mmu-68k/docs/tutorial/mmu_top_explanation.md)

## Maintenance rule

If RTL source line numbers move, update the affected tutorial `Source:` links as part of the same documentation maintenance pass.
