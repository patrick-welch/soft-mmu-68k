# Role handoff protocol

> The filename `manager-handoff-protocol.md` is retained for repository-link stability. This protocol now covers managers, coaches, and the MMU Packet Coordinator.

## Purpose

This protocol defines how `soft-mmu-68k` retires a long-running role-specific chat and bootstraps its replacement.

The goal is to reduce Project Lead reconstruction load, preserve project continuity, make chat retirement auditable, and establish a role-bounded handoff grounded in GitHub and repository evidence rather than rolling chat memory.

## Principles

- The repository and GitHub evidence are durable; chat context is temporary.
- A retiring chat performs extraction only, not new technical decision-making.
- A replacement chat earns authority through a bootstrap audit before directing packet work.
- Handoffs must preserve packet scope, PR state, toolchain state, known risks, and deferred work.
- Handoffs must distinguish confirmed durable facts from chat-derived summaries.
- The MMU Packet Coordinator is a control desk, not an authority source.

## Retirement triggers

Retire or replace a role-specific manager, coach, or Packet Coordinator chat when any of the following occurs:

- rolling context is exhausted or unreliable;
- the chat begins confusing project state, branches, Issues, or packet history;
- the role has accumulated too much mixed responsibility;
- the Project Lead cannot quickly determine what the chat believes is true;
- repeated hand repair is required after stale or overconfident guidance;
- a major phase transition requires a clean role boundary.

Retirement does not imply failure. It is a normal project-maintenance action.

## Source-of-truth order

Use this order when reconstructing state:

1. current merged repository state on `main`;
2. reviewed PR / reviewed commit / CI evidence;
3. current approved packet Issue body plus explicit Dev Manager or Project Lead decision comments;
4. `AGENTS.md` and committed process/design documentation;
5. committed packet definition, when one exists;
6. approved management memorandum;
7. preserved source briefing;
8. chat handoff summaries and informal notes.

If sources conflict, report the conflict and stop before making decisions that affect scope, compatibility, tests, packet state, or merge approval.

## Old-role handoff prompt

Use this prompt when retiring a role-specific manager, coach, or Packet Coordinator chat:

```text
You are being retired from the soft-mmu-68k project role: <role name>.

Perform extraction only. Do not make new technical decisions.
Do not create or approve new packets.
Do not approve merges.
Do not reinterpret Motorola-family compatibility.

Return a handoff summary with:

1. Role name and version being retired
2. Current scope of authority
3. Open packet Issues relevant to the role
4. Active branches and PRs you believe are relevant
5. Recently completed packets
6. Packets in progress
7. Known blockers or unresolved decisions
8. Toolchain state you believe matters
9. Source files or docs you believe are authoritative
10. Compatibility claims that are confirmed
11. Compatibility claims that are deferred or uncertain
12. Recommended first audit tasks for the replacement role
13. Any warnings about stale assumptions in your own context

Mark each item as one of:

- repository-confirmed
- Issue-confirmed
- PR-confirmed
- CI-confirmed
- chat-derived
- uncertain
```

## New-role bootstrap prompt

Use this prompt when starting a replacement manager, coach, or Packet Coordinator chat:

```text
You are <role name> for the soft-mmu-68k project.

Before taking authority, perform a bootstrap audit.
Do not create/approve packets, approve merges, resequence work, or make compatibility decisions beyond your documented role.

Read or inspect:

1. AGENTS.md
2. soft-mmu-68k/docs/process/ai/README.md
3. soft-mmu-68k/docs/process/ai/manager-handoff-protocol.md
4. soft-mmu-68k/docs/process/ai/role-registry.md
5. soft-mmu-68k/docs/process/ai/packet-and-pr-protocol.md
6. Current open packet Issues relevant to your role
7. Current open PRs relevant to your role
8. Recent merged PRs / closed packet Issues relevant to current sequence
9. The retiring-role handoff summary, if provided

Return:

1. What role you are assuming
2. What authority you do and do not have
3. Durable state inspected
4. Active packet Issues / PRs relevant to your role
5. Current risks or unknowns
6. What you need from the Project Lead before taking action
7. A proposed first low-risk task

Do not proceed beyond the audit until the Project Lead accepts your role state.
```

## Bootstrap audit requirements

A replacement chat must confirm:

- current default branch and current merged HEAD;
- current role boundary;
- active packet Issues and PRs in its area;
- current regression commands relevant to its area;
- whether any pending DEV Manager Dispensation applies;
- whether any handoff claims are only chat-derived;
- whether its first task is read-only, planning-only, or implementation-directed.

## Packet Coordinator bootstrap requirements

A replacement MMU Packet Coordinator must additionally:

- inspect all open Issues carrying the `packet` label when that label exists;
- inspect recently closed packet Issues relevant to the current sequence;
- inspect linked PRs and reviewed HEADs;
- reconstruct the Ready, Active, Review, Blocked, and Deferred queues from durable evidence;
- detect Issue/PR/commit contradictions and report them;
- report uncertainty and escalate missing decisions;
- never create, approve, resequence, close, or materially normalize a packet based only on chat memory.

If the packet labels have not yet been created, identify packet Issues from their `[PACKET]` title convention and linked process evidence, report the administrative gap, and do not invent status.

## First-task rule for replacement chats

The first task for a replacement role should be low risk.

Preferred first tasks:

- summarize current role boundaries;
- reconstruct the current packet queue from GitHub evidence;
- review an open PR without approving it;
- compare a handoff summary against durable state;
- identify contradictions without editing them.

Avoid as first tasks:

- merge approval;
- broad architecture decisions;
- Motorola-family compatibility reinterpretation;
- multi-file implementation packets;
- destructive Git repair;
- Packet Coordinator status changes not already authorized by explicit decision evidence.

## Naming and versioning convention

Use monotonically increasing role names for replacement chats:

```text
MMU Dev Manager 001
MMU Dev Manager 002
MMU Toolchain Coach 001
MMU Toolchain Coach 002
MMU Packet Coordinator 001
MMU Packet Coordinator 002
```

When a role is retired, keep the old role name in the handoff summary. The new role must identify the retired role it is replacing.

## Retirement authority

The Project Lead decides when a chat is retired.

A retiring chat may recommend retirement, but it must not assign its own replacement or transfer authority without Project Lead confirmation.
