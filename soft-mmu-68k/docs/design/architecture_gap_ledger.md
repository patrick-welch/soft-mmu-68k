# Architecture Gap Ledger

## Purpose

This ledger is a planning bridge between the current first-pass soft-mmu-68k
implementation and future Motorola-compliance work packets. It records known
implementation gaps, the evidence currently available in the repo, and the next
packet that should address each gap. It is not a claim of full Motorola PMMU
compatibility.

## Current verified baseline

- Regression scripts exist in `soft-mmu-68k/scripts/` for Icarus unit benches,
  Icarus integration benches, and Verilator lint.
- GitHub Actions HDL Regression exists at `.github/workflows/hdl-regression.yml`
  and runs the unit, integration, and lint scripts from `soft-mmu-68k/`.
- Unit benches are present under `soft-mmu-68k/tb/unit/`.
- Integration benches are present under `soft-mmu-68k/tb/integ/`.
- Verilator lint is covered by `soft-mmu-68k/scripts/run_verilator_lint.sh`.
- The Basys 3 smoke demo exists under `soft-mmu-68k/fpga/basys3/`, but it is
  smoke-level evidence only and not proof of a full 68k bus/system integration.

## Gap table

| ID | Area | Current implementation | Gap / limitation | Evidence today | Risk | Recommended next packet |
| --- | --- | --- | --- | --- | --- | --- |
| A1-G01 | Descriptor datapath boundary | `descriptor_pack` implements a Motorola-aligned long-format subset for root, pointer, and page descriptors. | The live walker/datapath still uses a compact 32-bit descriptor image, so long-format descriptors are not yet consumed end to end. | `soft-mmu-68k/docs/design/descriptor_formats.md`, `soft-mmu-68k/rtl/core/descriptor_pack.v`, `soft-mmu-68k/rtl/core/pt_walker.v` | Readers or later packets may assume descriptor migration is complete when it is deferred. | D1 test plan, then D2 implementation. |
| A1-G02 | Page table walker depth | `pt_walker` is minimal, single-level, and issues one descriptor read per miss. | No multi-level walk and no full CRP/SRP/TC-driven traversal. | `soft-mmu-68k/rtl/core/pt_walker.v`, `soft-mmu-68k/docs/wiki/Translation-Flow.md` | Future descriptor work could be blocked by walker assumptions. | WLK1, or D1 if descriptor migration is tackled first. |
| A1-G03 | Translation Control / root pointer behavior | `CRP`, `SRP`, and `TC` registers exist; `CRP` feeds the current walker table base and `TC` contributes a table-entry span. | Full Motorola TC field interpretation and root pointer behavior are not yet implemented. | `soft-mmu-68k/rtl/core/mmu_regs.v`, `soft-mmu-68k/rtl/core/mmu_top.v`, `soft-mmu-68k/docs/wiki/Translation-Flow.md` | Software-visible register presence can be mistaken for complete traversal semantics. | TC1 test/spec packet. |
| A1-G04 | Transparent Translation TT0/TT1 | First-pass subset uses high-byte base/mask plus selected enable, privilege, and program/data bits. | Full Motorola TT field decode and legality rules are deferred. | `soft-mmu-68k/docs/design/address_map.md`, `soft-mmu-68k/rtl/core/mmu_top.v` | Transparent-region behavior may diverge from Motorola-visible expectations. | TTR1 test packet. |
| A1-G05 | MMUSR / PTEST status model | `MMUSR` register image exists, and the control/status shim reports compact translated, transparent, or miss status. | Full Motorola-visible MMUSR synthesis and PTEST termination semantics are not implemented. | `soft-mmu-68k/rtl/core/mmu_regs.v`, `soft-mmu-68k/rtl/core/flush_ctrl.v`, `soft-mmu-68k/docs/wiki/Control-Operations-(PTEST-PLOAD-PFLUSH).md` | Tests may lock in compact shim behavior before architectural status rules are specified. | M1 test/spec packet. |
| A1-G06 | PLOAD / PFLUSH behavior | First-pass control shim supports preload and flush operations. | Behavior is not full instruction-visible Motorola semantics; preload has no full walk-completion model yet. | `soft-mmu-68k/rtl/core/flush_ctrl.v`, `soft-mmu-68k/docs/wiki/Control-Operations-(PTEST-PLOAD-PFLUSH).md` | Control operations may appear more complete than the current shim supports. | CTRL1 test/spec packet. |
| A1-G07 | CPU/special-space behavior | `FC=3'b111` is decoded as CPU/special space and excluded from transparent translation. | Full Motorola CPU-space behavior is not modeled. | `soft-mmu-68k/docs/design/address_map.md`, `soft-mmu-68k/rtl/core/mmu_decode.v`, `soft-mmu-68k/rtl/core/mmu_top.v` | CPU-space requests may take simplified paths that do not match a complete PMMU model. | FC1 or CPU1 test/spec packet. |
| A1-G08 | Fault model | Basic invalid, unmapped, bus, and permission fault classes exist. | Full fault prioritization, level reporting, and MMUSR mapping are incomplete. | `soft-mmu-68k/rtl/core/pt_walker.v`, `soft-mmu-68k/rtl/core/mmu_top.v`, `soft-mmu-68k/rtl/core/mmu_regs.v` | Later architectural tests may disagree about which fault is visible first. | M1 or FAULT1. |
| A1-G09 | Software-side 68k tests | Scaffold-level software tests exist under `soft-mmu-68k/sw/tests_68k/`. | They are not yet tied into a real execution harness. | `soft-mmu-68k/README.md`, `soft-mmu-68k/sw/tests_68k/` | Software expectations can drift from RTL if they are not executable in CI. | SW1 scaffold/harness plan. |
| A1-G10 | Hardware proof depth | Basys 3 smoke demo exists and exercises canned translated, transparent, and permission cases. | It is not a full 68k bus/system integration. | `soft-mmu-68k/README.md`, `soft-mmu-68k/fpga/basys3/tops/top_mmu_demo.v` | Hardware evidence may be overstated as system-level validation. | HW1 repeatability/expanded smoke doc, later BUS1. |

## Recommended packet order

1. D1 - descriptor datapath migration test plan
2. D2 - descriptor datapath implementation
3. M1 - MMUSR/PTEST status model test/spec
4. TTR1 - full TT/TTR legality test/spec
5. TC1 - TC/CRP/SRP traversal semantics
6. CTRL1 - PLOAD/PFLUSH architectural behavior
7. HW1 - expanded hardware smoke repeatability

## Rules for future packets

- Test/spec packets should precede RTL behavior changes.
- RTL edits require a trusted failing or incomplete test target.
- Do not collapse unrelated gaps into one packet.
- Keep public compatibility claims conservative.
