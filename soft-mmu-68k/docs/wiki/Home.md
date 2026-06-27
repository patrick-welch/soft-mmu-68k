# Soft MMU for 68K Systems Wiki

Welcome to the Wiki for the Soft MMU for 68K Systems project.

This Wiki exists to make the project readable, teachable, and reviewable as an engineering system. It supports both active development and careful study.

## What this project is

This repository contains a modular, synthesizable Soft Memory Management Unit (Soft MMU) for 68k-family systems.

The current implementation includes the core building blocks needed for a first-pass translated access path:

- a software-visible Memory Management Unit (MMU) register block
- Motorola-style Function Code (FC) decode
- user/supervisor Read / Write / Execute (R/W/X) permission checking
- a direct-mapped translation cache path
- a minimal single-level page-table walker
- a first-pass control shim for flush, probe, and preload operations
- a top-level integration wrapper
- a Basys 3 smoke-demo harness and Vivado flow

## Important scope note

This Wiki documents the implemented repo state, not merely the original project plan.

Several areas are present only as a first-pass subset and should not be overstated:

- Transparent Translation (`TT0` / `TT1`) is implemented only as a narrow subset.
- MMU Status Register (`MMUSR`) behavior is first-pass and not yet a full Motorola architectural model.
- Page Test (`PTEST`), Page Load (`PLOAD`), and Page Flush (`PFLUSH`) behavior is currently implemented as a control-layer shim rather than a complete architectural model.
- `descriptor_pack` is Motorola-aligned for a long-format subset, but the live translation datapath has not yet fully migrated end-to-end to Motorola long-format descriptors.
- The Basys 3 hardware design is a smoke demo, not a full 68k system-on-chip integration.

These distinctions matter. This Wiki should be precise about what is implemented now, what is partially implemented, and what is still deferred.

## Start here

If you are new to the project, read these pages in order:

1. [[Glossary]]
2. [[Architecture Overview|Architecture-Overview]]
3. [[MMU Registers|MMU-Registers]]
4. [[Function Codes and Access Classification|Function-Codes-and-Access-Classification]]
5. [[Descriptor Formats|Descriptor-Formats]]
6. [[Translation Flow|Translation-Flow]]

If you are trying to understand current hardware/demo status, go next to:

- [[FPGA Demo and Basys 3 Bring-Up|FPGA-Demo-and-Basys-3-Bring-Up]]
- [[Build, Simulation, and Verification|Build-Simulation-and-Verification]]

If you want to understand what is still missing, read:

- [[Deferred Features and Compatibility Gaps|Deferred-Features-and-Compatibility-Gaps]]

## Wiki organization

This Wiki is organized in three layers.

### 1. Vocabulary

These pages define the project's language.

- [[Glossary]]

### 2. Concepts

These pages explain how the design works.

- [[Architecture Overview|Architecture-Overview]]
- [[Function Codes and Access Classification|Function-Codes-and-Access-Classification]]
- [[Descriptor Formats|Descriptor-Formats]]
- [[Translation Flow|Translation-Flow]]
- [[Control Operations (PTEST PLOAD PFLUSH)|Control-Operations-(PTEST-PLOAD-PFLUSH)]]

### 3. Implementations

These pages tie concepts to the repo.

- [[MMU Registers|MMU-Registers]]
- [[Translation Cache (TLB and ATC)|Translation-Cache-(TLB-and-ATC)]]
- [[Page Table Walker|Page-Table-Walker]]
- [[FPGA Demo and Basys 3 Bring-Up|FPGA-Demo-and-Basys-3-Bring-Up]]
- [[Build, Simulation, and Verification|Build-Simulation-and-Verification]]
- [[Deferred Features and Compatibility Gaps|Deferred-Features-and-Compatibility-Gaps]]
- [[Source and Manual Map|Source-and-Manual-Map]]

## Editorial policy

This Wiki follows a few strict rules:

- Terms should be defined clearly before they are used casually.
- Acronyms should be expanded on first use.
- Pages should distinguish between implemented behavior, first-pass behavior, and deferred behavior.
- When possible, a page should identify where a concept is implemented in the repo.
- Public pages must not contain assistant-only citation artifacts such as `:contentReference[` or `oaicite:`.
- This Wiki should not claim full Motorola architectural compatibility where the repo itself does not support that claim.

## Recommended next page

Go to [[Glossary]].

That page is the authoritative vocabulary reference for this project and is the best entry point for all other technical pages.
