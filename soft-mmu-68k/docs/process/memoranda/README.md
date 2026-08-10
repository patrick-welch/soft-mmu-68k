# Management Memoranda

Management memoranda are durable records of **why** a project/process decision was made.

They preserve approved management rationale without replacing packet definitions, implementation evidence, or technical architecture documentation.

## Appropriate memorandum subjects

Use a memorandum for decisions such as:

- creation of a packet series;
- packet sequencing or dependency changes;
- packet split or combination decisions;
- packet deferral or cancellation;
- accepted process risk;
- manager or coach responsibility changes;
- adoption of a verification or tooling workflow;
- resolution of cross-manager recommendations;
- supersession of earlier process decisions.

Do not use memoranda as substitutes for technical architecture or compatibility records under `soft-mmu-68k/docs/design/`.

## Filename

Use:

```text
MEMO-<year>-<sequence>-<short-title>.md
```

## Required fields

Each memorandum should record:

- **Subject**
- **Date**
- **Status** — Proposed, Approved, or Superseded
- **Decision owner**
- **Participants / consulted roles**
- **Context**
- **Decision**
- **Packet effects**
- **Rationale**
- **Dependencies / risks**
- **Follow-up required**
- **Supersedes / superseded by**
- **Related briefing records**
- **Related PRs / packet definitions / design docs**

## Authority

A memorandum records approved project/process rationale at a point in time. It does not authorize implementation outside an approved packet and does not override later reviewed or merged repository behavior.

Use this relationship:

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

## Sequence and supersession

Sequence changes must not silently rewrite history. When a sequence changes, record the decision, update the packet registry, mark replaced packet definitions `Superseded` when applicable, link old and new records, and retain the reason for the change.

## Lightweight record rule

A memorandum should capture the decision and rationale, not reproduce an entire chat transcript, PR diff, CI log, source manual, or design document. Link durable evidence instead.

`PROC1A` creates this framework only. Historical memoranda are deferred to separately authorized evidence-backed work.
