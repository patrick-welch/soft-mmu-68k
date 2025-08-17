# Verification Plan (Phase 1)

**Unit tests**
- `mmu_regs`: reset, masks, side effects (MMUSR)
- `descriptor_pack`: round-trip vectors
- `perm_check`: FC × R/W/X × TTx matrix
- `tlb_dm`: hit/miss/refill/invalidate
- `pt_walker`: synthetic PT trees, all fault classes

**Integration tests**
- Instruction-visible: PLOAD/PTEST/PFLUSH  [^PRM]
- TTR bypass cases (040/060)  [^68040-UM]

**Exit criteria**
- 100% of programmed scenarios; all behavioral checks cite the manual section matched.

*References:* [^PRM] [^68030-UM] [^68040-UM]
