# MTC1 Human-Guided MATLAB Workflow — Step 24

**Packet:** MTC1
**Branch:** `matlab/mtc1-tc-crp-span-reference`
**Goal:** add the first small group of demo assertions: table structure and the core span-boundary invariants.

## Where we are

The demo shell already runs successfully and reports:

```text
rows:               13
conceptual cases:   9
```

Do not rewrite the demo. Keep the existing location-aware setup, generator call, table display, and summary.

For Step 24, we will append a compact assertion block to the **end** of:

```text
scripts/matlab/examples/run_tc_crp_span_demo.m
```

## Step 24A — Add the core assertion block

Immediately after the existing line:

```matlab
fprintf('  conceptual cases:   %d\n', numel(unique(T.case_name)));
```

add:

```matlab
% Step 24: Assert the generator shape and core TC-span boundary behavior.
assert(height(T) == 13, ...
    'MTC1 demo expected exactly 13 directed rows.');

assert(numel(unique(T.case_name)) == 9, ...
    'MTC1 demo expected exactly 9 conceptual cases.');

first_row = T(T.case_name == "first_in_range_vpn", :);
assert(height(first_row) == 1, ...
    'Expected exactly one first_in_range_vpn row.');
assert(first_row.vpn == 0 && ...
       first_row.in_range && ...
       first_row.descriptor_request && ...
       first_row.descriptor_addr_valid && ...
       first_row.descriptor_addr == first_row.crp, ...
    'First in-range VPN invariant failed.');

last_row = T(T.case_name == "last_in_range_vpn", :);
assert(height(last_row) == 1, ...
    'Expected exactly one last_in_range_vpn row.');
assert(last_row.vpn + uint64(1) == last_row.table_entries && ...
       last_row.in_range && ...
       last_row.descriptor_request && ...
       last_row.descriptor_addr_valid, ...
    'Last in-range VPN invariant failed.');

out_row = T(T.case_name == "first_out_of_range_vpn", :);
assert(height(out_row) == 1, ...
    'Expected exactly one first_out_of_range_vpn row.');
assert(out_row.vpn == out_row.table_entries && ...
       ~out_row.in_range && ...
       ~out_row.descriptor_request && ...
       ~out_row.descriptor_addr_valid && ...
       out_row.descriptor_addr == uint64(0) && ...
       out_row.prewalk_fault == "unmapped_span", ...
    'First out-of-range VPN invariant failed.');

zero_row = T(T.case_name == "zero_table_span", :);
assert(height(zero_row) == 1, ...
    'Expected exactly one zero_table_span row.');
assert(zero_row.vpn == 0 && ...
       zero_row.table_entries == 0 && ...
       ~zero_row.in_range && ...
       ~zero_row.descriptor_request && ...
       zero_row.prewalk_fault == "unmapped_span", ...
    'Zero-span invariant failed.');

fprintf('Step 24 core assertions passed.\n');
```

Save with **Ctrl+S**.

## What `assert` does

A MATLAB statement such as:

```matlab
assert(height(T) == 13, ...
    'MTC1 demo expected exactly 13 directed rows.');
```

means:

```text
evaluate the condition;
if it is true, continue silently;
if it is false, stop the script and report the supplied message.
```

So the demo is beginning to serve two purposes:

```text
human inspection -> display the table and summary
machine check     -> fail immediately if an invariant changes
```

## Why these assertions come first

This first group checks only the most central MTC1 invariants:

```text
13 directed rows
9 conceptual cases
VPN 0 is the first valid entry for a nonzero span
VPN TABLE_ENTRIES-1 is the last valid entry
VPN TABLE_ENTRIES is rejected
zero table span rejects even VPN 0
```

We are deliberately **not** adding all paired-comparison assertions in this step.

## Step 24B — Run the demo again

From the repository root in MATLAB:

```matlab
run('scripts/matlab/examples/run_tc_crp_span_demo.m')
```

The full table and summary should still display.

At the end, you should now also see:

```text
Step 24 core assertions passed.
```

There should be no assertion error.

## Stop point

Send back the final portion of the demo output showing:

```text
MTC1 summary:
  rows:               13
  conceptual cases:   9
Step 24 core assertions passed.
```

If that passes, Step 25 will add the paired-comparison assertions for:

```text
alternate CRP
TC span change
SRP inert
same VPN / different page offset
TC upper bits inert
```

That will complete the demo's packet-invariant checking.
