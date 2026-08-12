# MTC1 Human-Guided MATLAB Workflow — Step 7

**Packet:** MTC1
**Branch:** `matlab/mtc1-tc-crp-span-reference`
**Goal of this step:** extract the current table span from the low `VPN_WIDTH` bits of `TC` and decide whether the VPN is in range.

## What Step 6 proved

The remaining scalar inputs are now being accepted and preserved correctly:

```text
FC  = 1
CRP = 4096   = 0x001000
SRP = 8192   = 0x002000
TC  = 4
```

The previously verified address split also remains correct:

```text
VA          = 0x012345
VPN         = 18
PAGE_OFFSET = 0x345 = 837
```

We are now ready for the first MTC1-specific span decision.

## Repository anchor

**Verified repository fact:** for the current MTC1 boundary, `rtl/core/mmu_top.v` derives the configured table-entry span from:

```verilog
assign table_entries_cfg = tc_q[VPN_WIDTH-1:0];
```

MTC1 models that current implemented behavior only. This is not a claim that the low bits of the real MC68851 TC register have this meaning; full Motorola TC geometry is deferred.

## Step 7A — Extract `TABLE_ENTRIES`

In `mmu_tc_crp_span_reference.m`, place the following code after the `tc` validation block and before the temporary `R = struct(...)` block:

```matlab
    table_mask = bitshift(uint64(1), vpn_width) - uint64(1);
    table_entries = bitand(tc_u, table_mask);
```

### What this does

With the default configuration:

```text
VPN_WIDTH = 12
```

this expression:

```matlab
bitshift(uint64(1), vpn_width) - uint64(1)
```

produces a 12-bit mask:

```text
0xFFF
```

Then:

```matlab
table_entries = bitand(tc_u, table_mask);
```

keeps only the low 12 bits of `TC`.

For our current test value:

```text
TC = 4 = 0x00000004
```

the result is:

```text
TABLE_ENTRIES = 4
```

Therefore the valid VPN span is:

```text
VPN 0
VPN 1
VPN 2
VPN 3
```

There are four entries total.

## Step 7B — Make the range decision

Immediately after the extraction above, add:

```matlab
    in_range = vpn < table_entries;
```

The strict `<` is important.

For:

```text
TABLE_ENTRIES = 4
```

we expect:

```text
VPN = 3  -> in range
VPN = 4  -> out of range
```

So `TABLE_ENTRIES` behaves as a count, not as the number of the last valid entry.

## Step 7C — Add the two fields to `R`

In your current `R = struct(...)` block, add these two fields after `page_offset`:

```matlab
        'table_entries', table_entries, ...
        'in_range',      in_range);
```

Because `page_offset` is no longer the final field, change its current line from:

```matlab
        'page_offset', page_offset);
```

to:

```matlab
        'page_offset',   page_offset, ...
```

The end of the structure should therefore look like:

```matlab
        'vpn',           vpn, ...
        'page_offset',   page_offset, ...
        'table_entries', table_entries, ...
        'in_range',      in_range);
```

Save with **Ctrl+S**.

## Step 7D — Test the last in-range VPN

Run:

```matlab
Rlast = mmu_tc_crp_span_reference( ...
    hex2dec('003345'), ...
    1, ...
    hex2dec('001000'), ...
    hex2dec('002000'), ...
    4, ...
    struct())
```

The important values should be:

```text
VPN           = 3
PAGE_OFFSET   = 837
TABLE_ENTRIES = 4
IN_RANGE      = 1
```

MATLAB displays logical true as:

```text
1
```

## Step 7E — Test the first out-of-range VPN

Then run:

```matlab
Rout = mmu_tc_crp_span_reference( ...
    hex2dec('004345'), ...
    1, ...
    hex2dec('001000'), ...
    hex2dec('002000'), ...
    4, ...
    struct())
```

The important values should now be:

```text
VPN           = 4
PAGE_OFFSET   = 837
TABLE_ENTRIES = 4
IN_RANGE      = 0
```

The offset stays identical because both addresses end in `0x345`. Only the VPN crossed the table-span boundary.

## Stop point

Send back the displayed `Rlast` and `Rout` results, or the exact MATLAB error.

Do not add descriptor-request or descriptor-address logic yet.

Once these two boundary cases pass, the next step will turn the span decision into:

```text
DESCRIPTOR_REQUEST  = IN_RANGE
PREWALK_FAULT       = none / unmapped_span
ROOT_SOURCE         = CRP
SRP_USED            = false
```

without calculating the descriptor address yet.
