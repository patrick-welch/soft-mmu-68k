# ATC/TLB Microarchitecture

**Minimum**: Direct-mapped ATC/TLB; refill from walker; invalidate hooks.

**Later**: Set-associative variant; replacement policy.

**Behavioral contract**
- Hit/miss, refill, and attribute propagation are modeled as a first-pass
  project-local translation-cache contract, informed by the MC68030 MMU address
  translation and ATC model.[^68030-UM-ATC]
- `PFLUSH` variants are intentionally not modeled as full Motorola-visible
  behavior yet. Current invalidation hooks should be treated as staging behavior
  toward MC68030/MC68040-style ATC invalidation semantics.[^68030-UM-PFLUSH][^68040-UM-ATC]
- `PTEST` and `MMUSR` reporting remain first-pass status-model work, not a full
  Motorola architectural implementation.[^68030-UM-PTEST][^PRM-PMMU]

**Current repo status**
- The implemented translation cache is direct-mapped.
- Refill comes from the current single-level walker path.
- Flush/probe/preload behavior is still a control-layer shim.
- This document does not claim full Motorola PMMU, ATC, `PTEST`, or `PFLUSH`
  compatibility.

*Manual refs used:* [^68030-UM-ATC] [^68030-UM-PFLUSH] [^68040-UM-ATC] [^68030-UM-PTEST] [^PRM-PMMU]

[^68030-UM-ATC]: Motorola MC68030 User's Manual, Section 9 "Memory Management Unit", address translation and address translation cache behavior.
[^68030-UM-PFLUSH]: Motorola MC68030 User's Manual, Section 9 "Memory Management Unit", PMMU cache-control and flush behavior.
[^68040-UM-ATC]: Motorola MC68040 User's Manual, memory-management and ATC/TTR behavior used as later-lineage comparison material.
[^68030-UM-PTEST]: Motorola MC68030 User's Manual, Section 9 "Memory Management Unit", `PTEST` status/reporting behavior.
[^PRM-PMMU]: Motorola M68000 Family Programmer's Reference Manual, PMMU instruction and programmer-visible operation summaries.
