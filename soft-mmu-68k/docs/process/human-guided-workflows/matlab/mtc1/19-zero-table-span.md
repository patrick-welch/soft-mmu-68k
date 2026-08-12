# MTC1 Human-Guided MATLAB Workflow — Step 19

**Packet:** MTC1
**Branch:** `matlab/mtc1-tc-crp-span-reference`
**Goal of this step:** add mandatory case 8, **zero table span**, as the eleventh generator row.

## Advisory checkpoint before continuing

Continuing the current MATLAB train of thought is the cleaner choice.

The canonical MTC1 packet still authorizes only these four implementation files:

```text
soft-mmu-68k/scripts/matlab/models/mmu_tc_crp_span_reference.m
soft-mmu-68k/scripts/matlab/generators/generate_tc_crp_span_vectors.m
soft-mmu-68k/scripts/matlab/examples/run_tc_crp_span_demo.m
soft-mmu-68k/scripts/matlab/README.md
```

The new repository-preserved learning/process material under:

```text
soft-mmu-68k/docs/process/human-guided-workflows/
soft-mmu-68k/docs/process/memoranda/briefings/
```

is useful, but it is outside the current MTC1 allowed-file list. Leave those files untracked for now and do not stage them as part of MTC1 until we perform the planned process-policy cleanup/reconciliation.

## How much generator work remains?

At the end of Step 18 we have:

```text
10 rows
7 of 9 mandatory conceptual cases
```

Two directed-case steps remain:

```text
Step 19 -> zero table span            -> +1 row  -> 11 rows
Step 20 -> TC upper bits inert pair   -> +2 rows -> 13 rows
```

After Step 20 the generator will contain all nine mandatory conceptual cases and all thirteen approved directed rows.

After that we still need packet completion work: generator review/cleanup, README documentation, demo/assertions, MATLAB verification, repository/process cleanup, and then the normal commit/PR/review closeout.

## What Step 18 established

The page-offset pair should demonstrate:

```text
same VPN
different PAGE_OFFSET
same DESCRIPTOR_ADDR
```

Step 19 now tests the smallest possible configured span:

```text
TABLE_ENTRIES = 0
```

With zero table entries, there are no legal VPN values at all. Even VPN 0 must be rejected.

## Step 19A — Append the zero-span case

In `generate_tc_crp_span_vectors.m`, leave Steps 12–18 unchanged.

Immediately after:

```matlab
    T = [T; row_offset_a; row_offset_b];
```

and before the final `end`, add:

```matlab
    % Step 19: Show that a zero TC span rejects even VPN 0 before any request.
    R_zero_span = mmu_tc_crp_span_reference( ...
        hex2dec('000345'), ...
        1, ...
        hex2dec('001000'), ...
        hex2dec('002000'), ...
        0, ...
        struct());

    metadata_zero_span = table( ...
        "zero_table_span", ...
        "vpn_0_rejected", ...
        'VariableNames', {'case_name', 'variant'});

    row_zero_span = [metadata_zero_span struct2table(R_zero_span)];
    T = [T; row_zero_span];
```

Save with **Ctrl+S**.

## What this case means

The virtual address is:

```text
VA = 0x000345
```

so with the default:

```text
PAGE_SHIFT = 12
```

we get:

```text
VPN         = 0
PAGE_OFFSET = 0x345 = 837
```

But now:

```text
TC = 0
```

and the current MTC1 extraction therefore gives:

```text
TABLE_ENTRIES = 0
```

The span comparison becomes:

```text
VPN < TABLE_ENTRIES
0   < 0
```

which is false.

There is no special exception for VPN 0.

Therefore the expected outputs are:

```text
IN_RANGE               = false
DESCRIPTOR_REQUEST     = false
DESCRIPTOR_ADDR_VALID  = false
DESCRIPTOR_ADDR        = 0
PREWALK_FAULT           = "unmapped_span"
```

The zero descriptor address remains only an invalid-value sentinel.

This satisfies mandatory directed case 8.

## Step 19B — Run the generator

In the MATLAB Command Window:

```matlab
T = generate_tc_crp_span_vectors()
```

Expected size:

```text
11x22 table
```

The new row should be:

```text
11. zero_table_span / vpn_0_rejected
```

## Step 19C — Inspect only the zero-span row

Run:

```matlab
T(T.case_name == "zero_table_span", { ...
    'case_name', ...
    'variant', ...
    'va', ...
    'vpn', ...
    'tc', ...
    'table_entries', ...
    'in_range', ...
    'descriptor_request', ...
    'descriptor_addr_valid', ...
    'descriptor_addr', ...
    'prewalk_fault'})
```

Expected important values:

```text
case_name              = "zero_table_span"
variant                = "vpn_0_rejected"
VA                     = 837
VPN                    = 0
TC                     = 0
TABLE_ENTRIES          = 0
IN_RANGE               = false
DESCRIPTOR_REQUEST     = false
DESCRIPTOR_ADDR_VALID  = false
DESCRIPTOR_ADDR        = 0
PREWALK_FAULT           = "unmapped_span"
```

## Step 19D — Explicitly inspect the boundary expression

Run:

```matlab
zero_row = T(T.case_name == "zero_table_span", :);

zero_row.vpn < zero_row.table_entries
```

Expected:

```text
ans =

  logical

   0
```

This directly asks MATLAB to evaluate the same relationship used by the model:

```text
IN_RANGE = VPN < TABLE_ENTRIES
```

For this case that is literally:

```text
0 < 0
```

which is false.

## Stop point

Send back:

1. the displayed `11x22` generator result;
2. the compact zero-span row;
3. the logical result of `zero_row.vpn < zero_row.table_entries`.

Do not add the TC-upper-bits pair yet.

Step 20 will implement mandatory case 9, **TC upper bits inert**. It will add the final two rows and bring the generator to the approved total of **13 rows across 9 conceptual cases**.
