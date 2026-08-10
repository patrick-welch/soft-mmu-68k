# MEMO-2026-002 — Process Record Framework Adoption

- **Subject:** Adopt durable packet, registry, memorandum, and substantive-briefing records
- **Date:** 2026-08-09
- **Status:** Approved
- **Decision owner:** Project Lead
- **Participants / consulted roles:** MMU Documentation Manager; MMU Dev Manager; Project Lead

## Context

Returning to the project after a break exposed a gap in durable reconstruction of packet definitions, sequencing, and the rationale behind manager/coach decisions. The Documentation Manager proposed a canonical packet registry and management-memorandum structure; that proposal is preserved as [BRIEF-2026-002](briefings/BRIEF-2026-002-process-record-proposal.md).

The Project Lead additionally required preservation of substantive briefings that materially support later project decisions. The broad process-record effort was then split into a small framework packet and a bounded evidence-backed bootstrap packet so that neither implementation became historical archaeology.

PROC1A created the framework and merged through PR #38. PROC1B performs the bounded verified bootstrap using actual source artifacts and GitHub/repository evidence.

## Decision

Adopt these durable record types and boundaries:

- **Briefing records** preserve substantive decision inputs.
- **Management memoranda** preserve why project/process decisions were made.
- **Packet definitions** preserve what work is authorized.
- **PR, reviewed commit, test, and CI evidence** preserve what was actually implemented and reviewed.
- **Technical architecture and compatibility decisions** remain under `soft-mmu-68k/docs/design/`.
- Unverifiable history must not be reconstructed from memory.

Current merged repository state remains the final authority for what actually exists.

## Packet effects

The initially contemplated broad process packet was deliberately reduced before implementation into:

- `PROC1A — Durable Packet, Memorandum, and Briefing Framework`
- `PROC1B — Verified Packet and Briefing Record Bootstrap`

Both packets are assigned to the MMU Documentation Manager for implementation, with independent MMU Dev Manager review and commit-specific dispensation.

PROC1A was authorized to proceed in parallel with MTC1. PROC1B depends on PROC1A being merged, but otherwise may run in parallel with MTC1 because their file scopes are disjoint.

## Rationale

The split establishes durable process machinery first, then performs only a deliberately bounded evidence-backed bootstrap. This avoids relying on chat recollection, keeps process records reviewable, and prevents a documentation packet from expanding into complete project-history reconstruction.

## Dependencies / risks

- PROC1B must use actual source artifacts and verified repository/PR evidence.
- Missing or contradictory provenance blocks the affected record rather than being filled from memory.
- Process records must not replace technical design documentation or implementation evidence.

## Follow-up required

- Complete PROC1B's bounded bootstrap set.
- Add later packet history only through separately authorized evidence-backed work if useful.
- Preserve future substantive briefings and process decisions through the framework as they are created.

## Supersedes / superseded by

- **Supersedes:** no merged project record. It records the adopted framework decision and the pre-implementation split of the broader proposal.
- **Superseded by:** none.

## Related briefing records

- [BRIEF-2026-002 — Process Record Proposal](briefings/BRIEF-2026-002-process-record-proposal.md)

## Related PRs / packet definitions / design docs

- [PROC1A packet definition](../packets/PROC1A-durable-process-record-framework.md)
- [PROC1B packet definition](../packets/PROC1B-verified-packet-and-briefing-record-bootstrap.md)
- PR #38 — `PROC1A: add durable process record framework`
- [`../README.md`](../README.md) — adopted process-record boundaries
