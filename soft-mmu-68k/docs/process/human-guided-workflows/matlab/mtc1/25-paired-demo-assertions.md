# MTC1 Human-Guided MATLAB Workflow — Step 25

**Packet:** MTC1
**Branch:** `matlab/mtc1-tc-crp-span-reference`
**Goal:** add the paired-comparison assertions and complete the demo's MTC1 packet-invariant checks.

## Step 24 result

The demo still generated the complete 13-row table and reported:

```text
MTC1 summary:
  rows:               13
  conceptual cases:   9
Step 24 core assertions passed.
```

So the core boundary assertions are working.

Step 25 adds assertions for the five remaining comparison concepts:

```text
alternate CRP
TC span change
SRP inert / supervisor-class access
same VPN / different page offset
TC upper bits inert
```

## Step 25A — Append the paired-comparison assertion block

In:

```text
scripts/matlab/examples/run_tc_crp_span_demo.m
```

leave all existing Step 23 and Step 24 code unchanged.

Immediately after:

```matlab
fprintf('Step 24 core assertions passed.\n');
```

add:

```matlab
% Step 25: Assert the paired MTC1 comparison cases.

crp_rows = T(T.case_name == "alternate_crp", :);
assert(height(crp_rows) == 2, ...
    'Expected exactly two alternate_crp rows.');
assert(crp_rows.va(1) == crp_rows.va(2) && ...
       crp_rows.vpn(1) == crp_rows.vpn(2) && ...
       crp_rows.table_entries(1) == crp_rows.table_entries(2) && ...
       crp_rows.crp(1) ~= crp_rows.crp(2), ...
    'Alternate-CRP setup invariant failed.');
assert(crp_rows.crp(2) - crp_rows.crp(1) == ...
       crp_rows.descriptor_addr(2) - crp_rows.descriptor_addr(1), ...
    'Alternate-CRP descriptor-address delta invariant failed.');

span_rows = T(T.case_name == "tc_span_change", :);
assert(height(span_rows) == 2, ...
    'Expected exactly two tc_span_change rows.');
assert(span_rows.va(1) == span_rows.va(2) && ...
       span_rows.vpn(1) == span_rows.vpn(2) && ...
       span_rows.crp(1) == span_rows.crp(2) && ...
       span_rows.table_entries(1) ~= span_rows.table_entries(2) && ...
       span_rows.in_range(1) && ...
       ~span_rows.in_range(2) && ...
       span_rows.descriptor_request(1) && ...
       ~span_rows.descriptor_request(2), ...
    'TC span-change invariant failed.');

srp_row = T(T.case_name == "srp_inert_supervisor", :);
assert(height(srp_row) == 1, ...
    'Expected exactly one srp_inert_supervisor row.');
assert(srp_row.root_source == "CRP" && ...
       ~srp_row.srp_used && ...
       srp_row.crp ~= srp_row.srp && ...
       srp_row.descriptor_addr == ...
           srp_row.crp + srp_row.vpn * uint64(srp_row.descr_bytes), ...
    'SRP-inert invariant failed.');

offset_rows = T(T.case_name == "same_vpn_different_offset", :);
assert(height(offset_rows) == 2, ...
    'Expected exactly two same_vpn_different_offset rows.');
assert(offset_rows.vpn(1) == offset_rows.vpn(2) && ...
       offset_rows.page_offset(1) ~= offset_rows.page_offset(2) && ...
       offset_rows.descriptor_addr(1) == offset_rows.descriptor_addr(2), ...
    'Same-VPN/different-offset invariant failed.');

tc_rows = T(T.case_name == "tc_upper_bits_inert", :);
assert(height(tc_rows) == 2, ...
    'Expected exactly two tc_upper_bits_inert rows.');
assert(tc_rows.tc(1) ~= tc_rows.tc(2) && ...
       tc_rows.table_entries(1) == tc_rows.table_entries(2) && ...
       tc_rows.in_range(1) == tc_rows.in_range(2) && ...
       tc_rows.descriptor_request(1) == tc_rows.descriptor_request(2) && ...
       tc_rows.descriptor_addr(1) == tc_rows.descriptor_addr(2), ...
    'TC-upper-bits-inert invariant failed.');

fprintf('Step 25 paired assertions passed.\n');
fprintf('All MTC1 demo assertions passed.\n');
```

Save with **Ctrl+S**.

## What this block is checking

The paired rows are useful because we deliberately change one thing at a time.

For example, the alternate-CRP assertion checks that:

```text
same VA
same VPN
same table span
different CRP
```

produces a descriptor-address change equal to the CRP-base change.

The page-offset assertion does the opposite kind of experiment:

```text
same VPN
different page offset
```

must still produce:

```text
same descriptor address
```

These are effectively controlled experiments expressed as executable checks.

## Step 25B — Run the completed demo

From the repository root:

```matlab
run('scripts/matlab/examples/run_tc_crp_span_demo.m')
```

The final lines should be:

```text
MTC1 summary:
  rows:               13
  conceptual cases:   9
Step 24 core assertions passed.
Step 25 paired assertions passed.
All MTC1 demo assertions passed.
```

There should be no assertion error.

## Stop point

Send back the final portion of the output showing the summary and all three assertion-pass messages.

If Step 25 passes, the demo implementation is functionally complete.

The next checkpoint will be **full MTC1 verification and repository review**, including:

```text
MATLAB version
canonical demo invocation
git diff --check on the four MTC1 deliverables
git status --short
HDL regression disposition
```

We will still keep the separate process/learning documents out of the MTC1 staging set.
