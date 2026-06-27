# Verification Plan (Phase 1)

This plan tracks how the current first-pass RTL is checked. It distinguishes unit-level behavior, integration behavior, generated golden-vector collateral, and deferred Motorola compatibility work.

## Unit tests

| Area | RTL module(s) | Testbench / collateral | Current verification intent |
|---|---|---|---|
| MMU registers | `rtl/core/mmu_regs.v` | `tb/unit/mmu_regs_tb.sv` | Reset behavior, read/write behavior, register masks, `MMUSR` writable/reserved-bit policy |
| Descriptor pack/unpack | `rtl/core/descriptor_pack.v` | `tb/unit/descriptor_pack_tb.sv` | Round-trip vectors for the implemented Motorola-aligned long-format subset |
| FC decode and permissions | `rtl/core/mmu_decode.v`, `rtl/core/perm_check.v` | `tb/unit/perm_check_tb.sv`, `tb/common/golden_vectors/perm_check_golden_vectors.csv` | Access classification, R/W/X permission behavior, privilege-related fault marking, malformed request handling, and TT-bypass policy |
| Direct-mapped TLB / ATC path | `rtl/core/tlb_dm.v`, `rtl/core/tlb_compare.v` | `tb/unit/tlb_dm_tb.sv` | Hit/miss/refill/invalidate behavior for the first-pass direct-mapped translation cache |
| Page-table walker | `rtl/core/pt_walker.v` | `tb/unit/pt_walker_tb.sv` | Synthetic page-table trees and first-pass fault classes |

## Generated golden vectors

### `perm_check`

`perm_check` now has MATLAB-generated golden-vector collateral.

Source files:

- `scripts/matlab/models/mmu_perm_check_reference.m`
- `scripts/matlab/generators/generate_perm_check_vectors.m`
- `scripts/matlab/examples/run_perm_check_demo.m`

Generated output:

- `tb/common/golden_vectors/perm_check_golden_vectors.csv`

Coverage:

- user/supervisor mode: 2 cases
- request encoding: all 3-bit combinations, including malformed zero/multi-request cases
- user permission value: all 3-bit combinations
- supervisor permission value: all 3-bit combinations
- transparent-translation bypass: off/on

Total rows:

```text
2 * 8 * 8 * 8 * 2 = 2048
```

The reference model follows the current project policy that `tt_bypass` wins inside the permission checker: `allow = true` and `fault = 0` when TT bypass is asserted. That is a first-pass project behavior and should not be described as a complete Motorola PMMU architectural rule.

## Integration tests

| Area | Expected coverage |
|---|---|
| Instruction-visible control operations | First-pass `PLOAD`, `PTEST`, and `PFLUSH` shim behavior |
| Transparent translation | TT/TTR bypass cases for the implemented `TT0` / `TT1` subset |
| Top-level translation flow | TLB hit, TLB miss, walker refill, permission fault, transparent identity-style result |
| Basys 3 smoke demo | Hardware build/programming path and switch/LED-visible sanity cases |

## Exit criteria

For each implemented packet:

- unit testbench compiles and passes
- behavioral checks identify the expected implemented subset
- generated golden vectors are reproducible from checked-in source
- documentation distinguishes implemented behavior from deferred Motorola compatibility work
- public docs contain no assistant-only citation artifacts such as `:contentReference[` or `oaicite:`

## Deferred verification work

The following are not yet complete Phase 1 proof points:

- complete Motorola `MMUSR` synthesis for all `PTEST` result cases
- full architectural `PLOAD` / `PFLUSH` / `PTEST` behavior
- complete Motorola TT/TTR legality and matching rules
- full end-to-end migration of the live datapath to Motorola long-format descriptors
- bus-accurate 68k integration

## References

Manual references still need exact section/page anchoring in the source index and spec-to-module crosswalk. Current source families include:

- Motorola MC68851 PMMU User's Manual
- Motorola MC68030 User's Manual
- Motorola MC68040 User's Manual
- Motorola MC68060 User's Manual
- M68000 Family Programmer's Reference Manual
