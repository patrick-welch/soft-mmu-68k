# MTC1 Human-Guided MATLAB Workflow — Step 12

**Packet:** MTC1
**Branch:** `matlab/mtc1-tc-crp-span-reference`
**Goal of this step:** add exactly one directed case and turn its scalar result structure into a one-row MATLAB table.

## What Step 11 proved

MATLAB can now find and call:

```text
generate_tc_crp_span_vectors.m
```

and the current shell returns:

```text
0x0 empty table
```

We will now replace that temporary empty table with the first mandatory directed case.

## Step 12A — Replace the empty-table line

In `generate_tc_crp_span_vectors.m`, replace:

```matlab
    T = table();
```

with:

```matlab
    % Step 12: Build the first directed case and convert its result to one table row.
    R = mmu_tc_crp_span_reference( ...
        hex2dec('000345'), ...
        1, ...
        hex2dec('001000'), ...
        hex2dec('002000'), ...
        4, ...
        struct());

    metadata = table( ...
        "first_in_range_vpn", ...
        "baseline", ...
        'VariableNames', {'case_name', 'variant'});

    T = [metadata struct2table(R)];
```

Save with **Ctrl+S**.

## What this case means

The input virtual address is:

```text
VA = 0x000345
```

With:

```text
PAGE_SHIFT = 12
```

that gives:

```text
VPN         = 0
PAGE_OFFSET = 0x345 = 837
```

The TC value is:

```text
TC = 4
```

so:

```text
TABLE_ENTRIES = 4
```

and VPN 0 is in range.

Because:

```text
VPN = 0
```

the descriptor address should reduce to the CRP itself:

```text
DESCRIPTOR_ADDR = CRP + 0 * DESCR_BYTES
                = CRP
                = 0x001000
                = 4096
```

This satisfies mandatory directed case 1: **first in-range VPN**.

## What the new MATLAB does

This call:

```matlab
R = mmu_tc_crp_span_reference(...);
```

returns the scalar result structure we already built and tested.

This:

```matlab
struct2table(R)
```

converts that one scalar structure into a one-row MATLAB table whose columns are the fields of `R`.

We separately create:

```matlab
metadata = table( ...
    "first_in_range_vpn", ...
    "baseline", ...
    'VariableNames', {'case_name', 'variant'});
```

which is another one-row table containing the two approved generator-only metadata columns.

Finally:

```matlab
T = [metadata struct2table(R)];
```

places the two one-row tables side by side.

The square brackets mean horizontal concatenation here because both tables have exactly one row.

## Step 12B — Run the generator

In the Command Window:

```matlab
T = generate_tc_crp_span_vectors()
```

MATLAB will display a wide one-row table. That is okay.

## Step 12C — Inspect only the important columns

Rather than reading all 22 columns at once, run:

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

Expected important values:

```text
case_name              "first_in_range_vpn"
variant                "baseline"
vpn                    0
page_offset            837
table_entries          4
in_range               1
descriptor_request     1
descriptor_addr_valid  1
descriptor_addr        4096
```

## Stop point

Send back:

1. the result of `T = generate_tc_crp_span_vectors()`;
2. the compact selected-column display.

Do not add a second case yet.

Step 13 will add the **last in-range VPN** as a second row and use that to learn MATLAB vertical table concatenation.
