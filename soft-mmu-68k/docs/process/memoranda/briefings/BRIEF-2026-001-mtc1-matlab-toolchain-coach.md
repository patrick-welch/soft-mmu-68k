# Source Briefing Record — MTC1 MATLAB Toolchain Coach

- **Title:** Briefing to DEV Manager: Re-establish and sharpen MTC1
- **Date / source date:** 2026-08-09 — the source file does not state an explicit date; PROC1B uses the Project Lead's project-local date.
- **Originating role:** MMU MATLAB Toolchain Coach
- **Recipient / decision role:** MMU Dev Manager
- **Record status:** Source briefing
- **Related packet(s):** `MTC1`
- **Related memorandum:** [MEMO-2026-001 — MTC1 scope and sequencing](../MEMO-2026-001-mtc1-scope-and-sequencing.md)
- **Source/provenance note:** Preserved from the Project Lead-supplied source artifact `MTC1_DEV_Manager_Briefing.md`. The substantive source text below is preserved without folding in the later DEV Manager amendments. Repository formatting is normalized to LF line endings only.

---

## Preserved source briefing

# Briefing to DEV Manager: Re-establish and sharpen MTC1

From: MATLAB Toolchain Coach  
To: DEV Manager  
Project: `patrick-welch/soft-mmu-68k`  
Subject: Proposed authoritative definition for `MTC1`

## Request

The original conversational MTC1 packet brief is no longer reliably retrievable. Rather than reconstructing an undocumented chat artifact from memory, I recommend that we use the current repository state to establish a new, explicit, durable MTC1 definition before implementation begins.

Please review the proposed packet below and either:

1. approve it as the authoritative MTC1 scope;
2. amend it; or
3. replace it with a different scope before work starts.

If approved, the MTC1 pull request and PR history should become the durable record of this definition.

## Verified repository anchors

The following are durable repo facts, not reconstructed assumptions:

- `TC1A` is PR #29: `TC1A: add TC/CRP/SRP traversal plan`.
  - It documents the current implementation as CRP feeding the walker table base, TC contributing a limited table-span/configuration role, a minimal single-level walker, and no live SRP root selection.
  - It lists `MTC1` as a future MATLAB reference/vector model for TC address partitioning.

- `TC1B` is PR #30: `TC1B: add TC/CRP span tests`.
  - It locks down current executable behavior:
    - CRP-derived walker table base.
    - TC low bits as the current table-span boundary.
    - in-range translation behavior.
    - first out-of-range VPN producing the current unmapped result without a descriptor request.
    - SRP writes remaining inert for the current traversal path.
  - It explicitly does not implement full Motorola TC bitfield interpretation, SRP root selection, root/pointer traversal, TTR changes, or MMUSR/PTEST changes.

- `HW1A` is PR #37 and is merged.
  - It is documentation/hardware-process only.
  - `HW1B` remains the later human-executed Basys 3 smoke packet.

- `soft-mmu-68k/scripts/matlab/README.md` defines MATLAB as verification collateral:
  - reference models;
  - deterministic generators;
  - examples/demos;
  - optional generated vectors when a packet explicitly requires them.
  - MATLAB does not replace RTL/SystemVerilog regression.

- `AGENTS.md` requires packetized work, packet-specific branches, narrow file scope, deterministic MATLAB output, explicit reporting of whether MATLAB was run, and no generated CSV changes unless the packet assigns them.

## Why MTC1 needs a sharper name and boundary

The phrase `TC address partitioning` is ambiguous because it can mean two different things:

1. **Current project behavior** already locked by TC1B:
   - `PAGE_SHIFT` is an RTL parameter.
   - the full VPN is used as one single-level table index.
   - low TC bits supply a table-entry span.
   - CRP supplies the current table base.
   - SRP is stored but does not select the live root.

2. **Future Motorola-aligned behavior**:
   - TC controls address geometry for hierarchical traversal.
   - logical-address fields are divided into configurable table indexes plus page offset.
   - root selection and multi-level descriptor traversal eventually become relevant.

Those are different engineering problems and should not be silently combined.

Motorola's MC68851 design material describes the architectural tablewalk as dividing the logical address into configurable contiguous index fields, with TC fields controlling that geometry. That is important future work, but it is not what TC1B currently implements.

## Proposed authoritative packet

# Packet: MTC1 - MATLAB TC/CRP single-level span reference model

## Role

Implementation owners:

- Project Lead, executing MATLAB interactively.
- MATLAB Toolchain Coach, specifying/explaining MATLAB work and reviewing results.

This is intentionally a human-guided MATLAB packet rather than an autonomous HDL/Codex packet.

## Branch

Create from current `main`:

`codex/mtc1-tc-crp-span-reference`

All work must remain on this branch and go through a pull request.

## Goal

Create a small, deterministic MATLAB reference model of the **current TC1B-tested TC/CRP traversal boundary**.

MTC1 is intended to make the current single-level address/span arithmetic understandable and independently reproducible in MATLAB before later architecture work expands TC semantics.

MTC1 does **not** model the complete MC68851 Translation Control register, full TIA-TID/PS address partitioning, SRP root selection, or multi-level descriptor traversal.

## Behavioral scope

For configurable:

- virtual-address width;
- physical-address width;
- page shift;
- descriptor size;

model the current project behavior:

```text
VPN              = VA >> PAGE_SHIFT
PAGE_OFFSET      = low PAGE_SHIFT bits of VA
VPN_WIDTH        = VA_WIDTH - PAGE_SHIFT
TABLE_ENTRIES    = low VPN_WIDTH bits of TC
IN_RANGE         = VPN < TABLE_ENTRIES
ROOT_SOURCE      = CRP
SRP_USED         = false
DESCRIPTOR_ADDR  = CRP + VPN * DESCR_BYTES, when IN_RANGE
DESCRIPTOR_REQ   = IN_RANGE
PREWALK_FAULT    = none when IN_RANGE
                   unmapped_span when not IN_RANGE
```

Important boundary:

An in-range result means only that the current span check permits a descriptor request. MTC1 must not claim that the final translation succeeds, because descriptor validity, descriptor type, bus errors, permissions, TLB behavior, and final PA generation are outside this reference model.

## Proposed MATLAB API

Reference model:

```matlab
R = mmu_tc_crp_span_reference(va, fc, crp, srp, tc, opts)
```

Recommended behavior:

- scalar inputs produce one result struct;
- use integer-safe arithmetic;
- validate widths/options conservatively;
- preserve `fc` and `srp` as inputs so the model can explicitly demonstrate that current root selection is still CRP-only;
- return fields sufficient to explain the span decision and descriptor-address arithmetic.

Recommended result fields:

```text
va
fc
crp
srp
tc
va_width
pa_width
page_shift
vpn_width
descr_bytes
vpn
page_offset
table_entries
in_range
descriptor_request
descriptor_addr
root_source
srp_used
prewalk_fault
```

`descriptor_addr` should be meaningful only when `descriptor_request == true`; use a clearly documented sentinel when no request occurs.

## Allowed files

Only:

```text
soft-mmu-68k/scripts/matlab/models/mmu_tc_crp_span_reference.m
soft-mmu-68k/scripts/matlab/generators/generate_tc_crp_span_vectors.m
soft-mmu-68k/scripts/matlab/examples/run_tc_crp_span_demo.m
soft-mmu-68k/scripts/matlab/README.md
```

## Files and areas not to edit

Do not edit:

```text
soft-mmu-68k/rtl/
soft-mmu-68k/tb/
soft-mmu-68k/tb/common/golden_vectors/
soft-mmu-68k/fpga/
soft-mmu-68k/docs/design/
soft-mmu-68k/scripts/*.sh
.github/
AGENTS.md
```

Do not change existing `perm_check` MATLAB collateral except the shared MATLAB README if needed to document MTC1.

## Generator

Create:

```matlab
T = generate_tc_crp_span_vectors()
```

The generator should return an in-memory MATLAB table.

It should not write a CSV by default.

Use deterministic directed cases rather than random generation.

### Required representative cases

At minimum, include these seven conceptual cases:

1. **First in-range VPN**
   - VPN 0 with a nonzero table span.
   - Descriptor address equals CRP.

2. **Last in-range VPN**
   - VPN = `TABLE_ENTRIES - 1`.
   - Descriptor request occurs.
   - Address scaling by `DESCR_BYTES` is visible.

3. **First out-of-range VPN**
   - VPN = `TABLE_ENTRIES`.
   - No descriptor request.
   - Current prewalk result is `unmapped_span`.

4. **Alternate CRP**
   - Same VA/span with a different CRP.
   - Descriptor address moves by the CRP-base difference.

5. **TC span change**
   - Same VA and CRP under two TC span values.
   - Demonstrate that changing the current low-bit TC span can move the request from out-of-range to in-range, or vice versa.

6. **SRP inert / supervisor-class access**
   - Use a supervisor FC and a clearly different SRP value.
   - Current result still reports CRP as root source and `srp_used = false`.

7. **Same VPN, different page offset**
   - Two VAs in the same current page.
   - VPN and descriptor address stay the same.
   - Page offset changes.

The generator may include more rows if they materially improve explanation, but MTC1 should remain small and reviewable rather than exhaustive.

## Demo

Create:

```text
soft-mmu-68k/scripts/matlab/examples/run_tc_crp_span_demo.m
```

The demo should be location-aware, following the existing `perm_check` MATLAB pattern.

It should:

- add the required `models/` and `generators/` paths;
- call `generate_tc_crp_span_vectors`;
- display the resulting table;
- print a short coverage/summary section;
- contain simple assertions for the required packet invariants;
- write no committed artifact by default.

Suggested invocation from MATLAB with the current folder at the Git repository root:

```matlab
run('soft-mmu-68k/scripts/matlab/examples/run_tc_crp_span_demo.m')
```

## Assertions / acceptance checks

The MATLAB demo should prove at least:

```text
- generated table contains all required directed cases;
- first in-range VPN produces a descriptor request;
- last in-range VPN produces a descriptor request;
- VPN == TABLE_ENTRIES produces no descriptor request;
- alternate CRP changes descriptor address as expected;
- supervisor/SRP case still reports CRP and srp_used == false;
- same-VPN/different-offset cases share descriptor address;
- repeated execution produces identical results.
```

## README update

Update `soft-mmu-68k/scripts/matlab/README.md` with a short MTC1 section that documents:

- model path;
- generator path;
- demo path;
- how to run it;
- that output is currently in-memory only;
- that MTC1 models current TC1B single-level span behavior;
- that it is **not** a complete MC68851 TC/address-partition model;
- that no HDL testbench consumes MTC1 output in this packet.

## Generated-vector policy

For MTC1:

**Do not create or commit a CSV golden-vector file.**

The generator returns a MATLAB table for human/reference inspection.

If the model proves useful enough to become HDL-consumed verification collateral, that should be a separate packet, provisionally:

`MTC1B - promote TC/CRP span cases to committed vectors and SystemVerilog consumption`

That future packet would define the CSV schema, row count, consuming bench, regeneration rule, and regression behavior.

## Explicitly deferred from MTC1

Do not implement or model as current behavior:

- complete MC68851 TC bitfields;
- TIA/TIB/TIC/TID decoding;
- PS-driven page-size selection;
- Initial Shift semantics;
- multi-level address partitioning;
- CRP/SRP architectural root-selection rules;
- root descriptor traversal;
- pointer descriptor traversal;
- descriptor parsing;
- tablewalk bus timing;
- TLB behavior;
- TTR behavior;
- permission checking;
- MMUSR/PTEST synthesis;
- RTL changes;
- SystemVerilog test changes;
- HDL regression-vector consumption.

## Verification

### MATLAB

Run the MTC1 demo in MATLAB and report the actual MATLAB version used.

Expected command:

```matlab
run('soft-mmu-68k/scripts/matlab/examples/run_tc_crp_span_demo.m')
```

The demo must complete without assertion failure.

### Git

Before commit:

```bash
git diff --check --   soft-mmu-68k/scripts/matlab/models/mmu_tc_crp_span_reference.m   soft-mmu-68k/scripts/matlab/generators/generate_tc_crp_span_vectors.m   soft-mmu-68k/scripts/matlab/examples/run_tc_crp_span_demo.m   soft-mmu-68k/scripts/matlab/README.md

git status --short
```

Stage only the four allowed files.

### HDL regression

Local Icarus/Verilator regression may be skipped for MTC1 because the packet changes only MATLAB collateral and its README and does not change RTL, testbenches, generated HDL-consumed vectors, scripts, FPGA collateral, or workflows.

Report explicitly:

```text
SKIPPED: MATLAB-only reference-model packet; no HDL-consumed collateral changed.
```

If GitHub Actions runs automatically on the PR, report its result separately.

## Commit

Recommended commit message:

```text
MTC1: add MATLAB TC/CRP span reference model
```

## Pull request

Recommended title:

```text
MTC1: add MATLAB TC/CRP span reference model
```

The PR body should explicitly distinguish:

```text
Implemented MATLAB behavior:
- current TC1B TC/CRP span arithmetic reference model.

Tested:
- MATLAB directed demo and assertions.

Not implemented:
- Motorola TC field decoding;
- SRP root selection;
- multi-level traversal;
- committed vectors;
- SystemVerilog consumption;
- RTL changes.
```

The PR should include the MATLAB regeneration/run command even though no CSV is generated.

## Completion report

Return:

```text
Branch:
Commit:
Files changed:
Files intentionally not touched:
MATLAB version:
MATLAB command run:
MATLAB result:
HDL tests not run:
Known limitations:
Follow-up needed:
```

## Proposed follow-on naming

If MTC1 succeeds, keep future work separate:

- `MTC1B` - optional promotion of MTC1 scenarios into committed golden vectors plus SystemVerilog consumption.
- `MTC2` - MATLAB exploration/reference model for actual Motorola-style TC address geometry, including explicitly sourced TIA-TID/PS concepts, only after the DEV Manager defines the desired compatibility target.
- `TC2A` / later HDL packets - RTL changes only after tests/specification choose what future TC semantics the project actually wants to implement.

## Decision requested from DEV Manager

Please confirm or amend these points before MTC1 implementation:

1. Is MTC1 specifically the **current TC1B single-level TC/CRP span reference model**, with real Motorola TC geometry deferred?
2. Are the four MATLAB/README files above the complete allowed file set?
3. Is **no committed CSV** the correct MTC1 boundary?
4. Is the seven-case directed generator sufficient for MTC1?
5. Should `MTC1B` and `MTC2` remain separate future packets as proposed?
6. Once MTC1 is merged, may the project proceed directly to HW1B unless MTC1 exposes a material ambiguity?

My recommendation is **yes** to all six.
