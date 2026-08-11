# MTC1 Human-Guided MATLAB Workflow — Step 23

**Packet:** MTC1
**Branch:** `matlab/mtc1-tc-crp-span-reference`
**Goal:** create the MTC1 demo shell, make it location-aware, run the generator, and print a small summary.

## Important

You did not miss a demo edit earlier. We deliberately waited until after the model, generator, source review, and README work.

Because you are fatigued, do only this step now. Do **not** add the assertions yet.

The existing `run_perm_check_demo.m` uses the same location-aware pattern we want here: it finds its own file location, derives `scripts/matlab`, and adds the `models` and `generators` directories to the MATLAB path.

## Step 23A — Create the demo file

From the MATLAB Command Window, run:

```matlab
edit(fullfile(pwd, 'scripts', 'matlab', 'examples', ...
    'run_tc_crp_span_demo.m'))
```

If MATLAB asks whether to create the file, choose **Yes**.

## Step 23B — Enter this complete initial demo

```matlab
%RUN_TC_CRP_SPAN_DEMO Exercise the MTC1 TC/CRP span reference flow.
%
% This script is location-aware. It may be run directly from MATLAB
% without first changing into scripts/matlab/examples.

clear; clc;

% Step 23: Locate the MATLAB support directories and run the MTC1 generator.
this_file = mfilename('fullpath');
examples_dir = fileparts(this_file);
matlab_dir = fileparts(examples_dir);

addpath(fullfile(matlab_dir, 'models'));
addpath(fullfile(matlab_dir, 'generators'));

T = generate_tc_crp_span_vectors();

disp('MTC1 TC/CRP directed cases:');
disp(T);

fprintf('\nMTC1 summary:\n');
fprintf('  rows:               %d\n', height(T));
fprintf('  conceptual cases:   %d\n', numel(unique(T.case_name)));
```

Save with **Ctrl+S**.

## What the location-aware part does

This line:

```matlab
this_file = mfilename('fullpath');
```

asks MATLAB for the full path of the currently running script.

Then:

```matlab
examples_dir = fileparts(this_file);
matlab_dir = fileparts(examples_dir);
```

walks upward from:

```text
scripts/matlab/examples/
```

to:

```text
scripts/matlab/
```

That lets the script add:

```text
scripts/matlab/models/
scripts/matlab/generators/
```

without depending on whatever directory MATLAB happened to start in.

## Step 23C — Run it from the repository root

Run:

```matlab
run('scripts/matlab/examples/run_tc_crp_span_demo.m')
```

The important end of the output should be:

```text
MTC1 summary:
  rows:               13
  conceptual cases:   9
```

The full 13x22 table should also display above the summary.

## Stop point

Send back the output from:

```matlab
run('scripts/matlab/examples/run_tc_crp_span_demo.m')
```

That is enough for this step.

Do **not** add assertions yet. Once this shell runs correctly, the next step will add the demo assertions in a small, reviewable group.
