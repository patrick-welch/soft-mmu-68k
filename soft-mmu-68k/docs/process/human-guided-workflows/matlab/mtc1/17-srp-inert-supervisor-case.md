# MTC1 Human-Guided MATLAB Workflow — Step 17

**Packet:** MTC1
**Branch:** `matlab/mtc1-tc-crp-span-reference`
**Goal of this step:** add mandatory case 6, **SRP inert / supervisor-class access**.

## What Step 16 proved

The TC-span pair behaves correctly:

```text
same VA, VPN, CRP, SRP, and page geometry

TC = 4 -> TABLE_ENTRIES = 4 -> VPN 3 is in range
TC = 3 -> TABLE_ENTRIES = 3 -> VPN 3 is out of range
```

The logical mask:

```text
0
0
0
0
0
1
1
```

also showed exactly how MATLAB selects the two `tc_span_change` rows.

We now test a different current-project behavior: a supervisor-class function code must **not** cause MTC1 to select SRP.

## Repository anchor for the FC value

Current `mmu_decode.v` defines:

```text
FC 3'b101 = supervisor data
FC 3'b110 = supervisor program
```

For this directed case we will use:

```text
FC = 5 = 3'b101 = supervisor data
```

This is only being used to make the test clearly supervisor-class. MTC1 still preserves FC without implementing architectural CRP/SRP root selection.

## Step 17A — Append the SRP-inert case

In `generate_tc_crp_span_vectors.m`, leave Steps 12–16 unchanged.

Immediately after:

```matlab
    T = [T; row_span_in; row_span_out];
```

and before the final `end`, add:

```matlab
    % Step 17: Show that a supervisor-class FC still uses CRP and leaves SRP inert.
    R_srp = mmu_tc_crp_span_reference( ...
        hex2dec('002345'), ...
        5, ...
        hex2dec('001000'), ...
        hex2dec('00A000'), ...
        4, ...
        struct());

    metadata_srp = table( ...
        "srp_inert_supervisor", ...
        "supervisor_data", ...
        'VariableNames', {'case_name', 'variant'});

    row_srp = [metadata_srp struct2table(R_srp)];
    T = [T; row_srp];
```

Save with **Ctrl+S**.

## What this case means

The important inputs are deliberately separated:

```text
FC  = 5          supervisor-data class
CRP = 0x001000   4096
SRP = 0x00A000   40960
VA  = 0x002345
TC  = 4
```

The SRP is intentionally far away from the CRP so accidental SRP use would be obvious.

The address still gives:

```text
VPN         = 2
PAGE_OFFSET = 837
```

and because:

```text
TABLE_ENTRIES = 4
```

the VPN is in range.

## Step 17B — Work out the expected address

MTC1 says the current root source remains:

```text
ROOT_SOURCE = CRP
SRP_USED    = false
```

Therefore:

```text
DESCRIPTOR_ADDR
    = CRP + VPN * DESCR_BYTES
    = 4096 + 2 * 8
    = 4112
    = 0x001010
```

If SRP were being used instead, the address would have been:

```text
0x00A000 + 2 * 8
= 0x00A010
= 40976
```

We do **not** expect that result.

This makes the directed case easy to inspect.

## Step 17C — Run the generator

In the Command Window:

```matlab
T = generate_tc_crp_span_vectors()
```

Expected size:

```text
8x22 table
```

The new row should be:

```text
8. srp_inert_supervisor / supervisor_data
```

## Step 17D — Inspect only the SRP-inert row

Run:

```matlab
T(T.case_name == "srp_inert_supervisor", { ...
    'case_name', ...
    'variant', ...
    'fc', ...
    'va', ...
    'vpn', ...
    'crp', ...
    'srp', ...
    'in_range', ...
    'descriptor_request', ...
    'descriptor_addr', ...
    'root_source', ...
    'srp_used', ...
    'prewalk_fault'})
```

Expected values:

```text
case_name          = "srp_inert_supervisor"
variant            = "supervisor_data"
FC                 = 5
VPN                = 2
CRP                = 4096
SRP                = 40960
IN_RANGE           = true
DESCRIPTOR_REQUEST = true
DESCRIPTOR_ADDR    = 4112
ROOT_SOURCE        = "CRP"
SRP_USED           = false
PREWALK_FAULT      = "none"
```

## Step 17E — A small explicit check

Run:

```matlab
srp_row = T(T.case_name == "srp_inert_supervisor", :);

srp_row.descriptor_addr == srp_row.crp + ...
    srp_row.vpn * uint64(srp_row.descr_bytes)
```

Expected result:

```text
ans =

  logical

   1
```

This asks MATLAB directly whether the recorded descriptor address equals the **CRP-based** formula.

## Stop point

Send back:

1. the displayed `8x22` generator result;
2. the compact SRP-inert row;
3. the logical result of the explicit CRP-based address check.

Do not add the page-offset pair yet.

Step 18 will implement mandatory case 7: **same VPN, different page offset**. That pair will prove that changing only the low page-offset bits changes `page_offset` but leaves the VPN and descriptor address unchanged.
