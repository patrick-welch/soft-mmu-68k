# MTC1 Human-Guided MATLAB Workflow — Step 21

**Packet:** MTC1
**Branch:** `matlab/mtc1-tc-crp-span-reference`
**Goal:** review the completed generator before adding README or demo code.

## Step 20 result

The directed-case generator has reached the approved target:

```text
13 rows
9 conceptual directed cases
22 columns total
  - 2 generator metadata columns
  - 20 canonical MTC1 result fields
```

The final TC-upper-bits case passed all intended comparisons:

```text
different_tc        = true
same_table_entries  = true
same_in_range       = true
same_descriptor     = true
height(T)           = 13
```

Therefore the generator is now **functionally complete pending source review**.

## Why the next step is review rather than more coding

We built the generator incrementally across Steps 11–20. Before adding the README and demo, we should inspect the actual accumulated source file as one whole program.

The review should check:

```text
- all 13 rows are present exactly once;
- all 9 conceptual cases are represented;
- case_name / variant labels are consistent;
- the row order matches the approved learning sequence;
- no CSV writing or output-path logic was introduced;
- no accidental duplicated or stale code remains;
- comments still explain the learning steps clearly;
- the final table retains the approved 22-column schema;
- MATLAB syntax and formatting are clean enough for long-term maintenance.
```

## Action

Please upload the current local file:

```text
soft-mmu-68k/scripts/matlab/generators/generate_tc_crp_span_vectors.m
```

Also upload the current:

```text
soft-mmu-68k/scripts/matlab/models/mmu_tc_crp_span_reference.m
```

The generator is the primary Step 21 review target. The scalar model is useful so we can check the generator/model interface as it actually exists rather than reconstructing it from the exercise history.

## Repository/process note

Do not stage anything yet.

In particular, leave the new process-preservation material under:

```text
soft-mmu-68k/docs/process/human-guided-workflows/
soft-mmu-68k/docs/process/memoranda/briefings/
```

untracked until we deliberately perform the process-policy cleanup/reconciliation.

After the source review, the likely sequence is:

```text
Step 21  generator/model review and small cleanup
Step 22  MATLAB README update
Step 23+ demo script and assertions
         full MATLAB verification
         process/repository cleanup
         git diff/status review
         commit / push / PR / review / dispensation / merge
```

The exact numbering after Step 21 can be adjusted once we see whether the source review finds anything that should be corrected first.
