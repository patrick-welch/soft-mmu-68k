# FPGA Constraint Notes

The Basys 3 smoke demo uses the existing Digilent-style master XDC at:

- `fpga/basys3/xdc/Basys-3-Master.xdc`

This packet does not introduce a new board constraint scheme. Instead, the
Vivado `add_sources.tcl` script derives a tiny generated XDC for the demo by
copying only the lines needed for the current top-level ports and uncommenting
them.

Expected top-level port names for the demo:

- `clk`
- `btnC`
- `sw[15:0]`
- `led[15:0]`

Assumptions behind the generated XDC:

- `clk` is the Basys 3 100 MHz oscillator and reuses the master XDC clock pin
  plus its `create_clock` line.
- `btnC` is used as a simple active-high reset button for the demo top.
- `sw[15:0]` are the only user inputs needed for the first-pass VA/control
  selection.
- `led[15:0]` are the only user-visible outputs needed for the compact
  hit/fault/status/result display.
- The master XDC configuration properties at the bottom of the file are copied
  through unchanged.

This keeps the board-facing naming aligned with the stock Basys 3 XDC comments
while letting the demo remain small and reviewable.
