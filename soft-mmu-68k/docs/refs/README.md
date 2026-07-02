# References

This folder tracks vendor-primary manuals and project source material used by
SM68861 documentation.

The detailed acquisition and download checklist is maintained in
[`source-materials.md`](source-materials.md).

## Citation style

Design documents should use short, human-readable footnotes with enough detail
for a reader to understand what manual section or topic supports the claim.

Use this pattern:

```md
Claim text that depends on a manual.[^68030-UM-TT]

*Manual refs used:* [^68030-UM-TT]

[^68030-UM-TT]: Motorola MC68030 User's Manual, transparent translation register
    behavior and matching rules.
```

Avoid placeholder references such as `section __`, `page __`, or `fill with exact
cites` in committed public documentation.

## Current manual shorthand

Use these names consistently when a document needs a manual reference:

| Shorthand | Human-readable source |
| --- | --- |
| `[^68851-UM]` | Motorola MC68851 PMMU User's Manual. |
| `[^68030-UM]` | Motorola MC68030 User's Manual, especially Section 9 "Memory Management Unit" when discussing PMMU behavior. |
| `[^68040-UM]` | Motorola MC68040 User's Manual, especially ATC/TTR and exception-model material. |
| `[^68060-UM]` | Motorola MC68060 User's Manual, especially final-generation MMU deltas. |
| `[^PRM]` | Motorola M68000 Family Programmer's Reference Manual. |
| `[^68451-UM]` | Motorola MC68451 MMU User's Manual and related MC68010 + MMU bus-restart material. |

A document may use a more specific shorthand when helpful, for example
`[^68030-UM-TT]`, `[^68030-UM-FC]`, or `[^68851-UM-5.1.5.3]`.

Prefer the specific form when the citation supports a narrow technical claim.
