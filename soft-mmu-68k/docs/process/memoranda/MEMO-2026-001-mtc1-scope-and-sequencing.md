# MEMO-2026-001 — MTC1 Scope and Sequencing

- **Subject:** Establish the authoritative MTC1 scope and its sequencing relationship to later work
- **Date:** 2026-08-09
- **Status:** Approved
- **Decision owner:** Project Lead
- **Participants / consulted roles:** MMU MATLAB Toolchain Coach; MMU Dev Manager; Project Lead

## Context

The original conversational MTC1 brief could no longer be relied upon as durable project state. The MATLAB Toolchain Coach therefore re-established a proposed MTC1 definition from current repository evidence and the TC1A/TC1B boundary. That source proposal is preserved as [BRIEF-2026-001](briefings/BRIEF-2026-001-mtc1-matlab-toolchain-coach.md).

The MMU Dev Manager reviewed that proposal, approved it with targeted amendments, and established the amended MTC1 scope. The Project Lead accepted the amended definition. PROC1B preserves the source proposal separately from the later decision so that the original recommendation is not rewritten after the fact.

## Decision

The approved MTC1 boundary is:

- `MTC1` models the current TC1B-tested single-level TC/CRP span boundary.
- `MTC1` does **not** implement or model full Motorola TC address geometry as current behavior.
- Full TIA/TIB/TIC/TID and PS-driven geometry is deferred to a separate future `MTC2` concept.
- No committed CSV belongs to MTC1.
- `MTC1B` remains a separate optional future promotion of MTC1 scenarios into committed HDL-consumed vectors.
- The approved branch is `matlab/mtc1-tc-crp-span-reference`.
- The approved model uses conservative width/configuration boundaries: `1 <= VPN_WIDTH <= 32`, `PA_WIDTH <= 32`, `VA_WIDTH > PAGE_SHIFT`, `PA_WIDTH > PAGE_SHIFT`, and `DESCR_BYTES` must be byte-aligned and a power of two.
- The result includes `descriptor_addr_valid`, with `descriptor_addr_valid = descriptor_request`.
- MTC1 test configurations must reject descriptor-address calculations that cannot be represented in the selected PA width; no wraparound or overflow semantics are invented.
- The directed generator contains nine mandatory cases, including zero table span and TC-upper-bits-inert cases in addition to the seven cases proposed by the Toolchain Coach.
- `MTC1` may precede `HW1B` by Project Lead sequencing choice.
- `MTC1` is not an architectural dependency of the existing HW1B Basys 3 smoke target.

The detailed implementation authorization is preserved in [the MTC1 packet definition](../packets/MTC1-matlab-tc-crp-span-reference.md).

## Packet effects

- `MTC1` authoritative definition established.
- `MTC1B` remains optional/future.
- `MTC2` remains future/separate.
- `HW1B` sequencing remains after MTC1 unless the Project Lead changes it or MTC1 exposes a material ambiguity relevant to the existing hardware smoke target.

## Rationale

The decision keeps MTC1 aligned with behavior already locked by TC1B while preventing a small MATLAB reference-model packet from silently becoming a new Motorola-compatibility or full address-geometry project. The amendments make width handling, descriptor-address validity, overflow handling, and directed coverage explicit without expanding the architectural target.

## Dependencies / risks

- MTC1 depends on the current TC1B-tested behavior boundary as its modeling target.
- A future decision to model Motorola-style TC geometry requires explicit source-backed compatibility scoping and belongs in MTC2, not MTC1.
- MTC1 must not be treated as proof of final translation success; it models the pre-walk span/address boundary only.

## Follow-up required

- Execute MTC1 under its separately approved packet.
- Consider MTC1B only if committed HDL-consumed vectors are later desired.
- Define MTC2 separately if Motorola-style TC geometry becomes an approved target.
- Proceed to HW1B after MTC1 unless sequencing is changed or MTC1 reveals a material ambiguity.

## Supersedes / superseded by

- **Supersedes:** the unrecoverable conversational MTC1 brief as an authority source; it does not rewrite the preserved Toolchain Coach source briefing.
- **Superseded by:** none.

## Related briefing records

- [BRIEF-2026-001 — MTC1 MATLAB Toolchain Coach](briefings/BRIEF-2026-001-mtc1-matlab-toolchain-coach.md)

## Related PRs / packet definitions / design docs

- [MTC1 authoritative packet definition](../packets/MTC1-matlab-tc-crp-span-reference.md)
- PR #29 — `TC1A: add TC/CRP/SRP traversal plan`
- PR #30 — `TC1B: add TC/CRP span tests`
- [`tc_crp_srp_traversal_plan.md`](../../design/tc_crp_srp_traversal_plan.md)
