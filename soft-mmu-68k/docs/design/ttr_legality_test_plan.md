# TT/TTR Legality Test Plan

## Purpose

This is a repo-local TT/TTR legality test/spec document for
`soft-mmu-68k`.

It does not implement RTL or executable tests. It does not claim full Motorola
PMMU compatibility. It defines future test expectations for transparent
translation behavior so later test and implementation packets can work from a
reviewed legality surface instead of inferring it from scattered first-pass
behavior.

## Current implemented subset

The current implementation uses `TT0` and `TT1` as 32-bit register images from
`mmu_regs`.

The current first-pass subset uses:

- `TTx[31:24]` logical-address high-byte base
- `TTx[23:16]` logical-address high-byte mask
- `TTx[15]` enable
- `TTx[14]` supervisor match
- `TTx[13]` user match
- `TTx[12]` program-space match
- `TTx[11]` data-space match

For the current mask byte, a bit value of `1` means "don't care" for that
high-byte bit.

`mmu_top` performs TT qualification ahead of TLB lookup and page-walk use.
CPU/special space is excluded from TT qualification, and reserved FC encodings
do not TT-match. A TT match returns an identity-style PA by resizing the logical
address onto the physical-address bus.

A CPU-side TT match produces a valid response but does not assert `resp_hit_o`;
that signal remains reserved for translated/TLB-backed hits. A TT probe sets the
TT-qualified status class, not the translated status class. A TT match drives
the bypass path into `perm_check`; inside `perm_check`, `tt_bypass` wins with
`allow=1` and `fault=0`.

These are current repo behaviors only. They are not a complete Motorola TT/TTR
behavior model.

## Source and reference boundary

This document uses only source families already represented in the project
source-materials manifest. It adds no new sources and does not invent page
numbers.

The main relevant source families are:

- MC68851 PMMU User's Manual
- MC68030 User's Manual
- MC68040 User's Manual
- M68060 User's Manual
- M68000 Family Programmer's Reference Manual

This document is a repo-local test plan derived from current project docs, RTL,
integration benches, and the source manifest. It is not a completed
architectural proof.

## Terminology

| Term | Project-local meaning |
| --- | --- |
| Transparent Translation | The current first-pass path where a qualifying `TT0` or `TT1` register image bypasses page-table translation and returns an identity-style PA. |
| TT Register | A transparent-translation register image exposed by `mmu_regs`, currently `TT0` or `TT1`. |
| TTR | Shorthand for a TT register image and its matching rules in this project. |
| TT-qualified result | A result whose address, FC, privilege, space class, enable bit, and mask compare satisfy the current TT subset. |
| translated result | A TLB-backed or walker-derived page-translation result, not a TT-qualified bypass. |
| identity-style PA | The logical address resized onto the PA bus by `mmu_top` through its current `va_to_pa` helper. |
| normal memory FC | One of the current user/supervisor program/data FC encodings: `001`, `010`, `101`, or `110`. |
| CPU/special space | The current `FC=3'b111` class. It is not normal program or data space in this subset. |
| reserved FC encoding | `FC=3'b000` or `FC=3'b100` in the current first pass. These encodings do not assert normal memory-space classification. |
| permission bypass | The `tt_bypass` input to `perm_check`; when asserted, `perm_check` returns `allow=1` and `fault=0`. |
| legality rule | A repo-local expectation that says whether a future TT/TTR test case is allowed to TT-match, must not TT-match, or remains deferred. |
| first-pass subset | The implemented narrow TT behavior documented here and in `address_map.md`, not full Motorola behavior. |
| future full legality target | A later, explicitly scoped target that may decode additional Motorola TT/TTR fields and legality rules after this matrix is reviewed. |

## Function-code legality matrix

| FC | Current repo name / class | Normal memory? | Program? | Data? | User? | Supervisor? | CPU/special? | May TT-match today? | Expected future TTR legality note |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `000` | reserved | no | no | no | decode says user half, but not normal memory | no | no | no | Keep no-match unless a later FC legality packet gives this encoding an explicit architectural role. |
| `001` | user data | yes | no | yes | yes | no | no | yes, if TTR user and data bits plus address compare match | Normal user data TT-match case. |
| `010` | user program | yes | yes | no | yes | no | no | yes, if TTR user and program bits plus address compare match | Normal user program TT-match case. |
| `011` | currently unnamed / non-normal in `mmu_decode` | no | no | no | decode says user half, but not normal memory | no | no | no | Future packets should decide whether this encoding remains outside the model; do not infer Motorola CPU-space behavior from it. |
| `100` | reserved | no | no | no | no | decode says supervisor half, but not normal memory | no | no | Keep no-match unless a later FC legality packet gives this encoding an explicit architectural role. |
| `101` | supervisor data | yes | no | yes | no | yes | no | yes, if TTR supervisor and data bits plus address compare match | Normal supervisor data TT-match case. |
| `110` | supervisor program | yes | yes | no | no | yes | no | yes, if TTR supervisor and program bits plus address compare match | Normal supervisor program TT-match case. |
| `111` | CPU/special space | no | no | no | no | yes by privilege half only | yes | no | Must not TT-match in the current subset; do not overclaim complete Motorola CPU-space behavior. |

## Current TT field matrix

| Field | Current repo meaning | Current test expectation | Future legality question | Notes |
| --- | --- | --- | --- | --- |
| `TTx[31:24]` | Logical-address high-byte base. | Exact compared against the selected high byte after mask removal. | Whether future Motorola TTR address fields require a wider or differently positioned compare. | Current `VA_WIDTH` may be narrower in benches, but the subset selects the top available key bits. |
| `TTx[23:16]` | Logical-address high-byte mask, where `1` means don't care. | `8'h00` requires exact high-byte match; `8'hFF` ignores all high-byte bits. | Whether future field semantics differ by CPU family or TTR format. | Base bits under mask must not affect match. |
| `TTx[15]` | Entry enable. | Disabled entries never TT-match. | Whether future illegal enabled combinations need explicit rejection. | Applies independently to TT0 and TT1. |
| `TTx[14]` | Match supervisor normal-memory accesses. | Supervisor FCs may match only when this bit is set. | Whether future supervisor/access-level semantics need more detail. | CPU/special space still cannot TT-match. |
| `TTx[13]` | Match user normal-memory accesses. | User FCs may match only when this bit is set. | Whether future user/access-level semantics need more detail. | Reserved user-half encodings still cannot TT-match. |
| `TTx[12]` | Match program space. | Program FCs may match only when this bit is set. | Whether future instruction/data legality needs family-specific rules. | Works with the privilege bits and address compare. |
| `TTx[11]` | Match data space. | Data FCs may match only when this bit is set. | Whether future data-space legality needs family-specific rules. | Works with the privilege bits and address compare. |
| other bits | Ignored/reserved by the current subset. | Tests must not infer behavior from them today. | Which Motorola TT/TTR fields should be decoded later, and which encodings are legal. | Reserved here unless a future packet defines them. |

## Match-decision rules

The current match-decision rule is:

1. Lookup source must be valid.
2. FC must decode as normal user/supervisor program/data.
3. CPU/special space must be false.
4. TT entry must be enabled.
5. User/supervisor class must match the selected TT privilege bits.
6. Program/data class must match the selected TT space bits.
7. Masked high-byte compare must match.
8. TT0 or TT1 match creates `tt_match_any`.

The current compare rule is:

```text
(va_key & ~mask_key) == (base_key & ~mask_key)
```

This is the current repo subset and may not cover all Motorola TTR legality.

## TT0 / TT1 interaction

| Case | Current expected behavior |
| --- | --- |
| neither TT0 nor TT1 enabled | No TT match; access falls back to translated/probe path. |
| TT0 enabled and matching | `tt0_match=1`; `tt_match_any=1`; identity-style TT result. |
| TT1 enabled and matching | `tt1_match=1`; `tt_match_any=1`; identity-style TT result. |
| both enabled, only TT0 matching | `tt_match_any=1`; no TT1-specific result is exposed. |
| both enabled, only TT1 matching | `tt_match_any=1`; no TT0-specific result is exposed. |
| both enabled, both matching | `tt_match_any=1`; current behavior exposes no priority-visible distinction. |
| neither matching | No TT match; access falls back to translated/probe path. |

The current expression is:

```text
tt_match_any = tt0_match | tt1_match
```

No priority-visible result is currently exposed when both entries match.
Both-match should be tested as legal current behavior unless future Motorola
legality rules require otherwise. No test should infer TT0-vs-TT1 priority
unless a later implementation exposes such a distinction.

## CPU response expectations

| Case | Expected `resp_valid_o` | Expected `resp_fault_o` | Expected `resp_hit_o` | Expected `resp_pa_o` behavior | Expected walk request behavior | Expected permission behavior | Notes |
| --- | --- | --- | --- | --- | --- | --- | --- |
| TT disabled, normal translated path | Per translated path completion. | Per translated path and permission result. | `1` only for translated TLB-backed hit; `0` for walk completion. | Translated PA from TLB or walker. | Normal TLB miss may start a walk. | Permissions checked from translated attributes. | Baseline non-TT behavior must remain unchanged. |
| TT enabled and matched | `1` for CPU request. | `0`. | `0`. | Identity-style resized VA. | No page walk should start for the TT-hit access. | Permission denial is bypassed through `perm_check`. | Current TT-match behavior. |
| TT enabled but base mismatch | Per translated path completion. | Per translated path and permission result. | Per translated path. | Translated PA, not identity-style TT PA. | Normal TLB miss may start a walk. | Permissions checked normally. | Confirms address compare matters. |
| TT enabled but privilege mismatch | Per translated path completion. | Per translated path and permission result. | Per translated path. | Translated PA, not identity-style TT PA. | Normal TLB miss may start a walk. | Permissions checked normally. | Confirms `TTx[14:13]` matters. |
| TT enabled but program/data mismatch | Per translated path completion. | Per translated path and permission result. | Per translated path. | Translated PA, not identity-style TT PA. | Normal TLB miss may start a walk. | Permissions checked normally. | Confirms `TTx[12:11]` matters. |
| TT enabled but reserved FC | Per non-TT path completion if the bench supplies a usable translated result. | Per non-TT path. | Per non-TT path. | Must not be identity-style solely because TT fields match. | May follow the normal translated path in the current subset. | No TT bypass. | Reserved FC encodings must not become TT-qualified. |
| TT enabled but CPU/special FC | Per non-TT path completion if the bench supplies a usable translated result. | Per non-TT path. | Per non-TT path. | Must not be identity-style solely because TT fields match. | May follow the normal translated path in the current subset. | No TT bypass from `mmu_top`. | Do not claim complete Motorola CPU-space behavior. |
| TT0 match | `1`. | `0`. | `0`. | Identity-style resized VA. | No page walk should start. | `tt_bypass` wins. | No TT0-specific priority signal exists. |
| TT1 match | `1`. | `0`. | `0`. | Identity-style resized VA. | No page walk should start. | `tt_bypass` wins. | No TT1-specific priority signal exists. |
| both TT0 and TT1 match | `1`. | `0`. | `0`. | Identity-style resized VA. | No page walk should start. | `tt_bypass` wins. | Legal current behavior; no visible priority. |

## Probe / PTEST-adjacent expectations

These expectations describe current probe behavior without claiming full PTEST
semantics.

| Case | Expected `status_valid_o` | Expected `status_cmd_o` | Expected `status_hit_o` | Expected `status_pa_o` | Expected `status_bits_o` TT class | Expected `status_bits_o` translated class | Notes |
| --- | --- | --- | --- | --- | --- | --- | --- |
| translated result | `1` on probe completion. | Probe command. | `1`. | Translated PA. | `0`. | `1`. | Translated probe should set translated class and clear TT class. |
| TT-qualified result | `1` on probe completion. | Probe command. | `1`. | Identity-style resized VA. | `1`. | `0`. | TT-qualified probe should set TT class and clear translated class. |
| miss / no usable result | `1` on probe completion. | Probe command. | `0`. | Current zero/no-result behavior. | `0` in checked cases. | `0` in checked cases. | Current compact probe miss is not a full PTEST walk result. |
| reserved FC probe | `1` on probe completion. | Probe command. | Per non-TT lookup result. | Per non-TT lookup result. | `0`. | Set only if a translated result exists. | Reserved FC probe must not become TT-qualified in the current subset. |
| CPU/special-space probe | `1` on probe completion. | Probe command. | Per non-TT lookup result. | Per non-TT lookup result. | `0`. | Set only if a translated result exists. | CPU/special-space probe must not become TT-qualified. |
| TT disabled probe | `1` on probe completion. | Probe command. | Per translated lookup result. | Per translated lookup result. | `0`. | Set only if a translated result exists. | Disabled TTRs do not produce TT class. |
| TT base mismatch probe | `1` on probe completion. | Probe command. | Per translated lookup result. | Per translated lookup result. | `0`. | Set only if a translated result exists. | Address mismatch does not TT-qualify. |
| TT privilege mismatch probe | `1` on probe completion. | Probe command. | Per translated lookup result. | Per translated lookup result. | `0`. | Set only if a translated result exists. | Privilege mismatch does not TT-qualify. |
| TT program/data mismatch probe | `1` on probe completion. | Probe command. | Per translated lookup result. | Per translated lookup result. | `0`. | Set only if a translated result exists. | Program/data mismatch does not TT-qualify. |

CPU/special and reserved FC probes should not become TT-qualified in the current
subset. Complete Motorola PTEST termination semantics remain tied to
M1/CTRL1/future mapper work.

## Permission interaction

The current project distinguishes TT qualification from permission bypass:

- `mmu_top` decides whether an access is TT-qualified.
- `mmu_top` excludes CPU/special space from TT qualification.
- `perm_check` receives `tt_bypass`.
- Inside `perm_check`, `tt_bypass` wins with `allow=1` and `fault=0`.
- This is current project behavior after MGV0.
- This does not mean CPU/special space can TT-match, because `mmu_top` never
  asserts TT bypass for CPU/special space in the current subset.

Future permission interaction tests should include:

- TT match over supervisor-only translated page with user access
- TT non-match over supervisor-only translated page with user access
- TT match with malformed request encoding, if a future bench directly
  exercises `perm_check`
- CPU/special-space request with TT register that would otherwise match the high
  byte

## Mask behavior test matrix

| Case | Future test expectation |
| --- | --- |
| mask `8'h00`, exact high-byte match required | Matching base byte TT-qualifies when all other fields match. |
| mask `8'h00`, one-bit mismatch fails | Any unmasked high-byte mismatch prevents TT qualification. |
| mask `8'hFF`, all high-byte bits don't-care | Address high byte does not block TT qualification when all other fields match. |
| partial mask with one don't-care bit | Mismatch only under the don't-care bit must still TT-qualify. |
| partial mask with multiple don't-care bits | Mismatches only under don't-care bits must still TT-qualify. |
| base bits under mask should not affect match | Changing masked base bits must not change the match decision. |
| VA bits outside the high-byte key are not part of current TT comparison | Different lower VA bits with the same compared high-byte bits should not affect TT qualification. |

Do not modify RTL in this packet.

## Future MATLAB vector opportunity

TTR1 is a good candidate for future MATLAB-backed vectors, but this packet does
not create them.

Proposed future collateral may include:

```text
scripts/matlab/models/mmu_ttr_match_reference.m
scripts/matlab/generators/generate_ttr_match_vectors.m
scripts/matlab/examples/run_ttr_match_demo.m
tb/common/golden_vectors/ttr_match_golden_vectors.csv
```

MATLAB vectors should only be added in a later packet after this legality matrix
is reviewed.

## TTR1 future executable test targets

Future test packets should consider:

- unit-level or integration-level TT disabled case
- TT0 exact match
- TT1 exact match
- TT0 and TT1 both matching
- base mismatch
- mask don't-care match
- privilege mismatch
- program/data mismatch
- reserved FC no-match
- CPU/special FC no-match
- TT match bypasses walker
- TT match bypasses page-derived permission fault
- TT non-match falls back to walker/TLB path
- TT probe reports TT-qualified class
- translated probe reports translated class
- flushed translated TLB entry does not erase TT qualification
- TT behavior remains independent of descriptor format migration

## Non-goals

- no RTL edits
- no executable testbench edits
- no MATLAB source edits
- no generated CSV files
- no script or workflow edits
- no full Motorola PMMU compatibility claim
- no TC/CRP/SRP traversal implementation
- no PLOAD/PFLUSH behavior expansion
- no MMUSR hardware update implementation
- no hardware smoke changes
- no wiki publishing

## Acceptance criteria for a later implementation/test packet

A later executable TTR test packet must prove:

- all added TT/TTR cases pass in Icarus unit/integration regression
- current translated path behavior remains unchanged
- current permission behavior remains aligned with MGV0
- current probe status classes remain distinguishable
- Verilator lint passes
- GitHub Actions HDL Regression passes
- documentation remains conservative

## Verification for this packet

This packet is documentation/specification only. HDL scripts may be skipped with
this reason:

```text
SKIPPED: documentation-only test/spec packet
```

Before committing, verify:

```bash
git status --short
git diff --check
git diff --stat
git diff -- docs/design/ttr_legality_test_plan.md
```

If any non-documentation file changes, stop and report.
