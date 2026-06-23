# Electron Pushers soft-mmu-68k Codex Instructions

## Project identity

This repository implements a Motorola 68k-compatible soft MMU in Verilog/SystemVerilog.

Treat this as a hardware design project, not a generic software repo. Make small, reviewable changes. Do not claim Motorola/68851/68030 compatibility beyond behavior that is implemented, tested, or explicitly documented.

## Operating rules

- Prefer the smallest change that satisfies the requested task.
- Do not edit unrelated packets or subsystems.
- Do not rename files or reorganize directories unless explicitly requested.
- Do not install packages unless explicitly requested.
- Do not run long builds, FPGA synthesis, implementation, or bitstream generation unless explicitly requested.
- Do not use subagents unless explicitly requested.
- Do not use broad repo-wide exploratory tasks when a focused task is available.
- Before reporting success, state exactly what files changed and what checks were run.

## Toolchain rules

For RTL-only lint, prefer focused Verilator commands over broad whole-repo lint.

Known local tools may include:
- Verilator for lint/static checks.
- Icarus Verilog/vvp for simple dynamic simulations.
- Vivado for FPGA work, normally run manually by the project owner on Windows unless explicitly requested otherwise.

Do not assume a tool exists. Check before relying on it.

## Quality rules

- Keep RTL deterministic and synthesizable unless the file is clearly a testbench.
- Keep testbench-only constructs out of RTL.
- Add or update tests when changing behavior.
- Preserve existing public module interfaces unless the task explicitly requires an interface change.
- Do not silence lint warnings without explaining why.
- Do not overstate validation. Distinguish lint, simulation, synthesis, implementation, and real-board smoke testing.

## Documentation rules

- Documentation must match the current RTL and observed validation state.
- Mark smoke tests as smoke tests, not full architectural validation.
- Keep board bring-up notes factual and reproducible.
- When uncertain, write down the uncertainty instead of guessing.

## Current local-agent note

The repository currently has a tracked `.codex` file from an earlier Codex/IDE pass. Do not modify or remove it unless explicitly requested.
