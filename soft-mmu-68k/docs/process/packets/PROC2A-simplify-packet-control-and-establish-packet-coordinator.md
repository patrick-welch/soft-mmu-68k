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
- **Current status:** Authorized for implementation after source gate and Git preflight
- **Branch:** `docs/proc2a-packet-control-simplification`
- **Controlling transition Issue:** GitHub Issue #41
- **Final role name:** `MMU Packet Coordinator`

Issue #42 was created concurrently with the same PROC2A scope. The Project Lead designated Issue #41 as the controlling path; Issue #42 is closed as duplicate and is not an authorization or state source.

### Terminology rule

The final role name is **MMU Packet Coordinator**. Do not use `Packet Manager` as the active role title anywhere in new or amended project-process text. Historical/source material that originally proposed `Packet Manager` preserves that original wording and carries provenance explaining that the final adopted role name is `Packet Coordinator`.

## Decision sources

This packet implements the approved direction derived from:

1. the MMU Toolchain Coach packet-management simplification recommendation, preserved as `BRIEF-2026-003`;
2. the PROC2A R&D Manager review and decision, which approved the recommendation with targeted amendments;
3. current merged process framework and repository state on `main`.

Where wording differs, this authorized PROC2A packet controls implementation scope. Do not reinterpret or broaden the approved direction.

## Goal

Replace the hand-maintained live Markdown packet registry with a simpler control model:

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

Create the **MMU Packet Coordinator** as the operator of packet-control records while preserving the authority boundaries of the Project Lead, MMU Dev Manager, Documentation Manager, Toolchain Coach, Test Manager, R&D Manager, and implementation agents.

PROC2A must reduce duplicated mutable state. It must not create another packet database or documentation layer.

## Preconditions and transition Issue

Before implementation:

- verify current `main`;
- verify PROC1A and PROC1B are merged;
- verify the required source recommendation and R&D review are available;
- create or confirm the controlling PROC2A GitHub Issue;
- ensure the implementation branch is based on current verified `main` and contains no unknown work.

Verified implementation baseline:

`5aa18d4968eca7cb1c7dc4c55a2129b8f37e77d0`

Controlling transition Issue:

`#41 — [PACKET] PROC2A — Simplify Packet Control and Establish MMU Packet Coordinator`

The Issue contains explicit Project Lead authorization and operational `ready` disposition. Issue #42 is a closed duplicate.

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

Evidence points:

- PR #39 — PROC1B merged at `811f50cccfc8a096091d99d3288e9114076be215`;
- PR #40 — MTC1 merged at `7b39bb2e0713bace15126f5d6e5af41300972ac7`;
- main baseline `5aa18d4968eca7cb1c7dc4c55a2129b8f37e77d0`.

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

If sequence `003` conflicts with a newer merged memorandum or briefing, stop and request a new sequence number.

## Forbidden files and areas

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

Do not change HDL behavior, test behavior, simulation/lint commands, CI workflow triggers, compatibility claims, or SM68861 architectural behavior. Do not create historical packet Issues, reconstruct historical packet definitions, add a packet dashboard/generated registry/project-management tool, add a broad label taxonomy, or perform unrelated cleanup.

## Requirement 1 — preserve the source recommendation

Create:

`soft-mmu-68k/docs/process/memoranda/briefings/BRIEF-2026-003-packet-management-simplification-recommendation.md`

Required metadata identifies the MMU Toolchain Coach as originating role; Project Lead, MMU R&D Manager, and MMU Dev Manager as recipients/decision roles; Source briefing status; PROC2A; MEMO-2026-003; and source provenance.

Preserve the substantive source recommendation. Allowed normalization is filename normalization, LF line endings, trailing-whitespace cleanup, repository-relative links, and a metadata wrapper. Do not silently rewrite the source recommendation to match the later decision.

## Requirement 2 — create the management memorandum

Create:

`soft-mmu-68k/docs/process/memoranda/MEMO-2026-003-packet-control-simplification.md`

Record:

- why the live registry was judged too expensive;
- the MTC1 and PROC1B contradiction examples;
- adoption of GitHub Issues as the live packet control plane;
- establishment of the MMU Packet Coordinator role;
- authority retained by the Project Lead and MMU Dev Manager;
- freeze of the legacy registry;
- narrowing of committed packet definitions, memoranda, and briefing retention;
- no retrospective Issue creation for historical packets;
- PROC2A preceding HW1B;
- the Issue-template, AGENTS, and Packet Coordinator handoff amendments.

Do not treat the memorandum as technical architecture documentation.

## Requirement 3 — establish the MMU Packet Coordinator role

Add the role to `soft-mmu-68k/docs/process/ai/role-registry.md`.

Purpose: operate the live packet-control system and keep packet state reconstructable from GitHub and durable repository evidence.

Owns:

- packet ID uniqueness;
- creation and normalization of packet Issues after proposal or approval;
- application of approved operational status;
- recording approved dependencies and sequencing;
- linking Issue, branch, PR, and durable records;
- administrative completeness checks;
- Ready / Active / Review / Blocked / Deferred queue reporting;
- closeout comments and Issue closure;
- stale or contradictory packet-state detection;
- escalation of missing decisions.

Must not own:

- deciding whether a packet should exist;
- technical packet scope;
- packet sequencing decisions;
- Motorola-family interpretation;
- technical PR approval;
- DEV Manager Dispensation;
- merge approval;
- broad documentation stewardship;
- direct implementation unless separately assigned.

Authority shorthand:

```text
Dev Manager        = engineering decision authority
Packet Coordinator = packet control authority
```

Recommended tier: Engineering tier with high reasoning for state reconstruction. No independent Decision-tier authority. Conflicts are escalated.

The Packet Coordinator chat is a control desk, not an authority source. Replacement Packet Coordinators reconstruct state from Issues, PRs, commits, CI, and durable docs; chat memory is insufficient.

## Requirement 4 — designate GitHub Issues as live control plane

Update the process documentation to use:

```text
packet Issue
    = current operational packet scope and status

Dev Manager / Project Lead Issue comment
    = explicit approval or amendment decision

PR / reviewed commit / CI
    = implementation, review, and verification evidence

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
current approved packet Issue body plus Dev Manager or Project Lead decision comments
>
committed packet definition, when one exists
>
approved management memorandum
>
preserved source briefing
>
chat recollection / generic model memory
```

The Issue does not override merged code or reviewed test evidence.

## Requirement 5 — define the Issue lifecycle

Document:

```text
1. Specialist, Project Lead, or manager proposes work.
2. Dev Manager approves scope and sequencing.
3. Packet Coordinator creates or normalizes the packet Issue.
4. Packet Coordinator applies status:ready.
5. Implementation owner creates the named branch and links the Issue.
6. Implementation owner opens a PR linked to the Issue.
7. Packet Coordinator checks administrative completeness.
8. Dev Manager performs technical review, amendment, or Dispensation.
9. Project Lead merges.
10. Packet Coordinator posts closeout, records PR and merge commit, and closes the Issue.
```

A proposed Issue may exist before approval, but implementation must not begin until the Dev Manager or Project Lead explicitly approves scope and the operational state is ready.

## Requirement 6 — define Issue-body and amendment rules

- approval must be recorded in an explicit Dev Manager or Project Lead comment;
- material amendment must be recorded in a new explicit decision comment;
- after approval/amendment, the Packet Coordinator may update the Issue body to current approved scope;
- the Packet Coordinator maintains a short Decision History linking decision comments;
- editing the body must not erase earlier decision history;
- an implementation agent may not treat an unapproved body edit as authorization;
- if Issue body and decision comments conflict, stop and escalate.

## Requirement 7 — add the packet Issue template

Create `.github/ISSUE_TEMPLATE/packet.md` with YAML front matter:

```yaml
---
name: SM68861 packet
about: Propose or control one bounded SM68861 project packet
title: "[PACKET] <ID> — <short title>"
assignees: ""
---
```

The body contains Packet identity, Goal, Approved scope with Allowed/Forbidden files, Requirements, Acceptance criteria, Verification, Source/design/memorandum links, Branch and pull request, Decision history, Blockers/deferrals, and Closeout.

Operational status is represented by Issue state and `status:*` label; do not maintain a second mutable status value in the template body. Do not auto-assign a manager or require labels that might not exist.

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

Closed Issue dispositions are recorded in a closeout comment as `merged`, `cancelled`, or `superseded`.

Do not add priority, manager, subsystem, packet-type, compatibility, or roadmap label taxonomies.

If authenticated tooling exposes label creation, create the seven labels during PROC2A closeout. If label creation is unavailable, report exactly:

```text
SKIPPED: GitHub label administration unavailable in the implementation environment.
```

Do not repeatedly retry failed administration.

## Requirement 9 — freeze and correct the legacy registry

Update `soft-mmu-68k/docs/process/packets/packet-registry.md` to:

1. identify it as a legacy/bootstrap registry frozen by PROC2A;
2. state it is not the live packet-status source;
3. direct live packet queries to GitHub Issues;
4. preserve the bounded historical rows;
5. correct MTC1 to `Merged`, branch `matlab/mtc1-tc-crp-span-reference`, PR #40, merge commit `7b39bb2e0713bace15126f5d6e5af41300972ac7`, removing stale Ready/no-branch wording;
6. correct PROC1B to `Merged`, branch `docs/proc1b-verified-record-bootstrap`, PR #39, merge commit `811f50cccfc8a096091d99d3288e9114076be215`, removing stale Review wording;
7. not add PROC2A as a live-status row;
8. not backfill omitted historical packets;
9. retain the current path for link stability.

## Requirement 10 — change the default packet-record rule

For packets created after PROC2A:

- a GitHub Issue is the canonical operational packet brief;
- committed `docs/process/packets/<packet>.md` is optional, not automatic;
- committed packet definitions are appropriate only when durable knowledge or stable complex scope justifies them;
- ordinary bounded implementation packets do not require duplicate Markdown packet files;
- historical packet files created before PROC2A remain valid and are not deleted or rewritten.

PROC2A itself is preserved as a committed governance packet because it changes durable governance.

## Requirement 11 — narrow memorandum retention

A memorandum is appropriate for:

- role creation or retirement;
- material cross-packet sequencing changes;
- verification-policy changes;
- accepted process risk or formal waiver;
- material packet split/combination;
- durable governance changes;
- consequential cross-manager disagreement.

A memorandum is not required merely because a packet was approved, moved to Review, merged, received an ordinary amendment, changed implementation owner, or identified a routine follow-up. Those events belong in Issue/PR history.

## Requirement 12 — narrow briefing retention

Preserve a full briefing only when at least one is true:

1. unique source analysis/evidence is not captured elsewhere;
2. material alternatives or disagreement may need later review;
3. it is a major handoff whose loss would make reconstruction expensive;
4. the Project Lead explicitly requires retention.

Ordinary status reports, packet suggestions, amendment handoffs, review summaries, and chat-generated explanations do not automatically require committed briefing files. Do not commit full chat transcripts.

## Requirement 13 — update the PR template

Add near the top:

```text
Packet Issue: #<number>
Packet ID: <id>
Branch: <branch>
```

Add scope confirmation that the PR links the controlling Issue, the Issue body reflects current approved scope, and amendments are linked from Decision History.

Add closeout fields:

```text
Reviewed HEAD:
Merge commit after closeout:
Packet Issue closeout comment:
```

Do not weaken existing verification, compatibility, MATLAB, or Dispensation sections.

## Requirement 14 — update AGENTS.md

Add a concise rule for post-PROC2A packets:

- the controlling GitHub Issue is the live operational packet record;
- before editing, read the Issue and confirm approval/readiness/branch/allowed files/forbidden files/verification;
- stop if the Issue body conflicts with approval/amendment comments;
- every packet PR links the Issue;
- the Issue controls authorized work while merged repository state and reviewed evidence remain authoritative for implemented behavior.

Do not otherwise rewrite `AGENTS.md`.

## Requirement 15 — update Packet Coordinator handoff/bootstrap

Keep the repository path `soft-mmu-68k/docs/process/ai/manager-handoff-protocol.md`, but change its reader-facing title/purpose to a **role handoff protocol** for managers, coaches, and the Packet Coordinator. Update `ai/README.md` to display the link as `Role handoff protocol`; do not rename the file.

Packet Coordinator bootstrap must:

- inspect all open Issues carrying `packet` when the label exists;
- inspect recently closed relevant packet Issues;
- inspect linked PRs and reviewed HEADs;
- identify ready, active, review, blocked, and deferred queues;
- detect Issue/PR contradictions;
- report uncertainty and escalate;
- not create, approve, resequence, or close packets based only on chat memory.

## Requirement 16 — preserve the packet definition

Preserve this authorized governance packet at:

`soft-mmu-68k/docs/process/packets/PROC2A-simplify-packet-control-and-establish-packet-coordinator.md`

Formatting and repository-relative links may be normalized. Do not broaden or reduce authorized scope without a Dev Manager amendment.

## Requirement 17 — no retrospective Issue migration

Do not create Issues for:

```text
TC1A
TC1B
CTRL1
CTRL1B
HW1A
MTC1
PROC1A
PROC1B
```

Do not create Issues for earlier P1–P11 history.

## Requirement 18 — HW1B remains blocked

Record:

```text
HW1B may be prepared after PROC2A merges and the Packet Coordinator control model is operational.

PROC2A does not authorize Vivado execution, FPGA programming, board observation, RTL changes, or creation of an HW1B implementation branch.
```

The next packet decision remains with the Project Lead and MMU Dev Manager.

## Verification

Run from repository root:

```bash
git status --short --branch
git diff --stat
git diff --check
git diff --name-only
```

Verify changed paths are limited to the authorized file set.

Run focused searches:

```bash
grep -RIn -- "packet-registry.md" AGENTS.md .github soft-mmu-68k/docs/process || true

grep -RIn -- "MMU Packet Coordinator" AGENTS.md .github soft-mmu-68k/docs/process || true

grep -RIn -- "live packet" AGENTS.md .github soft-mmu-68k/docs/process || true

grep -RIn -- "branch/PR not yet present\|remains `Ready`\|remains `Review`" soft-mmu-68k/docs/process/packets/packet-registry.md || true
```

Inspect `.github/ISSUE_TEMPLATE/packet.md` for valid YAML front matter and complete Markdown structure.

If tooling allows, confirm Issue #41 exists, the PR links it, and required labels exist; otherwise record unavailable administration exactly.

## HDL / MATLAB / FPGA verification disposition

Do not run HDL, MATLAB, Vivado, synthesis, implementation, bitstream, or hardware tests.

Report exactly:

```text
SKIPPED: documentation/governance packet; no RTL, testbench, HDL-consumed vector, MATLAB, script, FPGA, workflow, or software behavior changed.
```

Automatic GitHub Actions is reported separately if triggered. Do not change workflow triggers.

## Acceptance criteria

PROC2A is complete when:

- the MMU Toolchain Coach recommendation is preserved as a source briefing;
- MEMO-2026-003 records the approved governance decision;
- the MMU Packet Coordinator role exists with explicit authority limits;
- GitHub Issues are the live packet control plane;
- Issue lifecycle and amendment rules are explicit;
- `.github/ISSUE_TEMPLATE/packet.md` exists;
- the PR template links PRs to packet Issues;
- `AGENTS.md` tells agents to read the controlling Issue;
- the handoff protocol covers Packet Coordinator bootstrap;
- the minimal label set is documented;
- labels are created or the exact skipped-administration reason is recorded;
- the legacy registry is corrected, frozen, and no longer presented as live;
- MTC1 and PROC1B contradictions are removed;
- committed packet definitions are no longer mandatory for ordinary future packets;
- memorandum and briefing retention thresholds are narrowed;
- no historical Issue backfill occurs;
- no technical or compatibility claims change;
- only allowed files change;
- `git diff --check` passes;
- the packet is committed, pushed, opened as a PR, reviewed, receives commit-specific Dispensation, and is merged;
- Issue #41 receives a closeout comment and is closed after merge.

## Commit and pull request

Recommended implementation commit message:

```text
PROC2A: simplify packet control and add Packet Coordinator role
```

Recommended PR title:

```text
PROC2A: simplify packet control and establish MMU Packet Coordinator
```

Required PR body headings:

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

## Required review sequence

```text
MMU Documentation Manager implementation and self-report
->
MMU Toolchain Coach review of Issue/PR/Git mechanics
->
MMU Dev Manager review of scope, authority, and governance
->
amendment if required
->
DEV Manager Dispensation for the exact reviewed HEAD
->
Project Lead merge
->
Packet Coordinator closeout comment, label verification, and Issue closure
```

Any push, amend, or force-push after Dispensation invalidates approval and requires re-review.

## Final response required from implementation owner

Return:

1. PROC2A Issue number and URL
2. branch
3. commit SHA
4. PR number and URL
5. exact files changed
6. exact files intentionally not touched
7. summary of process changes
8. `git diff --check` result
9. focused search results
10. GitHub label state
11. tests/checks run
12. tests/checks skipped with reasons
13. known limitations
14. follow-up needed
15. reviewed HEAD when available
16. merge/closeout state

## Known deferrals

Not part of PROC2A:

- automated packet dashboards;
- generated Issue-to-Markdown reports;
- historical Issue backfill;
- migration to GitHub Projects;
- broad label taxonomy;
- external project-management tools;
- HW1B execution;
- MTC1B;
- MTC2;
- TC2A;
- CTRL2A;
- FAULT1.
