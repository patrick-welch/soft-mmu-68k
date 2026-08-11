# MTC1 Human-Guided MATLAB Workflow — Step 26

**Packet:** MTC1
**Branch:** `matlab/mtc1-tc-crp-span-reference`
**Goal:** record the MATLAB environment, capture final repository state, and collect the four MTC1 deliverable files for final pre-staging review.

## Step 25 result

The completed demo reported:

```text
MTC1 summary:
  rows:               13
  conceptual cases:   9
Step 24 core assertions passed.
Step 25 paired assertions passed.
All MTC1 demo assertions passed.
```

Therefore the MTC1 demo implementation is functionally complete.

Do not add more behavior now.

## Step 26A — Record the actual MATLAB version

In the MATLAB Command Window, run:

```matlab
version
```

Copy the returned version string exactly.

This satisfies the packet requirement to report the actual MATLAB version used for verification.

## Step 26B — Capture repository state

In Git Bash, from the same location where you have been running `git status`, run:

```bash
git status --short
```

Do not stage anything yet.

We expect the MTC1-specific deliverables to include:

```text
soft-mmu-68k/scripts/matlab/models/mmu_tc_crp_span_reference.m
soft-mmu-68k/scripts/matlab/generators/generate_tc_crp_span_vectors.m
soft-mmu-68k/scripts/matlab/examples/run_tc_crp_span_demo.m
soft-mmu-68k/scripts/matlab/README.md
```

The separately preserved process/learning material may also remain untracked. That material stays outside the MTC1 staging set.

## Step 26C — Upload the final four MTC1 deliverable files

Upload the current local copies of:

```text
soft-mmu-68k/scripts/matlab/models/mmu_tc_crp_span_reference.m
soft-mmu-68k/scripts/matlab/generators/generate_tc_crp_span_vectors.m
soft-mmu-68k/scripts/matlab/examples/run_tc_crp_span_demo.m
soft-mmu-68k/scripts/matlab/README.md
```

This lets us review the exact final source before staging rather than reconstructing it from the incremental exercise.

## Why `git diff --check` waits until the next checkpoint

Three of the MTC1 files began as untracked files. Ordinary:

```bash
git diff --check
```

does not inspect untracked file contents.

So we will not pretend that a four-file `git diff --check` has validated files that Git is not yet tracking.

After the final source review, we can stage **only the four MTC1 deliverables**, then run the required staged whitespace check before committing.

The process/learning documents will remain outside that staging command.

## Verification status at this checkpoint

```text
Scalar model directed testing:          PASS
Generator row count:                    PASS — 13
Generator conceptual-case count:        PASS — 9
Scalar result schema:                   PASS — 20 fields
Demo location-aware execution:          PASS
Step 24 core demo assertions:           PASS
Step 25 paired demo assertions:         PASS
All MTC1 demo assertions:               PASS
Actual MATLAB version:                  PENDING Step 26A
Final four-file source review:          PENDING Step 26C
Four-file git diff --check:             PENDING until four MTC1 files are staged
HDL local regression:                   SKIPPED: MATLAB-only reference-model packet; no HDL-consumed collateral changed.
```

## Stop point

Send back:

1. the exact output from `version`;
2. `git status --short`;
3. the four final MTC1 deliverable files.

Do not stage anything yet.

The next step will be the final four-file source review. If that is clean, we will then stage exactly those four MTC1 files and perform the required pre-commit Git checks.
