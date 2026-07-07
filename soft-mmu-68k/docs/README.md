# SM68861 Project Documentation

This folder hosts canonical documentation for the SM68861 project.

SM68861 is a soft MMU for 68k-family systems. Deeper design documents may use
PMMU terminology when discussing MC68020 + MC68851-style paged memory-management
behavior, but top-level documentation should use the clearer public project
identity.

- `charter/`: project intent and workflow
- `refs/`: vendor/manual references used for engineering background
- `design/`: design decisions, implementation notes, and compatibility gaps
- `process/`: development and review workflow notes, including AI-assisted project operations and packet/PR control
- `roadmap/`: future opportunities and non-goal tracking
- `tutorial/`: guided source-level explanations of the current core RTL modules
- `wiki/`: GitHub Wiki source pages

## Citation and reference rules

Use human-readable footnotes only when the document makes a claim that depends on
a specific manual, manual section, or primary source.

Preferred pattern:

```md
Claim text that depends on the manual.[^SOURCE-SHORT-NAME]

*Manual refs used:* [^SOURCE-SHORT-NAME]

[^SOURCE-SHORT-NAME]: Manual title, section or chapter name, and the specific
    topic being relied on.
```

Do not commit placeholder citation anchors such as `section __`, `page __`, or
`fill with exact cites`.

Do not leave source TODOs in public-facing documentation. If the source is not
known well enough to cite clearly, either remove the claim or keep it in a
working note until the citation is known.

## Documentation rules

- Keep public-facing language clear and conservative.
- Do not claim full Motorola PMMU compatibility unless the behavior is implemented
  and verified.
- Distinguish implemented behavior, first-pass subset behavior, and deferred
  compatibility work.
- Use SM68861 / soft MMU language in top-level public documentation.
- Use PMMU language where the document is specifically discussing MC68851-style
  paged memory-management behavior.
