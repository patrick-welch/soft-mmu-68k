# MTC1 Human-Guided MATLAB Workflow — Step 10

**Packet:** MTC1
**Branch:** `matlab/mtc1-tc-crp-span-reference`
**DEV Manager ruling:** Approved. Proceed with result-schema cleanup; retain `VA_WIDTH <= 64` and `FC_WIDTH <= 64` only as MATLAB `uint64` representation limits.

## What the DEV Manager approved

The ruling confirms:

```text
VA_WIDTH <= 64
FC_WIDTH <= 64
```

may remain in MTC1, but only as MATLAB implementation representation constraints. They are not MC68851, SM68861, or Motorola-family architectural limits.

The ruling also approves the Step 10 schema cleanup:

```text
- keep descr_width and fc_width as configuration/validation inputs;
- remove descr_width and fc_width from returned R;
- return exactly the canonical approved fields;
- return them in the approved order;
- run one normal scalar call;
- inspect fieldnames(R);
```

The existing implementation already special-cases width 64 when calculating `max_va` and `max_fc`, so it does not attempt to represent `2^64` in a `uint64`.

## Step 10A — Add the Step 10 annotation

Immediately before the final `R = struct(...)` construction, add:

```matlab
    % Step 10: Return the canonical MTC1 result schema in approved order.
```

This continues the annotation convention beginning with Step 9.

## Step 10B — Replace the current result structure

Replace the entire current `R = struct(...)` block with:

```matlab
    % Step 10: Return the canonical MTC1 result schema in approved order.
    R = struct( ...
        'va',                    va_u, ...
        'fc',                    fc_u, ...
        'crp',                   crp_u, ...
        'srp',                   srp_u, ...
        'tc',                    tc_u, ...
        'va_width',              opts.va_width, ...
        'pa_width',              opts.pa_width, ...
        'page_shift',            opts.page_shift, ...
        'vpn_width',             vpn_width, ...
        'descr_bytes',           descr_bytes, ...
        'vpn',                   vpn, ...
        'page_offset',           page_offset, ...
        'table_entries',         table_entries, ...
        'in_range',              in_range, ...
        'descriptor_request',    descriptor_request, ...
        'descriptor_addr_valid', descriptor_addr_valid, ...
        'descriptor_addr',       descriptor_addr, ...
        'root_source',           root_source, ...
        'srp_used',              srp_used, ...
        'prewalk_fault',         prewalk_fault);
```

Notice what disappeared from the returned structure:

```text
descr_width
fc_width
```

They still remain in `opts`, still receive defaults, and still participate in validation. We are only removing them from the public result structure so `R` matches the packet-approved schema.

Save with **Ctrl+S**.

## Step 10C — Run one normal scalar call

Use the last-in-range case again:

```matlab
R = mmu_tc_crp_span_reference( ...
    hex2dec('003345'), ...
    1, ...
    hex2dec('001000'), ...
    hex2dec('002000'), ...
    4, ...
    struct())
```

The values should still include:

```text
va                    = 13125
fc                    = 1
crp                   = 4096
srp                   = 8192
tc                    = 4
va_width              = 24
pa_width              = 24
page_shift            = 12
vpn_width             = 12
descr_bytes           = 8
vpn                   = 3
page_offset           = 837
table_entries         = 4
in_range              = 1
descriptor_request    = 1
descriptor_addr_valid = 1
descriptor_addr       = 4120
root_source           = "CRP"
srp_used              = 0
prewalk_fault         = "none"
```

There should no longer be `descr_width` or `fc_width` fields in `R`.

## Step 10D — Inspect the exact field list

Now run:

```matlab
fieldnames(R)
```

Expected field sequence:

```text
va
fc
crp
srp
tc
va_width
pa_width
page_shift
vpn_width
descr_bytes
vpn
page_offset
table_entries
in_range
descriptor_request
descriptor_addr_valid
descriptor_addr
root_source
srp_used
prewalk_fault
```

That is the canonical MTC1 result schema approved by the DEV Manager.

## Stop point

Send back:

1. the displayed `R` result;
2. the output of `fieldnames(R)`.

Do not start the generator yet.

Once Step 10 is verified, we will do the requested whole-file annotation pass for Steps 1–10 before beginning the generator.
