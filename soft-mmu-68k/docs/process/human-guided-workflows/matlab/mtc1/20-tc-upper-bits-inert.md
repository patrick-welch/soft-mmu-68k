# MTC1 Human-Guided MATLAB Workflow — Step 20

**Packet:** MTC1
**Branch:** `matlab/mtc1-tc-crp-span-reference`
**Goal of this step:** add mandatory case 9, **TC upper bits inert**, and complete the approved 13-row generator.

## What Step 19 proved

The zero-span case behaved correctly:

```text
VPN                    = 0
TABLE_ENTRIES          = 0
IN_RANGE               = false
DESCRIPTOR_REQUEST     = false
DESCRIPTOR_ADDR_VALID  = false
DESCRIPTOR_ADDR        = 0
PREWALK_FAULT          = "unmapped_span"
```

The explicit comparison:

```matlab
zero_row.vpn < zero_row.table_entries
```

returned:

```text
logical 0
```

which is exactly the intended `0 < 0` boundary result.

We now have only one mandatory conceptual generator case left.

## Step 20A — Append the TC-upper-bits-inert pair

In `generate_tc_crp_span_vectors.m`, leave Steps 12–19 unchanged.

Immediately after:

```matlab
    T = [T; row_zero_span];
```

and before the final `end`, add:

```matlab
    % Step 20: Show that TC bits above VPN_WIDTH do not affect the current span.
    R_tc_low = mmu_tc_crp_span_reference( ...
        hex2dec('002345'), ...
        1, ...
        hex2dec('001000'), ...
        hex2dec('002000'), ...
        hex2dec('000004'), ...
        struct());

    metadata_tc_low = table( ...
        "tc_upper_bits_inert", ...
        "low_bits_only", ...
        'VariableNames', {'case_name', 'variant'});

    row_tc_low = [metadata_tc_low struct2table(R_tc_low)];

    R_tc_upper = mmu_tc_crp_span_reference( ...
        hex2dec('002345'), ...
        1, ...
        hex2dec('001000'), ...
        hex2dec('002000'), ...
        hex2dec('001004'), ...
        struct());

    metadata_tc_upper = table( ...
        "tc_upper_bits_inert", ...
        "upper_bit_set", ...
        'VariableNames', {'case_name', 'variant'});

    row_tc_upper = [metadata_tc_upper struct2table(R_tc_upper)];

    T = [T; row_tc_low; row_tc_upper];
```

Save with **Ctrl+S**.

## What these two TC values mean

With the default configuration:

```text
VA_WIDTH    = 24
PAGE_SHIFT  = 12
VPN_WIDTH   = 12
```

the current MTC1 span rule uses only the low 12 bits of `TC`.

The first TC value is:

```text
TC A = 0x000004
```

The second is:

```text
TC B = 0x001004
```

Bit 12 is different between them, but bit 12 is **above** the low 12-bit `VPN_WIDTH` field.

Their low 12 bits are therefore identical:

```text
TC A low 12 bits = 0x004
TC B low 12 bits = 0x004
```

so both must produce:

```text
TABLE_ENTRIES = 4
```

The VA is held constant:

```text
VA = 0x002345
```

which gives:

```text
VPN         = 2
PAGE_OFFSET = 837
```

Since VPN 2 is inside a four-entry span, both rows should be in range and both should select the same descriptor:

```text
DESCRIPTOR_ADDR
    = 4096 + 2 * 8
    = 4112
```

This satisfies mandatory directed case 9.

## Step 20B — Run the completed generator

In the MATLAB Command Window:

```matlab
T = generate_tc_crp_span_vectors()
```

Expected size:

```text
13x22 table
```

The final two rows should be:

```text
12. tc_upper_bits_inert / low_bits_only
13. tc_upper_bits_inert / upper_bit_set
```

At this point the generator contains all approved directed rows:

```text
1  first in-range VPN
1  last in-range VPN
1  first out-of-range VPN
2  alternate CRP
2  TC span change
1  SRP inert / supervisor access
2  same VPN / different page offset
1  zero table span
2  TC upper bits inert
-----------------------------------
13 rows total
```

## Step 20C — Inspect only the TC-upper-bits pair

Run:

```matlab
T(T.case_name == "tc_upper_bits_inert", { ...
    'case_name', ...
    'variant', ...
    'va', ...
    'vpn', ...
    'tc', ...
    'vpn_width', ...
    'table_entries', ...
    'in_range', ...
    'descriptor_request', ...
    'descriptor_addr'})
```

Expected important values:

```text
low_bits_only:
    VA                 = 9029
    VPN                = 2
    TC                 = 4
    VPN_WIDTH          = 12
    TABLE_ENTRIES      = 4
    IN_RANGE           = true
    DESCRIPTOR_REQUEST = true
    DESCRIPTOR_ADDR    = 4112

upper_bit_set:
    VA                 = 9029
    VPN                = 2
    TC                 = 4100
    VPN_WIDTH          = 12
    TABLE_ENTRIES      = 4
    IN_RANGE           = true
    DESCRIPTOR_REQUEST = true
    DESCRIPTOR_ADDR    = 4112
```

The decimal value `4100` is:

```text
0x1004
```

## Step 20D — Ask MATLAB to prove the intended relationships

Run:

```matlab
tc_rows = T(T.case_name == "tc_upper_bits_inert", :);

different_tc = tc_rows.tc(1) ~= tc_rows.tc(2)
same_table_entries = tc_rows.table_entries(1) == tc_rows.table_entries(2)
same_in_range = tc_rows.in_range(1) == tc_rows.in_range(2)
same_descriptor = tc_rows.descriptor_addr(1) == ...
    tc_rows.descriptor_addr(2)
```

Expected:

```text
different_tc =

  logical

   1

same_table_entries =

  logical

   1

same_in_range =

  logical

   1

same_descriptor =

  logical

   1
```

This is the key point:

```text
the complete 32-bit TC images are different,
but the current MTC1 behavior is identical because their low VPN_WIDTH bits match.
```

## Step 20E — Confirm the generator row count

Run:

```matlab
height(T)
```

Expected:

```text
ans =

    13
```

`height(T)` returns the number of rows in a MATLAB table.

## Stop point

Send back:

1. the displayed `13x22` generator result;
2. the compact TC-upper-bits table;
3. `different_tc`;
4. `same_table_entries`;
5. `same_in_range`;
6. `same_descriptor`;
7. `height(T)`.

Do not start the demo or README yet.

Once Step 20 passes, the **directed-case generator itself is functionally complete**. The next step will be a deliberate generator review/cleanup checkpoint before we move into README and demo work.
