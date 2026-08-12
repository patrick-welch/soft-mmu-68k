# MTC1 Human-Guided MATLAB Workflow — Step 14

**Packet:** MTC1
**Branch:** `matlab/mtc1-tc-crp-span-reference`
**Goal of this step:** add the first out-of-range VPN and complete the three-row span-boundary sequence.

## What Step 13 proved

The generator now returns two correct in-range rows:

```text
first_in_range_vpn:
    VPN                    = 0
    TABLE_ENTRIES          = 4
    DESCRIPTOR_ADDR        = 4096

last_in_range_vpn:
    VPN                    = 3
    TABLE_ENTRIES          = 4
    DESCRIPTOR_ADDR        = 4120
```

The descriptor-address difference is:

```text
4120 - 4096 = 24 bytes
```

which matches:

```text
3 VPN entries * 8 bytes per descriptor = 24 bytes
```

Now we will cross the exact span boundary.

## Step 14A — Append the first out-of-range VPN

In `generate_tc_crp_span_vectors.m`, leave Steps 12 and 13 unchanged.

Immediately after:

```matlab
    T = [T; row_last];
```

and before the final `end`, add:

```matlab
    % Step 14: Append the first out-of-range VPN and verify pre-walk rejection.
    R_out = mmu_tc_crp_span_reference( ...
        hex2dec('004345'), ...
        1, ...
        hex2dec('001000'), ...
        hex2dec('002000'), ...
        4, ...
        struct());

    metadata_out = table( ...
        "first_out_of_range_vpn", ...
        "baseline", ...
        'VariableNames', {'case_name', 'variant'});

    row_out = [metadata_out struct2table(R_out)];
    T = [T; row_out];
```

Save with **Ctrl+S**.

## What this case means

The virtual address is:

```text
VA = 0x004345
```

With:

```text
PAGE_SHIFT = 12
```

that gives:

```text
VPN         = 4
PAGE_OFFSET = 0x345 = 837
```

The span is still:

```text
TABLE_ENTRIES = 4
```

so the legal VPNs remain:

```text
0, 1, 2, 3
```

VPN 4 is therefore the **first out-of-range VPN**.

The scalar model should produce:

```text
IN_RANGE               = false
DESCRIPTOR_REQUEST      = false
DESCRIPTOR_ADDR_VALID   = false
DESCRIPTOR_ADDR         = 0
PREWALK_FAULT           = "unmapped_span"
```

The zero descriptor address is only a sentinel because the validity flag is false.

This satisfies mandatory directed case 3.

## Step 14B — Run the generator

In the Command Window, run:

```matlab
T = generate_tc_crp_span_vectors()
```

Expected size:

```text
3x22 table
```

The rows should now be:

```text
1. first_in_range_vpn
2. last_in_range_vpn
3. first_out_of_range_vpn
```

## Step 14C — Inspect the complete span boundary

Run:

```matlab
T(:, { ...
    'case_name', ...
    'vpn', ...
    'table_entries', ...
    'in_range', ...
    'descriptor_request', ...
    'descriptor_addr_valid', ...
    'descriptor_addr', ...
    'prewalk_fault'})
```

Expected comparison:

```text
first_in_range_vpn
    VPN = 0
    TABLE_ENTRIES = 4
    IN_RANGE = true
    DESCRIPTOR_REQUEST = true
    DESCRIPTOR_ADDR_VALID = true
    DESCRIPTOR_ADDR = 4096
    PREWALK_FAULT = "none"

last_in_range_vpn
    VPN = 3
    TABLE_ENTRIES = 4
    IN_RANGE = true
    DESCRIPTOR_REQUEST = true
    DESCRIPTOR_ADDR_VALID = true
    DESCRIPTOR_ADDR = 4120
    PREWALK_FAULT = "none"

first_out_of_range_vpn
    VPN = 4
    TABLE_ENTRIES = 4
    IN_RANGE = false
    DESCRIPTOR_REQUEST = false
    DESCRIPTOR_ADDR_VALID = false
    DESCRIPTOR_ADDR = 0
    PREWALK_FAULT = "unmapped_span"
```

## Why this three-row sequence matters

These rows pin down the exact meaning of the span comparison:

```text
VPN < TABLE_ENTRIES
```

not:

```text
VPN <= TABLE_ENTRIES
```

For a four-entry table:

```text
VPN 3 -> allowed
VPN 4 -> rejected
```

That boundary is the central behavior MTC1 is intended to make reproducible.

## Stop point

Send back:

1. the displayed `T = generate_tc_crp_span_vectors()` result;
2. the compact eight-column boundary display.

Do not add alternate-CRP cases yet.

Step 15 will start mandatory case 4, **alternate CRP**, using two rows with the same VA and span so we can see the descriptor address move only because the root base changed.
