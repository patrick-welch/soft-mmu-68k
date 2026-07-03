# Control Operations Behavior Plan

## Purpose

This is a repo-local control-operations behavior plan for SM68861. It covers the current PTEST/probe-style operation, PLOAD/preload-style operation, PFLUSH targeted flush, PFLUSHA/flush-all, compact control status records, and future MMUSR/PTEST mapping boundaries.

This document does not implement RTL, executable tests, MATLAB vectors, generated vectors, scripts, workflows, wiki updates, or README updates. It does not claim full Motorola PMMU compatibility. It defines future test expectations before executable tests or RTL behavior changes are added.

## Current Implemented Subset

The current implementation is useful and tested as a first-pass control shim, not as a full Motorola instruction model.

- `flush_ctrl` is the current first-pass control-operation shim.
- Current command classes are NOP, flush all, flush match, probe, and preload.
- Whole-cache flush emits a one-cycle `flush_all_o` pulse and a minimal completion status.
- Targeted flush emits a one-cycle `flush_match_o` pulse with address and Function Code operands.
- Probe issues a probe request and returns a compact status record.
- Probe can report translated results, transparent-translation-qualified results, or miss.
- Preload issues a preload request and completes on a request/ready handshake.
- Preload does not yet model full walk completion or architectural PLOAD semantics.
- Current compact status is not the final MMUSR encoding.
- Current hardware does not update MMUSR from PTEST/probe results.
- Current behavior is useful and tested as a control shim, but not a full Motorola instruction model.

Do not read the current control command availability as proof of complete PTEST, PLOAD, PFLUSH, PFLUSHA, MMUSR, or PMMU behavior.

## Source and Reference Boundary

This document uses only source families already represented in the repo source-materials manifest. It adds no new sources and does not invent page numbers.

The main relevant source families already present in repo references are:

- MC68851 PMMU User's Manual
- M68000 Family Programmer's Reference Manual
- MC68030 User's Manual
- MC68040 User's Manual
- M68060 User's Manual

This document is a repo-local test/spec plan derived from current project docs, RTL, benches, and the source manifest. It is not a completed architectural proof.

## Terminology

| Term | Project-local meaning |
| --- | --- |
| control operation | A command-style MMU operation that affects translation-cache maintenance, probe/status reporting, or preload triggering through the current control path. |
| control shim | The current first-pass RTL boundary, implemented by `flush_ctrl` and integrated by `mmu_top`, that accepts compact command classes and emits simple pulses, requests, and status records. |
| PTEST | The Motorola-family architectural concept being approximated by the current probe-style operation. This document does not claim complete PTEST semantics. |
| probe | The repo-local current operation that asks whether the first-pass system has a usable result for an address and Function Code. |
| PLOAD | The Motorola-family architectural concept being approximated by the current preload-style operation. This document does not claim complete PLOAD semantics. |
| preload | The repo-local current operation that issues `preload_req_valid_o` with address and Function Code operands and waits for `preload_req_ready_i`. |
| PFLUSH | The Motorola-family architectural concept being approximated by the current targeted flush-match operation. This document does not claim complete operand, mask, mode, or legality semantics. |
| PFLUSHA | The Motorola-family architectural concept being approximated by the current flush-all operation. This document does not claim complete instruction-visible semantics. |
| flush all | The current operation that emits `flush_all_o` for one cycle and causes the integrated direct-mapped translation cache to invalidate all entries. |
| flush match | The current operation that emits `flush_match_o` for one cycle with explicit address and Function Code operands. |
| command valid | The input qualifier indicating that the command fields are being presented to the control shim. |
| command ready | The output qualifier indicating that the control shim can accept a command. It is high when the shim is idle. |
| busy | The output state indicating that the control path or integrated MMU path has an in-flight operation or is otherwise not idle. |
| compact status record | The current small command completion/result record made from `status_valid_o`, `status_cmd_o`, `status_hit_o`, `status_pa_o`, and `status_bits_o`. |
| status valid | The one-cycle qualifier showing that the current compact status record is valid. |
| status command | The command class reported with a compact status record. |
| status hit | For probe, the current repo-local indication that a usable first-pass result exists. It is not only a TLB-hit synonym. |
| status PA | The physical-address result field in compact status. For translated probe results it carries the translated PA; for TT-qualified probe results it mirrors the probed VA resized to PA width. |
| status bits | The compact status bit vector. Current convention uses the top bit for TT-qualified result class and the next bit for translated result class, with low attribute bits for translated results when available. |
| translated result | A current translated/TLB-backed or refill-backed result that is not a TT-qualified bypass. For probe status it sets the translated class bit and clears the TT class bit. |
| transparent-translation-qualified result | A current TT0/TT1-qualified result that bypasses page-table translation and returns an identity-style PA. For probe status it sets the TT class bit and clears the translated class bit. |
| probe miss | The current probe result when no usable translated or TT-qualified first-pass result is found. It is not evidence of invalid, unmapped, bus, or permission fault by itself. |
| MMUSR update | A future hardware-produced update to the software-visible `mmu_regs.mmusr` image. Current PTEST/probe and CPU translation producers do not update it. |
| current subset | The implemented, first-pass repo behavior documented by current RTL, docs, and benches. |
| future Motorola-aligned target | A later explicitly scoped and tested target that may add more Motorola-aligned behavior without claiming more than the repo implements and proves. |

## Current Command Role Table

| Command | Current repo role | Current visible outputs | Current status behavior | Future architectural question | Notes |
| --- | --- | --- | --- | --- | --- |
| NOP | Default or unsupported command fallback. | No flush, probe, or preload request. | Minimal status with `status_cmd_o` reporting NOP, hit deasserted, zero PA, and zero bits. | Which unsupported encodings, if any, should become architecturally visible errors or ignored operations? | NOP/default status should not imply architectural behavior. |
| FLUSH_ALL / PFLUSHA-like operation | Whole translation-cache maintenance primitive. | One-cycle `flush_all_o`; integrated path clears the translation cache through `tlb_dm`. | Minimal completion status with hit deasserted, zero PA, and zero bits. | What are the eventual PFLUSHA instruction-visible legality, privilege, mode, and completion semantics? | Current flush all is a useful maintenance primitive, not complete PFLUSHA compatibility. |
| FLUSH_MATCH / targeted PFLUSH-like operation | Address-plus-FC scoped invalidation primitive. | One-cycle `flush_match_o`, `flush_addr_o`, and `flush_fc_o`. | Minimal completion status with hit deasserted, zero PA, and zero bits. | What exact PFLUSH operand, mask, function-code, mode, and legality semantics belong in a later Motorola-aligned subset? | Targeted flush is address-plus-FC scoped because the current translation-cache identity includes Function Code. |
| PROBE / PTEST-like operation | Current probe-style status query. | `probe_req_valid_o`, `probe_addr_o`, and `probe_fc_o`; integrated lookup response supplies translated, TT-qualified, or miss information. | Status reports `CMD_PROBE`, usable-result hit, result PA, and compact result class bits. | Should later PTEST walk on miss, synthesize MMUSR, report fault classes, and expose levels? | Future questions should focus on architectural PTEST semantics, not on whether the current shim can issue a probe. |
| PRELOAD / PLOAD-like operation | Current preload-style request/ready command. | `preload_req_valid_o`, `preload_addr_o`, and `preload_fc_o`; integrated path may trigger walker activity on miss. | Minimal completion status when `preload_req_ready_i` is observed. | Should later PLOAD force a walk, fill the TLB, report faults, update MMUSR, or prove walk completion? | Current preload has a handshake and integrated path, but not a full PLOAD completion model. |

## Current Probe/PTEST Status Model

`CMD_PROBE` is the current PTEST-like operation. It asks whether the current first-pass system has a usable result for an address and Function Code.

Current result classes are translated result, transparent-translation-qualified result, and miss.

- `status_hit_o` means a usable first-pass result exists.
- `status_hit_o` must not be reduced to "TLB hit only."
- A translated result sets the translated-status class bit and clears the TT-match class bit.
- A TT-qualified result sets the TT-match class bit and clears the translated-status class bit.
- TT-qualified status PA mirrors the probed VA resized to PA width.
- A miss deasserts `status_hit_o` and does not force translated or TT class bits.
- Current probe does not perform a full architectural PTEST walk on a miss.
- Current probe does not update MMUSR.

This current probe model is intentionally compact. It is useful for integration benches and the Basys 3 smoke path, but it is not a complete architectural PTEST termination or MMUSR model.

## Current PLOAD/Preload Model

`CMD_PRELOAD` is the current PLOAD-like operation.

- Current preload emits `preload_req_valid_o`, `preload_addr_o`, and `preload_fc_o`.
- Current preload waits for `preload_req_ready_i`.
- Current preload returns a minimal completion status.
- Current preload does not yet prove full walk completion.
- Current preload does not yet prove full architectural PLOAD semantics.

Future work must decide whether preload should force a walk, fill the TLB, update status, report faults, or interact with MMUSR. Any such decision needs executable tests or a reviewed RTL packet before behavior is claimed.

## Current PFLUSH/PFLUSHA Model

`CMD_FLUSH_ALL` is the current flush-all / PFLUSHA-like operation. It emits a one-cycle `flush_all_o` pulse and returns minimal completion status.

`CMD_FLUSH_MATCH` is the current targeted PFLUSH-like operation. It emits a one-cycle `flush_match_o` pulse with address and Function Code operands.

Targeted flush is address-plus-FC scoped because the current translation-cache identity includes Function Code. Current flush operations do not prove full Motorola PFLUSH/PFLUSHA legality, mask, mode, or operand semantics.

## MMUSR Relationship and Boundary

M1 is the boundary for current MMUSR/PTEST status vocabulary.

- Current compact status is staging only.
- Current compact status is not final MMUSR encoding.
- `mmu_regs.mmusr` exists, but hardware PTEST/probe producers do not update it today.
- Future PTEST work may update MMUSR through a mapper boundary.
- CTRL1 should not implement or specify port-level RTL for `mmusr_result_mapper`.
- CTRL1 lists future questions needed before mapper implementation.

Future questions before mapper implementation include:

- Which command classes update MMUSR?
- Does only PTEST update MMUSR?
- Do CPU translation faults update MMUSR?
- How are translated, TT-qualified, miss, invalid, unmapped, span, bus, and permission classes mapped?
- When is level 0 versus level 1 used?
- How is separate compact status preserved?

Until a mapper is implemented and tested, compact command status and the software-visible MMUSR image must remain separate concepts in documentation and tests.

## Fault and Priority Boundaries

Current and future control-operation work should preserve these boundaries:

- Flush completion is not a translation fault.
- Probe miss is not the same thing as invalid, unmapped, bus, or permission fault evidence.
- Current probe does not walk a miss to discover descriptor faults.
- Current CPU translation path has separate fault outputs.
- M1 maps future invalid, unmapped, span, bus, and permission classes to MMUSR vocabulary.
- Future PTEST that performs walking must define bus, invalid, unmapped, span, and permission priority before implementation.
- CTRL1 does not collapse fault-priority work into RTL.

Current CPU translation faults are visible through the translation response path, not through hardware-updated MMUSR. Current compact probe miss means absence of a usable cached or TT-qualified result in the first-pass probe path, not proof of a descriptor or permission failure.

## Future Executable Test Matrix

These are future executable test targets only. CTRL1 does not create benches or tests.

| Test target | Current expected behavior | Future expected behavior question | Likely bench | Notes |
| --- | --- | --- | --- | --- |
| flush all emits one-cycle flush_all pulse | `CMD_FLUSH_ALL` emits a one-cycle pulse. | Should future PFLUSHA expose additional completion or legality status? | `instr_shim_tb.sv`, `mmu_core_tb.sv`, future `control_ops_tb.sv` | Current pulse behavior is already the shim boundary. |
| flush all invalidates translated TLB entries | Integrated `flush_all` clears valid entries in `tlb_dm`. | Does later architectural PFLUSHA need additional scope or operand modes? | `mmu_core_tb.sv`, future `control_ops_tb.sv` | TT qualification is separate from translated TLB invalidation. |
| flush all returns minimal completion status | Status reports flush-all command with zero/no-hit status. | Should future status remain minimal or gain command-specific diagnostics? | `instr_shim_tb.sv` | Completion is not a fault. |
| targeted flush emits one-cycle flush_match pulse | `CMD_FLUSH_MATCH` emits a one-cycle pulse. | Should future PFLUSH modes create multiple matching operations? | `instr_shim_tb.sv`, future `control_ops_tb.sv` | Current shim emits one pulse. |
| targeted flush carries address operand | `flush_addr_o` captures `cmd_addr_i`. | Which future operand forms map to the address operand? | `instr_shim_tb.sv` | Current operand is explicit address. |
| targeted flush carries FC operand | `flush_fc_o` captures `cmd_fc_i`. | Which future function-code or mask modes are supported? | `instr_shim_tb.sv` | Current operand is explicit Function Code. |
| targeted flush affects matching address plus FC only | `tlb_dm` invalidates matching indexed tag and Function Code. | Should broader PFLUSH forms match multiple FCs or address masks? | `mmu_core_tb.sv`, future `control_ops_tb.sv` | Current subset is address-plus-FC scoped. |
| probe translated hit returns status_hit and translated class bit | Translated result sets `status_hit_o` and translated class bit, with TT class bit clear. | How should translated PTEST status map into MMUSR? | `instr_shim_tb.sv`, `mmu_core_tb.sv`, future `mmusr_mapper_tb.sv` | Preserve the meaning of `status_hit_o`. |
| probe TT-qualified result returns status_hit and TT class bit | TT-qualified result sets `status_hit_o` and TT class bit, with translated class bit clear. | How should TT-qualified PTEST be represented when MMUSR has no TT class bit? | `instr_shim_tb.sv`, `mmu_core_tb.sv`, future `mmusr_mapper_tb.sv` | Separate compact status remains necessary. |
| probe miss returns status_hit deasserted | Miss deasserts `status_hit_o` and does not force translated or TT class bits. | Should a later PTEST miss trigger a walk or update MMUSR as no-result status? | `instr_shim_tb.sv`, `mmu_core_tb.sv` | Miss is not fault evidence by itself. |
| probe does not update MMUSR today | `mmu_regs.mmusr` is not driven by current probe producers. | Should only PTEST update MMUSR, or should CPU faults do so too? | future `mmusr_mapper_tb.sv`, future `control_ops_tb.sv` | M1 owns the status vocabulary boundary. |
| preload emits preload request | `CMD_PRELOAD` emits `preload_req_valid_o` with address and FC operands. | Should future PLOAD force a walk even when translated state exists? | `instr_shim_tb.sv`, future `control_ops_tb.sv` | Current request is visible at shim boundary. |
| preload completes on ready handshake | Preload status completes when `preload_req_ready_i` is observed. | Should future completion wait for walk/refill outcome? | `instr_shim_tb.sv`, `mmu_core_tb.sv` | Current handshake is not full walk completion. |
| preload status remains minimal today | Status reports preload command with zero/no-hit status. | Should future PLOAD report result or fault classes? | `instr_shim_tb.sv`, future `control_ops_tb.sv` | Keep current status wording conservative. |
| preload does not claim full walk-completion behavior today | Current docs and RTL describe no full walk-completion model. | What exact walk, fill, and fault behavior should future PLOAD prove? | `mmu_core_tb.sv`, future `control_ops_tb.sv` | Do not overstate current preload. |
| busy/ready blocks overlapping probe/preload commands | Probe and preload deassert command ready while waiting. | Should later operations support deeper queues or cancellation? | `instr_shim_tb.sv`, future `control_ops_tb.sv` | Current control shim supports one in-flight probe or preload. |
| default/NOP command produces safe minimal status | Default command emits NOP-class minimal status. | Should unsupported architectural operations trap, no-op, or report an error? | `instr_shim_tb.sv` | Current default must not imply architectural behavior. |

## Staged Follow-On Model

Recommended follow-on sequence:

- `CTRL1B` - executable tests for current flush/probe/preload shim boundaries.
- `CTRL2A` - PTEST/MMUSR mapper test/spec or mapper RTL packet, if approved.
- `CTRL2B` - PLOAD walk-completion behavior tests, if approved.
- `CTRL2C` - PFLUSH/PFLUSHA architectural operand/legality expansion, if approved.
- `FAULT1` - fault-priority and MMUSR synthesis edge cases.

These are recommendations only. Each follow-on packet should stay independently scoped and should not combine control operations, traversal, TT legality, fault priority, MATLAB vectors, and RTL expansion without explicit approval.

## Non-Goals

This packet has these explicit non-goals:

- no RTL edits
- no executable testbench edits
- no MATLAB source edits
- no generated CSV files
- no script or workflow edits
- no wiki edits
- no README edits
- no full Motorola PMMU compatibility claim
- no MMUSR hardware update implementation
- no PTEST walk implementation
- no PLOAD walk-completion implementation
- no PFLUSH architectural operand expansion
- no TTR1 expansion
- no TC/CRP/SRP traversal expansion
- no hardware smoke changes
- no new external source research
- no invented Motorola bitfield or instruction-encoding claims

## Acceptance Criteria for Later Control-Operation Packets

Later control-operation executable-test or RTL packets must prove:

- current translated path remains stable
- current TT-qualified probe behavior remains stable
- `status_hit_o` meaning remains precise
- translated and TT status class bits remain distinguishable
- flush-all invalidates current translated TLB entries
- targeted flush is address-plus-FC scoped in current subset
- preload current handshake remains stable
- compact status remains clearly separate from MMUSR until a mapper is implemented
- MMUSR updates are introduced only through explicit tests/specs
- Verilator lint passes
- GitHub Actions HDL Regression passes
- documentation remains conservative