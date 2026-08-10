# SM68861 Process Documentation

This directory contains durable process documentation for the SM68861 / `soft-mmu-68k` project.

The process record separates authorization, decision rationale, source briefings, implementation evidence, and technical design records so that later reviewers can reconstruct what was decided without relying on chat memory.

## Areas

- [`ai/`](ai/) — AI-assisted project operations, role boundaries, manager handoff, and packet/PR lifecycle rules.
- [`packets/`](packets/) — canonical packet definitions plus the compact packet status and dependency registry.
- [`memoranda/`](memoranda/) — approved project/process rationale explaining why sequencing, responsibility, risk, or workflow decisions were made.
- [`memoranda/briefings/`](memoranda/briefings/) — preserved substantive briefing inputs supplied to a later decision-maker.
- [`hardware/`](hardware/) — hardware-facing process notes and repeatability plans.

## Record boundaries

Use each record type for one purpose:

```text
packet definition = WHAT work is authorized
packet registry   = compact status/dependency index
briefing record   = preserved substantive decision input
memorandum        = WHY a project/process decision was made
PR/commit/CI      = WHAT was actually changed, reviewed, and tested
design document   = technical architecture or compatibility decision
```

Do not duplicate full PR diffs, CI logs, chat transcripts, source manuals, or technical design records into process records. Link durable evidence instead.

Technical architecture and compatibility decisions remain under [`../design/`](../design/).

## Authority

Current merged repository state remains authoritative for what actually exists. For packet scope and process rationale, use the precedence and historical-record rules defined in [`packets/README.md`](packets/README.md) and [`memoranda/README.md`](memoranda/README.md).

The packet lifecycle, review, amendment, dispensation, and merge rules remain defined by [`ai/packet-and-pr-protocol.md`](ai/packet-and-pr-protocol.md).
