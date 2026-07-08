# AGENTS.md

This file belongs at the repository root.

Agents must read it before planning, editing, testing, committing, or opening a pull request.

## Project identity

This repository is `soft-mmu-68k`, a Verilog/SystemVerilog HDL project developing a compatibility-oriented soft Memory Management Unit for Motorola 68k-family systems.

This is a hardware design project. Treat RTL, testbenches, FPGA collateral, documentation, MATLAB collateral, generated vectors, and scripts as separate engineering artifacts with different review expectations.

Do not claim full Motorola, MC68851, MC68030, MC68040, or MC68060 compatibility unless the behavior is implemented, tested, and documented in this repository.

## Repository root and local checkout layout

The Git repository root is the directory containing this `AGENTS.md` file and `.git/`.

Do not infer project identity from the local checkout directory name. In local development, the checkout directory may be named `002`, `004`, or another lab/workbench name.

The active HDL project payload is `soft-mmu-68k/`.

Run HDL project scripts from `soft-mmu-68k/` unless a packet explicitly says otherwise.

Ignored local lab collateral may exist beside `soft-mmu-68k/` at the repository root. Examples include chat transcripts, VS Code workspaces/profiles, smoke results, Vivado project artifacts, and project-structure scratch files. These are not part of the tracked project unless explicitly assigned.

## Required operating model

Work in small, reviewable packets.

Each task gets its own branch and its own agent context. Do not combine unrelated packet work.

Before making changes, identify:

- the packet or task being worked
- the files expected to change
- the tests expected to run
- the files that must not be touched

If ambiguity affects correctness, safety, file scope, interface behavior, or compatibility claims, stop and ask for clarification.

If the ambiguity is minor and a conservative interpretation is obvious, proceed with the smallest safe change and state the assumption.

## Repository discipline

Do not perform broad cleanup.

Do not reformat unrelated files.

Do not rename files, move directories, or reorganize the project unless explicitly requested.

Do not rewrite generated or historical documentation unless explicitly requested.

Do not edit unrelated RTL, testbench, FPGA, script, MATLAB, generated-vector, workflow, or documentation files.

Do not run commands that mutate the working tree outside the requested task.

Do not create commits, branches, pull requests, or tags unless explicitly requested.

If `git pull` or branch checkout fails, stop.

Do not continue into edits or tests on stale or unknown code.

Report the Git failure, current branch, current HEAD, and `git status --short`.

Use ordinary `git pull` for routine updates unless the task explicitly requires lower-level Git diagnosis.

Do not use fetch/merge/rebase/reset workflows unless needed and explained.

Do not use `git add .`.

Stage only the files intentionally changed for the assigned packet.

Do not use `git clean` unless the user explicitly requests it.

Do not use destructive Git commands unless the user explicitly approves the exact command.

## Line endings and generated files

Respect `.gitattributes`.

The repository normalizes text files such as `.v`, `.sv`, `.vh`, `.md`, `.tcl`, `.xdc`, `.csv`, `.txt`, `.m`, `.gitignore`, and `.gitattributes` to LF.

Do not introduce CRLF or mixed line endings.

Do not perform bulk line-ending normalization unless explicitly requested.

Do not use Python, shell, or editor scripts to rewrite files across the repository unless explicitly requested.

Never commit editor, workspace, mount, cache, temporary, simulator-output, or tool-output files.

Generated files may be committed only when the packet explicitly requires them and they are intentional project artifacts, such as small deterministic golden-vector CSV files under `soft-mmu-68k/tb/common/golden_vectors/`.

Do not regenerate, rewrite, normalize, or reformat committed golden-vector files unless the assigned packet explicitly requires it.

Do not change `.vscode/` files unless the packet explicitly assigns that work.

Do not commit workspace profiles, local workspace files, or editor-generated state.

Examples of files that must not be committed unless explicitly assigned:

- `.fuse_hidden*`
- workspace profiles
- local `*.code-workspace` files
- Vivado run output
- simulator output
- waveform dumps
- temporary Python or shell script output
- build directories
- cache directories

## HDL coding rules

Prefer simple, synthesizable Verilog/SystemVerilog.

Keep RTL deterministic and reviewable.

Do not infer latches unintentionally.

Use explicit combinational defaults.

Use clear synchronous reset behavior when sequential logic is required.

Keep testbench-only constructs out of synthesizable RTL.

Preserve existing module interfaces unless the task explicitly requires an interface change.

If an interface changes, update every affected instantiation, testbench, and document that depends on it.

Parameterize widths where the surrounding design already uses width parameters.

Do not hard-code widths unnecessarily.

Do not silence lint warnings without explaining why.

## Testbench rules

Testbench work belongs in `soft-mmu-68k/tb/`.

Unit tests belong in `soft-mmu-68k/tb/unit/`.

Integration tests belong in `soft-mmu-68k/tb/integ/`.

Shared simulation helpers belong in `soft-mmu-68k/tb/common/`.

A testbench packet should normally avoid RTL changes unless the task explicitly requires a DUT fix.

If a bench packet exposes an RTL mismatch, do not silently patch RTL in the same packet unless the task explicitly authorizes RTL fixes.

Report the mismatch as a DUT issue.

Make tests deterministic.

Prefer directed tests for architectural corner cases before adding randomized tests.

State what simulator was used and what command was run.

If a test was not run, say so.

If a SystemVerilog test consumes a golden-vector file, fail loudly on:

- missing file
- malformed row
- unexpected row count
- DUT mismatch

## MATLAB and golden-vector rules

MATLAB collateral lives under `soft-mmu-68k/scripts/matlab/`.

Golden vectors live under `soft-mmu-68k/tb/common/golden_vectors/`.

MATLAB is a reference-modeling and vector-generation layer. It does not replace RTL, SystemVerilog benches, shell scripts, or GitHub Actions regression.

Do not require MATLAB to run in ordinary HDL regression unless the packet explicitly adds MATLAB execution to CI or the local test flow.

If MATLAB was not run, report it explicitly. Do not imply generated vectors were regenerated or validated by MATLAB unless that actually happened.

Do not modify MATLAB source, generated CSV vectors, or CSV-consuming testbenches unless the packet explicitly assigns that work.

Do not hand-edit generated CSV files unless the packet explicitly states that the CSV itself is defective and must be corrected.

Generated vector files must be deterministic. If randomness is used, the generator must set and document a fixed seed.

CSV golden-vector files must include a stable header row.

When practical, consuming SystemVerilog testbenches should validate the expected row count.

When adding or changing MATLAB-generated vectors, include the regeneration command or script path in the PR body.

When adding MATLAB-backed vectors, document:

- the MATLAB reference model used
- the generator used
- the regeneration command or script path
- the generated-vector path
- the consuming SystemVerilog testbench
- the behavioral scope being modeled

## Documentation rules

Documentation must match implemented behavior.

Do not describe future behavior as implemented behavior.

Use explicit caveats for first-pass or partial features.

Prefer wording such as `first-pass`, `subset`, `current implemented behavior`, `tested behavior`, or `test/spec target` when full Motorola behavior is not proven.

For Motorola-family behavior, distinguish among:

- implemented behavior
- tested behavior
- documented intended behavior
- deferred compatibility work
- uncertain interpretation

For architectural documentation, distinguish:

- current repo behavior
- tested behavior
- intended future behavior
- deferred compatibility work
- uncertain interpretation

When in doubt, write it out.

## Source and reference discipline

Use `soft-mmu-68k/docs/refs/source-materials.md` as the project source manifest.

Do not invent manual page numbers, section numbers, source titles, or compatibility claims.

If a Motorola-family behavior is uncertain, mark it as uncertain or deferred.

## FPGA and Vivado rules

Do not change Basys 3 constraints, Vivado TCL, board top modules, or FPGA collateral unless the task is specifically FPGA-related.

Do not weaken Vivado DRC checks to force bitstream generation unless explicitly requested.

Do not treat board smoke tests as full architectural validation.

When reporting FPGA work, distinguish:

- synthesis
- implementation
- bitstream generation
- programming
- board smoke testing

## Standard regression commands

From the repository root:

```bash
cd soft-mmu-68k
bash ./scripts/run_iverilog_unit.sh
bash ./scripts/run_iverilog_integ.sh
bash ./scripts/run_verilator_lint.sh
```

Run the commands relevant to the assigned packet.

Do not claim regression success unless the relevant command was actually run and passed.

For documentation-only packets, HDL regression may be skipped, but the report must explicitly say:

```text
SKIPPED: documentation-only packet
```

## Verilator lint reporting

When running Verilator lint, report whether the lint command passed.

The current `soft-mmu-68k/scripts/run_verilator_lint.sh` flow uses `-Wno-fatal` and may allow pre-existing accepted warnings to remain visible while still failing on true errors.

Do not describe lint as `clean` if accepted warnings remain visible.

Use wording such as:

- `Verilator lint passed`
- `Verilator lint passed with accepted warnings`
- `Verilator lint failed`

Do not claim `lint clean` unless the lint output is actually warning-free.

## Blocked work behavior

If blocked by tooling, permissions, missing credits, unavailable commands, merge conflicts, or an unexpected dirty worktree, stop and report.

A blocked-work report must include:

- current branch
- current HEAD
- whether the worktree is clean
- files changed, if any
- exact blocker message
- what was completed before the block
- what remains to be done

Do not retry destructive or quota-consuming operations repeatedly.

## Git and PR expectations

Before reporting completion, provide:

- current branch
- files changed
- summary of changes
- tests run
- tests not run
- known limitations or follow-up work

Use the repository pull request template when preparing PR text.

PR descriptions should include:

- module(s) implemented or modified
- packet or task identity
- purpose / summary
- changes made
- interfaces touched
- testing performed
- acceptance criteria status
- additional notes or TODOs

Completion report must include:

- Branch:
- Files changed:
- Files intentionally not touched:
- Summary:
- Tests run:
- Tests not run:
- Known limitations:
- Follow-up needed:

Do not stage or commit untracked workspace/profile files.

## Agent conduct

Be conservative.

Be precise.

Do not guess.

Do not overstate success.

Do not claim tests passed unless they were actually run.

Do not claim compatibility unless it is supported by repo docs, RTL, and tests.

Prefer the smallest correct change.

If blocked, report the blocker and stop.

This repository is being developed through coordinated agent packets. Stay inside the assigned packet.
