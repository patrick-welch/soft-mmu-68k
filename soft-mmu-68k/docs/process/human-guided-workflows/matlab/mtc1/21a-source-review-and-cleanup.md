# MTC1 Step 21 — Source Review and Cleanup Checkpoint

**Packet:** MTC1
**Branch:** `matlab/mtc1-tc-crp-span-reference`
**Files reviewed:**
- `scripts/matlab/models/mmu_tc_crp_span_reference.m`
- `scripts/matlab/generators/generate_tc_crp_span_vectors.m`

## Filename note

Any parenthetic copy suffixes visible in ChatGPT uploads, such as `(1)` or `(3)`, are attachment-environment artifacts only.

The canonical repository filenames remain:

```text
scripts/matlab/models/mmu_tc_crp_span_reference.m
scripts/matlab/generators/generate_tc_crp_span_vectors.m
```

No repository rename or copy is needed.

## Review result

**Generator behavior: PASS, pending only minor documentation cleanup.**

The generator contains exactly 13 rows across the 9 approved conceptual cases:

```text
1  first in-range VPN
1  last in-range VPN
1  first out-of-range VPN
2  alternate CRP
2  TC span change
1  SRP inert / supervisor-class access
2  same VPN / different page offset
1  zero table span
2  TC upper bits inert
-----------------------------------
13 rows total
```

It returns an in-memory MATLAB table, introduces only the approved `case_name` and `variant` generator metadata, writes no CSV, creates no directory, and contains no output-file argument.

The final table schema is 22 columns:

```text
2 generator metadata columns
20 canonical MTC1 model-result columns
```

No duplicated directed case or stale temporary row was found.

## Scalar model review

The scalar model matches the approved MTC1 current-subset behavior and returns the approved 20-field schema in the correct order.

Confirmed behavior includes:

```text
VPN             = VA >> PAGE_SHIFT
PAGE_OFFSET     = low PAGE_SHIFT bits of VA
VPN_WIDTH       = VA_WIDTH - PAGE_SHIFT
TABLE_ENTRIES   = low VPN_WIDTH bits of TC
IN_RANGE        = VPN < TABLE_ENTRIES
ROOT_SOURCE     = CRP
SRP_USED        = false
DESCRIPTOR_REQ  = IN_RANGE
DESCRIPTOR_ADDR = CRP + VPN * DESCR_BYTES when in range
PREWALK_FAULT   = none / unmapped_span
```

The width-64 implementation is already handled safely by special-casing `VA_WIDTH == 64` and `FC_WIDTH == 64`, so it does not attempt to construct `uint64(2^64)`.

## Required cleanup before README/demo work

One required documentation clarification remains in the scalar model.

The DEV Manager ruling permits:

```text
VA_WIDTH <= 64
FC_WIDTH <= 64
```

only as MATLAB `uint64` scalar representation limits and explicitly requires that the model document that these are **not MC68851 or SM68861 architectural limits**.

The current comment:

```matlab
% Step 4: Enforce basic range and MATLAB uint64 representation guards.
```

correctly identifies the implementation mechanism, but it does not yet state the required non-architectural classification explicitly enough.

### Step 21A — add the representation-limit clarification

Immediately below:

```matlab
% Step 4: Enforce basic range and MATLAB uint64 representation guards.
```

add:

```matlab
% VA_WIDTH <= 64 and FC_WIDTH <= 64 are MATLAB scalar uint64
% representation limits only. They are not MC68851 or SM68861
% architectural limits.
```

Do not change the executable logic for this cleanup.

## Optional source-quality observations — no change required now

There is some deliberately incremental validation ordering from the learning exercise: basic range checks added in Step 4 appear before the fuller scalar/integer checks added in Step 3.

That ordering is understandable from the development history and does not affect the valid configurations exercised by MTC1. Reorganizing the validation now would change more code than necessary and is not required for packet completion.

Likewise, the repeated explicit generator rows are verbose, but they make the nine directed concepts easy for a human to inspect. Do not refactor them into a helper merely for brevity.

## After Step 21A

Save the scalar model and run:

```matlab
T = generate_tc_crp_span_vectors();
height(T)
```

Expected:

```text
ans =

    13
```

Then inspect:

```matlab
fieldnames(mmu_tc_crp_span_reference( ...
    hex2dec('003345'), 1, hex2dec('001000'), ...
    hex2dec('002000'), 4, struct()))
```

The returned field list should remain the approved 20-field schema.

## Stop point

After the comment-only cleanup and the two quick checks above, Step 21 is complete.

Next: update `scripts/matlab/README.md` with the MTC1 model/generator/demo boundary and the required representation-limit language. The demo itself should still wait until after the README update.
