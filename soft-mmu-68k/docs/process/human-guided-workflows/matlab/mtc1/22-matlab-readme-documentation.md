# MTC1 Human-Guided MATLAB Workflow — Step 22

**Packet:** MTC1
**Branch:** `matlab/mtc1-tc-crp-span-reference`
**Goal:** update the shared MATLAB README so it accurately documents both the existing `perm_check` CSV flow and the new MTC1 in-memory reference flow.

## Step 21A checkpoint

The representation-limit comment is in the correct place beneath the Step 4 implementation guard:

```matlab
% VA_WIDTH <= 64 and FC_WIDTH <= 64 are MATLAB scalar uint64
% representation limits only. They are not MC68851 or SM68861
% architectural limits.
```

The subsequent checks still showed:

```text
height(T) = 13
fieldnames(...) = 20 canonical result fields
```

So Step 21 is complete.

## Step 22A — Open the existing README

From the MATLAB Command Window:

```matlab
edit(fullfile(pwd, 'scripts', 'matlab', 'README.md'))
```

Do not replace the existing `perm_check` documentation.

## Step 22B — Broaden one directory-layout sentence

Find:

```markdown
- `generators/` - scripts/functions that generate golden-vector files.
```

Replace it with:

```markdown
- `generators/` - scripts/functions that generate directed-case tables and/or golden-vector files.
```

This keeps the existing `perm_check` description true while also covering MTC1, whose generator intentionally writes no CSV.

## Step 22C — Add the MTC1 section

Insert the following complete section **immediately before** the existing:

```markdown
## Documentation policy
```

section.

```markdown
## Current in-memory reference flow: `MTC1` TC/CRP span model

MTC1 adds a deterministic MATLAB reference model for the current
TC1B-tested single-level TC/CRP span boundary:

```text
MATLAB scalar reference model -> in-memory directed-case table -> demo assertions
```

This is intentionally different from the `perm_check` golden-vector flow.
MTC1 writes no CSV, creates no output directory, and has no SystemVerilog
consumer in this packet.

Files:

- `models/mmu_tc_crp_span_reference.m`
- `generators/generate_tc_crp_span_vectors.m`
- `examples/run_tc_crp_span_demo.m`

The current MTC1 behavioral boundary is:

```text
VPN             = VA >> PAGE_SHIFT
PAGE_OFFSET     = low PAGE_SHIFT bits of VA
VPN_WIDTH       = VA_WIDTH - PAGE_SHIFT
TABLE_ENTRIES   = low VPN_WIDTH bits of TC
IN_RANGE        = VPN < TABLE_ENTRIES
ROOT_SOURCE     = CRP
SRP_USED        = false
DESCRIPTOR_REQ  = IN_RANGE
DESCRIPTOR_ADDR = CRP + VPN * DESCR_BYTES, when IN_RANGE
PREWALK_FAULT   = none when IN_RANGE
                  unmapped_span when not IN_RANGE
```

An in-range result only permits the current descriptor request. It does not
mean that final translation succeeded. Descriptor validity/type, bus errors,
permissions, TLB behavior, and final physical-address generation remain
outside MTC1.

The generator returns one in-memory MATLAB table with 13 deterministic rows
covering nine conceptual cases:

1. first in-range VPN;
2. last in-range VPN;
3. first out-of-range VPN;
4. alternate CRP;
5. TC span change;
6. SRP inert / supervisor-class access;
7. same VPN with different page offset;
8. zero table span;
9. TC upper bits inert.

Paired comparison cases account for the 13 table rows. The generator-only
metadata columns are `case_name` and `variant`; the remaining columns are the
20 canonical MTC1 scalar-model result fields.

The scalar implementation uses MATLAB `uint64` values for integer-safe scalar
representation. Accordingly:

```text
VA_WIDTH <= 64
FC_WIDTH <= 64
```

are MATLAB scalar representation limits only. They are **not** MC68851
architectural limits and are **not** SM68861 architectural limits.

MTC1 does not implement full Motorola TC address geometry. The following remain
explicitly deferred:

- TIA/TIB/TIC/TID decoding;
- PS-driven page-size selection;
- Initial Shift semantics;
- multi-level address partitioning;
- architectural CRP/SRP root-selection rules;
- root- and pointer-descriptor traversal.

Run the MTC1 demo from the repository root with:

```matlab
run('scripts/matlab/examples/run_tc_crp_span_demo.m')
```

The demo is expected to add the required model/generator paths, display the
in-memory directed-case table, print a concise summary, and assert the packet
invariants without creating a committed artifact.
```

## Step 22D — Save and inspect only the new section

Save with **Ctrl+S**.

Then, in MATLAB, you may simply leave the file open for visual inspection. No MATLAB execution is required for this documentation-only edit.

From Git Bash, do **not** stage anything yet.

Run only:

```bash
git status --short
```

At this point we expect the MTC1 implementation-related state to include:

```text
M  soft-mmu-68k/scripts/matlab/README.md
?? soft-mmu-68k/scripts/matlab/generators/generate_tc_crp_span_vectors.m
?? soft-mmu-68k/scripts/matlab/models/mmu_tc_crp_span_reference.m
```

plus the separate untracked process/learning material we already agreed not to stage with MTC1.

## Stop point

Send back:

1. `git status --short`;
2. if convenient, upload the edited `scripts/matlab/README.md`.

Do not create the demo yet.

Once the README edit is verified, Step 23 will create the minimal location-aware `run_tc_crp_span_demo.m` shell and then we will add its assertions incrementally rather than as one large script.
