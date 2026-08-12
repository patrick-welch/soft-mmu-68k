# MTC1 Human-Guided MATLAB Workflow — Step 28

**Packet:** MTC1
**Branch:** `matlab/mtc1-tc-crp-span-reference`
**Goal:** stage exactly the four authorized MTC1 deliverables, verify the staged set, and run the required Git whitespace checks before any commit.

## Step 27 result

The packet-root demo invocation passed with:

```text
MTC1 summary:
  rows:               13
  conceptual cases:   9
Step 24 core assertions passed.
Step 25 paired assertions passed.
All MTC1 demo assertions passed.
```

Git status still shows the four MTC1 deliverables plus the separate process/learning material, with nothing staged.

The screenshots also show final blank lines after the demo and generator content, consistent with the requested end-of-file newline cleanup.

## Step 28A — Stage only the four MTC1 deliverables

From Git Bash at:

```text
/c/source/HDL/002
```

run exactly:

```bash
git add --   soft-mmu-68k/scripts/matlab/models/mmu_tc_crp_span_reference.m   soft-mmu-68k/scripts/matlab/generators/generate_tc_crp_span_vectors.m   soft-mmu-68k/scripts/matlab/examples/run_tc_crp_span_demo.m   soft-mmu-68k/scripts/matlab/README.md
```

Do not use `git add .`, `git add -A`, or a directory-level add.

## Step 28B — Verify the staged filename set

Run:

```bash
git diff --cached --name-only
```

Expected output, with exactly these four paths and no process documents:

```text
soft-mmu-68k/scripts/matlab/README.md
soft-mmu-68k/scripts/matlab/examples/run_tc_crp_span_demo.m
soft-mmu-68k/scripts/matlab/generators/generate_tc_crp_span_vectors.m
soft-mmu-68k/scripts/matlab/models/mmu_tc_crp_span_reference.m
```

If anything else appears, stop before proceeding.

## Step 28C — Run both whitespace checks

First run the packet-required command exactly:

```bash
git diff --check --   soft-mmu-68k/scripts/matlab/models/mmu_tc_crp_span_reference.m   soft-mmu-68k/scripts/matlab/generators/generate_tc_crp_span_vectors.m   soft-mmu-68k/scripts/matlab/examples/run_tc_crp_span_demo.m   soft-mmu-68k/scripts/matlab/README.md
```

After staging, this checks for any remaining unstaged whitespace errors in those paths. No output is expected.

Then run the staged-content check:

```bash
git diff --cached --check --   soft-mmu-68k/scripts/matlab/models/mmu_tc_crp_span_reference.m   soft-mmu-68k/scripts/matlab/generators/generate_tc_crp_span_vectors.m   soft-mmu-68k/scripts/matlab/examples/run_tc_crp_span_demo.m   soft-mmu-68k/scripts/matlab/README.md
```

This is the important check for the three formerly untracked files plus the staged README change.

No output is expected.

## Step 28D — Inspect staged scope and status

Run:

```bash
git diff --cached --stat
git status --short
```

Expected staged MTC1 entries should look like:

```text
M  soft-mmu-68k/scripts/matlab/README.md
A  soft-mmu-68k/scripts/matlab/examples/run_tc_crp_span_demo.m
A  soft-mmu-68k/scripts/matlab/generators/generate_tc_crp_span_vectors.m
A  soft-mmu-68k/scripts/matlab/models/mmu_tc_crp_span_reference.m
```

The process/learning files should remain separately untracked:

```text
?? soft-mmu-68k/docs/process/human-guided-workflows/
?? soft-mmu-68k/docs/process/memoranda/briefings/MTC1_Scalar_Model_Review_Before_Step_10.md
```

That is intentional.

## Stop point

Send back the output of:

```bash
git diff --cached --name-only
git diff --check --   soft-mmu-68k/scripts/matlab/models/mmu_tc_crp_span_reference.m   soft-mmu-68k/scripts/matlab/generators/generate_tc_crp_span_vectors.m   soft-mmu-68k/scripts/matlab/examples/run_tc_crp_span_demo.m   soft-mmu-68k/scripts/matlab/README.md
git diff --cached --check --   soft-mmu-68k/scripts/matlab/models/mmu_tc_crp_span_reference.m   soft-mmu-68k/scripts/matlab/generators/generate_tc_crp_span_vectors.m   soft-mmu-68k/scripts/matlab/examples/run_tc_crp_span_demo.m   soft-mmu-68k/scripts/matlab/README.md
git diff --cached --stat
git status --short
```

Do not commit yet.

If those checks are clean and the staged set contains exactly the four authorized files, the next step is final staged-diff inspection and then commit preparation.

## Verification status

```text
MATLAB version:                         PASS — 26.1.0.3276743 (R2026a) Update 3
Packet-root demo invocation:            PASS
Generator row count:                    PASS — 13
Generator conceptual-case count:        PASS — 9
Scalar result schema:                   PASS — 20 fields
Step 24 core assertions:                PASS
Step 25 paired assertions:              PASS
All MTC1 demo assertions:               PASS
Final four-file functional review:      PASS
Scoped staging:                         PENDING Step 28A
Staged filename verification:           PENDING Step 28B
Packet-required git diff --check:        PENDING Step 28C
Staged git diff --cached --check:        PENDING Step 28C
HDL local regression:                   SKIPPED: MATLAB-only reference-model packet; no HDL-consumed collateral changed.
```
