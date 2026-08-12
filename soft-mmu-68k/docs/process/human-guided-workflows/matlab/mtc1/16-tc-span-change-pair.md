# MTC1 Human-Guided MATLAB Workflow — Step 16

**Packet:** MTC1
**Branch:** `matlab/mtc1-tc-crp-span-reference`
**Goal of this step:** add mandatory case 5, **TC span change**, as a paired in-range/out-of-range comparison.

## First: the `condition` error is harmless

This command:

```matlab
T(condition, :)
```

was explanatory pseudocode, not a literal command to run.

MATLAB interpreted `condition` as the name of a variable, and because no variable named `condition` exists, it correctly reported:

```text
Unrecognized function or variable 'condition'.
```

A real condition looks like the expression you had already used successfully:

```matlab
T(T.case_name == "alternate_crp", :)
```

Here:

```matlab
T.case_name == "alternate_crp"
```

produces a logical row-selection vector, and `:` means keep all columns.

Nothing needs to be fixed because of that error.

## What Step 15 proved

The alternate-CRP pair is correct:

```text
crp_a:
    CRP             = 4096
    DESCRIPTOR_ADDR = 4112

crp_b:
    CRP             = 12288
    DESCRIPTOR_ADDR = 12304
```

MATLAB calculated:

```text
CRP delta        = 8192
descriptor delta = 8192
```

Both values were displayed as `uint64`, which is expected because the scalar model preserves these address-like values using unsigned 64-bit integers.

That proves that, for identical VA and table geometry, changing only the CRP base moves the descriptor address by exactly the same amount.

## Step 16A — Append the TC-span-change pair

In `generate_tc_crp_span_vectors.m`, leave Steps 12–15 unchanged.

Immediately after:

```matlab
    T = [T; row_crp_a; row_crp_b];
```

and before the final `end`, add:

```matlab
    % Step 16: Compare two TC spans with the same VA and CRP.
    R_span_in = mmu_tc_crp_span_reference( ...
        hex2dec('003345'), ...
        1, ...
        hex2dec('001000'), ...
        hex2dec('002000'), ...
        4, ...
        struct());

    metadata_span_in = table( ...
        "tc_span_change", ...
        "span_4_in", ...
        'VariableNames', {'case_name', 'variant'});

    row_span_in = [metadata_span_in struct2table(R_span_in)];

    R_span_out = mmu_tc_crp_span_reference( ...
        hex2dec('003345'), ...
        1, ...
        hex2dec('001000'), ...
        hex2dec('002000'), ...
        3, ...
        struct());

    metadata_span_out = table( ...
        "tc_span_change", ...
        "span_3_out", ...
        'VariableNames', {'case_name', 'variant'});

    row_span_out = [metadata_span_out struct2table(R_span_out)];

    T = [T; row_span_in; row_span_out];
```

Save with **Ctrl+S**.

## What stays constant

Both rows use:

```text
VA          = 0x003345
FC          = 1
CRP         = 0x001000
SRP         = 0x002000
PAGE_SHIFT  = 12
DESCR_BYTES = 8
```

Therefore both rows have:

```text
VPN         = 3
PAGE_OFFSET = 837
```

Only `TC` changes.

## What changes

For:

```text
TC = 4
```

the current MTC1 model derives:

```text
TABLE_ENTRIES = 4
```

so:

```text
VPN 3 < 4
```

and the row is in range.

For:

```text
TC = 3
```

the model derives:

```text
TABLE_ENTRIES = 3
```

so:

```text
VPN 3 < 3
```

is false and the row becomes out of range.

This is mandatory directed case 5: the same VA/CRP moves between allowed and rejected solely because the current TC span changes.

## Step 16B — Run the generator

In the Command Window:

```matlab
T = generate_tc_crp_span_vectors()
```

Expected size:

```text
7x22 table
```

The two new rows should be:

```text
6. tc_span_change / span_4_in
7. tc_span_change / span_3_out
```

## Step 16C — Inspect just the TC-span pair

Run:

```matlab
T(T.case_name == "tc_span_change", { ...
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

Expected comparison:

```text
span_4_in:
    VPN                    = 3
    TC                     = 4
    TABLE_ENTRIES          = 4
    IN_RANGE               = true
    DESCRIPTOR_REQUEST     = true
    DESCRIPTOR_ADDR_VALID  = true
    DESCRIPTOR_ADDR        = 4120
    PREWALK_FAULT          = "none"

span_3_out:
    VPN                    = 3
    TC                     = 3
    TABLE_ENTRIES          = 3
    IN_RANGE               = false
    DESCRIPTOR_REQUEST     = false
    DESCRIPTOR_ADDR_VALID  = false
    DESCRIPTOR_ADDR        = 0
    PREWALK_FAULT          = "unmapped_span"
```

## The MATLAB idea to notice

This expression:

```matlab
T.case_name == "tc_span_change"
```

creates one logical value per table row.

With seven rows, it will conceptually look like:

```text
false
false
false
false
false
true
true
```

MATLAB then uses those logical values as a row mask.

If you want to see the mask itself, you may run:

```matlab
T.case_name == "tc_span_change"
```

That is optional, but it makes the table-selection syntax much less mysterious.

## Stop point

Send back:

1. the displayed `7x22` generator result;
2. the compact TC-span comparison table;
3. optionally, the logical mask from `T.case_name == "tc_span_change"` if you choose to inspect it.

Do not add the SRP-inert case yet.

Step 17 will implement mandatory case 6: **SRP inert / supervisor-class access**.
