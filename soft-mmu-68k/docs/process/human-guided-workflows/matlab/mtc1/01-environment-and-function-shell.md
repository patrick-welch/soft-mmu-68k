# MTC1 Human-Guided MATLAB Workflow — Step 1

**Packet:** MTC1
**Branch:** `matlab/mtc1-tc-crp-span-reference`
**Goal of this step:** create the scalar MATLAB function file in the normal MATLAB Editor, not a design surface.

## Working style

For MTC1, the Project Lead will enter and run the MATLAB work interactively.

The Toolchain Coach will provide one small step at a time:

1. create/open the correct file;
2. enter a small section of MATLAB;
3. save it;
4. run a small check;
5. inspect the result together;
6. continue only after the result is understood.

We will not paste the complete model as one large implementation block.

## Step 1 — Confirm MATLAB's current folder

In the MATLAB **Command Window**, enter:

```matlab
pwd
```

For this project, the desired Git repository root is:

```text
C:\source\HDL\002
```

If MATLAB reports a different folder, enter:

```matlab
cd('C:\source\HDL\002')
```

Then run:

```matlab
pwd
```

again.

## Step 2 — Create the MTC1 function file from the Command Window

Still in the MATLAB **Command Window**, enter:

```matlab
edit(fullfile(pwd, ...
    'soft-mmu-68k', ...
    'scripts', ...
    'matlab', ...
    'models', ...
    'mmu_tc_crp_span_reference.m'))
```

Because the file does not yet exist, MATLAB should ask whether to create it.

Choose **Yes**.

The file should open as a normal `.m` code file in the MATLAB Editor.

Do not use App Designer, Simulink, a Live Task, or another design surface for this packet.

## Stop point

Once the blank file is open in the normal MATLAB Editor, stop.

Return to the Toolchain Coach with:

```text
1. Output of pwd:
2. Did MATLAB ask to create the file? yes/no
3. Is mmu_tc_crp_span_reference.m now open in the normal MATLAB Editor? yes/no
```

Do not enter the function body yet.
