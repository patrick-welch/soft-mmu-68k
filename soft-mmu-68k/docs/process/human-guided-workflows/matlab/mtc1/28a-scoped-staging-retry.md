# MTC1 Step 28A — Scoped Staging Retry

**Packet:** MTC1
**Branch:** `matlab/mtc1-tc-crp-span-reference`

## What the last output tells us

Nothing is staged yet.

The key evidence is:

```text
 M soft-mmu-68k/scripts/matlab/README.md
?? soft-mmu-68k/scripts/matlab/examples/run_tc_crp_span_demo.m
?? soft-mmu-68k/scripts/matlab/generators/generate_tc_crp_span_vectors.m
?? soft-mmu-68k/scripts/matlab/models/mmu_tc_crp_span_reference.m
```

For `git status --short`:

```text
 M   = tracked file modified, but not staged
??   = untracked file
M    = modification staged
A    = new file staged
```

Also, `git diff --cached --name-only` produced no filenames, confirming the index is empty.

## Do only this now

From:

```text
/c/source/HDL/002
```

run exactly:

```bash
git add --   soft-mmu-68k/scripts/matlab/models/mmu_tc_crp_span_reference.m   soft-mmu-68k/scripts/matlab/generators/generate_tc_crp_span_vectors.m   soft-mmu-68k/scripts/matlab/examples/run_tc_crp_span_demo.m   soft-mmu-68k/scripts/matlab/README.md
```

Then immediately run:

```bash
git diff --cached --name-only
git status --short
```

Expected staged file list:

```text
soft-mmu-68k/scripts/matlab/README.md
soft-mmu-68k/scripts/matlab/examples/run_tc_crp_span_demo.m
soft-mmu-68k/scripts/matlab/generators/generate_tc_crp_span_vectors.m
soft-mmu-68k/scripts/matlab/models/mmu_tc_crp_span_reference.m
```

Expected status pattern:

```text
M  soft-mmu-68k/scripts/matlab/README.md
A  soft-mmu-68k/scripts/matlab/examples/run_tc_crp_span_demo.m
A  soft-mmu-68k/scripts/matlab/generators/generate_tc_crp_span_vectors.m
A  soft-mmu-68k/scripts/matlab/models/mmu_tc_crp_span_reference.m
?? soft-mmu-68k/docs/process/human-guided-workflows/
?? soft-mmu-68k/docs/process/memoranda/briefings/MTC1_Scalar_Model_Review_Before_Step_10.md
```

The two process-document entries must remain untracked.

## Stop point

Send back only the output from:

```bash
git diff --cached --name-only
git status --short
```

Do not commit yet. We will run the whitespace checks after confirming that exactly the four MTC1 deliverables are staged.
