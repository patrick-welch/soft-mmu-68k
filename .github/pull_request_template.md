# Pull request packet report

## Packet ID

`<packet id>`

## Summary

<brief summary of the change>

## Change type

Select all that apply:

- [ ] RTL
- [ ] Testbench
- [ ] Documentation
- [ ] FPGA / Vivado
- [ ] MATLAB / golden-vector
- [ ] Script / tooling
- [ ] Process-only
- [ ] Other: <describe>

## Files changed

- `<path>` - <summary>

## Scope confirmation

- [ ] This PR changes only files allowed by the packet brief.
- [ ] This PR does not modify forbidden files.
- [ ] This PR does not include unrelated cleanup or formatting.
- [ ] This PR does not include generated artifacts unless explicitly required by the packet.

## Behavior or documentation implemented

<describe implemented behavior, testbench behavior, documentation change, or process change>

## Verification performed

Commands run:

```bash
<command>
```

Results:

- <result>

## Tests not run

- <test or command> - <reason>

For documentation-only packets, include:

```text
SKIPPED: documentation-only packet
```

## Source/manual references, if applicable

- `<source>` - <section/page/claim, if verified>

Do not invent source titles, section numbers, page numbers, or compatibility claims.

## Compatibility and deferred behavior notes

- Implemented behavior:
- Tested behavior:
- Deferred compatibility work:
- Uncertain interpretation:

## MATLAB / golden-vector notes, if applicable

- MATLAB reference model:
- Generator:
- Regeneration command or script path:
- Generated-vector path:
- Consuming SystemVerilog testbench:
- Fixed seed, if randomness is used:
- CSV schema/header notes:
- MATLAB run status:

## Known TODOs

- <todo>

## DEV Manager review / dispensation

Reviewed HEAD: `<sha>`

DEV Manager decision:

- [ ] Pending review
- [ ] Amendment requested
- [ ] Approved by DEV Manager Dispensation
- [ ] Not approved

Dispensation applies only to the reviewed HEAD commit. Any further push, amend, or force-push requires re-review.
