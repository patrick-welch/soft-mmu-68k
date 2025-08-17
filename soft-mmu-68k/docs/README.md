# Project Documentation

This folder hosts canonical docs for the Electron Pushers Soft MMU (68k).

- `charter/`: project intent and workflow
- `refs/`: vendor/manual references we cite
- `design/`: our design decisions and deltas

## Citing sources
Use footnotes like: [^68851-UM-§4.2], [^68030-UM-TT0TT1], [^PRM-PFLUSH].
Define them at file end with manual + section and a stable link/identifier.

## Scope anchors (fill with exact cites)
- Programming model: CRP, SRP, TC, TT0/TT1, MMUSR [^68851-UM], [^68030-UM]
- ATC/TLB semantics, PLOAD/PFLUSH/PTEST [^68030-UM], [^68040-UM], [^PRM]
- Transparent translation (TTRs) [^68040-UM], [^68060-UM]

*See `refs/README.md` for the master list.*
