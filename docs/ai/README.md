# AI-assisted project operations

This directory contains process documentation for AI-assisted work on `soft-mmu-68k`.

The durable source of truth for this project is the repository itself: committed source files, `AGENTS.md`, pull requests, reviewed commits, CI results, and project documentation. Chat sessions are operational tools. They may be retired, replaced, or restarted without changing the project baseline.

## Documents

- [Manager handoff protocol](manager-handoff-protocol.md) - repeatable retirement and bootstrap process for long-running manager or coach chats.
- [Role registry](role-registry.md) - current role boundaries and model/reasoning tier guidance.
- [Packet and PR protocol](packet-and-pr-protocol.md) - packet lifecycle, PR review expectations, and DEV Manager Dispensation templates.

## Operating rule

When there is a conflict between chat memory and repository evidence, prefer the repository evidence. If repository evidence is incomplete, document the uncertainty and request clarification before changing code, tests, scripts, or compatibility claims.
