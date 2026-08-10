# Source Briefing Record — Process Record Proposal

- **Title:** Process Record Proposal — Packet Registry and Management Memoranda
- **Date / source date:** 2026-08-09 — the source file does not state an explicit date; PROC1B uses the Project Lead's project-local date.
- **Originating role:** MMU Documentation Manager
- **Recipient / decision role:** Project Lead
- **Record status:** Source briefing
- **Related packet(s):** `PROC1A`, `PROC1B`
- **Related memorandum:** [MEMO-2026-002 — Process record framework adoption](../MEMO-2026-002-process-record-framework-adoption.md)
- **Source/provenance note:** Preserved from the Project Lead-supplied source artifact `SM68861_Packet_Registry_and_Memoranda_Proposal.md`. Later decisions, including substantive-briefing preservation and the PROC1A/PROC1B split, are intentionally not folded back into the source proposal. Repository formatting is normalized to LF line endings only.

---

## Preserved source briefing

# Process Record Proposal — Packet Registry and Management Memoranda

## Current state

The repository already defines **how packets are supposed to work**, but it does not yet provide one canonical place that records the complete set of official packet definitions, dependencies, sequencing decisions, and management rationale.

Current durable process documents include:

- `soft-mmu-68k/docs/process/ai/packet-and-pr-protocol.md` — defines the packet lifecycle, packet brief format, review, amendment, dispensation, merge, and durable-state update.
- `soft-mmu-68k/docs/process/codex_packet_workflow.md` — defines one branch/PR per packet, packet scope discipline, verification, and says packet IDs should match a tracker or assignment label **when one exists**.
- `soft-mmu-68k/docs/process/ai/role-registry.md` — assigns packet definition and sequencing to the MMU Dev Manager.

Today, the actual reasoning behind packet creation and ordering is therefore distributed among chats, PR descriptions/comments, handoff notes, and whatever durable design/process documentation happens to be updated afterward.

That is adequate for executing an individual packet, but not ideal for reconstructing **why the project chose a sequence of packets** or how one manager/coach briefed another.

## Recommendation

Add two related durable process areas under the existing project documentation tree:

```text
soft-mmu-68k/docs/process/
├── README.md
├── packets/
│   ├── README.md
│   ├── packet-registry.md
│   └── <packet-id>-<short-title>.md
└── memoranda/
    ├── README.md
    └── MEMO-<year>-<sequence>-<short-title>.md
```

These serve different purposes and should not be collapsed into one kind of document.

## 1. `docs/process/packets/` — canonical packet record

This is the authoritative record of **what work has been defined and in what order**.

### `packet-registry.md`

Maintain a compact project-wide ledger such as:

| Packet | Title | Status | Depends on | Branch / PR | Decision source |
|---|---|---|---|---|---|
| M1 | MMUSR status baseline | Merged | — | PR #... | MEMO-2026-001 |
| M2 | PTEST behavior | Planned | M1 | — | MEMO-2026-002 |
| M3 | PLOAD behavior | Deferred | M2 | — | MEMO-2026-002 |

Suggested status vocabulary:

- Proposed
- Approved
- Ready
- Active
- Review
- Merged
- Deferred
- Superseded
- Cancelled

The registry should record sequence and dependencies, not duplicate implementation details.

### Individual packet definition

When a packet becomes official, preserve its approved brief as:

```text
soft-mmu-68k/docs/process/packets/<packet-id>-<short-title>.md
```

The file should contain the packet identity, goal, branch, allowed/forbidden files, requirements, acceptance criteria, verification, and intended closeout.

If the packet changes materially before implementation, update the durable packet definition or explicitly supersede it. Do not rely on a chat rewrite as the only authoritative definition.

## 2. `docs/process/memoranda/` — management decision record

Use memoranda for **why** project-management or engineering-management decisions were made.

Appropriate memorandum subjects include:

- creation of a new packet series;
- packet sequencing or dependency changes;
- splitting or combining proposed work;
- deferring a packet;
- accepting a known risk;
- changing manager/coach responsibilities;
- retiring or replacing an agent role;
- adopting a new verification or tool workflow;
- resolving disagreement between manager recommendations;
- cross-manager briefings that materially affect future work.

A memorandum should not replace an architecture/design record. Technical architectural decisions still belong under `soft-mmu-68k/docs/design/`. Memoranda explain project/process decisions and may link to the relevant design record.

### Suggested memorandum format

```text
MEMO-2026-001-packet-sequence-after-milestone-1.md
```

Each memo should state:

1. **Subject**
2. **Date**
3. **Status** — Proposed / Approved / Superseded
4. **Decision owner**
5. **Participants / consulted roles**
6. **Context**
7. **Decision**
8. **Packet effects** — created, reordered, deferred, superseded
9. **Rationale**
10. **Dependencies / risks**
11. **Follow-up required**
12. **Supersedes / superseded by**, if applicable
13. **Related PRs, packet files, design docs, or source material**

The memo should capture the decision, not reproduce an entire chat transcript.

## Authority rule

Use the following authority relationship:

```text
memorandum
    explains WHY a packet or sequence was approved
        ↓
packet definition
    defines WHAT the implementation packet is authorized to do
        ↓
branch / PR
    records WHAT was actually implemented and reviewed
        ↓
merged repository state
    remains the final authority for WHAT NOW EXISTS
```

If any of these conflict, merged/current repository state remains authoritative. The memorandum is historical rationale, not permission to contradict later reviewed implementation.

## Sequence changes

Do not silently edit history when packet sequencing changes.

For example, if the original plan was:

```text
M4 -> M5 -> M6
```

and new evidence requires:

```text
M4 -> M5A -> M5B -> M6
```

record the change in a memorandum, update `packet-registry.md`, and mark any replaced packet definition as `Superseded` rather than making the old plan disappear without explanation.

This gives future managers a traceable answer to:

- What was originally planned?
- What changed?
- Who approved it?
- Why?
- What is the current sequence?

## Recommended boundary

Use:

- `docs/design/` for durable technical architecture and compatibility decisions.
- `docs/process/packets/` for official work-package definitions and sequencing.
- `docs/process/memoranda/` for project/process decision rationale and manager-to-manager briefings.
- PRs for implementation/review evidence.
- chats for discussion and drafting, not final durable state.

## Recommended next step

Create a small documentation/process packet that:

1. adds `soft-mmu-68k/docs/process/README.md`;
2. adds `soft-mmu-68k/docs/process/packets/README.md`;
3. adds `soft-mmu-68k/docs/process/packets/packet-registry.md`;
4. adds `soft-mmu-68k/docs/process/memoranda/README.md`;
5. documents the authority and update rules above;
6. seeds the registry only with packet history that can be verified from the repository and reviewed PR history.

Do **not** reconstruct old packet history from memory. Historical entries should be added only when the defining PR, branch, committed document, or other durable evidence can be verified.
