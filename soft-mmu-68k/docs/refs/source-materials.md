# Source Materials Manifest

This file tracks external source materials used to understand, implement, and document the Soft MMU project.

Do not vendor third-party PDFs into this repository.  Store only bibliographic information, download locations, local filename suggestions, and project relevance notes.

## Status legend

- `acquired` - Patrick has located/downloaded a usable copy.
- `verified-download` - a stable public download location was checked.
- `wanted` - the source is useful but a stable downloadable PDF has not been verified yet.
- `superseded/context` - useful background, but not the primary source for implementation decisions.

## Core night-tablet set

| Status | Source | Download location | Suggested local filename | Project relevance |
|---|---|---|---|---|
| acquired / verified-download | Motorola, *M68000 Family Programmer's Reference Manual*, 1992 | https://www.nxp.com/docs/en/reference-manual/M68000PRM.pdf | `M68000_Family_Programmers_Reference_Manual_1992.pdf` | Cross-family instruction reference for privileged instructions, PMMU instructions, `MOVEC`, `PTEST`, `PLOAD`, `PFLUSH`, function-code context, and exception vocabulary. |
| acquired / verified-download | Motorola, *MC68851 PMMU User's Manual*, 3rd ed., 1988 | https://www.bitsavers.org/components/motorola/68000/68020/MC68851_PMMU_Users_Manual_3ed_1988.pdf | `MC68851_PMMU_Users_Manual_3ed_1988.pdf` | Primary external PMMU reference for CRP/SRP/TC/TTx/MMUSR, descriptors, ATC, table search, and PMMU control operations. |
| acquired / verified-download | Motorola, *MC68030 Enhanced 32-Bit Microprocessor User's Manual*, 3rd ed., 1990 | https://www.bitsavers.org/components/motorola/68000/68030/MC68030_Users_Manual_3ed_1990.pdf | `MC68030_Users_Manual_3ed_1990.pdf` | Integrated PMMU reference and closest bridge between MC68851-style behavior and on-chip 68k MMU behavior. |
| verified-download | Motorola, *MC68040 User's Manual*, 1993 | https://www.bitsavers.org/components/motorola/68000/68040/MC68040_Users_Manual_1993.pdf | `MC68040_Users_Manual_1993.pdf` | Later integrated MMU/cache/TTR model; useful for transparent translation registers, cache-inhibited mappings, ATC/cache interactions, and exception behavior. |
| verified-download | Motorola, *M68060 User's Manual* | https://www.nxp.com/docs/en/data-sheet/MC68060UM.pdf | `MC68060_Users_Manual.pdf` | Final 68k-family MMU/cache reference; useful for later-family deltas and compatibility boundaries. |
| verified-download | Motorola, *MC68020 32-Bit Microprocessor User's Manual*, 1984 | https://www.bitsavers.org/components/motorola/68000/68020/MC68020_32-Bit_Microprocessor_Users_Manual_1984.pdf | `MC68020_Users_Manual_1984.pdf` | Processor-side companion for the MC68851 coprocessor-interface environment. |
| acquired | MacGregor, Mothersole, and Moyer, "The Design and Implementation of the MC68851 Paged Memory Management Unit," *IEEE Micro*, 1986 | local project research copy / IEEE Xplore | `MC68851_Design_and_Implementation_IEEE_Micro_1986.pdf` | Implementation paper for the MC68851; useful for ATC, table walking, root pointer table behavior, and implementation tradeoffs. |
| verified-download | Motorola, *MC68040 Designer's Handbook*, 1990 | https://www.bitsavers.org/components/motorola/68000/68040/MC68040_Designers_Handbook_1990.pdf | `MC68040_Designers_Handbook_1990.pdf` | Board/system integration context for the 68040 family. |
| verified-download | Motorola, *MC68030 Data Sheet*, 1991 | https://www.bitsavers.org/components/motorola/68000/68030/MC68030_Data_Sheet_1991.pdf | `MC68030_Data_Sheet_1991.pdf` | Quick electrical/feature reference for the 68030. |

## Wanted / not yet verified

### ACM / SIGMICRO MMU comparison paper

Current lead:

- Candidate title: "Memory management units for microcomputer operating systems"
- Candidate related title: "Memory Management Units For 68000 Architectures"
- Candidate author lead: Gregg Zehr
- Candidate date lead: November 1986 or 1987
- Candidate venue lead: ACM / SIGMICRO or related microarchitecture proceedings

Status: `wanted`.

A stable downloadable PDF has not been verified.  The likely value is comparative context across 1980s MMUs, especially MC68451, MC68851, and competing microcomputer MMU designs.  Do not cite this as an implementation source until a real copy is found and reviewed.

Search strings:

```text
"Memory management units for microcomputer operating systems"
"Memory Management Units For 68000 Architectures"
"Gregg Zehr" "Memory Management Units"
"MC68451" "MC68851" "Zehr"
"68000 Architectures" "Memory Management Units"
```

### Board-level 68040/68060 TTR and cache-mode examples

Original lead:

- `BVME4500`-style board documentation showing practical TTR/cache-mode setup for device and board regions.

Status: `wanted`.

The original `BVME4500` lead has not been verified.  It may be a stale, obscure, or misremembered board identifier.  Do not cite it as a real source until a manual is located.

More promising replacement search family:

- Motorola MVME162
- Motorola MVME165
- Motorola MVME167
- Motorola MVME172
- Motorola MVME177
- MVME167BUG / MVME177BUG manuals

Reason: these Motorola VME single-board computers are plausible sources for practical 68040/68060 board firmware behavior: transparent translation setup, cache-inhibited device mappings, VMEbus address windows, and early boot MMU/cache initialization.

Search strings:

```text
"MVME167" "User's Manual" PDF
"MVME167" "Programmer's Reference" PDF
"MVME167BUG" manual PDF
"MVME162" "User's Manual" PDF
"MVME165" "User's Manual" PDF
"MVME177" "User's Manual" PDF
"MVME167" "cache-inhibited"
"MVME167" "transparent translation"
"MVME167" "68040" "TTR"
"MC68040" "VMEbus" "cache-inhibited"
```

## Citation policy for project docs

- Prefer Motorola/Freescale/NXP manuals for architectural behavior.
- Prefer Bitsavers only where vendor-hosted PDFs are unavailable or less stable.
- Use papers and board manuals as explanatory context unless their claims are checked against processor manuals.
- Do not cite wanted items in implementation docs until they are acquired and reviewed.
- Do not commit outside PDFs to this repository.
