# Soft MMU for 68K Systems

A modular, synthesizable **soft Memory Management Unit (MMU)** for Motorola 68K-family systems.

This project is an open-source hardware effort to build, document, and verify a 68K-style MMU in Verilog/SystemVerilog. The design is inspired by the Motorola MC68851 paged memory management unit and the later on-chip 68030/68040/68060 MMU lineage, but the current repo should be read as an **incremental engineering implementation**, not a finished drop-in Motorola-compatible replacement.

If you arrived here from LinkedIn, start with the project vocabulary first:

**Start here:** [Wiki Glossary](../../wiki/Glossary)

Then continue with:

- [Architecture Overview](../../wiki/Architecture-Overview)
- [MMU Registers](../../wiki/MMU-Registers)
- [Function Codes and Access Classification](../../wiki/Function-Codes-and-Access-Classification)
- [Descriptor Formats](../../wiki/Descriptor-Formats)
- [Translation Flow](../../wiki/Translation-Flow)
- [Build, Simulation, and Verification](../../wiki/Build-Simulation-and-Verification)
- [Deferred Features and Compatibility Gaps](../../wiki/Deferred-Features-and-Compatibility-Gaps)

## What this is

The goal is to make a 68K-compatible MMU design that is:

- **Readable**: organized as small RTL blocks with focused responsibilities.
- **Teachable**: documented through a Wiki glossary, architecture notes, and source-to-concept mapping.
- **Synthesizable**: written for FPGA-oriented HDL development.
- **Verifiable**: backed by unit tests, integration tests, and eventually board-level smoke demos.
- **Historically grounded**: aligned with the vocabulary and architecture of classic Motorola 68K memory-management hardware.

This is part of the broader **Electron Pushers** HDL learning and retro-computing effort.

## Current implementation scope

The current implementation includes first-pass versions of the major blocks needed for a translated access path:

- software-visible MMU register block
- Motorola-style Function Code (`FC[2:0]`) decode
- user/supervisor Read / Write / Execute permission checking
- direct-mapped translation cache path
- minimal page-table walker path
- first-pass control shim for flush, probe, and preload operations
- top-level integration wrapper
- Basys 3 FPGA smoke-demo harness and Vivado flow

Several areas are intentionally still limited. In particular, Transparent Translation (`TT0` / `TT1`), `MMUSR` behavior, `PTEST`, `PLOAD`, `PFLUSH`, and full Motorola descriptor compatibility are still being developed and should not be overstated.

For exact status, see:

- [Deferred Features and Compatibility Gaps](../../wiki/Deferred-Features-and-Compatibility-Gaps)
- [Source and Manual Map](../../wiki/Source-and-Manual-Map)

## Repository layout

The active codebase is under:

- [`soft-mmu-68k/`](soft-mmu-68k/)

Primary areas:

```text
soft-mmu-68k/
├── docs/       # design notes, references, architecture notes
├── rtl/        # synthesizable Verilog/SystemVerilog RTL
├── tb/         # unit and integration testbenches
├── sw/         # 68K-side software test scaffolding
├── fpga/       # Basys 3 demo top, constraints, Vivado scripts
└── scripts/    # simulation, build, and documentation helpers
```

Useful entry points:

- [`rtl/core/`](soft-mmu-68k/rtl/core/) — MMU core RTL blocks
- [`tb/unit/`](soft-mmu-68k/tb/unit/) — unit-level verification
- [`tb/integ/`](soft-mmu-68k/tb/integ/) — integration-level verification
- [`fpga/basys3/`](soft-mmu-68k/fpga/basys3/) — Basys 3 board bring-up/demo flow
- [`docs/`](soft-mmu-68k/docs/) — design/reference material

## Key RTL blocks

The design is split into focused modules rather than one large MMU blob.

Typical core blocks include:

- `mmu_regs.v` — CRP, SRP, TC, TT0, TT1, MMUSR register path
- `mmu_decode.v` — Motorola-style Function Code decode
- `perm_check.v` — user/supervisor and R/W/X permission enforcement
- `descriptor_pack.v` — descriptor packing/unpacking support
- `tlb_dm.v` / `tlb_compare.v` — direct-mapped translation cache path
- `pt_walker.v` — page-table walker path
- `flush_ctrl.v` — first-pass control operations for flush/probe/preload
- `mmu_top.v` — integration wrapper

See the Wiki pages for what each block currently implements and what remains deferred.

## Why this project exists

Commercial and historical 68K MMU options are interesting, but not especially approachable for modern HDL learning or FPGA experimentation.

This repo is meant to make the architecture inspectable:

- What does an MMU register block look like?
- How do Motorola Function Codes classify accesses?
- How does a translation cache differ from a normal software cache?
- How does a page-table walker feed a translation cache?
- What does it take to validate permission faults, transparent mappings, and flush/probe operations?

The point is not only to build an MMU, but to make the design reviewable by people learning HDL, retrocomputing, computer architecture, and verification.

## Build and simulation

The project is intended to support a Linux/WSL-based HDL workflow using common open-source tooling where possible, plus Vivado for FPGA bring-up.

For the current commands and tested flow, see:

- [Build, Simulation, and Verification](../../wiki/Build-Simulation-and-Verification)
- [FPGA Demo and Basys 3 Bring-Up](../../wiki/FPGA-Demo-and-Basys-3-Bring-Up)

## FPGA target

The first hardware demonstration target is the **Digilent Basys 3** board.

The Basys 3 work is currently a smoke-demo harness, not a complete 68K system-on-chip integration. It exists to prove that pieces of the MMU path can be built, constrained, synthesized, and observed on real FPGA hardware.

Start here:

- [`fpga/basys3/`](soft-mmu-68k/fpga/basys3/)
- [FPGA Demo and Basys 3 Bring-Up](../../wiki/FPGA-Demo-and-Basys-3-Bring-Up)

## Project status

This is an active engineering project.

The repo is organized to support staged implementation, code review, and agent-assisted development. The Wiki is the best place to understand what is implemented now, what is first-pass only, and what is still planned.

Recommended path for new readers:

1. [Glossary](../../wiki/Glossary)
2. [Architecture Overview](../../wiki/Architecture-Overview)
3. [Translation Flow](../../wiki/Translation-Flow)
4. [`rtl/core/`](soft-mmu-68k/rtl/core/)
5. [`tb/unit/`](soft-mmu-68k/tb/unit/)

## Contributing and review style

This project values small, reviewable changes.

A good pull request should identify:

- the module or subsystem changed
- the Motorola/68K concept being implemented
- the relevant unit or integration tests
- any compatibility gaps or deferred behavior
- whether the change is synthesizable RTL, simulation-only code, documentation, or FPGA bring-up support

The project deliberately avoids claiming full architectural compatibility until behavior is implemented and verified.

## License

See [`LICENSE`](soft-mmu-68k/LICENSE).
