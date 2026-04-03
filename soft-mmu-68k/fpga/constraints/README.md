# FPGA Constraint Notes

The Basys 3 smoke demo does not maintain a hand-written board-specific XDC.
Instead, the Vivado source-add script filters the stock Digilent-style master
XDC into a generated demo-only constraints file.

## Generated filtered XDC flow

Source files:
- `fpga/basys3/xdc/Basys-3-Master.xdc`
- `fpga/basys3/vivado/add_sources.tcl`

Generated output:
- `fpga/basys3/vivado/build/generated/basys3_mmu_demo.xdc`

`add_sources.tcl` reads the master XDC, strips comment markers from candidate
lines, and keeps only lines that match the demo top plus a few required board
properties:
- port constraints for `clk`
- port constraints for `btnC`
- port constraints for `sw[15:0]`
- port constraints for `led[15:0]`
- the `create_clock` line for the 100 MHz oscillator
- bottom-of-file configuration properties such as `CONFIG_VOLTAGE`, `CFGBVS`,
  bitstream compression, config rate, and config mode

This keeps the Basys 3 naming aligned with the stock master XDC while leaving
the demo constraint set small and reviewable.

## Expected top-level ports

The generated XDC assumes the top module exposes exactly these board-facing
ports:
- `clk`
- `btnC`
- `sw[15:0]`
- `led[15:0]`

Those names match `fpga/basys3/tops/top_mmu_demo.v`.

## Bring-up findings

- `clk` correctly reuses the Basys 3 100 MHz oscillator pin and matching
  `create_clock` entry from the master XDC.
- `btnC` works as the active-high reset input used to restart the smoke flow.
- `sw[15:0]` are sufficient for the current canned VA, FC, mode, and page
  selection inputs.
- `led[15:0]` are sufficient for the compact result display used by the demo.

## Bring-up caveat

The initial synthesis attempt for the Basys 3 smoke demo failed because an
invisible non-printable/BOM-style character had made its way into the HDL
source set. That issue was corrected in the later bring-up pass, and the later
Vivado run succeeded, producing the smoke-demo results captured in the
workspace note `../smoke-results/test-results.txt`.

## Known issues / notes

- The generated XDC is intentionally tied to the current demo top. If the top
  module ports change, update `add_sources.tcl` so the generated filter stays in
  sync.
- This flow proves the current demo harness can be built and programmed on a
  Basys 3. It does not imply a reusable generic constraints flow for future
  boards or larger top-level integrations.
