# Descriptor Datapath Migration Plan

## Purpose

This plan defines the test/spec path for migrating the live descriptor datapath
from the current compact page descriptor model toward the Motorola-aligned
long-format subset already represented by `descriptor_pack`.

This is a planning packet only. It does not claim that the live datapath already
consumes full Motorola long-format descriptors, and it does not implement RTL or
new tests.

## Current boundary

The current repo has a deliberate descriptor boundary:

- `soft-mmu-68k/rtl/core/descriptor_pack.v` implements a 64-bit
  Motorola-aligned long-format subset for root, pointer, and page descriptors.
- `soft-mmu-68k/rtl/core/pt_walker.v` currently uses a compact page descriptor
  model with local `DESC_*` bit positions and a default `DESCR_WIDTH` of 32.
- `soft-mmu-68k/rtl/core/mmu_top.v` integrates that compact walker behavior by
  forwarding the walker descriptor bus and applying permissions after the walk.
- The Basys 3 smoke behavior is evidence for the first-pass integrated subset
  and must not be broken by the migration.

## Migration goal

The target for D2 should stay conservative:

- The live walker/datapath should consume a descriptor representation compatible
  with the `descriptor_pack` long-format subset, or a clearly named internal
  decoded form derived from that subset.
- Compact descriptor assumptions should be removed from the live translation
  path or isolated behind an explicitly named compatibility boundary.
- Existing valid translated, transparent, permission, unmapped, invalid, and
  bus-error behaviors should remain covered.

## Non-goals for D2

D2 should not attempt:

- full multi-level page table walk
- full Motorola TC/CRP/SRP semantics
- complete MMUSR/PTEST synthesis
- full CPU/special-space behavior
- full transparent-translation legality
- full short-format descriptor support unless explicitly approved later

## Existing evidence

| File | Current role | Descriptor assumption observed | Migration relevance |
| --- | --- | --- | --- |
| `soft-mmu-68k/rtl/core/descriptor_pack.v` | Combinational pack/unpack reference for root, pointer, and page descriptors. | Defaults to a 64-bit long-format-oriented subset; validity is derived from `DT != 2'b00`; unsupported fields are zeroed. | Defines the planned descriptor field source for D1b/D2 tests. |
| `soft-mmu-68k/tb/unit/descriptor_pack_tb.sv` | Golden unit coverage for descriptor packing and unpacking. | Expects root/pointer fields at `[63]`, `[62:48]`, `[33:32]`, and address bits, plus page fields at `[40]`, `[38]`, `[36]`, `[35]`, `[34]`, `[33:32]`, and `[31:8]`. | Must keep passing while the live datapath migrates. |
| `soft-mmu-68k/docs/design/descriptor_formats.md` | Design note for the `descriptor_pack` subset. | Explicitly says the full live datapath has not yet migrated to long-format descriptors end to end. | Guards against overstating D2 compatibility claims. |
| `soft-mmu-68k/rtl/core/pt_walker.v` | Minimal single-level page-table walker. | Defaults to `DESCR_WIDTH = 32` and defines compact `DESC_DT`, `DESC_V`, `DESC_S`, `DESC_WP`, `DESC_CI`, `DESC_M`, `DESC_U`, and PFN positions. | Primary RTL migration point or compatibility-boundary point. |
| `soft-mmu-68k/tb/unit/pt_walker_tb.sv` | Unit coverage for walker success, invalid, unmapped, bus-error, and busy behavior. | Builds compact 32-bit descriptors in `make_page_desc` and expects compact attribute extraction. | D1b should introduce planned long-format or decoded-boundary walker vectors before D2 changes the RTL. |
| `soft-mmu-68k/tb/integ/mmu_core_tb.sv` | Integration coverage for preload/probe, TLB hit/miss/refill, TT, permission fault, CPU-space fallback, and bus fault behavior. | Uses compact 32-bit descriptor helpers and a 32-bit walker descriptor bus. | D2 must preserve current outward behavior while changing or isolating descriptor representation. |
| `soft-mmu-68k/rtl/core/mmu_top.v` | First-pass integration wrapper around registers, TLB, walker, TT, refill, and permission checks. | Passes `DESCR_WIDTH` to `pt_walker`; derives permissions from walker/TLB attribute bits after translation. | D2 must preserve refill timing assumptions, fault mapping, and permission split. |
| `soft-mmu-68k/docs/design/architecture_gap_ledger.md` | Gap ledger for future Motorola-compliance packets. | Identifies the descriptor datapath boundary as A1-G01: `descriptor_pack` is long-format-aligned while the live datapath remains compact. | Names D1 as the test plan and D2 as the later implementation packet. |
| `soft-mmu-68k/docs/design/address_map.md` | Current FC, permission, TT, probe, and Basys 3 smoke behavior reference. | Describes the current first-pass translated-vs-transparent split and smoke-level board evidence. | D2 should not disturb TT, permission, CPU/special-space, or smoke expectations. |
| `soft-mmu-68k/docs/wiki/Descriptor-Formats.md` | Wiki explanation of the two descriptor realities. | Separates `descriptor_pack` long-format subset from compact live walker/smoke descriptors. | Useful wording model for conservative public docs after D2. |
| `soft-mmu-68k/docs/wiki/Translation-Flow.md` | Wiki explanation of the current integrated datapath. | Describes a minimal single-level walker returning attributes for later permission checks. | D2 should not imply multi-level traversal or full Motorola status behavior. |

## Proposed test-first sequence

1. D1 - this plan.
2. D1b - descriptor datapath tests only.
3. D2 - RTL migration implementation.
4. D2b - cleanup docs after implementation.

D1b should add tests without changing RTL behavior yet:

- `soft-mmu-68k/tb/unit/descriptor_pack_tb.sv` golden vectors remain passing.
- `soft-mmu-68k/tb/unit/pt_walker_tb.sv` vectors exercise descriptor valid,
  invalid, unmapped, and page cases using the planned long-format or decoded
  descriptor boundary.
- `soft-mmu-68k/tb/integ/mmu_core_tb.sv` preserves current translated
  hit/miss/refill behavior.
- Permission-fault behavior remains controlled by `soft-mmu-68k/rtl/core/perm_check.v`,
  not by descriptor migration unless explicitly specified.
- Bus-error dominance remains covered so an abstract descriptor bus error still
  reports a bus fault ahead of descriptor interpretation.
- Compact descriptor assumptions are either removed from new expectations or
  explicitly isolated behind a named compatibility boundary.

## Descriptor field mapping checklist

For the subset already represented by `descriptor_pack`, D1b/D2 should account
for:

- [ ] root descriptor fields: `L/U`, `LIMIT`, `DT`, and root table address
- [ ] pointer descriptor fields: `L/U`, `LIMIT`, `DT`, and next-table address
- [ ] page descriptor fields: `S`, `CI`, `M`, `U`, `WP`, `DT`, and page base
  physical address
- [ ] descriptor type / invalid handling through `DT == 2'b00` and `DT != 2'b00`
- [ ] page frame address extraction from the planned page descriptor boundary
- [ ] permission/attribute bits passed toward permission logic as the existing
  `S`, `WP`, `CI`, `M`, and `U` attribute bundle or a clearly named successor
- [ ] reserved/unsupported fields treated conservatively and not used to claim
  full Motorola PMMU behavior

## D2 acceptance criteria

D2 must prove all of the following before acceptance:

- only approved RTL, test, and documentation files changed
- `soft-mmu-68k/tb/unit/descriptor_pack_tb.sv` still passes
- `soft-mmu-68k/tb/unit/pt_walker_tb.sv` passes
- `soft-mmu-68k/tb/integ/mmu_core_tb.sv` passes
- HDL Regression passes in GitHub Actions
- docs clearly state whether compact descriptor support remains, is removed, or
  is isolated
- no public claim of full Motorola PMMU compatibility

## Risks

- Changing walker descriptor width can break refill timing or bus-response
  assumptions.
- Permission attributes may be mis-mapped between the long-format subset and the
  existing permission logic.
- Descriptor invalid/unmapped semantics may shift if `DT`, valid, and page type
  handling are not specified first.
- Basys 3 smoke demo descriptor responder may need a later update if the live
  walker no longer accepts the compact smoke descriptor image.
- Tests may accidentally lock in non-Motorola compact behavior if D1b does not
  name the compatibility boundary clearly.

## Recommended D2 scope

D2 should stay narrow and should not mix in TC/root traversal or MMUSR work.

Potential D2 files may include:

- `soft-mmu-68k/rtl/core/pt_walker.v`
- `soft-mmu-68k/tb/unit/pt_walker_tb.sv`
- `soft-mmu-68k/tb/integ/mmu_core_tb.sv`
- `soft-mmu-68k/docs/design/descriptor_formats.md`
- possibly `soft-mmu-68k/fpga/basys3/tops/top_mmu_demo.v` only if the smoke
  descriptor responder must change

D2 should focus on the descriptor boundary and its direct tests. TC/root
traversal, full page-walk depth, MMUSR/PTEST synthesis, transparent-translation
legality, CPU/special-space behavior, and short-format descriptor support remain
deferred unless approved in a later packet.
