# HW1A Hardware Smoke Repeatability Plan

## Purpose

`HW1A` defines the repeatability plan and evidence standard for a later
human-executed `HW1B` physical Basys 3 smoke packet.

This document does not perform a hardware smoke test. It does not report that a
board was programmed, that Vivado was run, or that any physical observation was
made during this packet.

The goal is to make the later `HW1B` execution conservative, repeatable, and
reviewable for the SM68861 / soft-MMU hardware path.

## Scope Boundary

`HW1A` is documentation-only process work.

This packet does not include:

- physical hardware execution
- Vivado project repair
- RTL modification
- constraints modification
- testbench modification
- script or MATLAB modification
- generated collateral
- bitstreams, reports, logs, screenshots, or board photos
- compatibility claim expansion

Only a later deliberately authorized `HW1B` packet may perform and report a
physical board smoke execution.

## Definition Of A Hardware Smoke Test

At the current project maturity level, a hardware smoke test is a minimal
evidence-gathering check that the existing Basys 3 hardware path can be
repeated and observed from a specific repository commit.

A hardware smoke test may show that the current FPGA harness can be built or
programmed and that the expected front-panel or tool-observable result appears.
It is not:

- functional MMU validation
- full FPGA bring-up
- a timing closure campaign
- a hardware debug campaign
- a complete board-level validation effort
- proof of full Motorola-family PMMU compatibility
- proof of full 68k system integration

`HW1B` must predeclare the minimal expected observation before execution. That
expectation must come from the current repository collateral or project owner
direction for the exact commit under test. This `HW1A` plan does not invent or
freeze exact LED, switch, UART, Vivado, or bitstream behavior.

If the expected observable result is not confirmed before physical execution,
`HW1B` must stop as blocked rather than improvise a new board behavior target.

## Current Basys 3 Smoke Target For HW1B

The current `HW1B` physical smoke target is the existing Basys 3 smoke demo
documented in `soft-mmu-68k/README.md`. `HW1B` should treat that README section
and the matching FPGA collateral in the commit under test as the source for the
expected smoke procedure.

Primary repository collateral:

- `soft-mmu-68k/fpga/basys3/tops/top_mmu_demo.v`
- `soft-mmu-68k/fpga/basys3/vivado/run_synth_impl.tcl`
- `soft-mmu-68k/fpga/basys3/vivado/add_sources.tcl`
- `soft-mmu-68k/fpga/basys3/xdc/Basys-3-Master.xdc`
- `soft-mmu-68k/fpga/constraints/README.md`
- `soft-mmu-68k/README.md`

The root README currently documents that, on reset,
`fpga/basys3/tops/top_mmu_demo.v` programs:

- `CRP = 0x001000`
- `TC = 0x00000FFF`
- `TT0 = 0xF000F800`
- `TT1 = 0x00000000`

The root README currently documents four built-in descriptor responder cases:

- page `0`: valid user-accessible translated page at PFN `0x040`
- page `1`: valid supervisor-only translated page at PFN `0x041`
- page `2`: invalid descriptor
- page `3`: abstract bus-error response

The expected Vivado and board-observation flow for `HW1B`, as documented in the
root README, is:

1. Open Vivado at the repository root.
2. Run:

```tcl
cd fpga/basys3/vivado
source run_synth_impl.tcl
```

3. Program the generated bitstream from
   `fpga/basys3/vivado/build/basys3_mmu_demo/`.
4. Press `btnC` after programming or after changing switches.
5. Set switches, wait for the built-in rerun after the settle timer, then read
   the LEDs.

The front-panel controls documented for the current smoke demo are:

- `btnC`: active-high reset
- `sw[15]`: select TT-qualified region; `1` means VA high byte `0xF0`,
  `0` means translated region `0x00`
- `sw[14:13]`: mode
  - `00`: access
  - `01`: probe
  - `10`: preload then access+probe
  - `11`: targeted flush-match then access+probe
- `sw[12]`: supervisor (`1`) vs user (`0`)
- `sw[11]`: program/fetch (`1`) vs data (`0`)
- `sw[10]`: write (`1`) vs read (`0`)
- `sw[9:8]`: demo page selector
- `sw[7:0]`: low VA offset bits

The LED meanings documented for the current smoke demo are:

- `led[0]`: MMU busy
- `led[1]`: last access fault
- `led[2]`: last translated hit flag
- `led[3]`: last status/probe hit flag
- `led[4]`: last translated-status class bit
- `led[5]`: last TT-match status class bit
- `led[8:6]`: last access fault code
- `led[15:9]`: upper slice of the displayed PA/result

The minimum `HW1B` smoke observations are:

1. All switches low: translated access/probe smoke case.
2. `SW15=1`: TT-qualified identity-style smoke case.
3. `SW8=1`: user access to the supervisor-only translated page faults.
4. `SW12=1` and `SW8=1`: supervisor access to that same translated page
   succeeds.

For each smoke case, `HW1B` should record:

- switch setting
- expected LED/result meaning
- actual LED/result observation
- pass, fail, blocked, or inconclusive result
- photo, screenshot, transcript, or written observation

If the existing Basys 3 demo collateral does not clearly define the expected
observation for a case, `HW1B` must stop as blocked and report the ambiguity
rather than inventing or substituting a new smoke target.

## Pre-flight Checklist For HW1B

Before programming hardware or running a hardware-facing flow, the future
`HW1B` executor must record:

- repo branch under test
- commit SHA under test
- whether the working tree is clean
- host environment used
- project path used
- Vivado version, if Vivado is used
- board model
- board identifier, if one is available
- programming cable or hardware target path used
- bitstream or project artifact being programmed, if applicable
- exact commands or GUI path actually used
- expected observable result, if repo-confirmed
- known deviations before execution

`HW1B` must not require or invent a specific Vivado command unless that command
is confirmed by the current repository collateral or the project owner for the
commit being tested.

## Evidence Standard

The later `HW1B` report should include enough evidence for another reviewer to
understand what was attempted, what was observed, and why the result
classification was chosen.

Evidence should include:

- command transcript or concise GUI action log
- relevant tool version output, if available
- git status summary before execution
- programming result or failure text
- observed board behavior
- screenshot, photo, or log filenames when evidence is stored externally
- pass, fail, blocked, or inconclusive classification
- short human notes describing the observation

External evidence filenames should be stable and packet-oriented when practical,
for example:

```text
hw1b_<yyyymmdd>_<commit-short>_<evidence-kind>.<ext>
```

The exact storage location for photos, screenshots, logs, or tool outputs must
be chosen by the project owner or the `HW1B` packet. `HW1A` does not add those
artifacts.

## Result Classification

Only `HW1B`, not `HW1A`, may report actual hardware results.

Allowed result states:

- `pass`: the predeclared minimal smoke expectation was observed and supporting
  evidence was captured.
- `fail`: execution completed, but the expected smoke observation did not
  occur.
- `blocked`: execution could not start or complete because of setup, tool,
  hardware, path, artifact, or authorization issues.
- `inconclusive`: available evidence was insufficient, contradictory, or not
  tied clearly enough to the commit and artifact under test.

A pass is smoke-level evidence only. It must not be described as full MMU
architectural validation, timing closure proof, full board bring-up, or full
Motorola-family compatibility evidence.

## Stop Conditions

The `HW1B` executor must stop and report rather than improvise if:

- the repo commit under test is unclear
- the working tree state cannot be recorded
- the bitstream or project artifact is unclear
- the board model is unclear
- the programming cable or hardware target path is unclear
- Vivado or another required tool is missing
- the available toolchain is materially different from expectations
- the expected observable behavior is not known before execution
- programming fails in a way that suggests toolchain repair work
- hardware behavior differs from expectation and would require RTL, constraint,
  testbench, script, or debug changes
- any step would require editing files outside the authorized `HW1B` packet
- any step would require editing RTL, FPGA collateral, scripts, MATLAB
  collateral, generated vectors, or testbenches without explicit packet
  authorization

When a stop condition occurs, `HW1B` should report the blocked state with the
commit, tool, board, artifact, and evidence available up to the stop point.

## HW1B Report Template

```md
# HW1B Hardware Smoke Execution Report

- Date/time:
- Executor:
- Repo branch:
- Commit SHA:
- Working tree clean before execution: yes/no
- Host environment:
- Project path:
- Vivado/tool version:
- Board:
- Programming method:
- Artifact programmed:
- Expected observation:
- Actual observation:
- Evidence captured:
- Result: pass/fail/blocked/inconclusive
- Deviations:
- Follow-up needed:

| Case | Switch setting | Expected result | Actual observation | Evidence | Result |
|---|---|---|---|---|---|
| all switches low |  |  |  |  | pass/fail/blocked/inconclusive |
| SW15=1 |  |  |  |  | pass/fail/blocked/inconclusive |
| SW8=1 |  |  |  |  | pass/fail/blocked/inconclusive |
| SW12=1 and SW8=1 |  |  |  |  | pass/fail/blocked/inconclusive |
```

## Non-goals

`HW1A` and the later `HW1B` smoke execution are not:

- full FPGA bring-up
- timing closure campaign
- board-level debug campaign
- RTL fix work
- testbench fix work
- script or Vivado-flow repair work
- MATLAB or generated-vector work
- MMU architectural validation
- proof of full Motorola-family PMMU compatibility
- proof of full 68k CPU or bus-system integration

## Relationship To Nearby Packets

- `MTC1` may continue in parallel.
- `CTRL1B` is already the control-shim executable-test baseline.
- `HW1A` prepares `HW1B`; it does not authorize `HW1B`.
- `HW1B` requires a deliberate human checkpoint before physical execution.
- `CTRL2A`, `TC2A`, and `FAULT1` remain later strategic packets.
