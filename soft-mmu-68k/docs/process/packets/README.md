# Packet Records

This directory preserves historical committed packet definitions and durable packet/governance records that merit repository storage.

## Post-PROC2A default rule

For packets created after PROC2A, the **GitHub Issue is the canonical live operational packet brief**.

An ordinary bounded implementation packet does not require a duplicate committed `docs/process/packets/<packet>.md` file merely because the packet exists.

Create a committed packet/specification document only when stable repository content adds clear durable value, for example:

- architectural behavior or verification plans;
- hardware procedures;
- governance/process changes;
- unusually complex or multi-stage packet specifications whose stable scope should remain in the Git tree.

Historical packet files created before PROC2A remain valid records and must not be deleted or rewritten merely to fit the new model.

## Live control plane

For new packets, use one GitHub Issue containing the current normalized approved scope and operational state.

The Issue should record, as applicable:

- packet identity and title;
- decision owner and execution owner;
- proposed/approved branch;
- dependencies;
- goal and approved scope;
- allowed and forbidden files;
- requirements and acceptance criteria;
- verification requirements;
- source/design/memorandum links;
- branch and PR links;
- blockers/deferrals;
- decision-history links;
- closeout disposition.

Approval or material amendment must be recorded in an explicit MMU Dev Manager or Project Lead Issue comment. After such a decision, the MMU Packet Coordinator may normalize the Issue body to the current approved scope while retaining Decision History links to the decision comments.

An implementation agent must not treat an unapproved body edit as authorization. If the Issue body conflicts with approval/amendment comments, stop and escalate.

## Operational status

Use Issue state plus the minimal label set documented by PROC2A:

```text
packet
status:proposed
status:ready
status:active
status:review
status:blocked
status:deferred
```

Closed Issue dispositions are stated in the closeout comment as `merged`, `cancelled`, or `superseded`.

Do not create parallel mutable status fields in committed Markdown.

## Legacy registry

[`packet-registry.md`](packet-registry.md) is retained as the **frozen legacy/bootstrap registry** produced during PROC1A/PROC1B and corrected by PROC2A. It is not the live packet-status source.

Do not add new packets to it and do not update it for routine status transitions. Query GitHub Issues and linked PR/commit/CI evidence for current packet state.

## Authority chain

```text
merged repository state
    = final authority for implemented state
        ↓
reviewed PR / reviewed commit / CI
    = implementation, verification, and review evidence
        ↓
current approved packet Issue + explicit decision comments
    = authorized operational scope
        ↓
committed packet definition, when one exists
    = durable stable packet/governance record
        ↓
approved management memorandum
    = exceptional process rationale
        ↓
preserved source briefing
    = exceptional decision input
```

Technical architecture and compatibility decisions remain under `soft-mmu-68k/docs/design/`.

## Evidence discipline

Do not reconstruct packet state from chat memory when GitHub or repository evidence is available. Do not create retrospective Issues for historical packets unless a later explicitly authorized need requires it.
