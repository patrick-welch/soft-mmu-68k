# SM68861 Ecosystem Opportunities

## Purpose

This document records possible future applications for SM68861 without turning them into current implementation claims.

## Public project identity

SM68861 is a soft MMU for 68k-family systems.

## Current project center

The initial project center is a synthesizable and testable soft MMU / soft PMMU core targeting MC68020 + MC68851-style system behavior.

## MVP sequence

1. Fully synthesizable and testable core.
2. Integration with a simple MC68020 test SBC.
3. Later compatibility profiles and ecosystem-specific experiments.

## Extended opportunities

### MC68020 test SBC

A simple MC68020-oriented SBC is the first hardware-system integration target after the core MVP.

### MC68030 / MC68040 / MC68060 lineage

Later work may define compatibility profiles for integrated-MMU members of the 68k family. These are future profiles, not current claims.

### Macintosh, Amiga, Atari, and accelerator ecosystems

SM68861 may eventually be useful in retro-computing accelerator, expansion, or diagnostic projects, provided the core earns trust through Motorola-derived tests and clear bus/interface contracts.

### 68080-class ecosystems

68080-class systems are an extended research opportunity only. No compatibility claim should be made unless a concrete interface contract and test target are defined.

## Non-goals for current MVP

- drop-in physical MC68851 replacement
- full MC68851 architectural compatibility
- full MC68030 MMU compatibility
- MC68040/MC68060 MMU compatibility
- Macintosh/Amiga/Atari system compatibility
- Vampire/68080 compatibility
