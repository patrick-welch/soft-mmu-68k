# Canonical Packet Records

This directory is the durable home for approved packet definitions and the project packet registry.

## Status vocabulary

Use only these packet states:

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

## Packet-definition location

Official packet definitions belong at:

```text
soft-mmu-68k/docs/process/packets/<packet-id>-<short-title>.md
```

A packet definition should record, as applicable:

- packet identity
- title
- status
- owner
- branch
- goal
- dependencies
- allowed files
- forbidden files
- requirements
- acceptance criteria
- verification
- closeout
- known deferrals
- decision or memorandum links

An approved packet definition defines the authorized scope of work. It does not prove that the work was implemented. The pull request, reviewed commit, CI/test evidence, and merged repository state establish what was actually changed and accepted.

## Packet registry

[`packet-registry.md`](packet-registry.md) is the compact project-wide index for packet status, dependency, ownership, branch/PR, decision source, and packet-definition links.

The registry must stay compact. Do not duplicate full packet definitions, PR descriptions, diffs, or test logs there.

## Material packet changes

Do not silently rewrite packet history.

If an approved packet changes materially:

1. record the reason in a management memorandum;
2. update the packet registry;
3. update or supersede the packet definition as appropriate;
4. preserve links between the old and new records.

Example:

```text
Original:
M4 -> M5 -> M6

Revised:
M4 -> M5A -> M5B -> M6
```

The durable record should retain what changed, who approved it, why it changed, and what the current sequence is.

## Authority chain

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

Conflict precedence:

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

Technical architecture and compatibility decisions remain under `soft-mmu-68k/docs/design/` and are not replaced by this process hierarchy.

## Evidence discipline

Do not reconstruct historical packet definitions from memory. Historical packet records must be grounded in reliable repository, PR, committed-document, or preserved source evidence. Bounded historical/bootstrap work is handled by a separately authorized packet.
