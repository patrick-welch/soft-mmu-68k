# MEMO-2026-003 — Packet Control Simplification

- **Subject:** Adopt GitHub Issues as the live packet control plane and establish the MMU Packet Coordinator role
- **Date:** 2026-08-11
- **Status:** Approved
- **Decision owner:** Project Lead
- **Participants / consulted roles:** MMU Toolchain Coach; MMU R&D Manager; MMU Dev Manager; MMU Documentation Manager

## Context

PROC1A and PROC1B created useful durable distinctions among packet scope, status/indexing, management rationale, source briefings, PR/commit/CI evidence, and technical design records. The continuity problem they addressed was real.

The operational weakness emerged in the hand-maintained live `packet-registry.md`. Mutable GitHub facts were copied into Markdown and then had to be synchronized manually.

Two concrete contradictions were present on `main` before PROC2A:

- MTC1 was marked `Merged`, while its Branch / PR field still said the branch/PR was not present and its note still said implementation remained `Ready`.
- PROC1B was marked `Merged`, while its note still said the row remained `Review` before merge.

These examples were judged to be a data-model problem rather than an isolated documentation-discipline failure.

The MMU Toolchain Coach recommended collapsing packet control onto GitHub Issues, with PR/commit/CI evidence retaining implementation/review state and with memoranda/briefings reserved for exceptional durable decisions. The MMU R&D Manager approved that direction with targeted amendments. The Project Lead authorized PROC2A as the controlling implementation packet.

## Decision

Adopt this control model:

```text
GitHub Issue
    = live packet control record

Pull request / reviewed commit / CI
    = implementation, verification, and review evidence

Merged repository
    = final authority for implemented state

Design and process documentation
    = durable knowledge

Memorandum / preserved briefing
    = exceptional retained decision records
```

Establish the **MMU Packet Coordinator** role.

The final role name intentionally excludes `Manager`. Historical source material that proposed an `MMU Packet Manager` is preserved as historical decision input, but active project-process terminology is `MMU Packet Coordinator`.

Authority is separated as follows:

```text
Project Lead
    = final project / merge authority

MMU Dev Manager
    = engineering decision authority
      packet existence, technical scope, sequencing, amendments,
      technical review, commit-specific Dispensation

MMU Packet Coordinator
    = packet control authority
      Issue normalization, approved operational state, links,
      administrative completeness, queues, closeout, contradiction detection
```

The Packet Coordinator has no independent authority to decide whether a packet should exist, define technical scope, resequence work, interpret Motorola-family behavior, approve technical PRs, issue Dispensation, or approve merge.

## Issue control and decision history

For packets created after PROC2A:

- one GitHub Issue is the canonical live operational packet brief;
- explicit Dev Manager or Project Lead comments record approval and material amendments;
- after such a decision, the Packet Coordinator may normalize the Issue body to the current approved scope;
- Decision History links must preserve the approval/amendment record;
- an unapproved body edit is not implementation authorization;
- conflicts between Issue body and decision comments require escalation.

PROC2A itself is the transition packet and uses manually created packet Issue #41 before the Issue template exists. A concurrently created duplicate Issue #42 was explicitly marked duplicate and closed; it is not an authorization or state source.

## Legacy registry freeze

`soft-mmu-68k/docs/process/packets/packet-registry.md` is corrected once and frozen as a legacy/bootstrap record.

It remains at its existing path so historical links continue to work, but it is no longer the live packet-status source.

PROC2A corrects the two known contradictions:

- MTC1: merged through PR #40, branch `matlab/mtc1-tc-crp-span-reference`, merge commit `7b39bb2e0713bace15126f5d6e5af41300972ac7`.
- PROC1B: merged through PR #39, branch `docs/proc1b-verified-record-bootstrap`, merge commit `811f50cccfc8a096091d99d3288e9114076be215`.

No PROC2A row is added. No omitted historical packet rows are backfilled.

## Packet-definition retention

For packets created after PROC2A, a committed `docs/process/packets/<packet>.md` file is optional rather than automatic.

Use a committed packet/specification when durable repository knowledge or stable complex scope clearly justifies it, such as governance changes, architectural/test plans, hardware procedures, or unusually complex multi-stage work.

Ordinary bounded implementation packets use their controlling GitHub Issue as the operational packet brief.

Historical committed packet files remain valid records and are not deleted or retroactively rewritten.

## Memorandum retention

Memoranda become exceptional records, appropriate for matters such as:

- role creation/retirement;
- material cross-packet sequencing changes;
- verification-policy changes;
- accepted process risk or formal waiver;
- material packet split/combination decisions;
- durable governance changes;
- consequential cross-manager disagreement.

A memorandum is not required for ordinary approval, status transition, merge, routine amendment, execution-owner change, or routine follow-up identification.

## Briefing retention

Preserve a full briefing only when at least one is true:

1. it contains unique source analysis/evidence not captured elsewhere;
2. it records materially different alternatives or disagreement worth revisiting;
3. it is a major handoff whose loss would make reconstruction expensive;
4. the Project Lead explicitly requires retention.

Ordinary status reports, packet suggestions, amendment handoffs, review summaries, and chat-generated explanations do not automatically require committed briefing files.

The Toolchain Coach recommendation for PROC2A meets the retention threshold and is preserved as `BRIEF-2026-003`.

## Label and template decision

PROC2A defines the minimal label set only:

```text
packet
status:proposed
status:ready
status:active
status:review
status:blocked
status:deferred
```

Closed dispositions are recorded in a closeout comment as `merged`, `cancelled`, or `superseded`.

PROC2A adds a packet Issue template and updates the PR template to link PRs to their controlling Issues.

No broad label taxonomy, project dashboard, GitHub Projects migration, or external project-management software is adopted.

## Handoff/bootstrap decision

The role handoff protocol is expanded to managers, coaches, and the Packet Coordinator without renaming its repository path.

A replacement Packet Coordinator must reconstruct state from open/recently closed packet Issues, linked PRs, reviewed HEADs, commits, CI, and durable repository docs. It must detect contradictions, report uncertainty, and escalate missing decisions. Chat memory is not sufficient authority.

## Historical Issue migration

Do not create packet Issues retroactively for:

- TC1A
- TC1B
- CTRL1
- CTRL1B
- HW1A
- MTC1
- PROC1A
- PROC1B
- earlier P1–P11 history

Historical state remains in PRs, commits, existing packet files, memoranda/briefings, and the frozen bootstrap registry.

## Sequencing / HW1B

PROC2A precedes HW1B.

HW1B may be prepared only after PROC2A merges and the Packet Coordinator control model is operational.

PROC2A does not authorize Vivado execution, FPGA programming, board observation, RTL changes, or creation of an HW1B implementation branch.

The next packet decision remains with the Project Lead and MMU Dev Manager.

## Rationale

The project needs continuity without requiring the Dev Manager, Documentation Manager, or Project Lead to maintain a second mutable database of facts already owned by GitHub.

The adopted model preserves the conceptual separation created by PROC1A/PROC1B while removing duplicated live state and narrowing archival records to material that has lasting value.

## Dependencies / risks

- GitHub Issues are external to the Git tree, so technical/durable governance remains in reviewed repository artifacts and PR/commit/CI evidence.
- Issue-body edits can obscure earlier scope; explicit decision comments and Decision History links mitigate this risk.
- The Packet Coordinator could drift into decision authority; the role registry explicitly prohibits that.
- Required packet labels may need a one-time administrative action if current tooling does not expose label creation.

## Follow-up required

- Complete PROC2A review, Dispensation, and Project Lead merge.
- After merge, establish/verify the documented packet labels if administration was not available during implementation.
- Post the PROC2A Issue closeout comment and close Issue #41 after merge.
- Only then may the Project Lead/MMU Dev Manager decide whether to prepare HW1B under the new control model.

## Supersedes / superseded by

- **Supersedes:** live manual use of `packet-registry.md` as the packet-status control plane.
- **Superseded by:** none.

## Related briefing records

- [BRIEF-2026-003 — Packet Management Simplification Recommendation](briefings/BRIEF-2026-003-packet-management-simplification-recommendation.md)

## Related packet Issue / process records

- Packet Issue #41 — `PROC2A — Simplify Packet Control and Establish MMU Packet Coordinator`
- Duplicate Issue #42 — closed as duplicate; not controlling
- [PROC2A committed governance packet definition](../packets/PROC2A-simplify-packet-control-and-establish-packet-coordinator.md)
- [Packet and PR protocol](../ai/packet-and-pr-protocol.md)
- [Role registry](../ai/role-registry.md)
