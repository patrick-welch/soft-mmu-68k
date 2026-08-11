# Source Briefing Record — Packet Management Simplification Recommendation

- **Title:** SM68861 Packet Management Simplification Recommendation
- **Date / source date:** 2026-08-11
- **Originating role:** MMU Toolchain Coach
- **Recipient / decision role:** Project Lead; MMU R&D Manager; MMU Dev Manager
- **Record status:** Source briefing
- **Role-name correction:** The originating project role is **MMU Toolchain Coach**. Earlier draft wrappers used an incorrect role title; this is a metadata correction only and does not rewrite the preserved source recommendation.
- **Related packet:** `PROC2A`
- **Related memorandum:** `MEMO-2026-003-packet-control-simplification.md`
- **Source/provenance note:** Preserved from the Project Lead-supplied packet-management simplification recommendation. The substantive source text below is preserved. Repository formatting is normalized to LF; the recommendation is not silently rewritten to incorporate later R&D Manager amendments.

---

## Terminology note

The preserved source briefing below uses the originally proposed role name **MMU Packet Manager**. After reviewing the proposal, the Project Lead adopted the final role name **MMU Packet Coordinator** to make clear that the role coordinates packet state and records but does not hold manager-level technical or decision authority. The source text is intentionally left unchanged as historical decision input.

# SM68861 Packet Management Simplification Recommendation

**Date:** 2026-08-11
**Status:** Advisory recommendation; no repository changes authorized or made
**Project:** SM68861 — Soft MMU for 68k-family systems

## Executive recommendation

Create the **MMU Packet Manager** role, but do **not** implement the current proposal by simply assigning one more manager to maintain the existing packet registry, memorandum, briefing, and status machinery.

The role proposal has the right authority boundary:

- Project Lead retains final authority.
- MMU Dev Manager decides packet scope, sequencing, amendments, technical review, and commit-specific Dispensation.
- MMU Packet Manager operates packet control and records.
- MMU Documentation Manager owns broader documentation quality and alignment.
- MMU Toolchain Coach owns Git/PR/tooling mechanics.

The change I recommend is to **simplify the packet-control system at the same time**.

The core problem is not that the project lacks records. The core problem is that mutable packet state is being copied into multiple records that must then be manually synchronized.

Use **GitHub Issues as the live packet control plane**. Keep Git commits and PRs for implementation evidence and durable technical/process documentation. Preserve memoranda and briefings only when they contain information that is genuinely worth retaining.

## What is working in the current framework

PROC1A and PROC1B solved a real problem: after a break, packet scope, sequencing, rationale, and source provenance were difficult to reconstruct.

The current process correctly distinguishes:

- packet definition = what work was authorized;
- packet registry = status/dependency index;
- briefing = decision input;
- memorandum = management/process rationale;
- PR/commit/CI = what was actually changed and tested;
- design documents = technical architecture and compatibility decisions.

That separation is conceptually sound.

The existing process also correctly says not to copy complete PR diffs, CI logs, chat transcripts, source manuals, or design documents into process records.

Those principles should be retained.

## Where the current implementation is becoming too expensive

The problem is the **live registry**.

GitHub already knows whether a branch exists, whether a PR exists, whether the PR merged, what commit merged, and when it happened. Re-entering those facts in `packet-registry.md` creates a second mutable state database.

The recent MTC1 closeout demonstrates the failure mode.

After MTC1 was merged, an administrative commit changed only the registry Status field from `Ready` to `Merged`, while the same row still said that the branch/PR was not yet present and that implementation status remained `Ready`.

PROC1B has the same pattern: its Status was changed to `Merged`, while its note still says the row remains `Review` before merge.

That is not a discipline failure. It is a data-model problem. The registry contains facts that GitHub already owns, so every packet closeout creates synchronization work and opportunities for contradiction.

The result is exactly the burden described by the Dev Manager opinion: the Dev Manager is spending context on packet bookkeeping rather than technical decisions.

## Recommended control model

Use this model:

```text
GitHub Issue
    = live packet control record

Approved packet scope
    = Issue body plus explicit Dev Manager approval/amendment record

Branch / Pull Request
    = implementation, verification, review, and Dispensation evidence

Merged repository
    = final authority for implemented project state

Design documentation
    = durable technical/compatibility decisions

Management memorandum
    = exceptional cross-packet/process decision rationale

Preserved briefing
    = exceptional decision-critical source material
```

### One GitHub Issue per packet

Every new packet receives one GitHub Issue.

The issue is the live record for:

- packet ID;
- title;
- current operational status;
- decision owner;
- execution owner;
- dependencies;
- approved goal/scope;
- allowed and forbidden files;
- acceptance criteria;
- verification requirements;
- related design/source records;
- branch and PR linkage;
- blocked/deferred state;
- closeout result.

The issue should link to the implementation PR. The PR should link back to the packet issue.

When the packet is complete, the Packet Manager posts a short closeout comment containing the PR, reviewed/merged commit, and disposition, then closes the issue.

No Git commit should be required merely to change `Ready` to `Active`, `Review`, or `Merged`.

### Minimal status vocabulary

Keep the useful vocabulary but map it to issue state plus a small label set.

Suggested open-state labels:

- `packet`
- `status:proposed`
- `status:ready`
- `status:active`
- `status:review`
- `status:blocked`
- `status:deferred`

A completed packet is a closed issue with a closeout comment identifying the merged PR/commit.

Cancelled or superseded packets are closed with a comment identifying that disposition and the replacement packet when applicable.

Do not create a large taxonomy of packet-type, manager, subsystem, and priority labels until there is an actual need.

## What to do with canonical packet Markdown files

Do not delete the existing packet records. They are useful history and PROC1A/PROC1B are legitimate records of how the process evolved.

For **new packets**, however, do not require a committed `docs/process/packets/<packet>.md` file merely because a packet exists.

The GitHub Issue can be the canonical operational packet brief.

Create a committed packet/specification document only when the packet itself produces durable project knowledge that belongs in the repository, or when the scope is sufficiently complex that a stable committed specification adds value.

Examples:

- a technical behavior/test plan may belong under `docs/design/`;
- a durable hardware procedure may belong under `docs/process/hardware/`;
- a governance change belongs under `docs/process/`;
- an ordinary bounded implementation packet does not need a second committed copy of its issue body.

This avoids turning every unit of work into another documentation packet.

## Retire the live `packet-registry.md` concept

I recommend that `packet-registry.md` stop being the live source of packet status.

There are two acceptable migration choices:

1. **Preferred:** freeze it as a legacy/bootstrap record and direct current packet-state queries to GitHub Issues.
2. Keep a compact packet index containing only stable identifiers and links, with no mutable branch/PR/status notes.

Do not continue maintaining branch existence, PR status, merge status, and current execution notes manually in Markdown.

If a future human-readable dashboard is desirable, generate it from Issues/PR data rather than hand-maintaining a second database.

## Packet Manager role

Adopt the Packet Manager role with a narrower operational charter than the current proposal.

### Packet Manager owns

- packet ID uniqueness;
- creation and maintenance of packet Issues;
- applying the approved packet status;
- recording approved dependencies and sequencing;
- linking packet Issue, branch, PR, and relevant durable docs;
- checking that PR/closeout metadata is administratively complete;
- detecting stale or contradictory packet state;
- producing the current Ready/Active/Review/Blocked queue;
- posting closeout records and closing completed packet Issues;
- escalating missing decisions rather than inventing them.

### Packet Manager does not own

- deciding whether work should exist;
- choosing technical packet scope;
- changing sequencing without Dev Manager/Project Lead approval;
- Motorola-family behavior interpretation;
- technical PR approval;
- DEV Manager Dispensation;
- merge approval;
- broad documentation stewardship.

The simplest shorthand remains:

```text
Dev Manager    = engineering decision authority
Packet Manager = packet control authority
```

The Packet Manager chat should be a **control desk**, not a source of truth. On startup or handoff it should reconstruct state from GitHub Issues, PRs, and durable repository documents rather than from its own chat memory.

## Briefings: keep the concept, narrow the retention rule

The current rule that a substantive briefing used for decision-making should be preserved is defensible, but it is too broad as a default for this project's current scale.

Do not preserve every manager-to-manager briefing in the repository.

Preserve a full briefing only when at least one of these is true:

1. it contains unique source analysis or evidence not captured elsewhere;
2. it records materially different alternatives or disagreement that future reviewers may need to revisit;
3. it is a major manager handoff whose loss would make project state expensive to reconstruct;
4. the Project Lead explicitly marks it for retention.

Otherwise, the Packet Manager should record a concise decision-input summary in the packet Issue or relevant memorandum and link the originating artifact when a durable link exists.

Ordinary packet suggestions, status reports, amendment handoffs, review summaries, and chat-generated explanations do not automatically need their own committed briefing files.

Full chat transcripts should not be committed.

## Memoranda: exceptional, not routine

Keep management memoranda, but raise the threshold for creating one.

A memorandum is appropriate for:

- a cross-packet sequencing change with meaningful consequences;
- creation or retirement of a project role;
- a verification-policy change;
- accepted project/process risk or formal waiver;
- a packet split/combination that changes the roadmap materially;
- a durable governance decision likely to matter after another long break.

A memorandum is **not** required merely because:

- a packet was approved;
- a packet entered Review;
- a PR merged;
- a routine scope clarification was made;
- the implementation owner changed;
- an ordinary follow-up packet was identified.

Those events belong in the packet Issue and PR history.

## Recommended packet lifecycle

```text
1. Specialist / Project Lead proposes work
                |
                v
2. Dev Manager approves scope and sequencing
                |
                v
3. Packet Manager creates/normalizes GitHub packet Issue
                |
                v
4. Implementation owner creates branch and PR
                |
                v
5. Packet Manager checks administrative completeness
                |
                v
6. Dev Manager performs technical review / amendment / Dispensation
                |
                v
7. Project Lead merges
                |
                v
8. Packet Manager posts closeout and closes Issue
```

Create a memorandum or preserve a briefing only when the retention tests above are met.

## Recommended process amendment

If this direction is approved, create one small process packet, for example:

`PROC2A — Simplify Packet Control and Establish MMU Packet Manager`

Its purpose should be **simplification**, not more framework construction.

Likely allowed files:

- `soft-mmu-68k/docs/process/ai/role-registry.md`
- `soft-mmu-68k/docs/process/ai/packet-and-pr-protocol.md`
- `soft-mmu-68k/docs/process/packets/README.md`
- `soft-mmu-68k/docs/process/packets/packet-registry.md`
- `soft-mmu-68k/docs/process/memoranda/README.md`
- `soft-mmu-68k/docs/process/memoranda/briefings/README.md`
- `.github/pull_request_template.md`

The packet should:

- establish the Packet Manager authority boundary;
- designate GitHub Issues as the live packet control plane;
- stop treating `packet-registry.md` as live mutable state;
- add a `Packet issue` reference to the PR template;
- narrow memorandum and briefing retention rules;
- make one final correction/freeze of the legacy registry if needed;
- explicitly avoid historical backfill;
- explicitly avoid creating another layer of packet-control artifacts.

After PROC2A merges, create Issues only for current/future packets. Do not create Issues retroactively for the already merged historical packet set unless a specific future need justifies it.

## Bottom line

The Packet Manager idea is good.

The existing Packet Manager proposals correctly identify that packet control has become a separate operational job. What I would change is the amount of material that job is expected to maintain.

Do not solve excessive packet bookkeeping by creating a manager dedicated to excessive packet bookkeeping.

Use the new role to **collapse the control system**:

```text
Issue = packet state
PR = implementation/review state
Git history = implemented result
design/process docs = durable knowledge
memo/briefing = exception records
```

That gives the project the continuity that PROC1A/PROC1B were trying to create without requiring the Project Lead, Dev Manager, or Documentation Manager to act as a human database.
