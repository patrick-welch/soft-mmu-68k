# MTC1 — MATLAB TC/CRP Single-Level Span Reference Model

## Packet identity

- **Packet:** `MTC1`
- **Title:** MATLAB TC/CRP single-level span reference model
- **Owner / execution roles:** Project Lead + MMU MATLAB Toolchain Coach
- **Branch:** `matlab/mtc1-tc-crp-span-reference`
- **Current execution status:** maintained by [`packet-registry.md`](packet-registry.md); this definition records authorization, not implementation state.
- **Decision source:** [MEMO-2026-001 — MTC1 scope and sequencing](../memoranda/MEMO-2026-001-mtc1-scope-and-sequencing.md), based on the preserved Toolchain Coach source briefing and the accepted MMU Dev Manager amendments.

## Goal

Create a small, deterministic MATLAB reference model of the **current TC1B-tested TC/CRP traversal boundary**. The model makes the current single-level table-span and descriptor-address arithmetic independently reproducible without silently expanding the project into full Motorola TC address geometry.

MTC1 is a human-guided Project Lead + MATLAB Toolchain Coach packet, not an autonomous HDL/Codex implementation packet.

## Current behavioral boundary

For configured virtual/physical widths, page shift, and descriptor size, model the current project behavior:

```text
VPN             = VA >> PAGE_SHIFT
PAGE_OFFSET     = low PAGE_SHIFT bits of VA
VPN_WIDTH       = VA_WIDTH - PAGE_SHIFT
TABLE_ENTRIES   = low VPN_WIDTH bits of TC
IN_RANGE        = VPN < TABLE_ENTRIES
ROOT_SOURCE     = CRP
SRP_USED        = false
DESCRIPTOR_ADDR = CRP + VPN * DESCR_BYTES, when IN_RANGE
DESCRIPTOR_REQ  = IN_RANGE
PREWALK_FAULT   = none when IN_RANGE
                  unmapped_span when not IN_RANGE
```

An in-range result means only that the current span check permits a descriptor request. MTC1 does not claim final translation success; descriptor validity/type, bus errors, permissions, TLB behavior, and final PA generation are outside this packet.

## Configuration limits

MTC1 is intentionally constrained to the current project's useful width range:

```text
1 <= VPN_WIDTH <= 32
PA_WIDTH <= 32
VA_WIDTH > PAGE_SHIFT
PA_WIDTH > PAGE_SHIFT
DESCR_BYTES is byte-aligned
DESCR_BYTES is a power of two
```

Recommended defaults matching the current integrated RTL:

```text
VA_WIDTH    = 24
PA_WIDTH    = 24
PAGE_SHIFT  = 12
DESCR_WIDTH = 64
FC_WIDTH    = 3
```

For MTC1 test configurations, reject any case where:

```text
CRP + VPN * DESCR_BYTES
```

cannot be represented in the selected PA width. Do not invent wraparound or overflow semantics.

## MATLAB API direction

Reference model:

```matlab
R = mmu_tc_crp_span_reference(va, fc, crp, srp, tc, opts)
```

The model should use integer-safe arithmetic, validate options conservatively, preserve `fc` and `srp` inputs, and return fields sufficient to explain the span decision and descriptor-address calculation.

Approved result fields:

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
descriptor_addr_valid
descriptor_addr
root_source
srp_used
prewalk_fault
```

Use:

```text
descriptor_addr_valid = descriptor_request
```

`descriptor_addr` may be zero when invalid; the validity flag controls whether the value is meaningful.

## Allowed files

Only:

```text
soft-mmu-68k/scripts/matlab/models/mmu_tc_crp_span_reference.m
soft-mmu-68k/scripts/matlab/generators/generate_tc_crp_span_vectors.m
soft-mmu-68k/scripts/matlab/examples/run_tc_crp_span_demo.m
soft-mmu-68k/scripts/matlab/README.md
```

## Forbidden files and areas

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

No SystemVerilog consumer is part of MTC1. Do not modify existing `perm_check` MATLAB collateral except the shared MATLAB README if needed to document MTC1.

## Generator boundary

Create:

```matlab
T = generate_tc_crp_span_vectors()
```

The generator must:

- return an in-memory MATLAB table;
- be deterministic;
- use directed cases;
- write no CSV by default;
- contain the nine mandatory cases below.

## Nine mandatory directed cases

1. **First in-range VPN** — VPN 0 with nonzero span; descriptor address equals CRP.
2. **Last in-range VPN** — VPN = `TABLE_ENTRIES - 1`; request occurs and descriptor-byte scaling is visible.
3. **First out-of-range VPN** — VPN = `TABLE_ENTRIES`; no request; result is `unmapped_span`.
4. **Alternate CRP** — same VA/span with another CRP; descriptor address moves by the CRP-base difference.
5. **TC span change** — same VA/CRP under two TC span values; demonstrate movement between in-range and out-of-range.
6. **SRP inert / supervisor-class access** — supervisor FC with clearly different SRP; root remains CRP and `srp_used = false`.
7. **Same VPN, different page offset** — same VPN and descriptor address; page offset changes.
8. **Zero table span** — TC low VPN-width field = 0; VPN 0 is out of range; no request; result is `unmapped_span`.
9. **TC upper bits inert** — when `VPN_WIDTH < 32`, two TC values with identical low `VPN_WIDTH` bits but different upper bits produce identical `TABLE_ENTRIES`, `in_range`, and descriptor address.

Additional cases are allowed only when they materially improve explanation. Keep MTC1 small and reviewable.

## Demo boundary

Create:

```text
soft-mmu-68k/scripts/matlab/examples/run_tc_crp_span_demo.m
```

The demo should be location-aware and should:

- add required model/generator paths;
- call the generator;
- display the in-memory table;
- print a concise coverage/summary section;
- contain assertions for packet invariants;
- produce no committed artifact.

Recommended invocation:

```matlab
run('soft-mmu-68k/scripts/matlab/examples/run_tc_crp_span_demo.m')
```

## No-CSV boundary

**No committed CSV belongs to MTC1.**

The generator returns a MATLAB table for human/reference inspection. If HDL-consumed verification collateral is later desired, use a separate `MTC1B` packet to define vector schema, consuming SystemVerilog, regeneration rules, and regression behavior.

## Explicitly deferred Motorola TC geometry

Do not implement or model as current behavior:

```text
TIA/TIB/TIC/TID decoding
PS-driven page-size selection
Initial Shift semantics
multi-level address partitioning
architectural CRP/SRP root-selection rules
root descriptor traversal
pointer descriptor traversal
```

Descriptor parsing, tablewalk bus timing, TLB behavior, TTR behavior, permission checking, MMUSR/PTEST synthesis, RTL changes, and HDL-consumed vectors are also outside MTC1.

A future `MTC2` packet may explore actual Motorola-style TC address geometry only after the DEV Manager defines the compatibility target and relevant behavior is explicitly sourced.

## Verification

MATLAB execution is required. Report the actual MATLAB version used.

Run:

```matlab
run('soft-mmu-68k/scripts/matlab/examples/run_tc_crp_span_demo.m')
```

The demo must complete without assertion failure.

Before commit, run:

```bash
git diff --check -- \
  soft-mmu-68k/scripts/matlab/models/mmu_tc_crp_span_reference.m \
  soft-mmu-68k/scripts/matlab/generators/generate_tc_crp_span_vectors.m \
  soft-mmu-68k/scripts/matlab/examples/run_tc_crp_span_demo.m \
  soft-mmu-68k/scripts/matlab/README.md

git status --short
```

Stage only the four allowed files.

## HDL regression disposition

Local Icarus/Verilator regression may be skipped because MTC1 changes only MATLAB collateral and its README and does not modify HDL-consumed collateral.

Report exactly:

```text
SKIPPED: MATLAB-only reference-model packet; no HDL-consumed collateral changed.
```

If GitHub Actions runs automatically on the PR, report its result separately. Do not change workflow triggers.

## Closeout

MTC1 must conclude through:

```text
implementation
-> MATLAB verification
-> commit
-> push
-> pull request
-> DEV Manager review
-> DEV Manager Dispensation
-> merge
```

Recommended commit message and PR title:

```text
MTC1: add MATLAB TC/CRP span reference model
```

## Known follow-ons and sequencing

- `MTC1B` — optional promotion of MTC1 scenarios into committed golden vectors plus SystemVerilog consumption.
- `MTC2` — separate MATLAB architectural/reference effort for explicitly sourced Motorola-style TC geometry.
- `TC2A` and later HDL packets — separate RTL/test work after future semantics are chosen.
- `HW1B` may proceed after MTC1 unless MTC1 exposes a material ambiguity relevant to the existing smoke target. MTC1 is a chosen sequencing checkpoint, not an architectural dependency of the current Basys 3 smoke demo.
