# Architecture Gap Ledger

## Purpose

This ledger is a planning bridge between the current first-pass SM68861
implementation and future Motorola-compliance work packets. It records known
implementation gaps, the evidence currently available in the repo, and the next
packet that should address each gap. It is not a claim of full Motorola PMMU
compatibility.

## Name adoption note

The project name `SM68861` has been adopted for public-facing documentation.

This does not change the architecture baseline, compatibility status, or implementation claims. The public tagline is **Soft MMU for 68k-family systems**. The initial technical focus remains MC68020 + MC68851-style PMMU behavior, with broader 68k-family compatibility profiles tracked as future work.

## Current verified baseline

- Regression scripts exist in `soft-mmu-68k/scripts/` for Icarus unit benches,
  Icarus integration benches, and Verilator lint.
- GitHub Actions HDL Regression exists at `.github/workflows/hdl-regression.yml`
  and runs the unit, integration, and lint scripts from `soft-mmu-68k/`.
- Unit benches are present under `soft-mmu-68k/tb/unit/`.
- Integration benches are present under `soft-mmu-68k/tb/integ/`.
- Verilator lint is covered by `soft-mmu-68k/scripts/run_verilator_lint.sh`.
- D2 migrated the default live walker / `mmu_top` descriptor boundary to the
  64-bit long-format page descriptor subset used by `descriptor_pack`.
- M1 added the repo-local MMUSR/PTEST status model specification.
- MGV0 added CSV-driven `perm_check` golden-vector consumption using committed
  MATLAB-generated vectors.
- The Basys 3 smoke demo exists under `soft-mmu-68k/fpga/basys3/`, but it is
  smoke-level evidence only and not proof of a full 68k bus/system integration.

## Gap table

| ID | Area | Current implementation | Gap / limitation | Evidence today | Risk | Recommended next packet |
| --- | --- | --- | --- | --- | --- | --- |
| A1-G01 | Descriptor datapath boundary | `descriptor_pack` implements a Motorola-aligned long-format subset for root, pointer, and page descriptors. The default live walker / `mmu_top` boundary now consumes the 64-bit long-format page descriptor subset. | Root and pointer descriptors are still format-modeling coverage only; the live walker remains single-level and does not consume a full descriptor tree. | `soft-mmu-68k/docs/design/descriptor_formats.md`, `soft-mmu-68k/rtl/core/descriptor_pack.v`, `soft-mmu-68k/rtl/core/pt_walker.v`, `soft-mmu-68k/rtl/core/mmu_top.v` | Readers may mistake long-format page-descriptor consumption for complete Motorola descriptor-tree traversal. | TC1 traversal semantics after TTR1. |
| A1-G02 | Page table walker depth | `pt_walker` is minimal, single-level, and issues one descriptor read per miss using the long-format page descriptor subset. | No multi-level walk and no full CRP/SRP/TC-driven traversal. | `soft-mmu-68k/rtl/core/pt_walker.v`, `soft-mmu-68k/docs/wiki/Translation-Flow.md` | Future descriptor work could be blocked by walker assumptions. | TC1 test/spec packet. |
| A1-G03 | Translation Control / root pointer behavior | `CRP`, `SRP`, and `TC` registers exist; `CRP` feeds the current walker table base and `TC` contributes a table-entry span. | Full Motorola TC field interpretation and root pointer behavior are not yet implemented. | `soft-mmu-68k/rtl/core/mmu_regs.v`, `soft-mmu-68k/rtl/core/mmu_top.v`, `soft-mmu-68k/docs/wiki/Translation-Flow.md` | Software-visible register presence can be mistaken for complete traversal semantics. | TC1 test/spec packet. |
| A1-G04 | Transparent Translation TT0/TT1 | First-pass subset uses high-byte base/mask plus selected enable, privilege, and program/data bits. | Full Motorola TT field decode and legality rules are deferred. | `soft-mmu-68k/docs/design/address_map.md`, `soft-mmu-68k/rtl/core/mmu_top.v` | Transparent-region behavior may diverge from Motorola-visible expectations. | TTR1 test/spec packet. |
| A1-G05 | MMUSR / PTEST status model | `MMUSR` register image exists; M1 specifies the repo-local MMUSR/PTEST status vocabulary and future mapping boundary. | Hardware translation/PTEST producers are not wired into MMUSR yet; current compact status remains a staging record. | `soft-mmu-68k/rtl/core/mmu_regs.v`, `soft-mmu-68k/rtl/core/flush_ctrl.v`, `soft-mmu-68k/docs/design/mmusr_ptest_status_model.md`, `soft-mmu-68k/docs/wiki/Control-Operations-(PTEST-PLOAD-PFLUSH).md` | Tests may lock in compact shim behavior before hardware MMUSR synthesis is implemented. | CTRL1 or a later mapper implementation packet. |
| A1-G06 | PLOAD / PFLUSH behavior | First-pass control shim supports preload and flush operations. | Behavior is not full instruction-visible Motorola semantics; preload has no full walk-completion model yet. | `soft-mmu-68k/rtl/core/flush_ctrl.v`, `soft-mmu-68k/docs/wiki/Control-Operations-(PTEST-PLOAD-PFLUSH).md` | Control operations may appear more complete than the current shim supports. | CTRL1 test/spec packet. |
| A1-G07 | CPU/special-space behavior | `FC=3'b111` is decoded as CPU/special space and excluded from transparent translation. | Full Motorola CPU-space behavior is not modeled. | `soft-mmu-68k/docs/design/address_map.md`, `soft-mmu-68k/rtl/core/mmu_decode.v`, `soft-mmu-68k/rtl/core/mmu_top.v` | CPU-space requests may take simplified paths that do not match a complete PMMU model. | FC1 or CPU1 test/spec packet. |
| A1-G08 | Fault model | Basic invalid, unmapped, bus, and permission fault classes exist; M1 records the repo-local mapping vocabulary for MMUSR/PTEST status. | Full fault prioritization, level reporting, and hardware MMUSR mapping are incomplete. | `soft-mmu-68k/rtl/core/pt_walker.v`, `soft-mmu-68k/rtl/core/mmu_top.v`, `soft-mmu-68k/rtl/core/mmu_regs.v`, `soft-mmu-68k/docs/design/mmusr_ptest_status_model.md` | Later architectural tests may disagree about which fault is visible first. | CTRL1 or later FAULT1. |
| A1-G09 | Software-side 68k tests | Scaffold-level software tests exist under `soft-mmu-68k/sw/tests_68k/`. | They are not yet tied into a real execution harness. | `soft-mmu-68k/README.md`, `soft-mmu-68k/sw/tests_68k/` | Software expectations can drift from RTL if they are not executable in CI. | SW1 scaffold/harness plan. |
| A1-G10 | Hardware proof depth | Basys 3 smoke demo exists and exercises canned translated, transparent, and permission cases. | It is not a full 68k bus/system integration. | `soft-mmu-68k/README.md`, `soft-mmu-68k/fpga/basys3/tops/top_mmu_demo.v` | Hardware evidence may be overstated as system-level validation. | HW1 repeatability/expanded smoke doc, later BUS1. |
| A1-G11 | MATLAB-backed golden-vector bridge | MGV0 proves the first committed MATLAB reference-model to CSV to SystemVerilog testbench path through `perm_check_tb.sv`. | Only `perm_check` currently has this proven CSV-backed path; MATLAB is verification collateral, not a replacement for RTL tests. | `soft-mmu-68k/scripts/matlab/README.md`, `soft-mmu-68k/tb/unit/perm_check_tb.sv`, `soft-mmu-68k/tb/common/golden_vectors/perm_check_golden_vectors.csv` | Readers may overgeneralize one proven vector flow into a project-wide MATLAB verification strategy. | Extend only with packet-specific test plans. |

## Completed packet history note

D1/D2/M1/MGV0 are now treated as completed project history, not upcoming
architecture packets. ADMIN1 is this documentation-only alignment packet and is
not part of the architecture implementation sequence.

## Recommended packet order

1. TTR1 - full TT/TTR legality test/spec
2. TC1 - TC/CRP/SRP traversal semantics
3. CTRL1 - PLOAD/PFLUSH architectural behavior
4. HW1 - expanded hardware smoke repeatability

## Rules for future packets

- Test/spec packets should precede RTL behavior changes.
- RTL edits require a trusted failing or incomplete test target.
- Do not collapse unrelated gaps into one packet.
- Keep public compatibility claims conservative.
