# PROC1A Authorization and Packet Definition — Durable Packet, Memorandum, and Briefing Framework

## Authorization

**Packet ID:** `PROC1A`

**Title:** Durable Packet, Memorandum, and Briefing Framework

**Status:** **AUTHORIZED / READY**

**Decision owner:** Project Lead

**Packet owner / implementation role:** **MMU Documentation Manager**

**DEV Manager role:** packet definition, sequencing, scope review, PR review, and DEV Manager Dispensation

**Originating proposal:** `SM68861_Packet_Registry_and_Memoranda_Proposal(1).md`

**Parallel execution:** Authorized to proceed in parallel with `MTC1`.

**Dependency relationship:** `PROC1A` and `MTC1` are independent. Neither packet may modify the other's owned files.

## Why this packet exists

The project already has a packet lifecycle and role structure, but it lacks one canonical durable mechanism for recording:

- official packet definitions;
- packet status and dependencies;
- management/process rationale;
- substantive briefing records used as decision inputs.

The Documentation Manager identified this process gap.

The Project Lead additionally directed that substantive briefings be preserved for later review rather than disappearing into chat history.

`PROC1A` creates the **framework only**.

It intentionally does **not** perform broad historical backfill or ingest all prior briefing artifacts. That work is deferred to the smaller follow-up packet `PROC1B`.

This split keeps `PROC1A` small and reviewable.

---

# Packet: PROC1A — Durable Packet, Memorandum, and Briefing Framework

## Role

You are the **MMU Documentation Manager** implementing this documentation/process packet for the SM68861 / `soft-mmu-68k` project.

Your task is to establish the durable repository structure and rules.

Do not turn this packet into historical archaeology.

Do not reconstruct old packet history from memory.

## Recommended model/settings

- Role: MMU Documentation Manager
- Model tier: Engineering tier; use high reasoning if configurable because this changes durable project process documentation.
- Internet access: not required.
- GitHub / `gh`: available if needed to verify the current branch or PR state.
- Autonomy: conservative.
- Stop when provenance, authority, packet identity, or historical status is unclear.

## Repository

```text
patrick-welch/soft-mmu-68k
```

## Branch

Create from current verified `main`:

```text
docs/proc1a-process-record-framework
```

Before editing:

```bash
git switch main
git pull
git status --short --branch
git switch -c docs/proc1a-process-record-framework
```

If checkout, pull, or branch creation fails, stop and report:

```text
current branch
current HEAD
git status --short
failure
```

Do not use reset, rebase, force-push, or destructive cleanup to repair an unexpected Git state.

## Required first reading

Read before editing:

```text
AGENTS.md
soft-mmu-68k/docs/README.md
soft-mmu-68k/docs/process/ai/README.md
soft-mmu-68k/docs/process/ai/role-registry.md
soft-mmu-68k/docs/process/ai/packet-and-pr-protocol.md
soft-mmu-68k/docs/process/codex_packet_workflow.md
```

Also read the originating proposal supplied by the Project Lead:

```text
SM68861_Packet_Registry_and_Memoranda_Proposal(1).md
```

The proposal is the source recommendation.

This packet definition is the authorization controlling implementation scope.

## Goal

Create a durable process framework under:

```text
soft-mmu-68k/docs/process/
```

that clearly separates:

```text
packet definition
    = WHAT work is authorized

packet registry
    = compact status/dependency index

briefing record
    = preserved substantive input supplied to a decision-maker

management memorandum
    = WHY a project/process decision was made

pull request / reviewed commit
    = WHAT was actually changed and reviewed

design documentation
    = technical architecture and compatibility decisions
```

The framework must make clear that current reviewed/merged repository state remains authoritative for what actually exists.

## Allowed files

Create or edit only:

```text
soft-mmu-68k/docs/process/README.md

soft-mmu-68k/docs/process/packets/README.md
soft-mmu-68k/docs/process/packets/packet-registry.md
soft-mmu-68k/docs/process/packets/PROC1A-durable-process-record-framework.md

soft-mmu-68k/docs/process/memoranda/README.md
soft-mmu-68k/docs/process/memoranda/briefings/README.md

soft-mmu-68k/docs/process/ai/packet-and-pr-protocol.md
```

Optional navigation-only edits:

```text
soft-mmu-68k/docs/process/ai/README.md
soft-mmu-68k/docs/README.md
```

Use the optional files only if a concise link is genuinely needed.

## Forbidden files and areas

Do not edit:

```text
AGENTS.md
.github/

soft-mmu-68k/rtl/
soft-mmu-68k/tb/
soft-mmu-68k/tb/common/golden_vectors/
soft-mmu-68k/scripts/
soft-mmu-68k/scripts/matlab/
soft-mmu-68k/fpga/

soft-mmu-68k/docs/design/
soft-mmu-68k/docs/wiki/
soft-mmu-68k/docs/tutorial/
soft-mmu-68k/docs/roadmap/
soft-mmu-68k/docs/refs/
```

Do not modify any `MTC1` MATLAB collateral.

Do not change GitHub Actions or workflow triggers.

Do not create historical packet definitions other than `PROC1A`.

Do not create historical memoranda in this packet.

Do not ingest prior briefing artifacts in this packet.

Those are `PROC1B` concerns.

## Required repository structure

Create:

```text
soft-mmu-68k/docs/process/
├── README.md
├── packets/
│   ├── README.md
│   ├── packet-registry.md
│   └── PROC1A-durable-process-record-framework.md
└── memoranda/
    ├── README.md
    └── briefings/
        └── README.md
```

Existing process directories and files remain where they are.

Do not reorganize existing documentation.

## Requirement 1 — process index

Create `soft-mmu-68k/docs/process/README.md`.

It must explain the purpose of `ai/`, `packets/`, `memoranda/`, and `memoranda/briefings/` and preserve this distinction:

```text
packets define authorized work
memoranda record project/process rationale
briefings preserve substantive decision inputs
PRs/commits/CI preserve implementation and review evidence
design docs preserve technical architecture/compatibility decisions
```

Avoid duplicating detailed rules already documented elsewhere. Link to them.

## Requirement 2 — canonical packet records

Create `soft-mmu-68k/docs/process/packets/README.md` and define the official packet-record mechanism.

### Status vocabulary

Use:

```text
Proposed
Approved
Ready
Active
Review
Merged
Deferred
Superseded
Cancelled
```

### Packet-definition location

Official packet definitions belong at:

```text
soft-mmu-68k/docs/process/packets/<packet-id>-<short-title>.md
```

A packet definition should record, as applicable: packet identity, title, status, owner, branch, goal, dependencies, allowed files, forbidden files, requirements, acceptance criteria, verification, closeout, known deferrals, and decision/memorandum links.

An approved packet definition defines the authorized scope of work. It does not prove the work was implemented. The PR and reviewed/merged repository state establish what was actually implemented.

### Material packet changes

If an approved packet changes materially:

```text
record the reason in a memorandum
update the registry
update or supersede the packet definition
retain the old historical relationship
```

Do not silently rewrite packet history.

## Requirement 3 — packet registry framework

Create `soft-mmu-68k/docs/process/packets/packet-registry.md` with columns:

```text
Packet
Title
Status
Depends on
Owner
Branch / PR
Decision source
Packet definition
Notes
```

The registry is a compact project index. It must not duplicate full packet definitions or PR descriptions.

### PROC1A seed

Seed the registry with **only `PROC1A`** in this packet and record its current pre-merge state accurately.

Do not mark it `Merged` before merge.

Do not backfill TC1A, TC1B, CTRL1B, HW1A, MTC1, or other historical/current packets in `PROC1A`.

That evidence-backed bootstrap belongs to `PROC1B`.

Add a note that the registry is intentionally incomplete until the bounded bootstrap/backfill packet is completed.

## Requirement 4 — preserve this packet definition

Create `soft-mmu-68k/docs/process/packets/PROC1A-durable-process-record-framework.md` and preserve this approved packet definition substantively.

Repository-relative links and formatting may be normalized, but the authorized scope must not be silently broadened or reduced.

This intentionally bootstraps the framework using its own packet.

## Requirement 5 — management memoranda framework

Create `soft-mmu-68k/docs/process/memoranda/README.md` and define memoranda as durable records of **why** a project/process decision was made.

Appropriate memorandum subjects include creation of a packet series, packet sequencing/dependency changes, packet split or combination decisions, packet deferral/cancellation, accepted process risk, manager/coach responsibility changes, new verification/tool workflow adoption, resolution of cross-manager recommendations, and supersession of earlier process decisions.

Do not use memoranda as substitutes for technical architecture documents under `soft-mmu-68k/docs/design/`.

### Memo filename

Use:

```text
MEMO-<year>-<sequence>-<short-title>.md
```

### Required memo fields

Define:

```text
Subject
Date
Status
Decision owner
Participants / consulted roles
Context
Decision
Packet effects
Rationale
Dependencies / risks
Follow-up required
Supersedes / superseded by
Related briefing records
Related PRs / packet definitions / design docs
```

### Memo authority

A memorandum records approved management/process rationale at a point in time. It does not override later reviewed/merged repository behavior.

`PROC1A` creates the memorandum framework but does not create historical memoranda.

## Requirement 6 — substantive briefing preservation framework

Create `soft-mmu-68k/docs/process/memoranda/briefings/README.md`.

A **substantive briefing** is a project deliverable prepared for another project participant that materially supports later review or decision-making.

Examples include a briefing that transfers project state, recommends a decision, requests authorization, proposes packet scope or sequencing, hands off responsibility, summarizes review findings for another decision-maker, or materially affects later project/process work.

### Standing preservation rule

When a substantive briefing is used for project decision-making, preserve it as a repository briefing record.

The record should preserve the substantive source content rather than only a later summary. Do not silently rewrite the originating participant's recommendation. If formatting is normalized, note that formatting was normalized.

### Not every chat message is a briefing

Do not archive ordinary conversational exchanges, brainstorming fragments, or incidental chat messages merely because they occurred during project work.

The rule applies to substantive briefing deliverables intended to transfer, recommend, review, authorize, or hand off durable project state.

### Briefing filename

Use:

```text
BRIEF-<year>-<sequence>-<short-title>.md
```

### Required briefing metadata

Define:

```text
Title
Date or source date, when known
Originating role
Recipient / decision role
Record status: Source briefing
Related packet(s)
Related memorandum, when applicable
Source/provenance note
```

A briefing is an input record. It is not itself final approval unless the Project Lead explicitly made it so.

### Existing briefings

Do not ingest existing briefing artifacts in `PROC1A`.

`PROC1B` will preserve the currently identified MTC1 and process-gap briefings using their actual source files.

## Requirement 7 — authority chain

Document:

```text
briefing record
    preserves substantive decision input
        ↓
management memorandum
    explains WHY a process/sequence decision was approved
        ↓
packet definition
    defines WHAT work is authorized
        ↓
branch / pull request
    records WHAT was actually changed and reviewed
        ↓
merged repository state
    remains final authority for WHAT NOW EXISTS
```

Also document conflict precedence:

```text
current merged repository state
    >
reviewed PR / reviewed commit evidence
    >
approved packet definition for authorized scope
    >
approved management memorandum for process rationale
    >
preserved briefing record as decision input
    >
chat recollection / generic model memory
```

Technical architecture and compatibility decisions remain in `soft-mmu-68k/docs/design/`.

## Requirement 8 — sequence and supersession rule

Sequence changes must not silently rewrite history.

Example:

```text
Original:
M4 -> M5 -> M6

Revised:
M4 -> M5A -> M5B -> M6
```

Expected durable action:

```text
record the management decision
update the registry
mark replaced packet definitions Superseded when applicable
link the old and new records
retain the reason for the change
```

## Requirement 9 — focused packet/PR protocol integration

Make a small update to `soft-mmu-68k/docs/process/ai/packet-and-pr-protocol.md`.

Do not rewrite the existing lifecycle.

Add concise cross-references stating that approved packet definitions are preserved under `docs/process/packets/`; packet status/dependencies are tracked by `packet-registry.md`; material management/process rationale belongs under `docs/process/memoranda/`; substantive briefing inputs used by those decisions belong under `docs/process/memoranda/briefings/`; historical records must not be reconstructed from memory when reliable evidence is unavailable; and durable record updates are part of packet closeout when the packet changes project state.

Preserve the existing review, amendment, dispensation, and merge rules.

## Requirement 10 — keep the framework lightweight

Maintain this boundary:

```text
packet definition = authorized work
registry = compact index
briefing = source input
memorandum = management rationale
PR = implementation/review evidence
design doc = technical engineering decision
```

Do not duplicate full PR diffs, full CI logs, entire chat transcripts, large source documents, or technical design records. Link durable evidence instead.

## Deferred follow-up — PROC1B

`PROC1A` explicitly defers historical/current record bootstrap to:

```text
PROC1B — Verified Packet and Briefing Record Bootstrap
```

Expected `PROC1B` scope, subject to separate authorization:

```text
preserve the MTC1 MATLAB Toolchain Coach briefing
preserve the Documentation Manager process-gap proposal
preserve other specifically approved substantive briefing artifacts
create the corresponding management memoranda
seed verified packet history from repository/PR evidence
add MTC1 and other current packet definitions when approved source files are available
```

`PROC1B` must use source files and repository/PR evidence. It must not reconstruct history from memory.

## Acceptance criteria

`PROC1A` is complete when:

- `docs/process/README.md` exists and distinguishes the record types.
- `docs/process/packets/README.md` defines canonical packet records.
- `docs/process/packets/packet-registry.md` exists and is seeded only with PROC1A.
- `docs/process/packets/PROC1A-durable-process-record-framework.md` preserves this packet.
- `docs/process/memoranda/README.md` defines memorandum rules.
- `docs/process/memoranda/briefings/README.md` defines briefing preservation.
- the authority/conflict chain is documented.
- sequence/supersession rules are documented.
- `packet-and-pr-protocol.md` contains focused links to the new framework.
- no historical packet/briefing reconstruction occurs.
- no MTC1-owned files change.
- no RTL, testbench, MATLAB, FPGA, workflow, design, wiki, tutorial, roadmap, or reference collateral changes occur.
- Markdown changes pass `git diff --check`.
- the packet concludes with commit, push, and pull request.

## Verification

Run from repository root:

```bash
git status --short --branch
git diff --stat
git diff --check
```

Then review the focused diff for the changed `PROC1A` files.

If optional navigation files were changed, include them in review.

## HDL / MATLAB / FPGA verification disposition

Do not run local HDL regression.

Report exactly:

```text
SKIPPED: documentation/process-only packet; no RTL, testbench, HDL-consumed vector, MATLAB, script, FPGA, or workflow changes.
```

Do not run MATLAB.

Do not run Vivado.

Do not program hardware.

If GitHub Actions runs automatically after the PR is opened, report that result separately.

Do not modify workflow triggers inside `PROC1A`.

## Commit

Stage only the files intentionally changed for `PROC1A`.

Do not use `git add .`.

Before commit:

```bash
git status --short --branch
git diff --cached --stat
git diff --cached --check
git diff --cached
```

Recommended commit message:

```text
PROC1A: add durable process record framework
```

## Push

Push branch `docs/proc1a-process-record-framework`.

## Pull request

Create a PR titled:

```text
PROC1A: add durable process record framework
```

The PR body must identify packet, owner, classification, purpose, historical backfill deferral, MTC1 relationship, no RTL/testbench/MATLAB/FPGA/workflow changes, skipped local HDL regression, exact changed files, verification performed, skipped checks, known limitations, and the PROC1B follow-up.

## Review and approval

Required review sequence:

```text
Documentation Manager implementation/self-report
        ↓
MMU Dev Manager review
        ↓
Toolchain Coach review if packet-and-pr workflow wording materially changes
        ↓
DEV Manager Dispensation
        ↓
Project Lead merge approval / merge
```

The Documentation Manager must not self-approve the PR for merge.

DEV Manager Dispensation is commit-specific. Any later push/amend after review requires re-review.

## Merge

Do not merge until required review is complete, reviewed HEAD still matches the PR head, `git diff --check` passed, skipped HDL tests are accurately reported, automatic CI state is known, and the Project Lead permits merge.

Do not mark the registry entry `Merged` before the merge actually occurs.

A post-merge registry-status update may be handled by `PROC1B` or another smallest-authorized process update rather than falsifying pre-merge state.

## Expected final report

Return:

```text
Packet:
Branch:
Commit:
PR number / URL:
Files changed:
Files intentionally not touched:
Framework created:
Registry seed:
Verification commands/results:
HDL tests not run and reason:
MATLAB not run:
Vivado/hardware not run:
Automatic CI result, if any:
Known limitations:
PROC1B follow-up:
```

## Stop conditions

Stop and report if `AGENTS.md` cannot be read; `main` cannot be updated safely; the branch collides with unrelated work; implementation requires files outside the allowed list; historical reconstruction becomes necessary; a prior briefing must be paraphrased from memory; MTC1-owned files would need modification; `.github/` workflow changes would be required; architecture or compatibility decisions would need to be invented; or the packet grows into PROC1B historical/bootstrap scope.

## Parallel rule with MTC1

`PROC1A` is explicitly authorized in parallel with `MTC1`.

`PROC1A` owns process/documentation framework files only.

`MTC1` owns its approved MATLAB reference-model files.

Neither packet depends on the other for implementation.

The only relationship is project sequencing and future durable recording.

## DEV Manager authorization

**AUTHORIZED.**

The **MMU Documentation Manager** is assigned as the owner and implementation role for `PROC1A`.

This corrected packet supersedes the earlier oversized PROC1 draft before implementation begins.

The earlier draft should not be treated as an active authorized implementation packet.

`PROC1B` is intentionally deferred as a separate smaller packet for evidence-backed briefing preservation and packet-history bootstrap after the framework exists.
