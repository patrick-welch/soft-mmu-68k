# Soft MMU for 68K Systems

This repository holds a modular, synthesizable soft MMU for 68k-family systems.
The current tree has completed packets through `P11` plus the post-bring-up
cleanup/fix pass that made the Basys 3 smoke demo synthesize and run cleanly.

## Current status

Implemented now:
- `P1/P1b`: MMU register block with `CRP`, `SRP`, `TC`, `TT0`, `TT1`, and a
  first-pass software-visible `MMUSR` image.
- `P2/P2b`: `descriptor_pack` supports a Motorola-aligned long-format subset
  for root, pointer, and page descriptors.
- `P3/P3b`: Motorola-style FC decode plus user/supervisor read-write-execute
  permission checking.
- `P4`: direct-mapped TLB compare/store path.
- `P5`: minimal single-level page-table walker.
- `P6/P6b`: first-pass flush/probe/preload control shim with TT-aware probe
  status classification.
- `P7a/P7b/P7c`: FIFO utility plus minimal 68k-side and AXI-to-Wishbone-facing
  bus shims.
- `P8/P8b`: `mmu_top` integration, direct-mapped lookup/refill path, and a
  first-pass `TT0/TT1` qualification path ahead of the translated flow.
- `P9a/P9b`: shared testbench helpers and a stronger integration bench.
- `P10a/P10b`: freestanding 68k software-side validation scaffold for TT,
  permissions, and translated-vs-transparent maintenance behavior.
- `P11`: Basys 3 smoke-demo top and Vivado project flow.

First-pass only:
- `TT0/TT1` support is a narrow subset: base byte, mask byte, enable,
  user/supervisor matching, and program/data matching.
- `MMUSR`, `PTEST`, `PLOAD`, and `PFLUSH` behavior is a control-layer shim, not
  a full Motorola architectural model.
- `descriptor_pack` is Motorola-aligned, but the current walker/integration
  datapath still uses its own compact 32-bit page-descriptor image.
- The Basys 3 design is a built-in smoke harness, not a 68k SoC integration.

Still deferred:
- Full Motorola TT/TTR field decoding and legality rules.
- Full Motorola `MMUSR` synthesis and complete `PTEST` termination semantics.
- Multi-level page-walk behavior and broader descriptor-type coverage.
- A full bus-accurate system around the MMU.
- Real 68k CPU execution on hardware.

## Repo map

- `rtl/core/`: register block, decode/permissions, TLB, walker, control shim,
  and top-level MMU integration.
- `rtl/bus/`: first-pass external bus shims.
- `tb/unit/`: focused unit benches.
- `tb/integ/`: integration benches for the control path, top-level datapath,
  and bus shims.
- `sw/tests_68k/`: freestanding software-side expectation models.
- `fpga/basys3/`: demo top, master XDC, and Vivado scripts.
- `docs/design/`: design notes for the implemented subset and its caveats.

## Lint and simulation

The repo does not yet have a single top-level `make lint` target, so the
current workflow is explicit tool invocation. The commands below cover the main
packets that contributors are expected to touch.

In the current workspace, simple unit/control benches were the most portable
with local `iverilog`; the shared-package integration bench may require a newer
SystemVerilog-capable simulator build depending on your tool version.

Unit-level packets:

```sh
iverilog -g2012 -I . -o /tmp/mmu_regs_tb tb/unit/mmu_regs_tb.sv rtl/core/mmu_regs.v
vvp /tmp/mmu_regs_tb

iverilog -g2012 -I . -o /tmp/descriptor_pack_tb tb/unit/descriptor_pack_tb.sv rtl/core/descriptor_pack.v
vvp /tmp/descriptor_pack_tb

iverilog -g2012 -I . -o /tmp/perm_check_tb tb/unit/perm_check_tb.sv rtl/core/perm_check.v rtl/core/mmu_decode.v
vvp /tmp/perm_check_tb

iverilog -g2012 -I . -o /tmp/tlb_dm_tb tb/unit/tlb_dm_tb.sv rtl/core/tlb_compare.v rtl/core/tlb_dm.v
vvp /tmp/tlb_dm_tb

iverilog -g2012 -I . -o /tmp/pt_walker_tb tb/unit/pt_walker_tb.sv rtl/core/pt_walker.v
vvp /tmp/pt_walker_tb
```

Integration-level packets:

```sh
iverilog -g2012 -I . -o /tmp/instr_shim_tb tb/integ/instr_shim_tb.sv rtl/core/flush_ctrl.v
vvp /tmp/instr_shim_tb

iverilog -g2012 -I . -o /tmp/mmu_core_tb tb/integ/mmu_core_tb.sv rtl/core/mmu_top.v
vvp /tmp/mmu_core_tb

iverilog -g2012 -I . -o /tmp/if_68k_shim_tb tb/integ/if_68k_shim_tb.sv rtl/bus/if_68k_shim.v
vvp /tmp/if_68k_shim_tb

iverilog -g2012 -I . -o /tmp/if_axi_wb_bridge_tb tb/integ/if_axi_wb_bridge_tb.sv rtl/bus/if_axi_wb_bridge.v
vvp /tmp/if_axi_wb_bridge_tb
```

Representative structural lint:

```sh
verilator --lint-only -Wall -I. \
  rtl/core/mmu_regs.v rtl/core/mmu_decode.v rtl/core/perm_check.v \
  rtl/core/tlb_compare.v rtl/core/tlb_dm.v rtl/core/pt_walker.v \
  rtl/core/flush_ctrl.v rtl/core/mmu_top.v fpga/basys3/tops/top_mmu_demo.v
```

Note: the repo is not yet warning-clean under `verilator -Wall`; the Basys 3
demo top still emits known empty-pin and unused-signal warnings in the current
state.

Software scaffold:

```sh
make -f sw/build/Makefile all \
  CC_68K=m68k-elf-gcc \
  CFLAGS_68K="-mc68020 -O2 -ffreestanding -Wall -Wextra"
```

## Basys 3 smoke demo

### What the demo configures

On reset, `fpga/basys3/tops/top_mmu_demo.v` programs:
- `CRP = 0x001000`
- `TC = 0x00000FFF`
- `TT0 = 0xF000F800`
- `TT1 = 0x00000000`

The built-in descriptor responder models four small cases:
- page `0`: valid user-accessible translated page at PFN `0x040`
- page `1`: valid supervisor-only translated page at PFN `0x041`
- page `2`: invalid descriptor
- page `3`: abstract bus-error response

### Front-panel controls

- `btnC`: active-high reset.
- `sw[15]`: select TT-qualified region (`1` => VA high byte `0xF0`, `0` => translated region `0x00`).
- `sw[14:13]`: mode
  `00` access
  `01` probe
  `10` preload then access+probe
  `11` targeted flush-match then access+probe
- `sw[12]`: supervisor (`1`) vs user (`0`)
- `sw[11]`: program/fetch (`1`) vs data (`0`)
- `sw[10]`: write (`1`) vs read (`0`)
- `sw[9:8]`: demo page selector
- `sw[7:0]`: low VA offset bits

LEDs:
- `led[0]`: MMU busy
- `led[1]`: last access fault
- `led[2]`: last translated hit flag
- `led[3]`: last status/probe hit flag
- `led[4]`: last translated-status class bit
- `led[5]`: last TT-match status class bit
- `led[8:6]`: last access fault code
- `led[15:9]`: upper slice of the displayed PA/result

### Bring-up flow

1. Open Vivado in the repo root.
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

The constraint flow is intentionally small: `add_sources.tcl` filters the stock
Basys 3 master XDC into a generated XDC that keeps only the ports needed by the
demo. See `fpga/constraints/README.md` for details.

### What the board demo proves

The successful Basys 3 smoke run shows that the current FPGA harness can:
- configure the MMU register block from the demo top
- execute translated access and probe flows on hardware
- show a TT-qualified identity-style result distinct from a translated result
- show a user permission-fault case on the board
- rerun the canned flow from switch settings without editing HDL

Observed post-bring-up smoke cases from the workspace note
`../smoke-results/test-results.txt`:
- all switches low: translated access/probe smoke case
- `SW15=1`: TT-qualified identity-style smoke case
- `SW8=1`: user access to the supervisor-only translated page faults
- `SW12=1` and `SW8=1`: supervisor access to that same translated page succeeds

### What the board demo does not prove

It does not prove:
- full Motorola PMMU architectural behavior
- complete TT/TTR legality handling
- full `MMUSR` or `PTEST` compatibility
- multi-level page walks or a complete descriptor tree
- real CPU instruction execution through a 68k core
- full-system bus timing or software integration

## Known issues and bring-up notes

- The board demo is intentionally a smoke demo. Treat it as proof that the
  current subset builds and toggles correctly on hardware, not as full-system
  validation.
- `resp_hit_o` is reserved for translated/TLB-backed hits. A successful TT
  bypass reports success through `resp_valid_o`/`status_hit_o`, but does not
  claim a translated hit.
- The TT subset is intentionally narrow and should not be described as full
  Motorola transparent translation support.
- The first successful Basys 3 bring-up happened after correcting an earlier
  Vivado synthesis failure caused by an invisible non-printable/BOM-style
  character in the source set. The later corrected run succeeded and produced
  the smoke results captured in `../smoke-results/test-results.txt`.

For the current TT subset and descriptor caveats, start with
`docs/design/address_map.md` and `docs/design/descriptor_formats.md`.
