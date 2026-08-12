# MTC1 Human-Guided MATLAB Workflow — Step 8

**Packet:** MTC1
**Branch:** `matlab/mtc1-tc-crp-span-reference`
**Goal of this step:** convert the verified span decision into the current pre-walk control result.

## What Step 7 proved

The span boundary is behaving correctly:

```text
TC = 4

VPN = 3 -> TABLE_ENTRIES = 4 -> IN_RANGE = 1
VPN = 4 -> TABLE_ENTRIES = 4 -> IN_RANGE = 0
```

The identical page offset in both tests also confirms that only the VPN crossed the table boundary.

We can now derive four MTC1 result fields from that decision:

```text
DESCRIPTOR_REQUEST = IN_RANGE
ROOT_SOURCE        = CRP
SRP_USED           = false

PREWALK_FAULT =
    none            when IN_RANGE
    unmapped_span   when out of range
```

An in-range result only permits a descriptor request. It does **not** mean the translation has succeeded.

## Step 8A — Derive the control results

In `mmu_tc_crp_span_reference.m`, place the following code immediately after:

```matlab
    in_range = vpn < table_entries;
```

Add:

```matlab
    descriptor_request = in_range;
    root_source = "CRP";
    srp_used = false;

    if in_range
        prewalk_fault = "none";
    else
        prewalk_fault = "unmapped_span";
    end
```

## What this MATLAB means

This line:

```matlab
descriptor_request = in_range;
```

directly expresses the MTC1 boundary:

```text
in-range VPN     -> descriptor request allowed
out-of-range VPN -> no descriptor request
```

These two lines:

```matlab
root_source = "CRP";
srp_used = false;
```

make the current root-selection behavior explicit.

The model still accepts and preserves `srp`, but MTC1 intentionally does not use it to select the root.

The final `if` block gives us a readable model-level pre-walk result:

```text
"none"
```

or:

```text
"unmapped_span"
```

These strings are MTC1 reference-model labels. They are not being presented as Motorola hardware fault-code encodings.

## Step 8B — Add the four fields to `R`

At the end of your current `R = struct(...)` block, change:

```matlab
        'table_entries', table_entries, ...
        'in_range',      in_range);
```

to:

```matlab
        'table_entries',      table_entries, ...
        'in_range',           in_range, ...
        'descriptor_request', descriptor_request, ...
        'root_source',        root_source, ...
        'srp_used',           srp_used, ...
        'prewalk_fault',      prewalk_fault);
```

Save with **Ctrl+S**.

## Step 8C — Rerun the last in-range case

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

The important new fields should be:

```text
descriptor_request: 1
root_source:        "CRP"
srp_used:            0
prewalk_fault:      "none"
```

## Step 8D — Rerun the first out-of-range case

Run:

```matlab
Rout = mmu_tc_crp_span_reference( ...
    hex2dec('004345'), ...
    1, ...
    hex2dec('001000'), ...
    hex2dec('002000'), ...
    4, ...
    struct())
```

The important new fields should be:

```text
descriptor_request: 0
root_source:        "CRP"
srp_used:            0
prewalk_fault:      "unmapped_span"
```

## Stop point

Send back the displayed `Rlast` and `Rout` results, or the exact MATLAB error.

Do not calculate the descriptor address yet.

Once these fields are verified, the next step will add:

```text
DESCRIPTOR_ADDR = CRP + VPN * DESCR_BYTES
```

for in-range requests, including the required PA-width overflow check and the `descriptor_addr_valid` result.
