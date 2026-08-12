# MTC1 Human-Guided MATLAB Workflow — Step 18

**Packet:** MTC1
**Branch:** `matlab/mtc1-tc-crp-span-reference`
**Goal of this step:** add mandatory case 7, **same VPN / different page offset**, as a two-row comparison.

## What Step 17 proved

The supervisor-class SRP-inert case behaved exactly as intended:

```text
FC                 = 5
CRP                = 4096
SRP                = 40960
VPN                = 2
DESCRIPTOR_ADDR    = 4112
ROOT_SOURCE        = "CRP"
SRP_USED           = false
```

The explicit CRP-based formula check also returned:

```text
logical 1
```

So the current MTC1 behavior remains CRP-rooted even with a supervisor-class function code and a clearly different SRP.

We now test a different address property:

```text
changing only the page-offset bits must not change the VPN
or the descriptor address.
```

## Step 18A — Append the page-offset pair

In `generate_tc_crp_span_vectors.m`, leave Steps 12–17 unchanged.

Immediately after:

```matlab
    T = [T; row_srp];
```

and before the final `end`, add:

```matlab
    % Step 18: Compare two VAs with the same VPN but different page offsets.
    R_offset_a = mmu_tc_crp_span_reference( ...
        hex2dec('002123'), ...
        1, ...
        hex2dec('001000'), ...
        hex2dec('002000'), ...
        4, ...
        struct());

    metadata_offset_a = table( ...
        "same_vpn_different_offset", ...
        "offset_123", ...
        'VariableNames', {'case_name', 'variant'});

    row_offset_a = [metadata_offset_a struct2table(R_offset_a)];

    R_offset_b = mmu_tc_crp_span_reference( ...
        hex2dec('002ABC'), ...
        1, ...
        hex2dec('001000'), ...
        hex2dec('002000'), ...
        4, ...
        struct());

    metadata_offset_b = table( ...
        "same_vpn_different_offset", ...
        "offset_abc", ...
        'VariableNames', {'case_name', 'variant'});

    row_offset_b = [metadata_offset_b struct2table(R_offset_b)];

    T = [T; row_offset_a; row_offset_b];
```

Save with **Ctrl+S**.

## What these addresses mean

Both virtual addresses are in VPN 2:

```text
VA A = 0x002123
VA B = 0x002ABC
```

With:

```text
PAGE_SHIFT = 12
```

the upper bits produce:

```text
VPN A = 2
VPN B = 2
```

while the low twelve bits produce different offsets:

```text
PAGE_OFFSET A = 0x123 = 291
PAGE_OFFSET B = 0xABC = 2748
```

Everything else is held constant:

```text
FC  = 1
CRP = 0x001000
SRP = 0x002000
TC  = 4
```

Because both rows have VPN 2, both should use the same descriptor:

```text
DESCRIPTOR_ADDR
    = CRP + VPN * DESCR_BYTES
    = 4096 + 2 * 8
    = 4112
    = 0x001010
```

The page offset does not participate in descriptor-address selection.

This satisfies mandatory directed case 7.

## Step 18B — Run the generator

In the Command Window:

```matlab
T = generate_tc_crp_span_vectors()
```

Expected size:

```text
10x22 table
```

The new rows should be:

```text
9.  same_vpn_different_offset / offset_123
10. same_vpn_different_offset / offset_abc
```

## Step 18C — Inspect only the page-offset pair

Run:

```matlab
T(T.case_name == "same_vpn_different_offset", { ...
    'case_name', ...
    'variant', ...
    'va', ...
    'vpn', ...
    'page_offset', ...
    'table_entries', ...
    'in_range', ...
    'descriptor_addr'})
```

Expected comparison:

```text
offset_123:
    VA              = 8483
    VPN             = 2
    PAGE_OFFSET     = 291
    TABLE_ENTRIES   = 4
    IN_RANGE        = true
    DESCRIPTOR_ADDR = 4112

offset_abc:
    VA              = 10940
    VPN             = 2
    PAGE_OFFSET     = 2748
    TABLE_ENTRIES   = 4
    IN_RANGE        = true
    DESCRIPTOR_ADDR = 4112
```

## Step 18D — Ask MATLAB to prove the three relationships

Run:

```matlab
offset_rows = T(T.case_name == "same_vpn_different_offset", :);

same_vpn = offset_rows.vpn(1) == offset_rows.vpn(2)
different_offset = offset_rows.page_offset(1) ~= offset_rows.page_offset(2)
same_descriptor = offset_rows.descriptor_addr(1) == ...
    offset_rows.descriptor_addr(2)
```

Expected:

```text
same_vpn =

  logical

   1

different_offset =

  logical

   1

same_descriptor =

  logical

   1
```

The MATLAB operator:

```matlab
~=
```

means **not equal**.

So this line:

```matlab
offset_rows.page_offset(1) ~= offset_rows.page_offset(2)
```

asks whether the two page offsets are different.

## Stop point

Send back:

1. the displayed `10x22` generator result;
2. the compact page-offset pair;
3. `same_vpn`;
4. `different_offset`;
5. `same_descriptor`.

Do not add the zero-span case yet.

Step 19 will implement mandatory case 8, **zero table span**, where `TC` contributes zero table entries and even VPN 0 must be rejected before a descriptor request.
