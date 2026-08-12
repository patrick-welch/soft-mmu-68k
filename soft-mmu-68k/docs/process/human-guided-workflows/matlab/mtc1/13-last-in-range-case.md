# MTC1 Human-Guided MATLAB Workflow — Step 13

**Packet:** MTC1
**Branch:** `matlab/mtc1-tc-crp-span-reference`
**Goal of this step:** add the second mandatory directed case and learn vertical table concatenation.

## What Step 12 proved

The first generator row is correct:

```text
case_name              = "first_in_range_vpn"
variant                = "baseline"
VPN                    = 0
PAGE_OFFSET            = 837
TABLE_ENTRIES          = 4
IN_RANGE               = true
DESCRIPTOR_REQUEST     = true
DESCRIPTOR_ADDR_VALID  = true
DESCRIPTOR_ADDR        = 4096
```

MATLAB displayed logical values as `true` rather than `1`; that is normal and preferable for table readability.

We now have a real one-row, 22-column in-memory table.

## Step 13A — Append the last in-range VPN

In `generate_tc_crp_span_vectors.m`, leave the existing Step 12 code unchanged.

Immediately after:

```matlab
    T = [metadata struct2table(R)];
```

and before the function's final `end`, add:

```matlab
    % Step 13: Append the last in-range VPN as the second directed table row.
    R_last = mmu_tc_crp_span_reference( ...
        hex2dec('003345'), ...
        1, ...
        hex2dec('001000'), ...
        hex2dec('002000'), ...
        4, ...
        struct());

    metadata_last = table( ...
        "last_in_range_vpn", ...
        "baseline", ...
        'VariableNames', {'case_name', 'variant'});

    row_last = [metadata_last struct2table(R_last)];
    T = [T; row_last];
```

Save with **Ctrl+S**.

## What this case means

We keep:

```text
TC          = 4
CRP         = 0x001000
PAGE_SHIFT  = 12
DESCR_BYTES = 8
```

but choose:

```text
VA = 0x003345
```

which gives:

```text
VPN         = 3
PAGE_OFFSET = 0x345 = 837
```

Since:

```text
TABLE_ENTRIES = 4
```

the valid VPNs are:

```text
0, 1, 2, 3
```

so VPN 3 is the **last in-range VPN**.

Its descriptor address is:

```text
CRP + VPN * DESCR_BYTES
= 0x001000 + 3 * 8
= 0x001018
= 4120
```

This satisfies mandatory directed case 2.

## The MATLAB concept: vertical table concatenation

In Step 12 we used:

```matlab
T = [metadata struct2table(R)];
```

The space inside the brackets joins two one-row tables **horizontally**, adding columns.

In Step 13 we use:

```matlab
T = [T; row_last];
```

The semicolon joins compatible tables **vertically**, adding rows.

Conceptually:

```text
[ A  B ]     horizontal -> more columns

[ A ]
[ B ]        vertical   -> more rows
```

For vertical table concatenation, MATLAB requires the tables to have the same variable names in the same order with compatible data types. Our two rows satisfy that because both come from the same metadata schema plus the same scalar reference-model schema.

## Step 13B — Run the generator

In the Command Window, run:

```matlab
T = generate_tc_crp_span_vectors()
```

Expected table size:

```text
2x22 table
```

The first row should remain the Step 12 case and the second row should be `last_in_range_vpn`.

## Step 13C — Inspect the boundary-relevant columns

Run:

```matlab
T(:, { ...
    'case_name', ...
    'variant', ...
    'vpn', ...
    'page_offset', ...
    'table_entries', ...
    'in_range', ...
    'descriptor_request', ...
    'descriptor_addr_valid', ...
    'descriptor_addr'})
```

Expected rows:

```text
"first_in_range_vpn"  "baseline"  VPN 0  offset 837  entries 4  true  true  true  4096
"last_in_range_vpn"   "baseline"  VPN 3  offset 837  entries 4  true  true  true  4120
```

The important comparison is:

```text
VPN 0 -> descriptor address 4096
VPN 3 -> descriptor address 4120
```

That visibly demonstrates descriptor-byte scaling.

## Stop point

Send back:

1. the displayed `T = generate_tc_crp_span_vectors()` result;
2. the compact selected-column display.

Do not add the out-of-range case yet.

Step 14 will add mandatory case 3 — **the first out-of-range VPN** — so the table will show the complete boundary sequence:

```text
first in range
last in range
first out of range
```
