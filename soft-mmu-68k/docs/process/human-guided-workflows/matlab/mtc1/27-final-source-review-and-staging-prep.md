# MTC1 Human-Guided MATLAB Workflow — Step 27

**Packet:** MTC1
**Branch:** `matlab/mtc1-tc-crp-span-reference`
**Goal:** finish the final four-file pre-staging review and make only the small cleanup changes found by that review.

## Verification captured

MATLAB reported:

```text
26.1.0.3276743 (R2026a) Update 3
```

The current Git status shows the four MTC1 deliverables plus the separate process/learning material:

```text
M  soft-mmu-68k/scripts/matlab/README.md
?? soft-mmu-68k/docs/process/human-guided-workflows/
?? soft-mmu-68k/docs/process/memoranda/briefings/MTC1_Scalar_Model_Review_Before_Step_10.md
?? soft-mmu-68k/scripts/matlab/examples/run_tc_crp_span_demo.m
?? soft-mmu-68k/scripts/matlab/generators/generate_tc_crp_span_vectors.m
?? soft-mmu-68k/scripts/matlab/models/mmu_tc_crp_span_reference.m
```

Nothing is staged.

## Final four-file review result

### `mmu_tc_crp_span_reference.m`

**Functional review: PASS.**

The model retains:

- the approved defaults;
- the current TC1B single-level span behavior;
- conservative PA overflow rejection;
- CRP as the current root source;
- SRP preserved but inert;
- the exact approved 20-field result schema;
- the DEV Manager-required clarification that the 64-bit VA/FC limits are MATLAB `uint64` representation limits, not MC68851 or SM68861 architectural limits.

One whitespace-only line in the uploaded source contains four spaces. Remove the spaces so the blank line is actually empty before the Git whitespace check.

The uploaded file also has no final newline after the closing `end`. Add one final newline as normal source-file hygiene.

### `generate_tc_crp_span_vectors.m`

**Functional review: PASS.**

The generator contains exactly 13 rows covering the nine approved conceptual cases, introduces only `case_name` and `variant` as generator metadata, has no output-file argument, creates no directory, and writes no CSV.

No stale or duplicate case code was found.

The uploaded file has no final newline after the closing `end`. Add one final newline.

### `run_tc_crp_span_demo.m`

**Functional review: PASS.**

The demo is location-aware, calls the generator, displays the in-memory table, reports 13 rows and 9 conceptual cases, and contains the core plus paired packet-invariant assertions.

The observed MATLAB execution ended with:

```text
Step 24 core assertions passed.
Step 25 paired assertions passed.
All MTC1 demo assertions passed.
```

The uploaded file has no final newline. Add one final newline.

### `scripts/matlab/README.md`

**Content review: PASS after one wording correction.**

The MTC1 section accurately separates the in-memory flow from the existing `perm_check` CSV/SystemVerilog flow and correctly documents the implementation-only `uint64` representation limits and deferred Motorola TC geometry.

One path-context sentence needed correction. The Git working-tree root shown by Git Bash is:

```text
C:/source/HDL/002
```

so the packet's root-relative invocation is:

```matlab
run('soft-mmu-68k/scripts/matlab/examples/run_tc_crp_span_demo.m')
```

When MATLAB is already in the project-content directory:

```text
C:/source/HDL/002/soft-mmu-68k
```

the equivalent invocation is:

```matlab
run('scripts/matlab/examples/run_tc_crp_span_demo.m')
```

The complete replacement README supplied with this review documents both contexts and changes the now-implemented demo wording from “is expected to” to present tense.

## Step 27A — Replace the README

Replace:

```text
soft-mmu-68k/scripts/matlab/README.md
```

with the supplied complete `README.md`.

Do not splice individual README paragraphs.

## Step 27B — Tiny MATLAB-file cleanup

In `mmu_tc_crp_span_reference.m`:

1. make the blank line after the `pa_width` default block truly empty rather than containing spaces;
2. ensure the file ends with a newline after the final `end`.

In both:

```text
generate_tc_crp_span_vectors.m
run_tc_crp_span_demo.m
```

ensure there is a final newline after the closing `end` / final statement.

Do not otherwise change MATLAB logic.

## Step 27C — Run the packet-root invocation once

In MATLAB:

```matlab
cd('C:\source\HDL\002')
run('soft-mmu-68k/scripts/matlab/examples/run_tc_crp_span_demo.m')
```

Expected final lines:

```text
MTC1 summary:
  rows:               13
  conceptual cases:   9
Step 24 core assertions passed.
Step 25 paired assertions passed.
All MTC1 demo assertions passed.
```

This verifies the exact root-relative invocation recorded by the MTC1 packet.

## Step 27D — Stop before staging

From Git Bash:

```bash
git status --short
```

Do not stage yet.

Send back the final demo lines and `git status --short`.

If those remain clean, the next step is the tightly scoped staging/checkpoint:

- stage exactly the four MTC1 deliverables;
- verify the staged filename list;
- run `git diff --check` as required by the packet;
- run `git diff --cached --check` so the three formerly untracked MATLAB files are actually included in the whitespace check;
- inspect the staged diff before any commit.

## Verification status

```text
MATLAB version:                         PASS — 26.1.0.3276743 (R2026a) Update 3
Scalar model directed testing:          PASS
Generator row count:                    PASS — 13
Generator conceptual-case count:        PASS — 9
Scalar result schema:                   PASS — 20 fields
Demo location-aware execution:          PASS
Step 24 core assertions:                PASS
Step 25 paired assertions:              PASS
All MTC1 demo assertions:               PASS
Final four-file functional review:      PASS
Source hygiene cleanup:                 PENDING Step 27A/27B
Packet-root invocation:                 PENDING Step 27C
Git whitespace checks:                  PENDING after scoped staging
HDL local regression:                   SKIPPED: MATLAB-only reference-model packet; no HDL-consumed collateral changed.
```
