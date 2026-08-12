# SM68861 Process Documentation

This directory contains durable process documentation for the SM68861 / `soft-mmu-68k` project.

The process record separates live packet control, durable governance, implementation evidence, and technical design records so that later reviewers can reconstruct what was decided without relying on chat memory.

## Areas

- [`ai/`](ai/) — AI-assisted project operations, role boundaries, role handoff, and packet/PR lifecycle rules.
- [`packets/`](packets/) — historical committed packet definitions plus guidance for packet records. For packets created after PROC2A, GitHub Issues are the live operational packet control plane.
- [`memoranda/`](memoranda/) — exceptional durable project/process rationale for consequential governance, sequencing, verification-policy, waiver, or role decisions.
- [`memoranda/briefings/`](memoranda/briefings/) — selectively preserved decision-critical source briefings.
- [`hardware/`](hardware/) — hardware-facing process notes and repeatability plans.
- [`human-guided-workflows/`](human-guided-workflows/) — selectively preserved historical human-guided execution and learning workflows.

## Control and record boundaries

Use each record type for one purpose:

```text
packet Issue      = current operational packet scope and status
Dev Manager / Project Lead Issue comment
                  = explicit approval or amendment decision
PR/commit/CI      = implementation, review, and verification evidence
merged repository = final authority for implemented state
process/design doc= durable governance or technical knowledge
memorandum        = exceptional retained management/process rationale
briefing record   = exceptional retained decision input
```

Do not duplicate mutable GitHub branch/PR/merge state into a hand-maintained Markdown status database. Do not copy full PR diffs, CI logs, chat transcripts, source manuals, or technical design records into process records. Link durable evidence instead.

The legacy [`packets/packet-registry.md`](packets/packet-registry.md) is a frozen bootstrap snapshot, not the live packet status source. Current packet state is read from GitHub Issues and linked PR/commit/CI evidence.

Technical architecture and compatibility decisions remain under [`../design/`](../design/).

## Authority and precedence

When records conflict, use this order:

```text
current merged repository state
>
reviewed PR / reviewed commit / CI evidence
>
current approved packet Issue body plus Dev Manager or Project Lead decision comments
>
committed packet definition, when one exists
>
approved management memorandum
>
preserved source briefing
>
chat recollection / generic model memory
```

The Issue controls authorized operational work; it does not override merged code, reviewed tests, or durable technical evidence.

The packet lifecycle, approval/amendment rules, review, Dispensation, merge, and closeout rules are defined by [`ai/packet-and-pr-protocol.md`](ai/packet-and-pr-protocol.md).
