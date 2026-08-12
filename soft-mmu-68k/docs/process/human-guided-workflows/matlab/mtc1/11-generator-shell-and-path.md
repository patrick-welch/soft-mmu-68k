# MTC1 Human-Guided MATLAB Workflow — Step 11

**Packet:** MTC1
**Branch:** `matlab/mtc1-tc-crp-span-reference`
**Goal of this step:** create the generator function shell and prove MATLAB can call it.

## Where we are

The scalar reference model is complete enough to use as the engine for the directed-case generator.

Do **not** change `mmu_tc_crp_span_reference.m` in this step.

The generator will eventually:

```text
- call the scalar reference model repeatedly;
- build the approved directed cases;
- return one in-memory MATLAB table;
- write no CSV;
- create no output directories.
```

We will build that incrementally.

## Step 11A — Create the generator file

In the MATLAB Command Window, run:

```matlab
edit(fullfile(pwd, 'scripts', 'matlab', 'generators', ...
    'generate_tc_crp_span_vectors.m'))
```

If MATLAB asks whether to create the file, choose **Yes**.

## Step 11B — Type the minimal generator shell

Enter only:

```matlab
function T = generate_tc_crp_span_vectors()
%GENERATE_TC_CRP_SPAN_VECTORS Build deterministic MTC1 directed cases.
% Step 11: Establish the in-memory directed-case generator entry point.

    T = table();

end
```

Save with **Ctrl+S**.

### What is new here?

The output variable is named:

```matlab
T
```

because the final generator will return a MATLAB **table** rather than a structure.

For now:

```matlab
T = table();
```

creates an empty table. This is temporary scaffolding, just as `R = struct();` was when we started the scalar model.

## Step 11C — Add the generator folder to the MATLAB path

The model folder was added earlier, but the generator folder is a different directory.

Run:

```matlab
addpath(fullfile(pwd, 'scripts', 'matlab', 'generators'))
```

Then verify MATLAB can find the new function:

```matlab
which generate_tc_crp_span_vectors
```

Expected path:

```text
C:\source\HDL\002\soft-mmu-68k\scripts\matlab\generators\generate_tc_crp_span_vectors.m
```

## Step 11D — Call the empty generator

Run:

```matlab
T = generate_tc_crp_span_vectors()
```

A normal result will be an empty MATLAB table, typically displayed approximately as:

```text
T =

  0x0 empty table
```

Exact formatting can vary.

## Stop point

Send back:

1. the result of `which generate_tc_crp_span_vectors`;
2. the displayed result of `T = generate_tc_crp_span_vectors()`.

Do not add directed cases yet.

Once the shell works, Step 12 will add **one single directed case — the first in-range VPN** — and use it to learn how we turn one scalar result structure into one row of a MATLAB table.
