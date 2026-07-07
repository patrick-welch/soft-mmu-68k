# Manager handoff protocol

## Purpose

This protocol defines how `soft-mmu-68k` retires a long-running role-specific chat and bootstraps its replacement.

The goal is to reduce project-lead reconstruction load, preserve project continuity, make chat retirement auditable, and establish a role-bounded handoff that is grounded in repository evidence rather than rolling chat memory.

## Principles

- The repository is durable; chat context is temporary.
- A retiring chat performs extraction only, not new technical decision-making.
- A replacement chat earns authority through a bootstrap audit before directing packet work.
- Handoffs must preserve packet scope, PR state, toolchain state, known risks, and deferred work.
- Handoffs must distinguish confirmed repository facts from chat-derived summaries.

## Retirement triggers

Retire or replace a manager or coach chat when any of the following occurs:

- rolling context is exhausted or unreliable
- the chat begins confusing project state, branches, or packet history
- the role has accumulated too much mixed responsibility
- the project lead cannot quickly determine what the chat believes is true
- repeated hand repair is required after the chat gives stale or overconfident guidance
- a major phase transition requires a clean role boundary

Retirement does not imply failure. It is a normal project-maintenance action.

## Source-of-truth order

Use this order when reconstructing state:

1. GitHub `main` and active PR branches
2. `AGENTS.md`
3. merged PRs, reviewed commits, and CI results
4. files under `soft-mmu-68k/`
5. project docs, including `soft-mmu-68k/docs/refs/source-materials.md`
6. active packet briefs and PR descriptions
7. chat handoff summaries
8. unmerged or informal chat notes

If sources conflict, report the conflict and stop before making decisions that affect scope, compatibility, tests, or merge approval.

## Old-manager handoff prompt

Use this prompt when retiring a role-specific manager or coach chat:

```text
You are being retired from the soft-mmu-68k project role: <role name>.

Perform extraction only. Do not make new technical decisions.
Do not assign new packets.
Do not approve merges.
Do not reinterpret Motorola-family compatibility.

Return a handoff summary with:

1. Role name and version being retired
2. Current scope of authority
3. Active branches and PRs you believe are relevant
4. Recently completed packets
5. Packets in progress
6. Known blockers or unresolved decisions
7. Toolchain state you believe matters
8. Source files or docs you believe are authoritative
9. Compatibility claims that are confirmed
10. Compatibility claims that are deferred or uncertain
11. Recommended first audit tasks for the replacement role
12. Any warnings about stale assumptions in your own context

Mark each item as one of:

- repository-confirmed
- PR-confirmed
- CI-confirmed
- chat-derived
- uncertain
```

## New-manager bootstrap prompt

Use this prompt when starting a replacement manager or coach chat:

```text
You are <role name> for the soft-mmu-68k project.

Before taking authority, perform a bootstrap audit.
Do not assign packets, approve merges, or make compatibility decisions yet.

Read or inspect:

1. AGENTS.md
2. soft-mmu-68k/docs/process/ai/README.md
3. soft-mmu-68k/docs/process/ai/manager-handoff-protocol.md
4. soft-mmu-68k/docs/process/ai/role-registry.md
5. soft-mmu-68k/docs/process/ai/packet-and-pr-protocol.md
6. The current open PR list
7. The most recent merged PRs relevant to your role
8. The retiring manager handoff summary, if provided

Return:

1. What role you are assuming
2. What authority you do and do not have
3. Repository state inspected
4. Active PRs relevant to your role
5. Current risks or unknowns
6. What you need from the project lead before taking action
7. A proposed first low-risk task

Do not proceed beyond the audit until the project lead accepts your role state.
```

## Bootstrap audit requirements

A replacement chat must confirm:

- current default branch
- current role boundary
- active PRs in its area
- current regression commands relevant to its area
- whether any pending DEV Manager Dispensation applies
- whether any handoff claims are only chat-derived
- whether its first task is read-only, planning-only, or implementation-directed

## First-task rule for replacement chats

The first task for a replacement manager or coach should be low risk.

Preferred first tasks:

- summarize current role boundaries
- review an open PR without approving it
- produce a packet brief for human review
- compare a handoff summary against repository state

Avoid as first tasks:

- merge approval
- broad architecture decisions
- Motorola-family compatibility reinterpretation
- multi-file implementation packets
- destructive Git repair

## Naming and versioning convention

Use monotonically increasing role names for replacement chats:

```text
MMU Dev Manager 001
MMU Dev Manager 002
MMU Toolchain Coach 001
MMU Toolchain Coach 002
```

When a role is retired, keep the old role name in the handoff summary. The new role must identify the retired role it is replacing.

## Retirement authority

The project lead decides when a chat is retired.

A retiring chat may recommend retirement, but it must not assign its own replacement or transfer authority without project-lead confirmation.
