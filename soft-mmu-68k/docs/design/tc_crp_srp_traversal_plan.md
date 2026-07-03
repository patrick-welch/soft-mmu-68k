# TC / CRP / SRP Traversal Semantics Plan

## Purpose

This is a repo-local TC / CRP / SRP traversal semantics test/spec document for
SM68861.

It does not implement RTL. It does not add executable tests. It does not add
MATLAB vectors. It does not claim full Motorola PMMU compatibility.

The purpose of this plan is to define future test expectations for traversal
behavior before executable tests or RTL changes attempt to expand the current
walker. The plan separates current implemented behavior from future
Motorola-aligned targets so later packets can work from a reviewed local
semantics surface.

## Current Implemented Subset

The current implementation is first-pass and deliberately limited.

- `mmu_regs` exposes `CRP`, `SRP`, `TC`, `TT0`, `TT1`, and `MMUSR` register
  images.
- `mmu_top` wires the relevant register state into the integrated path.
- `CRP` is currently passed to the walker as the table base.
- `TC` currently contributes a limited table-entry span/configuration role by
  feeding the walker `table_entries_i` input from the low VPN-width portion of
  the `TC` image.
- The current walker behavior is minimal and single-level.
- The current walker issues one descriptor read per miss.
- The current default descriptor boundary is the 64-bit long-format page
  descriptor subset after D2.
- The current live walker does not perform full root/pointer traversal.
- The current live walker does not consume a complete Motorola descriptor tree.
- The current implementation does not fully interpret Motorola TC fields.
- `SRP` exists as a register image, but full SRP root-selection behavior is
  deferred. Current RTL does not show SRP selecting a live traversal root.
- TC contributes current table-span/configuration behavior, but not full
  Motorola address-partition semantics.
- TT/TTR behavior is covered by TTR1 and should not be expanded here.

Do not read register presence as traversal completeness. The current repo has
useful register images, a live single-level walker, and a long-format page
descriptor boundary; it does not yet have full TC/CRP/SRP-driven descriptor-tree
traversal.

## Source and Reference Boundary

This document uses only source families already represented in the repo source
materials manifest. It adds no new sources and does not invent page numbers.

The main relevant source families are:

- MC68851 PMMU User's Manual
- MC68030 User's Manual
- MC68040 User's Manual
- M68060 User's Manual
- M68000 Family Programmer's Reference Manual

This document is a repo-local test plan derived from current project docs, RTL,
benches, tutorials, and the source manifest. It is not a completed
architectural proof.

## Terminology

| Term | Project-local meaning |
| --- | --- |
| Translation Control register | The software-visible register image stored by `mmu_regs` as `tc`. Current RTL uses part of this image as a table-entry span input; full Motorola field interpretation is deferred. |
| TC | Short name for the Translation Control register image. In current traversal, the low VPN-width bits become `table_entries_cfg` for the single-level walker. |
| Current Root Pointer | The software-visible root pointer image stored by `mmu_regs` as `crp`. In the current integrated path, it feeds the walker's table base. |
| CRP | Short name for the Current Root Pointer register image. Current live traversal treats it as a table base, not as a fully decoded Motorola root-pointer descriptor tree. |
| Supervisor Root Pointer | The software-visible root pointer image stored by `mmu_regs` as `srp`. Current RTL stores and exposes it, but does not use it for live root selection. |
| SRP | Short name for the Supervisor Root Pointer register image. Full supervisor-root selection remains a future semantics question. |
| root pointer | A root address or root pointer image that future traversal may use as the starting point for descriptor-tree walking. In the current subset, the visible live root is `CRP` as the table base. |
| root descriptor | A descriptor format modeled by `descriptor_pack` for root translation structures. It is format coverage today, not a live consumed traversal level. |
| pointer descriptor | A descriptor format modeled by `descriptor_pack` for next-table pointers. In the current live single-level walker, non-page descriptor types report unmapped rather than being traversed. |
| page descriptor | The descriptor kind consumed by the current live walker when `DT` equals the current page descriptor type. It supplies page base and attributes. |
| table index | The VPN-derived index used by the current single-level walker to choose one descriptor slot. Today it is the current VPN scaled by descriptor size. |
| table span | The configured number of entries accepted by the current walker. Today `start_vpn >= table_entries_i` produces an unmapped result before a descriptor fetch. |
| page offset | The low `PAGE_SHIFT` bits of the virtual address. On a successful walk, `mmu_top` combines this offset with the walked page base. |
| page size / page shift | The page geometry parameterized by `PAGE_SHIFT`. Current benches commonly use smaller widths for simulation, while the default RTL parameter is 12. |
| single-level walker | The current `pt_walker` behavior: one table base, one VPN-derived descriptor address, one descriptor read, and no root/pointer descent. |
| multi-level traversal | A future behavior where the walker may consume root, pointer, and page descriptors across multiple levels. This is not implemented today. |
| descriptor-tree traversal | A future traversal model that starts at a selected root and follows descriptor levels until a page mapping or terminal fault is reached. |
| root selection | The policy that decides whether a request uses CRP, SRP, or another root source based on access class and TC/root state. Current live RTL does not implement SRP selection. |
| function-code-qualified access | An access classified by `FC[2:0]` through `mmu_decode`, including user/supervisor and program/data distinctions for normal memory classes. |
| current subset | The implemented and tested first-pass repo behavior: TT/TTR qualification, TLB lookup, single-level long-format page descriptor walk, refill, and permission after translation. |
| future Motorola-aligned target | A future explicitly scoped target that may add more Motorola-aligned TC fields, root selection, descriptor traversal, and status behavior after tests specify the expected subset. |

## Current Register Role Table

| Register | Current repo role | Current traversal effect | Future traversal question | Notes |
| --- | --- | --- | --- | --- |
| CRP | Software-visible current root pointer image in `mmu_regs`. | Feeds the walker table base in the live `mmu_top` subset. | Should CRP remain a simple base for Stage 1, or become a source for root descriptor traversal in later stages? | Current behavior is table-base use, not complete root descriptor semantics. |
| SRP | Software-visible supervisor root pointer image in `mmu_regs`. | No live root-selection effect is visible in current RTL. | When should supervisor accesses select SRP, and how should unsupported SRP use behave? | Current SRP storage must not be mistaken for implemented supervisor traversal. |
| TC | Software-visible 32-bit Translation Control image. | Low VPN-width bits feed `table_entries_cfg`; the walker treats that as a table span. | Which TC concepts should control enable, page size, address partition, levels, limit checks, and root selection? | Current behavior is a narrow configuration/span role only. |
| TT0 | Transparent-translation register image. | TT qualification occurs before TLB/walker use. | Covered by TTR1, not expanded here. | TC1A should only preserve the ordering relationship. |
| TT1 | Transparent-translation register image. | TT qualification occurs before TLB/walker use. | Covered by TTR1, not expanded here. | CPU/special and reserved FC TT behavior belongs to TTR1/FC follow-up work. |
| MMUSR | Software-visible MMU status image. | No current hardware traversal producer updates the MMUSR image. | How should future traversal results map to MMUSR/PTEST status? | Covered by M1 and future mapper work; do not implement here. |

## Current Live Traversal Model

The current live traversal model is:

1. A request arrives through `mmu_top` with virtual address, function code,
   read/write intent, and fetch intent.
2. `mmu_decode` classifies the function code.
3. TT/TTR qualification occurs before TLB or walker use.
4. A TT/TTR match bypasses traversal and returns the current identity-style PA
   result. TTR legality details remain covered by TTR1.
5. If TT/TTR does not match, the direct-mapped TLB lookup is attempted.
6. A TLB miss captures the request and triggers the minimal walker.
7. The walker computes a descriptor read address from the current table base
   plus a VPN-derived index scaled by the 64-bit descriptor size.
8. The current table base comes from `CRP` through `mmu_top`.
9. The current table span comes from the configured `table_entries_i` value
   derived from `TC`.
10. If the VPN is outside the configured table span, the walker produces the
    current unmapped response before issuing a descriptor read.
11. Otherwise, the walker reads one descriptor.
12. A valid long-format page descriptor produces a page base and attribute
    vector for refill and later permission checking.
13. An invalid descriptor produces the current invalid fault.
14. A non-page descriptor produces unmapped in the current single-level subset.
15. A bus error during descriptor fetch dominates descriptor interpretation.
16. Permission is checked outside the walker after a translated TLB hit or a
    successful walk.
17. The walker does not traverse root or pointer descriptor levels.

This model is useful and tested, but it is not a complete TC/CRP/SRP traversal
model.

## TC Field Interpretation Inventory

| TC-related concept | Current repo behavior | Known gap | Future test/spec question | Notes |
| --- | --- | --- | --- | --- |
| translation enable / disabled state | `TC` resets to zero. Current live traversal does not fully implement Motorola enable/disable semantics; zero table entries make walker misses fail the current span check. | No complete architectural enable/disable model. | Should disabled translation bypass, fault, or preserve current local behavior for a staged subset? | Do not infer full enable semantics from reset comments alone. |
| page size / page offset width | `PAGE_SHIFT` is an RTL parameter, not a decoded TC field. | TC-driven page size is not implemented. | Should TC later select page size, and which page sizes are in scope? | Current benches may use small page shifts for simulation. |
| table index partitioning | Current walker uses the full VPN as a single index. | No TC-driven split into multiple indexes. | How should TC partition virtual address bits among root, pointer, and page levels? | Phrase future work as concepts unless field names are confirmed in-source. |
| number of levels | Current walker is single-level. | No live multi-level traversal. | Which TC concepts should select one-level, two-level, or broader traversal in future packets? | Stage 1 should stay single-level. |
| table-entry span / table_entries | `mmu_top` derives `table_entries_cfg` from low VPN-width TC bits and feeds the walker. | Span is not a complete Motorola limit interpretation. | What exact in-range and out-of-range cases should executable tests lock down first? | Current `start_vpn >= table_entries_i` reports unmapped. |
| root pointer selection | Current live walker uses CRP as table base. | SRP and FC-based root selection are not implemented. | Which FC classes should select CRP, SRP, or an unsupported/deferred path? | Preserve current CRP behavior until tests specify a change. |
| root descriptor interpretation | `descriptor_pack` models a root descriptor subset. | Live walker does not consume root descriptors. | When should a selected root pointer lead to root descriptor fetch/validation? | Format coverage is not traversal coverage. |
| pointer descriptor interpretation | `descriptor_pack` models a pointer descriptor subset. | Live walker treats non-page descriptor types as unmapped. | Which pointer descriptor types should cause a next-level fetch in Stage 2? | Current non-page handling must remain clear for Stage 0/1 tests. |
| page descriptor interpretation | Current walker consumes the long-format page descriptor subset. | Only a narrow page descriptor subset is live. | Which additional page fields, if any, are needed before multi-level traversal? | D2 made this the default live descriptor boundary. |
| limit checks | Current span check rejects `start_vpn >= table_entries_i`. | Full root/pointer limit semantics are absent. | Should future limit failures map separately from unmapped, and at what level? | M1 proposes MMUSR L mapping for span-like future status. |
| bus-error handling during traversal | Walker reports bus fault when the descriptor response has `mem_resp_err_i`. | Multi-level bus-error priority is not specified. | At which level should future bus errors be reported, and should they stop all descriptor decode? | Current bus error dominates descriptor interpretation. |
| invalid descriptor handling | `DT == 2'b00` reports invalid. | Multi-level invalid handling is not specified. | Should root, pointer, and page invalid descriptors share one priority and status vocabulary? | Current invalid is distinct from unmapped. |
| non-page descriptor handling in single-level subset | Nonzero DT other than page reports unmapped. | Future pointer/root descriptors may become valid traversal nodes. | How should tests preserve Stage 0/1 non-page behavior while allowing Stage 2 traversal expansion? | Do not describe current non-page as architecturally invalid for all future models. |
| interaction with TT/TTR bypass | TT/TTR qualification happens before TLB/walker use. | Full TTR legality is outside this plan. | Which TC/CRP/SRP tests must prove TT match prevents traversal? | TTR1 owns detailed TT matrix. |
| interaction with MMUSR/PTEST status | Current CPU faults and compact probe status exist outside hardware MMUSR synthesis. | MMUSR/PTEST mapping is deferred. | Which traversal results should future mapper work consume? | M1 owns the status model boundary. |

## CRP / SRP Root-Selection Policy Questions

Current live RTL does not prove SRP-driven root selection. If an access reaches
the current walker, CRP is the visible live table-base source. Future
TC/CRP/SRP work must decide whether user and supervisor accesses select
different roots, when SRP is active, and how disabled or unsupported root
selection behaves.

TT qualification happens before translation traversal and excludes CPU/special
space under the current TTR1 rule. Do not claim full Motorola CPU-space
behavior from the current subset.

| FC | Current repo class | Current root source if visible | Future CRP/SRP/root-selection question | Notes |
| --- | --- | --- | --- | --- |
| `000` | reserved | CRP if the request falls through to the current walker; no SRP selection visible. | Should reserved FCs fault, use a default root, or remain unsupported before traversal? | Do not accidentally give reserved FCs a complete root policy. |
| `001` | user data | CRP if traversal occurs. | Should user data use CRP, a user root, or another TC-qualified root policy? | Normal user data is a core Stage 1 test candidate. |
| `010` | user program | CRP if traversal occurs. | Should user program share user-data root policy or differ by program/data class? | Current walker does not branch on FC. |
| `011` | non-normal / currently unnamed | CRP if the request falls through to the current walker; no SRP selection visible. | Should this encoding remain outside normal traversal, fault, or map to a defined class? | Do not infer Motorola CPU-space behavior from this encoding. |
| `100` | reserved | CRP if the request falls through to the current walker; no SRP selection visible. | Should supervisor-half reserved FCs have a distinct unsupported behavior? | Current decode marks supervisor half by `FC[2]`, but no normal memory class. |
| `101` | supervisor data | CRP if traversal occurs. | Should supervisor data select SRP, CRP, or a TC-controlled root? | SRP behavior is deferred unless a later RTL packet implements it. |
| `110` | supervisor program | CRP if traversal occurs. | Should supervisor program share supervisor-data root policy or differ by program/data class? | Current permission behavior distinguishes supervisor, but root selection does not. |
| `111` | CPU/special space | CRP if the request falls through to the current walker; TT bypass is excluded. | Should CPU/special space bypass traversal, fault, use special roots, or remain outside scope? | Do not claim complete Motorola CPU-space behavior. |

## Descriptor Traversal Model Candidates

Future work should be staged. Do not jump directly from the current
single-level implementation to broad multi-level traversal without first
pinning down TC/span/root expectations.

| Stage | Purpose | What tests should prove | What remains deferred | Risk |
| --- | --- | --- | --- | --- |
| Stage 0 - current single-level page descriptor read | Preserve and document the implemented D2 live path. | CRP table base affects descriptor read address; TC span gates in-range versus out-of-range VPN; one long-format page descriptor succeeds; invalid, non-page, and bus cases remain distinct. | SRP selection, root descriptors, pointer descriptors, TC partitioning, full MMUSR/PTEST mapping. | Later work may accidentally break current stable translated path. |
| Stage 1 - explicit TC/root/span semantics while staying single-level | Make current CRP and TC behavior explicit in executable tests while still avoiding multi-level traversal. | Current CRP-as-base and TC-as-span behavior; unsupported SRP/root-selection behavior is either unchanged or explicitly deferred; TT/TTR ordering is preserved. | Full root/pointer descent and Motorola TC bitfield coverage. | Tests might overfit current placeholder TC semantics if future names are not clear. |
| Stage 2 - root/pointer/page descriptor traversal test model | Define and test a small descriptor-tree traversal model before RTL expansion. | Selected root source, root descriptor read, pointer descriptor read, page descriptor read, level-specific invalid/unmapped/bus/span behavior. | Broader family-specific deltas, complete field coverage, full PTEST/MMUSR synthesis. | Multi-level tests may expose ambiguity in root selection and fault priority. |
| Stage 3 - broader Motorola-aligned multi-level traversal | Expand toward a reviewed Motorola-aligned traversal subset. | TC partitioning, root selection, descriptor type transitions, limit checks, and fault/status mapping across multiple levels. | Complete compatibility claims until implemented, tested, and documented. | Highest risk of overclaiming or mixing unrelated compatibility work. |

## Future Executable Test Matrix

These are future executable test targets only. This packet adds no tests.

| Test target | Current expected behavior | Future expected behavior question | Likely bench | Notes |
| --- | --- | --- | --- | --- |
| CRP base affects descriptor read address | Walker descriptor address is `CRP + VPN * descriptor_bytes`. | Should CRP later point directly to a table, a root descriptor, or a root table structure? | `pt_walker_tb.sv`, `mmu_core_tb.sv`, future `tc_crp_srp_tb.sv` | Current behavior should be locked before root traversal changes. |
| SRP does not accidentally affect current user path unless specified | SRP is stored but not used for current live root selection. | When should SRP become active, and for which FC classes? | `mmu_core_tb.sv`, future `tc_crp_srp_tb.sv` | A user-path test should catch accidental SRP wiring. |
| TC table span accepts in-range VPN | VPN less than `table_entries_i` allows a descriptor read. | What TC field or fields define span in a future model? | `pt_walker_tb.sv`, `mmu_core_tb.sv` | Current low-TC-bit span should be made explicit in TC1B. |
| TC table span rejects out-of-range VPN | `start_vpn >= table_entries_i` reports current unmapped behavior before descriptor fetch. | Should future status distinguish span/limit from generic unmapped? | `pt_walker_tb.sv`, future `tc_crp_srp_tb.sv` | M1 proposes later MMUSR L mapping for span-like cases. |
| single-level valid page descriptor succeeds | Long-format page descriptor with page DT refills and returns PA/attrs. | Which additional page fields should future traversal preserve? | `pt_walker_tb.sv`, `mmu_core_tb.sv` | Keep D2 boundary stable. |
| single-level invalid descriptor faults | `DT == 2'b00` produces invalid fault. | Should invalid root, pointer, and page descriptors report level-specific status later? | `pt_walker_tb.sv`, `mmu_core_tb.sv` | Current invalid is distinct from non-page/unmapped. |
| single-level non-page descriptor reports unmapped in current subset | Nonzero DT other than page reports unmapped. | When Stage 2 supports pointer/root descriptors, which non-page cases remain unmapped? | `pt_walker_tb.sv`, `mmu_core_tb.sv` | Do not call all future pointer descriptors invalid. |
| bus error dominates descriptor interpretation | Descriptor bus error reports bus fault even if returned bits look invalid or non-page. | How should bus errors identify traversal level in future status? | `pt_walker_tb.sv`, `mmu_core_tb.sv` | Current priority is already visible in walker code and tests. |
| TT/TTR match bypasses traversal | TT match returns identity-style PA and no walk starts for the matched CPU request. | How should TC disabled/span/root state interact with TT match in future tests? | `mmu_core_tb.sv` | Detailed TT legality remains TTR1. |
| TT/TTR non-match falls back to traversal | Non-matching TT allows current TLB/walker path to proceed. | Which TC/root policies apply after TT non-match? | `mmu_core_tb.sv`, future `tc_crp_srp_tb.sv` | Preserve TT-before-traversal ordering. |
| reserved FC does not accidentally select unsupported root behavior | Reserved FCs do not TT-match; current traversal can still fall through to CRP if exercised. | Should reserved FCs be rejected before traversal or explicitly mapped to a local policy? | future `tc_crp_srp_tb.sv` | Avoid silent compatibility claims. |
| CPU/special FC does not accidentally claim complete Motorola behavior | CPU/special FC does not TT-match; current path can fall through to translated behavior in the subset. | Should CPU/special traversal be unsupported, special-cased, or deferred? | `mmu_core_tb.sv`, future `tc_crp_srp_tb.sv` | TTR1 already preserves CPU/special TT exclusion. |
| permission fault occurs after successful translation, not inside walker | Walker forwards attrs; `mmu_top`/`perm_check` report permission fault after TLB hit or successful walk. | Should future PTEST/MMUSR include permission-aware traversal results? | `mmu_core_tb.sv` | Keep walker and permission boundary clear. |
| PTEST/MMUSR mapping remains deferred to M1/future mapper work | Current MMUSR register image is not hardware-updated by traversal results. | Which traversal classes feed a future `mmusr_result_mapper`? | future mapper tests, future `tc_crp_srp_tb.sv` | Do not add mapper behavior in TC1A. |

Optional future MATLAB vector collateral may become useful after these semantics
are reviewed. Candidate consumers could include a future `tc_crp_srp_tb.sv` or
a future MATLAB vector set, but MATLAB must not replace directed HDL tests.

## Fault and Priority Expectations

Current and future work should preserve these expectations unless a later
packet explicitly changes them:

- TT/TTR bypass happens before traversal.
- TT/TTR detailed legality is owned by TTR1 and should not be redefined here.
- Table span/out-of-range behavior must be specified before implementation.
- In the current walker, out-of-range span reports unmapped before descriptor
  fetch.
- Bus error during descriptor fetch dominates descriptor decode.
- Invalid descriptor is distinct from non-page/unmapped in the current fault
  vocabulary.
- Non-page descriptors report unmapped in the current single-level subset.
- Permission faults occur after successful translation and outside the walker.
- MMUSR/PTEST synthesis remains covered by M1/future mapper work.
- Do not collapse fault-priority work into this packet.

For future multi-level traversal, tests must specify whether each fault class
is reported at root, pointer, or page level before RTL consumes those levels.

## MATLAB Vector Opportunity

TC/CRP/SRP traversal is a candidate for future MATLAB-backed modeling, but not
in this packet.

Potential future MATLAB collateral may include:

```text
scripts/matlab/models/mmu_tc_partition_reference.m
scripts/matlab/models/mmu_traversal_reference.m
scripts/matlab/generators/generate_tc_traversal_vectors.m
scripts/matlab/examples/run_tc_traversal_demo.m
tb/common/golden_vectors/tc_traversal_golden_vectors.csv
```

MATLAB vectors should wait until this semantics matrix is reviewed, and
probably until a smaller TC1B executable-test scope is chosen. Any future
MATLAB-backed packet must document the reference model, generator,
regeneration command, generated vector path, consuming SystemVerilog bench, and
behavioral scope.

## Recommended Follow-On Packets

Recommended follow-on sequence:

- `TC1B` - executable tests for current TC/CRP table-base and span behavior.
- `MTC1` - optional MATLAB reference/vector model for TC address partitioning.
- `TC2A` - RTL cleanup for explicit TC/span/root-selection boundaries, if
  tests expose ambiguity.
- `TC2B` - staged root/pointer traversal implementation plan.

These are recommendations only. Each packet should remain independently scoped
and should not combine traversal, TTR legality, MMUSR/PTEST mapping, MATLAB,
and RTL expansion without explicit approval.

## Non-Goals

This packet has these explicit non-goals:

- no RTL edits
- no executable testbench edits
- no MATLAB source edits
- no generated CSV files
- no script or workflow edits
- no full Motorola PMMU compatibility claim
- no TTR1 expansion
- no PLOAD/PFLUSH behavior expansion
- no MMUSR hardware update implementation
- no hardware smoke changes
- no wiki publishing
- no tutorial edits
- no new external source research
- no invented Motorola bitfield claims

## Acceptance Criteria for Later Implementation/Test Packets

Later TC/CRP/SRP executable-test or RTL packets must prove:

- current simple translated path remains stable
- current D2 descriptor boundary remains stable
- current TTR1 behavior remains stable
- CRP/table-base behavior is tested explicitly
- TC table-span behavior is tested explicitly
- SRP/root-selection behavior is either tested or explicitly deferred
- bus/invalid/unmapped/span/permission priority remains clear
- Verilator lint passes
- GitHub Actions HDL Regression passes
- documentation remains conservative

Where later work adds MATLAB vectors, it must also prove that the vectors are
deterministic, generated from documented collateral, and consumed by a bench
that fails loudly on missing, malformed, or mismatched rows.

## Verification for This Packet

Before committing this documentation-only packet, verify:

```powershell
git status --short --branch
git diff --check -- soft-mmu-68k/docs/design/tc_crp_srp_traversal_plan.md
git diff --stat
git diff -- soft-mmu-68k/docs/design/tc_crp_srp_traversal_plan.md
```

HDL scripts may be skipped with this exact reason:

```text
SKIPPED: documentation-only packet
```

If any non-documentation or non-owned file changes, stop and report.