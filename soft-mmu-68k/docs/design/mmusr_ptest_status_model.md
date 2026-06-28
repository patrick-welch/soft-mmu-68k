# MMUSR / PTEST Status Model

## Purpose

This is a repo-local planning/spec document for the current first-pass
`soft-mmu-68k` soft-MMU subset. It defines conservative status vocabulary and
mapping conventions for future MMUSR/PTEST work so later test and RTL packets do
not have to guess.

This document does not implement full Motorola PMMU compatibility. It records
current repo behavior and proposed repo-local conventions only.

This document does not change RTL or tests.

## Current baseline

- `soft-mmu-68k/rtl/core/mmu_regs.v` exposes a software-visible 16-bit MMUSR
  image.
- Current MMUSR bits are B, L, S, A, W, I, M, G, and level. Reserved bits are
  forced low by the register block.
- Current MMUSR is software-writeable for status-class bits and level bits.
  Writes are masked by `MMUSR_SW_WRITABLE_MASK`.
- Hardware translation/PTEST producers are not wired into MMUSR yet.
- `soft-mmu-68k/rtl/core/flush_ctrl.v` reports a compact probe/status record
  using `status_valid_o`, `status_cmd_o`, `status_hit_o`, `status_pa_o`, and
  `status_bits_o`.
- `soft-mmu-68k/rtl/core/mmu_top.v` currently reports CPU-side faults
  separately through `resp_fault_o`, `resp_fault_code_o`, and
  `resp_perm_fault_o`.
- Current status behavior is first-pass and compact. For `CMD_PROBE`, the
  implemented status path reports translated TLB-backed results,
  transparent-translation-qualified results, or misses. It does not yet perform
  a complete architectural PTEST walk and MMUSR synthesis.

## M1 decisions

The decisions below are repo-local conventions for the current single-level
subset. They are not claims of full Motorola architectural truth.

- PTEST/probe update policy:
  - Current behavior: PTEST/probe reports separate compact status only through
    `flush_ctrl`/`mmu_top`; it does not update `mmu_regs.mmusr`.
  - Proposed repo-local convention: a later PTEST implementation should both
    expose the separate probe status record and update the software-visible
    MMUSR register image for PTEST completions. Normal CPU translation
    responses should not be treated as MMUSR updates unless a later packet
    explicitly adds that behavior.
- Compact status staging:
  - `status_bits_o` should remain a staging representation for current tests,
    board smoke visibility, and the control shim boundary.
  - It should not be described as the final MMUSR encoding.
- MMUSR synthesis boundary:
  - A later implementation should add an explicitly named status-mapping
    boundary, proposed here as `mmusr_result_mapper`.
  - That boundary should consume translated/TT/miss/fault inputs and produce a
    16-bit MMUSR image plus an update qualifier for `mmu_regs`.
  - `mmu_regs` may need a hardware-producer update input in that later packet,
    but this M1 packet does not define port-level RTL changes.
- Level-number convention:
  - Proposed repo-local convention: level `4'h1` means the current single
    descriptor-table/page level.
  - Level `4'h0` means no descriptor level was reached or identified, such as
    TT-qualified bypass, compact probe miss, flush completion, or preload
    completion.
  - Out-of-range table span faults are still associated with level `4'h1`
    because the current configured single-level table span was evaluated.
- TT-qualified PTEST representation:
  - Current compact status distinguishes TT-qualified results with
    `status_bits_o[7]` set and `status_bits_o[6]` clear.
  - Proposed MMUSR-like status for TT-qualified results should have no fault
    bits set and level `4'h0`.
  - Because MMUSR has no repo-local TT bit today, the separate probe status
    record remains necessary to distinguish TT-qualified success from other
    no-fault results.
- Permission vector to MMUSR fields:
  - `resp_perm_fault_o[0]` / `perm_check.fault[0]` (`no_read`) maps to MMUSR A.
  - `resp_perm_fault_o[1]` / `perm_check.fault[1]` (`write_protect`) maps to
    MMUSR W.
  - `resp_perm_fault_o[2]` / `perm_check.fault[2]` (`no_execute`) maps to
    MMUSR A.
  - `resp_perm_fault_o[3]` / `perm_check.fault[3]`
    (`privilege_related`) maps to MMUSR S in addition to the underlying A or W
    class.
  - `resp_perm_fault_o[4]` / `perm_check.fault[4]` (`bad_req`) maps to MMUSR A
    as a repo-local malformed-request/access-class violation until a later
    fault-model packet says otherwise.
- Fault/result class mapping:
  - Invalid descriptor/page maps to MMUSR I at level `4'h1`.
  - Non-page descriptor or otherwise unmapped descriptor result maps to MMUSR I
    at level `4'h1` in this single-level subset. This does not claim that all
    non-page descriptors are architecturally invalid in a complete PMMU.
  - Table span/out-of-range unmapped result maps to MMUSR L at level `4'h1`.
  - Bus fault maps to MMUSR B at level `4'h1`.
  - Permission faults map through S/A/W as described above at level `4'h1`.
  - Translated hits map as no-fault translated results at level `4'h1`, with M
    proposed from the translated descriptor/TLB attribute when available.
  - TT-qualified results map as no-fault results at level `4'h0` and remain
    distinguishable only through the separate status record.
  - Compact probe miss maps as no-fault/no-result status at level `4'h0`; it is
    not the same as invalid, unmapped, bus, or permission fault evidence.

## Current compact status channels

| Source | Signal or field | Current meaning | M1 relevance | Future mapping target |
| --- | --- | --- | --- | --- |
| `soft-mmu-68k/rtl/core/flush_ctrl.v` | `status_valid_o` | One-cycle valid marker for a compact command status record. | Qualifies when `status_cmd_o`, hit, PA, and bits are meaningful. | PTEST/MMUSR mapper input valid. |
| `soft-mmu-68k/rtl/core/flush_ctrl.v` | `status_cmd_o` | Reports the command class that completed, such as probe, preload, flush all, or flush match. | Distinguishes PTEST-like probe status from PLOAD/PFLUSH completion status. | Mapper command qualifier; only PTEST should update MMUSR under this M1 convention. |
| `soft-mmu-68k/rtl/core/flush_ctrl.v` | `status_hit_o` | For probe, means a usable first-pass result exists. This includes translated TLB-backed results and TT-qualified results. | Prevents treating `status_hit_o` as only a TLB-hit bit. | Result class input for translated/TT/miss synthesis. |
| `soft-mmu-68k/rtl/core/flush_ctrl.v` | `status_pa_o` | Translated PA for translated probe result, VA-resized PA for TT-qualified result, zero for current zero-status completions. | Carries useful result address but is not an MMUSR bit field. | Separate PTEST/probe result address. |
| `soft-mmu-68k/rtl/core/flush_ctrl.v` | `status_bits_o` | Compact 8-bit status. Current convention uses bit 7 for TT match, bit 6 for translated result, and low attribute bits for translated attributes. | Staging representation only; not final MMUSR encoding. | `mmusr_result_mapper` class and attribute input. |
| `soft-mmu-68k/rtl/core/mmu_top.v` | `resp_fault_o` | CPU-side translation response fault flag. | Shows fault status currently exists outside MMUSR and outside compact probe status. | Future fault-result input if PTEST walks or if a later packet maps CPU faults. |
| `soft-mmu-68k/rtl/core/mmu_top.v` | `resp_fault_code_o` | CPU-side fault class: none, permission, invalid, unmapped, or bus. | Provides current invalid/unmapped/bus/permission vocabulary. | MMUSR B/L/I/S/A/W class selection. |
| `soft-mmu-68k/rtl/core/mmu_top.v` | `resp_perm_fault_o` | Five-bit permission diagnostic vector from `perm_check`: no read, write protect, no execute, privilege related, bad request. | Defines the current source for S/A/W-style synthesis. | MMUSR S/A/W field mapper. |
| `soft-mmu-68k/rtl/core/mmu_regs.v` | `mmusr` | Software-visible 16-bit MMUSR image with masked writable status and level bits. | Final register image exists, but no hardware producer updates it today. | Hardware-updated MMUSR image for PTEST completions. |

## MMUSR field vocabulary

| Field | Bit(s) | Repo-local vocabulary | Current meaning | Proposed future synthesis | Deferred issues |
| --- | --- | --- | --- | --- | --- |
| B | 15 | Bus error. | Software-visible bit only. CPU-side bus faults are reported through `resp_fault_code_o`. | Set for walker bus faults at level `4'h1`. | Complete bus-cycle/PMMU termination behavior. |
| L | 14 | Limit or span violation. | Software-visible bit only. Current walker reports out-of-range table span as unmapped. | Set for `start_vpn >= table_entries_i` at level `4'h1`. | Full TC/root/pointer limit interpretation. |
| S | 13 | Supervisor/privilege-related violation. | Software-visible bit only. Do not confuse with descriptor S attribute. | Set when permission vector `privilege_related` is set. | Full supervisor/access-level PMMU semantics. |
| A | 12 | Access violation. | Software-visible bit only. | Set for read denial, execute denial, and malformed permission request. Combine with S when privilege-related. | Complete access-level model. |
| W | 11 | Write-protect violation. | Software-visible bit only. | Set for write-protect denial. Combine with S when privilege-related. | Whether future write faults also set A is deferred. |
| I | 10 | Invalid descriptor/page or no usable page descriptor in this subset. | Software-visible bit only. | Set for `DT == 2'b00`; also set for valid non-page descriptor results that the current single-level walker reports as unmapped. | Multi-level traversal may give non-page descriptors a different meaning. |
| M | 9 | Modified. | Software-visible bit only. Current page descriptor/TLB attributes include M as an attribute. | For translated results, mirror the translated M attribute when available. | Side-effect setting/clearing of M is not modeled. |
| G | 7 | Globally shared. | Software-visible bit only. No current descriptor/TLB source is wired for G. | Remains zero unless a later descriptor/status packet adds a source. | Full shared/global PMMU behavior. |
| level number | 3:0 | Repo-local level identifier. | Software-writeable low nibble only. | `4'h1` for current single descriptor level; `4'h0` when no descriptor level is reached or identified. | Multi-level numbering for future TC/CRP/SRP traversal. |

## Result-class matrix

| Result class | Current source signal(s) | Proposed MMUSR bits | Proposed level value | Updates MMUSR register image? | Separate PTEST/probe status? | Notes / deferred issues |
| --- | --- | --- | --- | --- | --- | --- |
| translated TLB hit | `status_hit_o=1`, `status_bits_o[6]=1`, `status_bits_o[7]=0`, low attribute bits from `tlb_lookup_attr`; CPU path also uses `resp_hit_o=1` | No fault bits. M mirrors translated M attribute when available. G remains 0. | `4'h1` | Current: no. Later PTEST: yes. | Yes. Current compact status reports PA and class. | `resp_hit_o` is reserved for translated/TLB-backed CPU hits; TT success does not set it. |
| transparent-translation-qualified result | `tt_match_any`, `status_hit_o=1`, `status_bits_o[7]=1`, `status_bits_o[6]=0`, `status_pa_o` mirrors VA resized to PA width | No fault bits; M/G 0. | `4'h0` | Current: no. Later PTEST: yes. | Yes. Required to distinguish TT from ordinary no-fault status. | Full TT legality is deferred. CPU/special space is excluded from current TT matching. |
| probe miss | `status_hit_o=0`, translated and TT class bits clear in current checked cases | No fault bits. | `4'h0` | Current: no. Later PTEST: yes, if the later PTEST policy records miss in MMUSR. | Yes. | Current compact probe miss is absence of a usable cached/TT result, not evidence of invalid/unmapped/bus/permission fault. |
| invalid descriptor | CPU path: `resp_fault_o=1`, `resp_fault_code_o=RESP_FAULT_INVALID`; walker: `FAULT_INVALID` for `DT==2'b00` | I | `4'h1` | Current: no. Later PTEST: yes when PTEST walk/fault synthesis exists. | Not today beyond CPU response; future PTEST should report it. | Current compact probe does not walk a miss to discover this. |
| non-page descriptor / unmapped | CPU path: `resp_fault_o=1`, `resp_fault_code_o=RESP_FAULT_UNMAPPED`; walker: nonzero `DT` other than page | I | `4'h1` | Current: no. Later PTEST: yes when PTEST walk/fault synthesis exists. | Not today beyond CPU response; future PTEST should report it. | Repo-local single-level convention only; future multi-level traversal may reinterpret non-page descriptors. |
| table span / out-of-range unmapped | Walker checks `start_vpn >= table_entries_i` and reports `FAULT_UNMAPPED`; CPU path maps to `RESP_FAULT_UNMAPPED` | L | `4'h1` | Current: no. Later PTEST: yes when PTEST walk/fault synthesis exists. | Not today beyond CPU response; future PTEST should report it. | This is the current subset's limit/span-like case. |
| bus fault | Walker `mem_resp_err_i` reports `FAULT_BUS`; CPU path maps to `RESP_FAULT_BUS` | B | `4'h1` | Current: no. Later PTEST: yes when PTEST walk/fault synthesis exists. | Not today beyond CPU response; future PTEST should report it. | Bus error dominates descriptor interpretation in the walker. |
| read permission fault | CPU path `RESP_FAULT_PERM`; `resp_perm_fault_o[0]` set, optionally `[3]` set | A, plus S if privilege-related | `4'h1` | Current: no. Later PTEST: yes when permission-aware PTEST exists. | Not today beyond CPU response; future PTEST should report it. | Requires translated lookup/walk to succeed before permission checking. |
| write permission fault | CPU path `RESP_FAULT_PERM`; `resp_perm_fault_o[1]` set, optionally `[3]` set | W, plus S if privilege-related | `4'h1` | Current: no. Later PTEST: yes when permission-aware PTEST exists. | Not today beyond CPU response; future PTEST should report it. | Whether W should also imply A remains deferred. |
| execute permission fault | CPU path `RESP_FAULT_PERM`; `resp_perm_fault_o[2]` set, optionally `[3]` set | A, plus S if privilege-related | `4'h1` | Current: no. Later PTEST: yes when permission-aware PTEST exists. | Not today beyond CPU response; future PTEST should report it. | Execute/fetch permissions come from `perm_check` request classification. |
| privilege-related permission fault | CPU path `RESP_FAULT_PERM`; `resp_perm_fault_o[3]` set with read/write/execute cause | S plus A or W according to the denied access class | `4'h1` | Current: no. Later PTEST: yes when permission-aware PTEST exists. | Not today beyond CPU response; future PTEST should report it. | `S` is a fault class here, not the page descriptor S attribute. |
| preload status | `status_cmd_o=CMD_PRELOAD`, `status_hit_o=0`, `status_pa_o=0`, `status_bits_o=0` | No MMUSR bits. | `4'h0` | No under M1. | Yes, as compact command completion status. | Full PLOAD completion/walk status remains deferred. |
| flush status | `status_cmd_o=CMD_FLUSH_ALL` or `CMD_FLUSH_MATCH`, `status_hit_o=0`, `status_pa_o=0`, `status_bits_o=0` | No MMUSR bits. | `4'h0` | No under M1. | Yes, as compact command completion status. | Full PFLUSH architectural expansion remains deferred. |

## Fault priority

This is a conservative proposed priority order for the current subset. It
reflects current implementation order where known and does not claim complete
Motorola fault-priority coverage.

1. TT-qualified result for valid normal-memory TT matches:
   `soft-mmu-68k/rtl/core/mmu_top.v` qualifies TT before TLB/walker use for the
   active lookup. A TT-qualified CPU result bypasses descriptor walk and page
   permission checking. Current TT qualification excludes CPU/special space.
2. Translated TLB-backed result:
   on a TLB hit, `mmu_top.v` returns the translated PA. For CPU requests, the
   translated hit is then checked by `perm_check`.
3. Future PTEST miss handling:
   current compact probe stops at translated/TT/miss. A future PTEST walk must
   explicitly decide when a miss becomes a walk, a descriptor fault, or a
   permission result.
4. Walker table span check:
   `soft-mmu-68k/rtl/core/pt_walker.v` reports out-of-range table span before
   issuing a descriptor memory request.
5. Walker bus error:
   once a descriptor response returns, `mem_resp_err_i` reports bus fault before
   descriptor DT interpretation.
6. Descriptor interpretation:
   `DT == 2'b00` reports invalid. Nonzero `DT` other than the current page type
   reports unmapped in the single-level subset.
7. Permission after successful translated lookup/walk:
   permission faults occur after a translated TLB hit or successful walk/refill
   result. Read and execute denials map to A, write denial maps to W, and
   privilege-related denial additionally maps to S.
8. Malformed permission requests:
   `soft-mmu-68k/rtl/core/perm_check.v` reports malformed zero-hot or multi-hot
   permission requests as `bad_req`. Its TT-bypass input does not legalize a
   malformed request. Mapping that class to MMUSR A is a repo-local convention
   for later synthesis.

## PTEST / probe policy

Today, PTEST/probe is represented by the first-pass control shim:

- `soft-mmu-68k/rtl/core/flush_ctrl.v` accepts `CMD_PROBE`, waits for a probe
  response, and emits compact status.
- `soft-mmu-68k/rtl/core/mmu_top.v` supplies that response from the current
  lookup path. It distinguishes translated TLB-backed result, TT-qualified
  result, and miss.
- Current probe does not update `soft-mmu-68k/rtl/core/mmu_regs.v` MMUSR.
- Current probe does not walk a miss to discover invalid, unmapped, bus, or
  permission fault classes.

Later MMUSR-like PTEST synthesis should:

- preserve the separate compact status record so tests and smoke paths can keep
  distinguishing translated, TT-qualified, and miss results;
- synthesize a 16-bit MMUSR image through the proposed `mmusr_result_mapper`
  boundary;
- update the MMUSR register image on PTEST completion only when the later packet
  adds a hardware producer path into `mmu_regs`;
- distinguish TT-qualified results from translated TLB-backed hits using the
  separate status metadata, because MMUSR currently has no TT class bit;
- keep probe miss distinct from invalid, unmapped, bus, and permission results:
  a miss means the current compact probe found no usable cached/TT result, while
  invalid/unmapped/bus/permission require a walk or permission result that the
  current probe path does not yet produce.

## M1b / M2 test targets

Do not add these tests in this packet. Future packets should add focused tests
for:

- unit test for compact-status-to-MMUSR mapping
- unit test for permission-vector-to-MMUSR mapping
- integration test for translated hit PTEST result
- integration test for TT-qualified PTEST result
- integration test for miss result
- integration test for invalid descriptor result
- integration test for unmapped/non-page result
- integration test for bus fault result
- integration test for permission fault result
- regression check that normal CPU translation behavior is unchanged

## Non-goals

- no RTL implementation
- no executable test changes
- no full Motorola PMMU compatibility claim
- no TC/CRP/SRP traversal work
- no TTR legality expansion
- no PLOAD/PFLUSH architectural expansion
- no hardware smoke expansion

## Acceptance criteria for a later implementation packet

A later implementation packet must prove all of the following before acceptance:

- mapping unit tests pass
- integration PTEST/MMUSR cases pass
- existing unit regression passes
- existing integration regression passes
- Verilator lint passes
- GitHub Actions HDL Regression passes
- docs remain conservative
