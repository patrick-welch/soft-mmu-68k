# Management Memoranda

Management memoranda are exceptional durable records of **why** a consequential project/process decision was made.

They preserve approved management rationale without replacing packet Issues, implementation evidence, or technical architecture documentation.

## Appropriate memorandum subjects

Use a memorandum for decisions such as:

- creation or retirement of a project role;
- material cross-packet sequencing or dependency changes;
- verification-policy changes;
- accepted process risk or a formal waiver;
- material packet split or combination decisions;
- durable governance changes;
- resolution of consequential cross-manager disagreement;
- supersession of an earlier consequential process decision.

Do not use memoranda as substitutes for technical architecture or compatibility records under `soft-mmu-68k/docs/design/`.

## Events that do not require a memorandum

A memorandum is not required merely because:

- a packet was approved;
- a packet moved to Review;
- a pull request merged;
- an ordinary packet amendment was made;
- an implementation owner changed;
- a routine follow-up packet was identified.

Those events belong in the controlling packet Issue and PR history.

## Filename

Use:

```text
MEMO-<year>-<sequence>-<short-title>.md
```

## Recommended fields

When a memorandum is warranted, record as applicable:

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
- **Related packet Issues / PRs / packet definitions / design docs**

## Authority

A memorandum records approved management/process rationale at a point in time. It does not authorize implementation outside an approved packet Issue and does not override later reviewed or merged repository behavior.

Use this relationship:

```text
packet Issue + explicit decision comments
    authorize and control current operational packet scope
        ↓
branch / pull request / CI
    record what was changed, tested, and reviewed
        ↓
merged repository state
    remains final authority for what now exists

memorandum
    preserves exceptional WHY when the rationale itself has durable value

briefing record
    preserves exceptional source input when retention criteria are met
```

## Sequence and supersession

Consequential sequence changes must not silently rewrite history. Record the approval/amendment in the packet Issue. Create or update a memorandum only when the change meets the retention threshold above.

## Lightweight record rule

A memorandum should capture the decision and rationale, not reproduce an entire chat transcript, PR diff, CI log, source manual, or design document. Link durable evidence instead.
