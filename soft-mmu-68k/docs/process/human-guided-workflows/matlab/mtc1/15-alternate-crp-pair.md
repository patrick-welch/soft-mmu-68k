# MTC1 Human-Guided MATLAB Workflow — Step 15

**Packet:** MTC1
**Branch:** `matlab/mtc1-tc-crp-span-reference`
**Goal of this step:** add mandatory case 4, **alternate CRP**, as a two-row comparison.

## What Step 14 proved

The generator now shows the complete span boundary:

```text
VPN 0 -> first in range
VPN 3 -> last in range
VPN 4 -> first out of range
```

For `TABLE_ENTRIES = 4`, the comparison is therefore visibly:

```text
VPN < TABLE_ENTRIES
```

with VPN 3 accepted and VPN 4 rejected.

We now move to a different question:

```text
If VA, TC, page geometry, FC, and SRP stay the same,
does changing only CRP move the descriptor address
by exactly the same amount as the CRP base changes?
```

That is mandatory directed case 4.

## Step 15A — Append the alternate-CRP pair

In `generate_tc_crp_span_vectors.m`, leave Steps 12–14 unchanged.

Immediately after:

```matlab
    T = [T; row_out];
```

and before the final `end`, add:

```matlab
    % Step 15: Compare two CRP bases with the same VA and table span.
    R_crp_a = mmu_tc_crp_span_reference( ...
        hex2dec('002345'), ...
        1, ...
        hex2dec('001000'), ...
        hex2dec('002000'), ...
        4, ...
        struct());

    metadata_crp_a = table( ...
        "alternate_crp", ...
        "crp_a", ...
        'VariableNames', {'case_name', 'variant'});

    row_crp_a = [metadata_crp_a struct2table(R_crp_a)];

    R_crp_b = mmu_tc_crp_span_reference( ...
        hex2dec('002345'), ...
        1, ...
        hex2dec('003000'), ...
        hex2dec('002000'), ...
        4, ...
        struct());

    metadata_crp_b = table( ...
        "alternate_crp", ...
        "crp_b", ...
        'VariableNames', {'case_name', 'variant'});

    row_crp_b = [metadata_crp_b struct2table(R_crp_b)];

    T = [T; row_crp_a; row_crp_b];
```

Save with **Ctrl+S**.

## What these two rows hold constant

Both rows use:

```text
VA          = 0x002345
FC          = 1
SRP         = 0x002000
TC          = 4
PAGE_SHIFT  = 12
DESCR_BYTES = 8
```

Therefore both rows should have:

```text
VPN         = 2
PAGE_OFFSET = 0x345 = 837
IN_RANGE    = true
```

Only `CRP` changes.

## Step 15B — Work out the expected descriptor addresses

For variant `crp_a`:

```text
CRP         = 0x001000 = 4096
VPN         = 2
DESCR_BYTES = 8

DESCRIPTOR_ADDR
    = 4096 + 2 * 8
    = 4112
    = 0x001010
```

For variant `crp_b`:

```text
CRP         = 0x003000 = 12288
VPN         = 2
DESCR_BYTES = 8

DESCRIPTOR_ADDR
    = 12288 + 2 * 8
    = 12304
    = 0x003010
```

The CRP base changed by:

```text
0x003000 - 0x001000
= 0x002000
= 8192
```

and the descriptor address should also change by exactly:

```text
12304 - 4112
= 8192
```

The `VPN * DESCR_BYTES` term is identical in both rows, so it cancels when we compare them.

## Step 15C — Run the generator

In the Command Window:

```matlab
T = generate_tc_crp_span_vectors()
```

Expected size:

```text
5x22 table
```

The new rows should be:

```text
4. alternate_crp / crp_a
5. alternate_crp / crp_b
```

## Step 15D — Inspect only the alternate-CRP rows

Run:

```matlab
T(T.case_name == "alternate_crp", { ...
    'case_name', ...
    'variant', ...
    'va', ...
    'vpn', ...
    'crp', ...
    'table_entries', ...
    'in_range', ...
    'descriptor_addr'})
```

Expected values:

```text
alternate_crp  crp_a
    VA              = 9029
    VPN             = 2
    CRP             = 4096
    TABLE_ENTRIES   = 4
    IN_RANGE        = true
    DESCRIPTOR_ADDR = 4112

alternate_crp  crp_b
    VA              = 9029
    VPN             = 2
    CRP             = 12288
    TABLE_ENTRIES   = 4
    IN_RANGE        = true
    DESCRIPTOR_ADDR = 12304
```

## Step 15E — Let MATLAB calculate the two deltas

Now run:

```matlab
crp_rows = T(T.case_name == "alternate_crp", :);

crp_delta = crp_rows.crp(2) - crp_rows.crp(1)
addr_delta = crp_rows.descriptor_addr(2) - crp_rows.descriptor_addr(1)
```

Expected:

```text
crp_delta  = 8192
addr_delta = 8192
```

This is a useful MATLAB-table technique:

```matlab
T(condition, :)
```

means:

```text
select the rows where condition is true,
and keep all columns
```

while:

```matlab
T(condition, {'column_a','column_b'})
```

selects those rows and only the named columns.

## Stop point

Send back:

1. the displayed `5x22` generator result;
2. the compact alternate-CRP table;
3. `crp_delta`;
4. `addr_delta`.

Do not add the TC-span-change pair yet.

Step 16 will implement mandatory case 5, **TC span change**, using the same VA and CRP under two TC values so one row is in range and the other is out of range.
