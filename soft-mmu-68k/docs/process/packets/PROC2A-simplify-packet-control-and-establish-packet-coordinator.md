# PROC2A — Simplify Packet Control and Establish MMU Packet Coordinator

## Authorization

- **Packet ID:** `PROC2A`
- **Title:** Simplify Packet Control and Establish MMU Packet Coordinator
- **Classification:** documentation / governance / process
- **Decision owner:** Project Lead
- **Implementation owner:** MMU Documentation Manager
- **Consulted role:** MMU Toolchain Coach
- **Technical/process review:** MMU Dev Manager
- **Final merge authority:** Project Lead
- **Status at authorization:** Authorized for implementation after source gate and Git preflight
- **Branch:** `docs/proc2a-packet-control-simplification`
- **Controlling transition Issue:** GitHub Issue #42
- **Final role name:** `MMU Packet Coordinator`

## Terminology rule

The active role title is **MMU Packet Coordinator**. Do not use `Packet Manager` as the active role title in new or amended project-process text.

Historical/source material that originally proposed `Packet Manager` preserves that wording and carries provenance explaining the final adopted role name.

## Decision sources

Implementation is controlled by this authorized packet. Supporting decision records are:

1. the preserved MMU Toolchain Coach packet-management simplification recommendation;
2. the PROC2A R&D Manager review/decision, which approved the recommendation with targeted amendments;
3. current merged process framework and repository state on `main`.

Where wording differs, this authorized PROC2A packet controls scope.

## Goal

Replace the hand-maintained live Markdown packet registry with a simpler model:

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
    = exceptional decision records
```

Create the **MMU Packet Coordinator** as the operator of packet-control records while preserving Project Lead, MMU Dev Manager, Documentation Manager, Toolchain Coach, Test Manager, R&D Manager, and implementation-agent authority boundaries.

PROC2A reduces duplicated mutable state. It must not create another packet database or documentation layer.

## Preconditions

Before implementation:

- verify current `main`;
- verify PROC1A and PROC1B are merged;
- verify the required source briefing and R&D review are available;
- create/confirm the controlling PROC2A GitHub Issue;
- ensure the implementation branch is based on current verified `main` and contains no unknown work.

The verified implementation baseline was `main` at `5aa18d4968eca7cb1c7dc4c55a2129b8f37e77d0`. The existing `docs/proc2a-packet-control-simplification` branch was verified identical to that baseline before edits.

The controlling transition Issue is #42: `[PACKET] PROC2A — Simplify Packet Control and Establish MMU Packet Coordinator`.

## Required first reading

Read before editing:

```text
AGENTS.md
soft-mmu-68k/docs/process/README.md
soft-mmu-68k/docs/process/ai/README.md
soft-mmu-68k/docs/process/ai/role-registry.md
soft-mmu-68k/docs/process/ai/manager-handoff-protocol.md
soft-mmu-68k/docs/process/ai/packet-and-pr-protocol.md
soft-mmu-68k/docs/process/packets/README.md
soft-mmu-68k/docs/process/packets/packet-registry.md
soft-mmu-68k/docs/process/memoranda/README.md
soft-mmu-68k/docs/process/memoranda/briefings/README.md
.github/pull_request_template.md
```

Review evidence:

- PR #39 — PROC1B merged at `811f50cccfc8a096091d99d3288e9114076be215`;
- PR #40 — MTC1 merged at `7b39bb2e0713bace15126f5d6e5af41300972ac7`;
- `main` baseline `5aa18d4968eca7cb1c7dc4c55a2129b8f37e77d0`.

## Allowed files

Create or edit only:

```text
AGENTS.md
.github/ISSUE_TEMPLATE/packet.md
.github/pull_request_template.md
soft-mmu-68k/docs/process/README.md
soft-mmu-68k/docs/process/ai/README.md
soft-mmu-68k/docs/process/ai/role-registry.md
soft-mmu-68k/docs/process/ai/manager-handoff-protocol.md
soft-mmu-68k/docs/process/ai/packet-and-pr-protocol.md
soft-mmu-68k/docs/process/packets/README.md
soft-mmu-68k/docs/process/packets/packet-registry.md
soft-mmu-68k/docs/process/packets/PROC2A-simplify-packet-control-and-establish-packet-coordinator.md
soft-mmu-68k/docs/process/memoranda/README.md
soft-mmu-68k/docs/process/memoranda/MEMO-2026-003-packet-control-simplification.md
soft-mmu-68k/docs/process/memoranda/briefings/README.md
soft-mmu-68k/docs/process/memoranda/briefings/BRIEF-2026-003-packet-management-simplification-recommendation.md
```

If MEMO/BRIEF sequence 003 conflicts with a newer merged file, stop and obtain a new sequence number.

## Forbidden areas

Do not edit:

```text
README.md
LICENSE.md
soft-mmu-68k/README.md
soft-mmu-68k/rtl/
soft-mmu-68k/tb/
soft-mmu-68k/scripts/
soft-mmu-68k/scripts/matlab/
soft-mmu-68k/tb/common/golden_vectors/
soft-mmu-68k/fpga/
soft-mmu-68k/sw/
soft-mmu-68k/docs/design/
soft-mmu-68k/docs/wiki/
soft-mmu-68k/docs/tutorial/
soft-mmu-68k/docs/roadmap/
soft-mmu-68k/docs/refs/
.github/workflows/
```

Do not change HDL/test behavior, simulation/lint commands, CI workflow triggers, compatibility claims, or architectural behavior. Do not create historical packet Issues, reconstruct historical packet definitions, add a dashboard/generated registry/project-management tool, create a broad label taxonomy, or perform unrelated cleanup.

## Requirement 1 — preserve source recommendation

Create:

`soft-mmu-68k/docs/process/memoranda/briefings/BRIEF-2026-003-packet-management-simplification-recommendation.md`

Metadata identifies the MMU Toolchain Coach as originating role and Project Lead / MMU R&D Manager / MMU Dev Manager as recipients/decision roles. Preserve the substantive recommendation and its historical `MMU Packet Manager` terminology without folding later amendments into the source.

## Requirement 2 — management memorandum

Create:

`soft-mmu-68k/docs/process/memoranda/MEMO-2026-003-packet-control-simplification.md`

Record:

- why the live registry was too expensive;
- MTC1 and PROC1B contradiction examples;
- GitHub Issues as live packet control plane;
- establishment of MMU Packet Coordinator;
- Project Lead and Dev Manager retained authority;
- legacy registry freeze;
- narrowed packet-definition, memorandum, and briefing retention;
- no retrospective historical Issues;
- PROC2A before HW1B;
- Issue template, AGENTS update, and Packet Coordinator handoff rules.

## Requirement 3 — Packet Coordinator role

Add the role to `role-registry.md`.

Authority boundary:

```text
Dev Manager        = engineering decision authority
Packet Coordinator = packet control authority
```

Packet Coordinator owns ID uniqueness, Issue creation/normalization after proposal/approval, approved operational status, approved dependencies/sequencing records, links, administrative completeness, queue reporting, closeout comments/Issue closure, contradiction detection, and escalation.

It does not own packet existence decisions, technical scope, sequencing decisions, Motorola interpretation, technical PR approval, Dispensation, merge approval, broad documentation stewardship, or direct implementation unless separately assigned.

The Packet Coordinator chat is a control desk, not an authority source. Replacement Packet Coordinators reconstruct state from Issues, PRs, commits, CI, and durable docs, not chat memory.

## Requirement 4 — Issues are the live control plane

Update process documentation to use:

```text
packet Issue
    = current operational packet scope and status

Dev Manager / Project Lead Issue comment
    = explicit approval or amendment decision

PR / reviewed commit / CI
    = implementation, review, verification evidence

merged repository
    = final authority for implemented state

committed process/design docs
    = durable knowledge and governance

memorandum / briefing
    = exceptional retained decision records
```

Precedence:

```text
current merged repository state
>
reviewed PR / reviewed commit / CI evidence
>
current approved packet Issue body plus Dev Manager decision comments
>
committed packet definition, when one exists
>
approved management memorandum
>
preserved source briefing
>
chat recollection / generic model memory
```

## Requirement 5 — Issue lifecycle

Document:

```text
1. Specialist, Project Lead, or manager proposes work.
2. Dev Manager approves scope and sequencing.
3. Packet Coordinator creates or normalizes packet Issue.
4. Packet Coordinator applies status:ready.
5. Implementation owner creates approved branch and links Issue.
6. Implementation owner opens PR linked to Issue.
7. Packet Coordinator checks administrative completeness.
8. Dev Manager performs technical review/amendment/Dispensation.
9. Project Lead merges.
10. Packet Coordinator posts closeout, records PR/merge commit, closes Issue.
```

Implementation must not begin before explicit approval and operational `ready` state.

## Requirement 6 — Issue-body and amendment rules

- approval requires explicit Dev Manager or Project Lead comment;
- material amendment requires new explicit decision comment;
- Packet Coordinator may normalize body after decision;
- Decision History links preserve decision comments;
- body edits do not erase history;
- unapproved body edits do not authorize implementation;
- body/comment conflict requires stop/escalation.

## Requirement 7 — packet Issue template

Create `.github/ISSUE_TEMPLATE/packet.md` with YAML front matter and sections for identity, goal, approved scope, allowed/forbidden files, requirements, acceptance criteria, verification, source/design/memo links, branch/PR, Decision History, blockers/deferrals, and closeout.

Operational status is represented by Issue state and `status:*` label, not a second mutable body field.

## Requirement 8 — minimal label set

Document only:

```text
packet
status:proposed
status:ready
status:active
status:review
status:blocked
status:deferred
```

Closed dispositions are recorded as `merged`, `cancelled`, or `superseded` in closeout comments.

If tooling/permissions expose label creation, create the seven labels during closeout. Otherwise report exactly:

`SKIPPED: GitHub label administration unavailable in the implementation environment.`

Do not repeatedly retry failed administration.

## Requirement 9 — freeze/correct legacy registry

Update `packet-registry.md` to:

- label it legacy/bootstrap and frozen by PROC2A;
- state it is not live status source;
- direct live queries to GitHub Issues;
- preserve bounded historical rows;
- correct MTC1 to merged, branch `matlab/mtc1-tc-crp-span-reference`, PR #40, merge commit `7b39bb2e0713bace15126f5d6e5af41300972ac7`, removing stale Ready/no-branch wording;
- correct PROC1B to merged, branch `docs/proc1b-verified-record-bootstrap`, PR #39, merge commit `811f50cccfc8a096091d99d3288e9114076be215`, removing stale Review wording;
- not add PROC2A;
- not backfill omitted history;
- retain current path.

## Requirement 10 — default packet-record rule

For post-PROC2A packets, GitHub Issue is canonical operational brief. Committed packet Markdown is optional and used only when durable knowledge or stable complex scope justifies it. Historical packet files remain valid and are not deleted or rewritten.

PROC2A itself is preserved as a committed governance packet.

## Requirement 11 — narrow memorandum retention

Memoranda are appropriate for role creation/retirement, material cross-packet sequencing, verification-policy changes, accepted risk/formal waiver, material split/combination, durable governance, and consequential cross-manager disagreement.

They are not required for routine approval, Review status, merge, ordinary amendment, owner change, or routine follow-up.

## Requirement 12 — narrow briefing retention

Preserve full briefing only for unique source analysis/evidence, material alternatives/disagreement, major handoff, or explicit Project Lead retention. Routine status reports, packet suggestions, amendment handoffs, review summaries, and chat explanations do not automatically require committed briefings. Do not commit full chat transcripts.

## Requirement 13 — PR template

Add near the top:

```text
Packet Issue: #<number>
Packet ID: <id>
Branch: <branch>
```

Add confirmation that PR links Issue, Issue reflects approved scope, and amendments are linked from Decision History. Add closeout fields for Reviewed HEAD, merge commit, and packet Issue closeout comment. Do not weaken existing verification/compatibility/MATLAB/Dispensation sections.

## Requirement 14 — AGENTS.md

Add concise post-PROC2A packet-Issue rules requiring agents to read the Issue, confirm approval/readiness/branch/scope/verification, stop on decision conflict, and link every packet PR to the controlling Issue. Merged repository state and reviewed evidence remain authoritative for implemented behavior.

Do not otherwise rewrite `AGENTS.md`.

## Requirement 15 — role handoff / Packet Coordinator bootstrap

Keep `manager-handoff-protocol.md` path but change reader-facing title/purpose to a role handoff protocol for managers, coaches, and Packet Coordinator. Display the link as `Role handoff protocol` in `ai/README.md`.

Packet Coordinator bootstrap must inspect open packet Issues, recently closed relevant packet Issues, linked PRs/reviewed HEADs, reconstruct queues, detect contradictions, report uncertainty, and never create/approve/resequence/close packets based only on chat memory.

## Requirement 16 — preserve PROC2A definition

Preserve this governance packet at:

`soft-mmu-68k/docs/process/packets/PROC2A-simplify-packet-control-and-establish-packet-coordinator.md`

Do not broaden or reduce scope without a Dev Manager amendment.

## Requirement 17 — no retrospective Issue migration

Do not create Issues for TC1A, TC1B, CTRL1, CTRL1B, HW1A, MTC1, PROC1A, PROC1B, or earlier P1–P11 history.

## Requirement 18 — HW1B remains blocked

Record:

```text
HW1B may be prepared after PROC2A merges and the Packet Coordinator control model is operational.

PROC2A does not authorize Vivado execution, FPGA programming, board observation, RTL changes, or creation of an HW1B implementation branch.
```

The next packet decision remains with Project Lead and MMU Dev Manager.

## Verification

Run from repository root:

```bash
git status --short --branch
git diff --stat
git diff --check
git diff --name-only
```

Changed paths must be limited to the allowed set.

Run focused searches:

```bash
grep -RIn -- "packet-registry.md" AGENTS.md .github soft-mmu-68k/docs/process || true
grep -RIn -- "MMU Packet Coordinator" AGENTS.md .github soft-mmu-68k/docs/process || true
grep -RIn -- "live packet" AGENTS.md .github soft-mmu-68k/docs/process || true
grep -RIn -- "branch/PR not yet present\|remains `Ready`\|remains `Review`" soft-mmu-68k/docs/process/packets/packet-registry.md || true
```

Inspect `.github/ISSUE_TEMPLATE/packet.md` for valid YAML front matter and complete Markdown structure.

Confirm the PROC2A Issue and PR links when available. Create/verify required labels if tooling allows; otherwise report the exact skipped administrative state.

## HDL / MATLAB / FPGA verification disposition

Do not run HDL, MATLAB, Vivado, synthesis, implementation, bitstream, or hardware tests.

Report exactly:

```text
SKIPPED: documentation/governance packet; no RTL, testbench, HDL-consumed vector, MATLAB, script, FPGA, workflow, or software behavior changed.
```

Automatic GitHub Actions results are reported separately. Workflow triggers must not change.

## Acceptance criteria

PROC2A is complete when:

- the Toolchain Coach recommendation is preserved as a source briefing;
- MEMO-2026-003 records the governance decision;
- MMU Packet Coordinator exists with explicit limits;
- GitHub Issues are designated as live control plane;
- lifecycle/amendment rules are explicit;
- packet Issue template exists;
- PR template links to packet Issues;
- AGENTS directs agents to the controlling Issue;
- handoff protocol includes Packet Coordinator bootstrap;
- minimal labels are documented and either created or the exact unavailable reason is recorded;
- legacy registry is corrected/frozen and MTC1/PROC1B contradictions removed;
- ordinary future packet Markdown is optional;
- memorandum/briefing thresholds are narrowed;
- no historical Issue backfill occurs;
- no technical/compatibility claims change;
- only allowed files changed;
- `git diff --check` passes;
- work proceeds through commit/push/PR, Toolchain Coach mechanics review, Dev Manager governance review, commit-specific Dispensation, Project Lead merge, then Packet Coordinator Issue closeout/closure.

## Pull request

Recommended title:

`PROC2A: simplify packet control and establish MMU Packet Coordinator`

PR body headings:

```markdown
## Packet Issue
## Summary
## Files Changed
## Process Changes
## Legacy Registry Freeze
## Verification
## Tests Not Run
## GitHub Administrative State
## Compatibility / Architecture Impact
## Known TODOs
## DEV Manager Review / Dispensation
```

## Review sequence

```text
MMU Documentation Manager implementation and self-report
->
MMU Toolchain Coach review of Issue/PR/Git mechanics
->
MMU Dev Manager review of scope, authority, governance
->
amendment if required
->
DEV Manager Dispensation for exact reviewed HEAD
->
Project Lead merge
->
Packet Coordinator closeout comment, label verification, Issue closure
```

Any push/amend/force-push after Dispensation invalidates approval and requires re-review.

## Known deferrals

Not part of PROC2A:

- automated packet dashboards;
- generated Issue-to-Markdown reports;
- historical Issue backfill;
- GitHub Projects migration;
- broad label taxonomy;
- external project-management tools;
- HW1B execution;
- MTC1B;
- MTC2;
- TC2A;
- CTRL2A;
- FAULT1.
