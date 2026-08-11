# AI-assisted project operations

This directory contains process documentation for AI-assisted work on `soft-mmu-68k`.

The durable source of truth for this project is the repository plus its linked GitHub packet/PR evidence: committed source files, `AGENTS.md`, packet Issues, pull requests, reviewed commits, CI results, and project documentation. Chat sessions are operational tools. They may be retired, replaced, or restarted without changing the project baseline.

## Documents

- [Role handoff protocol](manager-handoff-protocol.md) — repeatable retirement and bootstrap process for managers, coaches, and the MMU Packet Coordinator. The filename is retained for link stability.
- [Role registry](role-registry.md) — current role boundaries, including the MMU Packet Coordinator, and model/reasoning tier guidance.
- [Packet and PR protocol](packet-and-pr-protocol.md) — GitHub-Issue packet control, approval/amendment history, PR review expectations, DEV Manager Dispensation, and closeout rules.

## Packet control after PROC2A

For packets created after PROC2A, one GitHub Issue is the live operational packet record. The MMU Packet Coordinator maintains administrative packet state from Issues, PRs, commits, CI, and durable docs; the role does not own technical scope, sequencing decisions, Dispensation, or merge authority.

The legacy Markdown packet registry is frozen and is not the live status source.

## Operating rule

When there is a conflict between chat memory and GitHub/repository evidence, prefer durable evidence using the precedence documented in the packet protocol. If durable evidence is incomplete or contradictory, document the uncertainty and request clarification before changing scope, code, tests, scripts, compatibility claims, or packet state.
